import '../../domain/scheduler/models.dart';
import '../db/database.dart';

/// Converts the persisted [DeckConfig] row into the scheduler's pure
/// [DeckSchedConfig]. Percentages are stored as integers (e.g. 130 = 1.3x)
/// so the DB stays free of floating point rounding surprises.
DeckSchedConfig schedConfigFromRow(DeckConfig row) {
  return DeckSchedConfig(
    learningStepsMin: _parseSteps(row.learningStepsMin),
    relearningStepsMin: _parseSteps(row.relearningStepsMin),
    graduatingIntervalDays: row.graduatingIntervalDays,
    easyIntervalDays: row.easyIntervalDays,
    startingEase: row.startingEase,
    easyBonus: row.easyBonusPct / 100,
    intervalModifier: row.intervalModifierPct / 100,
    hardIntervalMultiplier: row.hardIntervalPct / 100,
    newIntervalMultiplier: row.newIntervalPct / 100,
    minimumLapseInterval: row.minimumLapseInterval,
    leechThreshold: row.leechThreshold,
    leechSuspends: row.leechSuspends,
    maximumIntervalDays: row.maximumIntervalDays,
    minEase: row.minEase,
    fsrsParams: parseFloats(row.fsrsParams),
    desiredRetention: row.desiredRetention,
    historicalRetention: row.historicalRetention,
    ignoreRevlogsBeforeMs: ignoreRevlogsBeforeMs(row.ignoreRevlogsBeforeDate),
    easyDaysPercentages: parseFloats(row.easyDaysPercentages),
  );
}

List<int> _parseSteps(String csv) =>
    csv.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).map(int.parse).toList();

/// Comma/space separated numbers, e.g. FSRS parameters as Anki shows them.
List<double> parseFloats(String text) => text
    .split(RegExp(r'[,\s]+'))
    .map((s) => s.trim())
    .where((s) => s.isNotEmpty)
    .map(double.parse)
    .toList();

/// Anki's `ignore_revlogs_before_date_to_ms`: "YYYY-MM-DD" at 00:00 UTC.
int ignoreRevlogsBeforeMs(String date) {
  if (date.trim().isEmpty) return 0;
  final parsed = DateTime.tryParse('${date.trim()}T00:00:00Z');
  return parsed?.millisecondsSinceEpoch ?? 0;
}

String stepsToCsv(List<int> steps) => steps.join(',');

int ratingToInt(Rating r) => switch (r) {
      Rating.again => 1,
      Rating.hard => 2,
      Rating.good => 3,
      Rating.easy => 4,
    };
