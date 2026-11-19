import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'data/backup/backup_service.dart';
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
  final theme = await ThemeController.load();
  runApp(AppRoot(theme: theme));
}

/// The open collection: the database and the repositories built on it.
class Collection {
  Collection._(this.db, this.decks, this.notetypes, this.notes, this.study, this.stats);

  final AppDatabase db;
  final DeckRepository decks;
  final NotetypeRepository notetypes;
  final NoteRepository notes;
  final StudyRepository study;
  final StatsRepository stats;

  static Future<Collection> open() async {
    final db = AppDatabase();
    await db.ensureSeeded();
    final decks = DeckRepository(db);
    final notetypes = NotetypeRepository(db);
    await notetypes.ensureSeeded();
    final notes = NoteRepository(db, decks, notetypes);
    return Collection._(db, decks, notetypes, notes, StudyRepository(db), StatsRepository(db));
  }
}

/// Owns the collection for the app's lifetime: opens it, reopens it after a
/// backup is restored (so no restart is needed), and makes the daily
/// automatic backup when the app starts and when it goes to the background.
class AppRoot extends StatefulWidget {
  const AppRoot({super.key, required this.theme});
  final ThemeController theme;

  @override
  State<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> with WidgetsBindingObserver {
  Collection? _collection;
  BackupService? _backups;
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _open();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _open() async {
    final c = await Collection.open();
    if (!mounted) return;
    setState(() {
      _collection = c;
      _backups = BackupService(c.db, onReopen: _reopen);
      _generation++;
    });
    _autoBackup();
  }

  /// Called by [BackupService.restore] once the old database is closed and
  /// the restored files are in place.
  Future<void> _reopen() async {
    final restoredTheme = await ThemeController.load();
    await widget.theme.setMode(restoredTheme.mode);
    await _open();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.hidden) _autoBackup();
  }

  void _autoBackup() {
    final backups = _backups;
    if (backups == null) return;
    // Best effort: a failed automatic backup must never disturb studying.
    unawaited(backups.autoBackupIfDue().then((_) {}, onError: (Object _) {}));
  }

  @override
  Widget build(BuildContext context) {
    final c = _collection;
    if (c == null) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: widget.theme.mode,
        home: const Scaffold(body: Center(child: CupertinoActivityIndicator())),
      );
    }
    return AnkiFlutterApp(
      key: ValueKey(_generation),
      db: c.db,
      decks: c.decks,
      notetypes: c.notetypes,
      notes: c.notes,
      study: c.study,
      stats: c.stats,
      theme: widget.theme,
      backups: _backups,
    );
  }
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
    this.backups,
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

  /// Backups; null (tests) hides them.
  final BackupService? backups;

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
        Provider<BackupService?>.value(value: w.backups),
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
