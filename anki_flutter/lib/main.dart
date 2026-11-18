import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'data/db/database.dart';
import 'data/media/pronunciation_service.dart';
import 'data/repositories/deck_repository.dart';
import 'data/repositories/note_repository.dart';
import 'data/repositories/notetype_repository.dart';
import 'data/repositories/stats_repository.dart';
import 'data/repositories/study_repository.dart';
import 'ui/home/home_shell.dart';
import 'ui/theme/app_theme.dart';
import 'ui/theme/theme_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final db = AppDatabase();
  await db.ensureSeeded();

  final decks = DeckRepository(db);
  final notetypes = NotetypeRepository(db);
  await notetypes.ensureSeeded();
  final notes = NoteRepository(db, decks, notetypes);
  final study = StudyRepository(db);
  final stats = StatsRepository(db);
  final theme = await ThemeController.load();

  runApp(AnkiFlutterApp(
    db: db,
    decks: decks,
    notetypes: notetypes,
    notes: notes,
    study: study,
    stats: stats,
    theme: theme,
  ));
}

class AnkiFlutterApp extends StatefulWidget {
  const AnkiFlutterApp({
    super.key,
    required this.db,
    required this.decks,
    required this.notetypes,
    required this.notes,
    required this.study,
    required this.stats,
    this.theme,
  });

  final AppDatabase db;
  final DeckRepository decks;
  final NotetypeRepository notetypes;
  final NoteRepository notes;
  final StudyRepository study;
  final StatsRepository stats;

  /// The saved light/dark choice; null (tests) means an in-memory one that
  /// follows the system.
  final ThemeController? theme;

  @override
  State<AnkiFlutterApp> createState() => _AnkiFlutterAppState();
}

class _AnkiFlutterAppState extends State<AnkiFlutterApp> {
  late final ThemeController _theme = widget.theme ?? ThemeController();

  @override
  void dispose() {
    if (widget.theme == null) _theme.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = widget;
    return MultiProvider(
      providers: [
        Provider<AppDatabase>.value(value: w.db),
        Provider<DeckRepository>.value(value: w.decks),
        Provider<NotetypeRepository>.value(value: w.notetypes),
        Provider<NoteRepository>.value(value: w.notes),
        Provider<StudyRepository>.value(value: w.study),
        Provider<StatsRepository>.value(value: w.stats),
        Provider<PronunciationService>(create: (_) => PronunciationService(w.db, w.notes, w.notetypes)),
        ChangeNotifierProvider<ThemeController>.value(value: _theme),
      ],
      child: ListenableBuilder(
        listenable: _theme,
        builder: (context, _) => MaterialApp(
          title: 'Anki',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: _theme.mode,
          home: const HomeShell(),
        ),
      ),
    );
  }
}
