import 'package:drift/drift.dart';

import '../db/database.dart';

class TemplateSpec {
  final String name;
  final String questionFormat;
  final String answerFormat;

  const TemplateSpec({required this.name, required this.questionFormat, required this.answerFormat});
}

class NotetypeRepository {
  NotetypeRepository(this._db);

  final AppDatabase _db;

  Stream<List<Notetype>> watchNotetypes() => _db.select(_db.notetypes).watch();

  Future<List<NotetypeField>> fieldsFor(int notetypeId) =>
      (_db.select(_db.notetypeFields)
            ..where((f) => f.notetypeId.equals(notetypeId))
            ..orderBy([(f) => OrderingTerm.asc(f.ord)]))
          .get();

  Future<List<NotetypeTemplate>> templatesFor(int notetypeId) =>
      (_db.select(_db.notetypeTemplates)
            ..where((t) => t.notetypeId.equals(notetypeId))
            ..orderBy([(t) => OrderingTerm.asc(t.ord)]))
          .get();

  Future<int> createNotetype({
    required String name,
    required List<String> fieldNames,
    required List<TemplateSpec> templates,
    String css = '',
  }) async {
    return _db.transaction(() async {
      final notetypeId = await _db.into(_db.notetypes).insert(NotetypesCompanion(name: Value(name), css: Value(css)));
      for (var i = 0; i < fieldNames.length; i++) {
        await _db.into(_db.notetypeFields).insert(
              NotetypeFieldsCompanion.insert(notetypeId: notetypeId, name: fieldNames[i], ord: i),
            );
      }
      for (var i = 0; i < templates.length; i++) {
        final t = templates[i];
        await _db.into(_db.notetypeTemplates).insert(
              NotetypeTemplatesCompanion.insert(
                notetypeId: notetypeId,
                name: t.name,
                ord: i,
                questionFormat: Value(t.questionFormat),
                answerFormat: Value(t.answerFormat),
              ),
            );
      }
      return notetypeId;
    });
  }

  /// Deletes a note type along with every note/card built from it - matches
  /// Anki's own confirmation-then-cascade behaviour (the UI is expected to
  /// confirm with the user before calling this).
  Future<void> deleteNotetype(int notetypeId) async {
    await _db.transaction(() async {
      final noteIds = await (_db.selectOnly(_db.notes)
            ..addColumns([_db.notes.id])
            ..where(_db.notes.notetypeId.equals(notetypeId)))
          .map((row) => row.read(_db.notes.id)!)
          .get();
      for (final noteId in noteIds) {
        await (_db.delete(_db.cards)..where((c) => c.noteId.equals(noteId))).go();
      }
      await (_db.delete(_db.notes)..where((n) => n.notetypeId.equals(notetypeId))).go();
      await (_db.delete(_db.notetypeTemplates)..where((t) => t.notetypeId.equals(notetypeId))).go();
      await (_db.delete(_db.notetypeFields)..where((f) => f.notetypeId.equals(notetypeId))).go();
      await (_db.delete(_db.notetypes)..where((n) => n.id.equals(notetypeId))).go();
    });
  }

  /// Creates the classic "Basic" and "Basic (and reversed card)" note types
  /// on first launch, mirroring a fresh Anki profile.
  Future<void> ensureSeeded() async {
    final any = await _db.select(_db.notetypes).getSingleOrNull();
    if (any != null) return;

    await createNotetype(
      name: 'Basic',
      fieldNames: const ['Front', 'Back'],
      templates: const [
        TemplateSpec(name: 'Card 1', questionFormat: '{{Front}}', answerFormat: '{{FrontSide}}<hr id="answer">{{Back}}'),
      ],
    );
    await createNotetype(
      name: 'Basic (and reversed card)',
      fieldNames: const ['Front', 'Back'],
      templates: const [
        TemplateSpec(name: 'Card 1', questionFormat: '{{Front}}', answerFormat: '{{FrontSide}}<hr id="answer">{{Back}}'),
        TemplateSpec(name: 'Card 2', questionFormat: '{{Back}}', answerFormat: '{{FrontSide}}<hr id="answer">{{Front}}'),
      ],
    );
  }
}
