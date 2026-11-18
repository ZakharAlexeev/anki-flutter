import 'dart:io';
import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';

import '../../data/db/database.dart';
import '../../data/media/media_resolver.dart';
import '../../data/media/pronunciation_service.dart';
import '../../data/repositories/deck_repository.dart';
import '../../data/repositories/note_repository.dart';
import '../../data/repositories/notetype_repository.dart';
import '../../data/repositories/study_repository.dart';
import '../../domain/scheduler/scheduler.dart' show IntervalKind, InSecs, InDays;
import '../../domain/template_renderer.dart';
import '../theme/app_theme.dart';
import 'html_view.dart';

/// A study session: one deck, or every deck at once when [deckId] is null.
///
/// Layout follows iOS conventions: a close button and thin progress bar on
/// top, the card filling the screen (tap it to flip), and the four rating
/// buttons in a single row at the bottom where the thumb rests. On desktop,
/// Space/Enter reveal the answer and 1-4 rate it.
class StudyScreen extends StatefulWidget {
  const StudyScreen({super.key, required this.deckId, required this.deckName});

  final int? deckId;
  final String deckName;

  @override
  State<StudyScreen> createState() => _StudyScreenState();
}

class _StudyScreenState extends State<StudyScreen> {
  List<CardEntry> _queue = [];
  bool _loading = true;
  bool _showAnswer = false;
  bool _answering = false;
  int _answered = 0;
  String? _error;
  RenderedCard? _rendered;
  String? _cardDeckName;
  String? _resolvedQuestionHtml;
  String? _resolvedAnswerHtml;
  Map<Rating, IntervalKind>? _previews;
  DateTime? _cardShownAt;
  List<String> _questionSounds = const [];
  List<String> _answerSounds = const [];
  final _media = MediaResolver();
  final _focusNode = FocusNode();

  // Created on first use, so screens (and tests) without audio never touch
  // the platform audio plugin.
  AudioPlayer? _player;
  int _playToken = 0;

  /// Answers given in this session, newest last, for Undo.
  final List<UndoEntry> _undoStack = [];

  StudyRepository get _study => context.read<StudyRepository>();
  NoteRepository get _notes => context.read<NoteRepository>();
  NotetypeRepository get _notetypes => context.read<NotetypeRepository>();

  @override
  void initState() {
    super.initState();
    _loadQueue();
  }

