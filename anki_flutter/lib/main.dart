import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'data/db/database.dart';
import 'data/repositories/deck_repository.dart';
import 'data/repositories/note_repository.dart';
import 'data/repositories/notetype_repository.dart';
import 'data/repositories/study_repository.dart';
import 'ui/decks/deck_list_screen.dart';
import 'ui/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final db = AppDatabase();
  await db.ensureSeeded();

  final decks = DeckRepository(db);
  final notetypes = NotetypeRepository(db);
  await notetypes.ensureSeeded();
  final notes = NoteRepository(db, decks, notetypes);
  final study = StudyRepository(db);

  runApp(AnkiFlutterApp(db: db, decks: decks, notetypes: notetypes, notes: notes, study: study));
}

class AnkiFlutterApp extends StatelessWidget {
  const AnkiFlutterApp({
    super.key,
    required this.db,
    required this.decks,
    required this.notetypes,
    required this.notes,
    required this.study,
  });

  final AppDatabase db;
  final DeckRepository decks;
  final NotetypeRepository notetypes;
  final NoteRepository notes;
  final StudyRepository study;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AppDatabase>.value(value: db),
        Provider<DeckRepository>.value(value: decks),
        Provider<NotetypeRepository>.value(value: notetypes),
        Provider<NoteRepository>.value(value: notes),
        Provider<StudyRepository>.value(value: study),
      ],
      child: MaterialApp(
        title: 'Anki Flutter',
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        home: const DeckListScreen(),
      ),
    );
  }
}
