import 'dart:io';

import 'package:anki_flutter/data/backup/backup_service.dart';
import 'package:anki_flutter/data/db/database.dart';
import 'package:anki_flutter/data/repositories/deck_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory tmp;
  late File dbFile;
  late AppDatabase db;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('anki_backup_test');
    dbFile = File(p.join(tmp.path, 'anki_flutter.sqlite'));
    db = AppDatabase.forTesting(NativeDatabase(dbFile));
    await db.ensureSeeded();
  });

  tearDown(() async {
    await db.close();
    await tmp.delete(recursive: true);
  });

  BackupService service({Future<void> Function()? onReopen}) => BackupService(
        db,
        onReopen: onReopen,
        baseDir: () async => tmp,
        databaseFile: () async => dbFile,
      );

  Future<List<String>> deckNames(AppDatabase d) async => [for (final x in await d.select(d.decks).get()) x.name];

  test('a backup restores exactly the state it was made from, media included', () async {
    await DeckRepository(db).createDeck('Before');
    final media = Directory(p.join(tmp.path, 'media'))..createSync();
    File(p.join(media.path, 'pron_ox_go.mp3')).writeAsBytesSync([1, 2, 3]);

    final backup = await service().create();
    expect(backup.kind, BackupKind.manual);

    // Change everything after the backup.
    await DeckRepository(db).createDeck('After');
    File(p.join(media.path, 'pron_ox_go.mp3')).deleteSync();
    File(p.join(media.path, 'later.mp3')).writeAsBytesSync([9]);

    AppDatabase? reopened;
    await service(onReopen: () async {
      reopened = AppDatabase.forTesting(NativeDatabase(dbFile));
    }).restore(await backup.file.readAsBytes());

    expect(await deckNames(reopened!), ['Before']);
    expect(File(p.join(media.path, 'pron_ox_go.mp3')).readAsBytesSync(), [1, 2, 3]);
    expect(File(p.join(media.path, 'later.mp3')).existsSync(), isFalse);

    // The state before the restore was kept, so the restore can be undone.
    final kinds = [for (final b in await BackupService(reopened!, baseDir: () async => tmp).list()) b.kind];
    expect(kinds, containsAll([BackupKind.manual, BackupKind.beforeRestore]));
    await reopened!.close();
    db = AppDatabase.forTesting(NativeDatabase.memory()); // for tearDown
  });

  test('automatic backups: at most once a day, newest ten kept', () async {
    final s = service();
    final start = DateTime(2026, 1, 1, 9);
    expect(await s.autoBackupIfDue(now: start), isNotNull);
    expect(await s.autoBackupIfDue(now: start.add(const Duration(hours: 5))), isNull);
    for (var day = 1; day <= 12; day++) {
      expect(await s.autoBackupIfDue(now: start.add(Duration(days: day))), isNotNull);
    }
    final autos = (await s.list()).where((b) => b.kind == BackupKind.auto).toList();
    expect(autos, hasLength(BackupService.keepAuto));
    expect(autos.first.createdAt, start.add(const Duration(days: 12)));
  });

  test('foreign or broken files are refused before anything is touched', () async {
    expect(() => service().inspect([1, 2, 3, 4]), throwsA(isA<BackupException>()));
  });
}