  @override
  void dispose() {
    _playToken++;
    _player?.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  List<String> get _currentSounds => _showAnswer ? _answerSounds : _questionSounds;

  /// Plays [files] one after another, like Anki; an empty list just stops.
  /// Starting another playback cancels whatever is still queued.
  Future<void> _play(List<String> files) async {
    final token = ++_playToken;
    if (files.isEmpty) {
      await _player?.stop();
      return;
    }
    final dir = await PronunciationService.mediaDirectory();
    final player = _player ??= AudioPlayer();
    for (final name in files) {
      final file = File(p.join(dir.path, p.basename(name)));
      if (token != _playToken || !mounted) return;
      if (!await file.exists()) continue;
      try {
        final done = player.onPlayerComplete.first;
        await player.stop();
        await player.play(DeviceFileSource(file.path));
        await done.timeout(const Duration(seconds: 30));
      } catch (_) {
        // A missing codec or a broken file shouldn't interrupt studying.
      }
    }
  }

  Future<List<CardEntry>> _fetchQueue() {
    final id = widget.deckId;
    return id == null ? _study.dueQueueAll() : _study.dueQueue(id);
  }

  Future<void> _loadQueue() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final queue = await _fetchQueue();
      if (!mounted) return;
      setState(() {
        _queue = queue;
        _loading = false;
        _showAnswer = false;
      });
      if (queue.isNotEmpty) await _renderCurrent();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Не удалось загрузить карточки: $e';
      });
    }
  }

  CardEntry get _current => _queue.first;

  Future<void> _renderCurrent() async {
    final card = _current;
    final db = context.read<AppDatabase>();
    final decks = context.read<DeckRepository>();
    final noteRow = await (db.select(db.notes)..where((n) => n.id.equals(card.noteId))).getSingle();
    final fields = _notes.decodeFields(noteRow.fieldsJson);
    final templates = await _notetypes.templatesFor(noteRow.notetypeId);
    final template = templates.firstWhere((t) => t.ord == card.templateOrd, orElse: () => templates.first);
    final fieldDefs = await _notetypes.fieldsFor(noteRow.notetypeId);
    final notetype = await _notetypes.notetype(noteRow.notetypeId);
    final deckName = widget.deckId == null ? (await decks.deckById(card.deckId)).name : widget.deckName;

    final rendered = renderCard(
      template: template,
      fieldDefs: fieldDefs,
      fieldValues: fields,
      css: notetype?.css ?? '',
      tags: noteRow.tags,
      deckName: deckName,
      notetypeName: notetype?.name ?? '',
    );
    final previews = await _study.previewOutcomes(card.id);
    final resolvedQuestion = await _media.resolve(rendered.questionHtml);
    final resolvedAnswer = await _media.resolve(rendered.answerHtml);
    if (!mounted) return;
    final questionSounds = MediaResolver.soundFiles(rendered.questionHtml);
    setState(() {
      _rendered = rendered;
      _cardDeckName = deckName;
      _resolvedQuestionHtml = resolvedQuestion;
      _resolvedAnswerHtml = resolvedAnswer;
      _previews = previews;
      _cardShownAt = DateTime.now();
      _questionSounds = questionSounds;
      _answerSounds = MediaResolver.soundFiles(rendered.answerHtml);
    });
    // Audio plays only when asked for (the speaker button), never on its
    // own; a new card just silences whatever the last one was playing.
    _play(const []);
  }

  void _reveal() {
    if (_showAnswer || _rendered == null) return;
    HapticFeedback.selectionClick();
    setState(() => _showAnswer = true);
    _play(const []);
  }

  Future<void> _answer(Rating rating) async {
    if (_answering || !_showAnswer) return; // guard against a double tap re-answering the same card twice
    HapticFeedback.lightImpact();
    setState(() => _answering = true);

    final elapsedMs = _cardShownAt == null ? 0 : DateTime.now().difference(_cardShownAt!).inMilliseconds;
    try {
      final result = await _study.answerCard(cardId: _current.id, rating: rating, timeTakenMs: elapsedMs);
      _undoStack.add(result.undo);
      final freshQueue = await _fetchQueue();
      if (!mounted) return;
      _showCard(freshQueue, answered: _answered + 1);
      if (result.outcome.becameLeech && mounted) {
        final suspended = result.outcome.state.queue == CardQueue.suspended;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(suspended
              ? 'Трудная карточка: её часто забывают, поэтому она отложена'
              : 'Трудная карточка: её часто забывают — добавлена метка leech'),
        ));
      }
      if (_queue.isNotEmpty) await _renderCurrent();
    } catch (e) {
      if (!mounted) return;
      setState(() => _answering = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
    }
  }

  /// Takes the last answer back and shows that card again, question side
  /// up - like Anki's Undo. Several answers can be undone in a row.
  Future<void> _undo() async {
    if (_answering || _undoStack.isEmpty) return;
    HapticFeedback.selectionClick();
    setState(() => _answering = true);
    final entry = _undoStack.removeLast();
    try {
      await _study.undo(entry);
      final fresh = await _fetchQueue();
      // The restored card comes back first, wherever its old state would
      // otherwise have placed it in the queue.
      final i = fresh.indexWhere((c) => c.id == entry.cardId);
      if (i > 0) fresh.insert(0, fresh.removeAt(i));
      if (!mounted) return;
      _showCard(fresh, answered: max(0, _answered - 1));
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Ответ отменён'), duration: Duration(seconds: 1)));
      if (_queue.isNotEmpty) await _renderCurrent();
    } catch (e) {
      if (!mounted) return;
      setState(() => _answering = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Не удалось отменить: $e')));
    }
  }

  void _showCard(List<CardEntry> queue, {required int answered}) {
    setState(() {
      _queue = queue;
      _answered = answered;
      _showAnswer = false;
      _rendered = null;
      _resolvedQuestionHtml = null;
      _resolvedAnswerHtml = null;
      _previews = null;
      _answering = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.space): _reveal,
        const SingleActivator(LogicalKeyboardKey.enter): _reveal,
        const SingleActivator(LogicalKeyboardKey.digit1): () => _answer(Rating.again),
        const SingleActivator(LogicalKeyboardKey.digit2): () => _answer(Rating.hard),
        const SingleActivator(LogicalKeyboardKey.digit3): () => _answer(Rating.good),
        const SingleActivator(LogicalKeyboardKey.digit4): () => _answer(Rating.easy),
        const SingleActivator(LogicalKeyboardKey.keyZ, control: true): _undo,
        const SingleActivator(LogicalKeyboardKey.keyZ, meta: true): _undo,
      },
      child: Focus(
        focusNode: _focusNode,
        autofocus: true,
        child: Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                _TopBar(
                  answered: _answered,
                  remaining: _queue.length,
                  loading: _loading,
                  onUndo: _undoStack.isEmpty || _answering ? null : _undo,
                ),
                Expanded(
                  child: _loading
                      ? const Center(child: CupertinoActivityIndicator())
                      : _error != null
                          ? _ErrorState(message: _error!, onRetry: _loadQueue)
                          : _queue.isEmpty
                              ? _AllDoneState(answered: _answered)
                              : _buildStudyBody(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStudyBody() {
    final rendered = _rendered;
    final questionHtml = _resolvedQuestionHtml;
    final answerHtml = _resolvedAnswerHtml;
    if (rendered == null || questionHtml == null || answerHtml == null) {
      return const Center(child: CupertinoActivityIndicator());
    }
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, 0),
                child: GestureDetector(
                  onTap: _reveal,
                  behavior: HitTestBehavior.opaque,
                  // Keyed by card so moving to the next card swaps instantly;
                  // only question -> answer of the same card flips.
                  child: KeyedSubtree(
                    key: ValueKey(_current.id),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 380),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      transitionBuilder: _flipTransition,
                      layoutBuilder: (current, previous) => Stack(children: [...previous, ?current]),
                      child: _CardFace(
                        key: ValueKey<bool>(_showAnswer),
                        deckName: _cardDeckName ?? widget.deckName,
                        html: _showAnswer ? answerHtml : questionHtml,
                        css: rendered.css,
                        onPlaySound: _currentSounds.isEmpty ? null : () => _play(_currentSounds),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.md),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: _showAnswer ? _buildAnswerButtons() : _buildShowAnswerButton(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Rotates the outgoing face away to 90° and the incoming one in from
  /// 90°, so the card appears to turn over.
  Widget _flipTransition(Widget child, Animation<double> animation) {
    final rotate = Tween(begin: pi, end: 0.0).animate(animation);
    return AnimatedBuilder(
      animation: rotate,
      child: child,
      builder: (context, child) {
        final isUnder = child!.key != ValueKey<bool>(_showAnswer);
        final tilt = ((animation.value - 0.5).abs() - 0.5) * 0.0025 * (isUnder ? -1.0 : 1.0);
        final angle = isUnder ? min(rotate.value, pi / 2) : rotate.value;
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.rotationY(angle)..setEntry(3, 0, tilt),
          // Past 90° the face is turned away; hide it rather than show it mirrored.
          child: angle > pi / 2 ? const SizedBox.shrink() : child,
        );
      },
    );
  }

  Widget _buildShowAnswerButton() {
    return Column(
      key: const ValueKey('show'),
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: double.infinity,
          height: 52,
          child: FilledButton(
            style: FilledButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
            onPressed: _reveal,
            child: const Text('Показать ответ', style: TextStyle(fontSize: 16)),
          ),
        ),
        const SizedBox(height: 6),
        Text('или коснитесь карточки', style: TextStyle(fontSize: 12.5, color: context.appColors.muted)),
      ],
    );
  }

  Widget _buildAnswerButtons() {
    final previews = _previews;
    return Row(
      key: const ValueKey('rate'),
      children: [
        for (final (rating, label, color) in const [
          (Rating.again, 'Снова', AppColors.again),
          (Rating.hard, 'Трудно', AppColors.hard),
          (Rating.good, 'Хорошо', AppColors.good),
          (Rating.easy, 'Легко', AppColors.easy),
        ]) ...[
          if (rating != Rating.again) const SizedBox(width: 6),
          Expanded(
            child: _RatingButton(
              label: label,
              interval: previews?[rating] == null ? null : _intervalLabel(previews![rating]!),
              color: color,
              onTap: _answering ? null : () => _answer(rating),
            ),
          ),
        ],
      ],
    );
  }

  /// The label above a button, chosen and rounded like Anki's
  /// `answer_button_time`: seconds, minutes and days as whole numbers,
  /// hours, months (a twelfth of a year) and years to one decimal.
  String _intervalLabel(IntervalKind kind) {
    final secs = switch (kind) {
      InSecs(:final secs) => secs.toDouble(),
      InDays(:final days) => days * 86400.0,
    };
    const minute = 60.0, hour = 3600.0, day = 86400.0, year = 365 * day, month = year / 12;
    String oneDecimal(double v) {
      final r = (v * 10).round() / 10;
      return r == r.roundToDouble() ? r.toStringAsFixed(0) : r.toStringAsFixed(1).replaceAll('.', ',');
    }

    if (secs < minute) return '${secs.round()} с';
    if (secs < hour) return '${(secs / minute).round()} мин';
    if (secs < day) return '${oneDecimal(secs / hour)} ч';
    if (secs < month) return '${(secs / day).round()} д';
    if (secs < year) return '${oneDecimal(secs / month)} мес';
    return '${oneDecimal(secs / year)} г';
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.answered, required this.remaining, required this.loading, this.onUndo});

  final int answered;
  final int remaining;
  final bool loading;

  /// Undoes the last answer; null (button greyed out) when there is none.
  final VoidCallback? onUndo;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final total = answered + remaining;
    final progress = total == 0 ? (loading ? 0.0 : 1.0) : answered / total;
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.xs, AppSpacing.xs, AppSpacing.xs, 0),
      child: Row(
        children: [
          CupertinoButton(
            padding: const EdgeInsets.all(AppSpacing.sm + 2),
            onPressed: () => Navigator.of(context).maybePop(),
            child: Icon(CupertinoIcons.xmark, size: 22, color: context.accentForeground, semanticLabel: 'Закрыть'),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: TweenAnimationBuilder<double>(
                tween: Tween(end: progress),
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
                builder: (context, value, _) => LinearProgressIndicator(
                  value: value,
                  minHeight: 5,
                  backgroundColor: colors.surfaceAlt,
                  color: AppColors.accent,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm + 4),
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 34),
            child: Text(
              total == 0 ? '' : '$answered/$total',
              textAlign: TextAlign.right,
              style: TextStyle(fontSize: 13, color: colors.muted, fontFeatures: const [FontFeature.tabularFigures()]),
            ),
          ),
          CupertinoButton(
            padding: const EdgeInsets.all(AppSpacing.sm + 2),
            onPressed: onUndo,
            child: Icon(
              CupertinoIcons.arrow_uturn_left,
              size: 21,
              color: onUndo == null ? colors.muted.withValues(alpha: 0.35) : context.accentForeground,
              semanticLabel: 'Отменить ответ',
            ),
          ),
        ],
      ),
    );
  }
}

