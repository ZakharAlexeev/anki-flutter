import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// The app's light/dark choice: follow the system, or force one.
///
/// Persisted to a tiny JSON file next to the database rather than in the
/// database itself, so changing it needs no schema migration. Without a
/// [file] (tests) the choice simply lives in memory.
class ThemeController extends ChangeNotifier {
  ThemeController({ThemeMode initialMode = ThemeMode.system, this.file}) : _mode = initialMode;

  ThemeMode _mode;

  /// Where the choice is saved; null keeps it in memory only.
  final File? file;

  ThemeMode get mode => _mode;

  static Future<ThemeController> load() async {
    final dir = await getApplicationSupportDirectory();
    final file = File(p.join(dir.path, 'settings.json'));
    var mode = ThemeMode.system;
    try {
      if (await file.exists()) {
        final json = jsonDecode(await file.readAsString());
        final name = json is Map ? json['theme'] : null;
        mode = ThemeMode.values.firstWhere((m) => m.name == name, orElse: () => ThemeMode.system);
      }
    } catch (_) {
      // A corrupt settings file must never stop the app from starting.
    }
    return ThemeController(initialMode: mode, file: file);
  }

  Future<void> setMode(ThemeMode mode) async {
    if (mode == _mode) return;
    _mode = mode;
    notifyListeners();
    final file = this.file;
    if (file == null) return;
    try {
      await file.parent.create(recursive: true);
      await file.writeAsString(jsonEncode({'theme': mode.name}), flush: true);
    } catch (_) {
      // Not saved; the choice still applies for this session.
    }
  }
}
