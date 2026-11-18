import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/db/database.dart';
import '../../data/repositories/deck_repository.dart';
import '../../data/repositories/stats_repository.dart';
import '../../data/repositories/study_repository.dart';
import '../common/ios.dart';
import '../editor/note_editor_screen.dart';
import '../study/study_screen.dart';
import '../theme/app_theme.dart';
import 'deck_actions.dart';

/// Home tab, "Сегодня": a summary of today's work with one button that
/// studies every deck, then the decks themselves as an inset grouped list.
class DeckListScreen extends StatefulWidget {
  const DeckListScreen({super.key, this.refreshToken = 0});

  /// Bumped by the tab bar each time this tab is re-opened, so counts that
  /// changed elsewhere (a card added from another tab) are reloaded.
  final int refreshToken;

  @override
  State<DeckListScreen> createState() => _DeckListScreenState();
}

class _DeckListScreenState extends State<DeckListScreen> {
  StreamSubscription<List<Deck>>? _sub;
  List<Deck>? _decks;
  Map<int, DueQueueCounts> _counts = const {};
  StudyHabit? _habit;
  int _loadGeneration = 0;

  @override
  void initState() {
    super.initState();
    _sub = context.read<DeckRepository>().watchDecks().listen((decks) {
      _decks = decks;
      _reload();
    });
  }

  @override
  void didUpdateWidget(DeckListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshToken != widget.refreshToken) _reload();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _reload() async {
    final decks = _decks;
    if (decks == null) return;
    final generation = ++_loadGeneration;
    final study = context.read<StudyRepository>();
    final stats = context.read<StatsRepository>();
    final counts = <int, DueQueueCounts>{};
    for (final d in decks) {
      counts[d.id] = await study.counts(d.id);
    }
    final habit = await stats.habit();
    // A newer reload started while this one was running: drop the stale result.
    if (!mounted || generation != _loadGeneration) return;
    setState(() {
      _counts = counts;
      _habit = habit;
    });
  }

  Future<void> _push(Widget screen) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
    if (mounted) _reload();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final decks = _decks;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          CupertinoSliverNavigationBar(
            largeTitle: const Text('Сегодня'),
            backgroundColor: colors.bg.withValues(alpha: 0.94),
            border: null,
            trailing: CupertinoButton(
              padding: EdgeInsets.zero,
              minimumSize: const Size(44, 44),
              onPressed: () => _push(const NoteEditorScreen()),
              child: Icon(
                CupertinoIcons.plus,
                size: 26,
                color: context.accentForeground,
                semanticLabel: 'Новая карточка',
              ),
            ),
          ),
          if (decks == null)
            const SliverFillRemaining(child: Center(child: CupertinoActivityIndicator()))
          else if (decks.isEmpty)
            SliverFillRemaining(hasScrollBody: false, child: _EmptyState(onCreate: () => createDeckWithPrompt(context)))
          else
            SliverList.list(children: [
              Padding(
                // Same left edge as the large title above it.
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Text(_todayLabel(DateTime.now()), style: TextStyle(fontSize: 15, color: colors.muted)),
              ),
              const SizedBox(height: AppSpacing.md),
              _TodayCard(
                counts: _counts,
                habit: _habit,
                onStart: () => _push(const StudyScreen(deckId: null, deckName: 'Все колоды')),
                onAddCard: () => _push(const NoteEditorScreen()),
              ),
              SectionHeader(
                'Колоды',
                trailing: _Legend(colors: colors),
              ),
              GroupedSection(children: [
                for (final deck in decks)
                  _DeckRow(
                    deck: deck,
                    counts: _counts[deck.id],
                    onTap: () => _push(StudyScreen(deckId: deck.id, deckName: deck.name)),
                    onLongPress: () async {
                      await showDeckActions(context, deck);
                      if (mounted) _reload();
                    },
                  ),
              ]),
              const SectionFooter('Удерживайте колоду, чтобы открыть карточки, настройки и другие действия.'),
              _NewDeckLink(onAdd: () => createDeckWithPrompt(context)),
            ]),
        ],
      ),
    );
  }

  static const _weekdays = ['понедельник', 'вторник', 'среда', 'четверг', 'пятница', 'суббота', 'воскресенье'];
  static const _months = [
    'января', 'февраля', 'марта', 'апреля', 'мая', 'июня',
    'июля', 'августа', 'сентября', 'октября', 'ноября', 'декабря',
  ];

  static String _todayLabel(DateTime d) {
    final weekday = _weekdays[d.weekday - 1];
    return '${weekday[0].toUpperCase()}${weekday.substring(1)}, ${d.day} ${_months[d.month - 1]}';
  }
}

/// "+ Новая колода" link under the deck list.
class _NewDeckLink extends StatelessWidget {
  const _NewDeckLink({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.xl),
      child: Align(
        alignment: Alignment.centerLeft,
        child: CupertinoButton(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          onPressed: onAdd,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(CupertinoIcons.add_circled, size: 20, color: context.accentForeground),
              const SizedBox(width: 6),
              Text('Новая колода', style: TextStyle(fontSize: 16, color: context.accentForeground)),
            ],
          ),
        ),
      ),
    );
  }
}

String plural(int n, String one, String few, String many) {
  final mod10 = n % 10;
  final mod100 = n % 100;
  if (mod10 == 1 && mod100 != 11) return one;
  if (mod10 >= 2 && mod10 <= 4 && (mod100 < 12 || mod100 > 14)) return few;
  return many;
}