class _CardFace extends StatelessWidget {
  const _CardFace({super.key, required this.deckName, required this.html, required this.css, this.onPlaySound});

  final String deckName;
  final String html;
  final String css;

  /// Replays this side's audio; null when the side has none.
  final VoidCallback? onPlaySound;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: colors.border.withValues(alpha: 0.6)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.md),
            child: Text(deckName, style: TextStyle(fontSize: 12.5, color: colors.muted)),
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: max(0, constraints.maxHeight - AppSpacing.md * 2)),
                  // As in the design mock-up: the speaker sits centred right
                  // under the word, part of the card rather than a toolbar.
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        HtmlView(html: html, css: css),
                        if (onPlaySound != null)
                          Padding(
                            padding: const EdgeInsets.only(top: AppSpacing.md),
                            child: CupertinoButton(
                              padding: const EdgeInsets.all(AppSpacing.sm + 2),
                              minimumSize: const Size(48, 48),
                              onPressed: onPlaySound,
                              child: Icon(
                                CupertinoIcons.speaker_2,
                                size: 28,
                                color: context.accentForeground,
                                semanticLabel: 'Прослушать произношение',
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RatingButton extends StatelessWidget {
  const _RatingButton({required this.label, required this.interval, required this.color, required this.onTap});

  final String label;
  final String? interval;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final fg = dark ? Color.lerp(color, Colors.white, 0.35)! : color;
    return Material(
      color: color.withValues(alpha: dark ? 0.22 : 0.12),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: SizedBox(
          height: 60,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(label, style: TextStyle(color: fg, fontWeight: FontWeight.w600, fontSize: 15)),
              if (interval != null) ...[
                const SizedBox(height: 2),
                Text(interval!, style: TextStyle(color: fg.withValues(alpha: 0.8), fontSize: 12)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _AllDoneState extends StatelessWidget {
  const _AllDoneState({required this.answered});

  final int answered;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: const BoxDecoration(color: AppColors.accent, shape: BoxShape.circle),
              child: const Icon(CupertinoIcons.checkmark_alt, size: 40, color: Colors.white),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('На сегодня всё', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppSpacing.sm),
            Text(
              answered == 0
                  ? 'Карточек для повторения больше нет'
                  : 'Повторено карточек: $answered. Возвращайтесь завтра.',
              style: TextStyle(fontSize: 15, color: colors.muted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            SizedBox(
              width: 220,
              child: FilledButton(onPressed: () => Navigator.of(context).maybePop(), child: const Text('Готово')),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(CupertinoIcons.exclamationmark_circle, size: 40, color: colors.muted),
            const SizedBox(height: AppSpacing.md),
            Text(message, style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.lg),
            OutlinedButton(onPressed: onRetry, child: const Text('Повторить')),
          ],
        ),
      ),
    );
  }
}
