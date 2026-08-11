import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/db/database.dart';
import '../../data/repositories/note_repository.dart';
import '../../data/repositories/notetype_repository.dart';
import '../../data/repositories/study_repository.dart';
import '../../domain/template_renderer.dart';
import 'html_view.dart';

class StudyScreen extends StatefulWidget {
  const StudyScreen({super.key, required this.deckId, required this.deckName});

  final int deckId;
  final String deckName;

  @override
  State<StudyScreen> createState() => _StudyScreenState();
}

class _StudyScreenState extends State<StudyScreen> {
  List<CardEntry> _queue = [];
  bool _loading = true;
  bool _showAnswer = false;
  RenderedCard? _rendered;
  Map<Rating, CardSchedState>? _previews;

  StudyRepository get _study => context.read<StudyRepository>();
  NoteRepository get _notes => context.read<NoteRepository>();
  NotetypeRepository get _notetypes => context.read<NotetypeRepository>();

  @override
  void initState() {
    super.initState();
    _loadQueue();
  }

  Future<void> _loadQueue() async {
    setState(() => _loading = true);
    final queue = await _study.dueQueue(widget.deckId);
    setState(() {
      _queue = queue;
      _loading = false;
      _showAnswer = false;
    });
    if (queue.isNotEmpty) await _renderCurrent();
  }

  CardEntry get _current => _queue.first;

  Future<void> _renderCurrent() async {
    final card = _current;
    final db = context.read<AppDatabase>();
    final noteRow = await (db.select(db.notes)..where((n) => n.id.equals(card.noteId))).getSingle();
    final fields = _notes.decodeFields(noteRow.fieldsJson);
    final templates = await _notetypes.templatesFor(noteRow.notetypeId);
    final template = templates.firstWhere((t) => t.ord == card.templateOrd, orElse: () => templates.first);
    final fieldDefs = await _notetypes.fieldsFor(noteRow.notetypeId);

    final rendered = renderCard(template: template, fieldDefs: fieldDefs, fieldValues: fields);
    final previews = await _study.previewOutcomes(card.id);
    if (!mounted) return;
    setState(() {
      _rendered = rendered;
      _previews = previews;
    });
  }

  Future<void> _answer(Rating rating) async {
    await _study.answerCard(cardId: _current.id, rating: rating);
    setState(() {
      _queue = _queue.skip(1).toList();
      _showAnswer = false;
      _rendered = null;
      _previews = null;
    });
    if (_queue.isNotEmpty) await _renderCurrent();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.deckName)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _queue.isEmpty
              ? const Center(child: Text('На сегодня карточек не осталось 🎉'))
              : _buildStudyBody(),
    );
  }

  Widget _buildStudyBody() {
    final rendered = _rendered;
    return Column(
      children: [
        Expanded(
          child: rendered == null
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      HtmlView(html: rendered.questionHtml),
                      if (_showAnswer) ...[
                        const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider()),
                        HtmlView(html: rendered.answerHtml),
                      ],
                    ],
                  ),
                ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: _showAnswer ? _buildAnswerButtons() : _buildShowAnswerButton(),
          ),
        ),
      ],
    );
  }

  Widget _buildShowAnswerButton() {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: () => setState(() => _showAnswer = true),
        child: const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Text('Показать ответ')),
      ),
    );
  }

  Widget _buildAnswerButtons() {
    final previews = _previews;
    return Row(
      children: [
        Expanded(child: _ratingButton(Rating.again, 'Снова', Colors.red, previews)),
        const SizedBox(width: 8),
        Expanded(child: _ratingButton(Rating.hard, 'Трудно', Colors.orange, previews)),
        const SizedBox(width: 8),
        Expanded(child: _ratingButton(Rating.good, 'Хорошо', Colors.green, previews)),
        const SizedBox(width: 8),
        Expanded(child: _ratingButton(Rating.easy, 'Легко', Colors.blue, previews)),
      ],
    );
  }

  Widget _ratingButton(Rating rating, String label, Color color, Map<Rating, CardSchedState>? previews) {
    final preview = previews?[rating];
    return FilledButton(
      style: FilledButton.styleFrom(backgroundColor: color),
      onPressed: () => _answer(rating),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label),
            if (preview != null) Text(_intervalLabel(preview), style: const TextStyle(fontSize: 11)),
          ],
        ),
      ),
    );
  }

  String _intervalLabel(CardSchedState state) {
    if (state.queue == CardQueue.learning || state.queue == CardQueue.relearning) {
      final now = DateTime.now();
      final dueAt = DateTime.fromMillisecondsSinceEpoch(state.due * 1000);
      final minutes = dueAt.difference(now).inMinutes.clamp(1, 999);
      return minutes < 60 ? '<$minutes мин' : '${(minutes / 60).round()} ч';
    }
    final days = state.ivl;
    if (days < 30) return '$days д';
    if (days < 365) return '${(days / 30).round()} мес';
    return '${(days / 365).toStringAsFixed(1)} г';
  }
}
