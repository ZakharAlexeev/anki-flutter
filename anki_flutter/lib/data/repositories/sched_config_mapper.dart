import '../../domain/scheduler/models.dart';
import '../db/database.dart';

/// Converts the persisted [DeckConfig] row into the scheduler's pure
/// [DeckSchedConfig], and back for the small set of fields the editor lets
/// the user change. Percentages are stored as integers (e.g. 130 = 1.3x) so
/// the DB stays free of floating point rounding surprises.
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
    leechThreshold: row.leechThreshold,
    maximumIntervalDays: row.maximumIntervalDays,
    minEase: row.minEase,
  );
}

List<int> _parseSteps(String csv) =>
    csv.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).map(int.parse).toList();

String stepsToCsv(List<int> steps) => steps.join(',');

int ratingToInt(Rating r) => switch (r) {
      Rating.again => 1,
      Rating.hard => 2,
      Rating.good => 3,
      Rating.easy => 4,
    };