/// Colours of the three per-deck numbers, matching Anki's own convention.
class DueColors {
  const DueColors._();
  static Color newCards(bool dark) => dark ? const Color(0xFF7FAEDB) : AppColors.easy;
  static Color learning(bool dark) => dark ? const Color(0xFFE08B89) : AppColors.again;
  static Color review(bool dark) => dark ? const Color(0xFF6FC2A2) : AppColors.good;
}

class _Legend extends StatelessWidget {
  const _Legend({required this.colors});

  final AppSemanticColors colors;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    Widget dot(Color c, String label) => Padding(
          padding: const EdgeInsets.only(left: 10),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 7, height: 7, decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(fontSize: 12, color: colors.muted)),
          ]),
        );
    return Row(mainAxisSize: MainAxisSize.min, children: [
      dot(DueColors.newCards(dark), 'новые'),
      dot(DueColors.learning(dark), 'учу'),
      dot(DueColors.review(dark), 'повтор'),
    ]);
  }
}

class _TodayCard extends StatelessWidget {
  const _TodayCard({required this.counts, required this.habit, required this.onStart, required this.onAddCard});

  final Map<int, DueQueueCounts> counts;
  final StudyHabit? habit;
  final VoidCallback onStart;
  final VoidCallback onAddCard;

  @override
  Widget build(BuildContext context) {
    final total = counts.values.fold<int>(0, (s, c) => s + c.total);
    final habit = this.habit;
    final done = total == 0;
    const onCard = Colors.white;
    final onCardMuted = Colors.white.withValues(alpha: 0.78);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Container(
        // Same inner padding as the deck rows, so the card's text and the
        // deck names start on one line.
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.circular(20)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(done ? 'На сегодня всё' : 'К повторению', style: TextStyle(fontSize: 14, color: onCardMuted)),
            const SizedBox(height: 2),
            if (done)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 4),
                child: Row(children: [
                  Icon(CupertinoIcons.checkmark_seal_fill, color: onCard, size: 34),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Все карточки повторены',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: onCard),
                    ),
                  ),
                ]),
              )
            else
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '$total',
                    style: const TextStyle(fontSize: 44, fontWeight: FontWeight.w700, color: onCard, letterSpacing: -1),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${plural(total, 'карточка', 'карточки', 'карточек')}'
                      '${habit == null ? '' : ' · ≈ ${habit.estimateMinutes(total)} мин'}',
                      style: TextStyle(fontSize: 15, color: onCardMuted),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: AppSpacing.md),
            _WeekStrip(habit: habit),
            const SizedBox(height: 6),
            Text(_streakLabel(habit), style: TextStyle(fontSize: 13, color: onCardMuted)),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              child: CupertinoButton(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                padding: const EdgeInsets.symmetric(vertical: 13),
                onPressed: done ? onAddCard : onStart,
                child: Text(
                  done ? 'Добавить карточку' : 'Начать занятие',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.accentStrong),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _streakLabel(StudyHabit? habit) {
    if (habit == null) return ' ';
    final n = habit.streakDays;
    if (n == 0) return 'Начните серию сегодня';
    return '$n ${plural(n, 'день', 'дня', 'дней')} подряд';
  }
}

class _WeekStrip extends StatelessWidget {
  const _WeekStrip({required this.habit});

  final StudyHabit? habit;

  @override
  Widget build(BuildContext context) {
    final week = habit?.lastWeek ?? List.filled(7, false);
    return Row(
      children: [
        for (var i = 0; i < week.length; i++) ...[
          if (i > 0) const SizedBox(width: 4),
          Expanded(
            child: Container(
              height: 5,
              decoration: BoxDecoration(
                color: week[i] ? const Color(0xFFA6D8C4) : Colors.white.withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _DeckRow extends StatelessWidget {
  const _DeckRow({required this.deck, required this.counts, required this.onTap, required this.onLongPress});

  final Deck deck;
  final DueQueueCounts? counts;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final counts = this.counts;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final finished = counts != null && counts.total == 0;

    Widget number(int n, Color c) => n == 0
        ? const SizedBox.shrink()
        : Padding(
            padding: const EdgeInsets.only(left: 10),
            child: Text(
              '$n',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: c, fontFeatures: const [
                FontFeature.tabularFigures(),
              ]),
            ),
          );

    return GroupedRow(
      title: deck.name,
      muted: finished,
      onTap: onTap,
      onLongPress: onLongPress,
      trailing: counts == null
          ? const SizedBox.shrink()
          : finished
              ? Icon(CupertinoIcons.checkmark_alt, size: 18, color: DueColors.review(dark))
              : Row(mainAxisSize: MainAxisSize.min, children: [
                  number(counts.newCount, DueColors.newCards(dark)),
                  number(counts.learningCount, DueColors.learning(dark)),
                  number(counts.reviewCount, DueColors.review(dark)),
                ]),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(CupertinoIcons.rectangle_stack_badge_plus, size: 52, color: AppColors.accent),
          const SizedBox(height: AppSpacing.lg),
          Text('Создайте первую колоду', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Соберите карточки по теме, а расписание повторений приложение рассчитает само.',
            style: TextStyle(fontSize: 15, height: 1.4, color: colors.muted),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),
          FilledButton(onPressed: onCreate, child: const Text('Создать колоду')),
        ],
      ),
    );
  }
}
