import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/db/database.dart';
import '../../data/repositories/deck_repository.dart';
import '../../data/repositories/sched_config_mapper.dart';
import '../../data/repositories/study_repository.dart';
import '../../domain/scheduler/fsrs.dart';
import '../theme/app_theme.dart';

/// Exposes the deck's [DeckConfig] (learning/relearning steps, graduating
/// and easy intervals, ease/interval percentages, leech threshold, daily
/// limits) - `DeckRepository.updateDeckConfig` already existed but had no
/// UI calling it, so these were only ever reachable by importing an .apkg
/// that happened to set them.
class DeckSettingsScreen extends StatefulWidget {
  const DeckSettingsScreen({super.key, required this.deckId, required this.deckName});

  final int deckId;
  final String deckName;

  @override
  State<DeckSettingsScreen> createState() => _DeckSettingsScreenState();
}

class _DeckSettingsScreenState extends State<DeckSettingsScreen> {
  DeckConfig? _config;
  bool _saving = false;
  bool _leechSuspends = false;

  final _learningSteps = TextEditingController();
  final _relearningSteps = TextEditingController();
  final _graduatingInterval = TextEditingController();
  final _easyInterval = TextEditingController();
  final _startingEase = TextEditingController();
  final _easyBonusPct = TextEditingController();
  final _intervalModifierPct = TextEditingController();
  final _hardIntervalPct = TextEditingController();
  final _newIntervalPct = TextEditingController();
  final _leechThreshold = TextEditingController();
  final _maximumIntervalDays = TextEditingController();
  final _minEase = TextEditingController();
  final _newPerDay = TextEditingController();
  final _reviewsPerDay = TextEditingController();
  final _minimumLapseInterval = TextEditingController();
  final _desiredRetention = TextEditingController();
  final _historicalRetention = TextEditingController();
  final _fsrsParams = TextEditingController();
  final _ignoreBefore = TextEditingController();
  bool _fsrsEnabled = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final c in [
      _learningSteps,
      _relearningSteps,
      _graduatingInterval,
      _easyInterval,
      _startingEase,
      _easyBonusPct,
      _intervalModifierPct,
      _hardIntervalPct,
      _newIntervalPct,
      _leechThreshold,
      _maximumIntervalDays,
      _minEase,
      _newPerDay,
      _reviewsPerDay,
      _minimumLapseInterval,
      _desiredRetention,
      _historicalRetention,
      _fsrsParams,
      _ignoreBefore,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    final config = await context.read<DeckRepository>().configForDeck(widget.deckId);
    if (!mounted) return;
    final options = await context.read<StudyRepository>().schedulingOptions();
    if (!mounted) return;
    setState(() {
      _config = config;
      _learningSteps.text = config.learningStepsMin;
      _relearningSteps.text = config.relearningStepsMin;
      _graduatingInterval.text = '${config.graduatingIntervalDays}';
      _easyInterval.text = '${config.easyIntervalDays}';
      _startingEase.text = '${config.startingEase / 10}'; // stored as permille, shown as %
      _easyBonusPct.text = '${config.easyBonusPct}';
      _intervalModifierPct.text = '${config.intervalModifierPct}';
      _hardIntervalPct.text = '${config.hardIntervalPct}';
      _newIntervalPct.text = '${config.newIntervalPct}';
      _leechThreshold.text = '${config.leechThreshold}';
      _leechSuspends = config.leechSuspends;
      _maximumIntervalDays.text = '${config.maximumIntervalDays}';
      _minEase.text = '${config.minEase / 10}';
      _newPerDay.text = '${config.newPerDay}';
      _reviewsPerDay.text = '${config.reviewsPerDay}';
      _minimumLapseInterval.text = '${config.minimumLapseInterval}';
      _desiredRetention.text = _percent(config.desiredRetention);
      _historicalRetention.text = _percent(config.historicalRetention);
      _fsrsParams.text = config.fsrsParams.replaceAll(',', ', ');
      _ignoreBefore.text = config.ignoreRevlogsBeforeDate;
      _fsrsEnabled = options.fsrsEnabled;
    });
  }

  int? _int(TextEditingController c) => int.tryParse(c.text.trim());

  static String _percent(double v) {
    final pct = (v * 100 * 10).round() / 10;
    return pct == pct.roundToDouble() ? pct.toStringAsFixed(0) : pct.toString();
  }

  /// A retention typed as a percentage (e.g. "90") -> 0.90.
  double? _retention(TextEditingController c) {
    final v = double.tryParse(c.text.trim().replaceAll(',', '.'));
    if (v == null) return null;
    final r = v / 100;
    return r >= 0.7 && r <= 0.99 ? r : null;
  }

  /// FSRS parameters as Anki shows them: 17, 19 or 21 numbers, or empty
  /// for the defaults. Returns null when they aren't a valid set.
  String? _validParams() {
    final text = _fsrsParams.text.trim();
    if (text.isEmpty) return '';
    try {
      final values = parseFloats(text);
      Fsrs(values); // throws on a wrong count or non-finite values
      return values.join(',');
    } on FormatException {
      return null;
    }
  }
  int? _percentAsEase(TextEditingController c) {
    final pct = double.tryParse(c.text.trim());
    return pct == null ? null : (pct * 10).round();
  }

  bool _validSteps(String csv) {
    final parts = csv.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    if (parts.isEmpty) return true; // empty is valid: graduates immediately
    return parts.every((s) => (num.tryParse(s) ?? -1) > 0);
  }

  Future<void> _save() async {
    final config = _config;
    if (config == null) return;

    if (!_validSteps(_learningSteps.text) || !_validSteps(_relearningSteps.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Шаги должны быть положительными числами через запятую')),
      );
      return;
    }
    final graduatingInterval = _int(_graduatingInterval);
    final easyInterval = _int(_easyInterval);
    final startingEase = _percentAsEase(_startingEase);
    final easyBonusPct = _int(_easyBonusPct);
    final intervalModifierPct = _int(_intervalModifierPct);
    final hardIntervalPct = _int(_hardIntervalPct);
    final newIntervalPct = _int(_newIntervalPct);
    final leechThreshold = _int(_leechThreshold);
    final maximumIntervalDays = _int(_maximumIntervalDays);
    final minEase = _percentAsEase(_minEase);
    final newPerDay = _int(_newPerDay);
    final reviewsPerDay = _int(_reviewsPerDay);

    final numbers = [
      graduatingInterval,
      easyInterval,
      startingEase,
      easyBonusPct,
      intervalModifierPct,
      hardIntervalPct,
      newIntervalPct,
      leechThreshold,
      maximumIntervalDays,
      minEase,
      newPerDay,
      reviewsPerDay,
    ];
    final minimumLapseInterval = _int(_minimumLapseInterval);
    final desiredRetention = _retention(_desiredRetention);
    final historicalRetention = _retention(_historicalRetention);
    final fsrsParams = _validParams();
    final ignoreBefore = _ignoreBefore.text.trim();
    if (desiredRetention == null || historicalRetention == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Запоминаемость — число от 70 до 99 процентов')),
      );
      return;
    }
    if (fsrsParams == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Параметры FSRS: 17, 19 или 21 число через запятую, как в Anki')),
      );
      return;
    }
    if (ignoreBefore.isNotEmpty && ignoreRevlogsBeforeMs(ignoreBefore) == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Дата должна быть в формате ГГГГ-ММ-ДД')),
      );
      return;
    }
    if (numbers.any((n) => n == null || n < 0) || minimumLapseInterval == null || minimumLapseInterval < 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Все числовые поля должны быть заполнены неотрицательными числами')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await context.read<DeckRepository>().updateDeckConfig(DeckConfigsCompanion(
            id: Value(config.id),
            learningStepsMin: Value(_learningSteps.text.trim()),
            relearningStepsMin: Value(_relearningSteps.text.trim()),
            graduatingIntervalDays: Value(graduatingInterval!),
            easyIntervalDays: Value(easyInterval!),
            startingEase: Value(startingEase!),
            easyBonusPct: Value(easyBonusPct!),
            intervalModifierPct: Value(intervalModifierPct!),
            hardIntervalPct: Value(hardIntervalPct!),
            newIntervalPct: Value(newIntervalPct!),
            leechThreshold: Value(leechThreshold!),
            leechSuspends: Value(_leechSuspends),
            maximumIntervalDays: Value(maximumIntervalDays!),
            minEase: Value(minEase!),
            newPerDay: Value(newPerDay!),
            reviewsPerDay: Value(reviewsPerDay!),
            minimumLapseInterval: Value(minimumLapseInterval),
            desiredRetention: Value(desiredRetention),
            historicalRetention: Value(historicalRetention),
            fsrsParams: Value(fsrsParams),
            ignoreRevlogsBeforeDate: Value(ignoreBefore),
          ));
      // New parameters change every card's memory state; Anki recomputes
      // them on save, and so do we.
      final memoryInputsChanged = fsrsParams != config.fsrsParams ||
          historicalRetention != config.historicalRetention ||
          ignoreBefore != config.ignoreRevlogsBeforeDate;
      if (_fsrsEnabled && memoryInputsChanged && mounted) {
        await context.read<StudyRepository>().recomputeMemoryStates(deckConfigId: config.id);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Настройки сохранены')));
      Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = _config;
    return Scaffold(
      appBar: AppBar(title: Text('Настройки — ${widget.deckName}')),
      body: config == null
          ? const Center(child: CircularProgressIndicator())
          : Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xl),
                  children: [
                    Text('РАСПИСАНИЕ', style: Theme.of(context).textTheme.labelSmall),
                    const SizedBox(height: AppSpacing.sm),
                    Text('Параметры повторения', style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 6),
                    Text(
                      'Настройте темп обучения. Значения применяются только к этой колоде.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: context.appColors.muted),
                    ),
                    _section('Шаги обучения'),
                    _numRow(_learningSteps, 'Новые (мин, через запятую)'),
                    _numRow(_relearningSteps, 'Повтор после ошибки (мин, через запятую)'),
                    _section('Интервалы'),
                    _numRow(_graduatingInterval, 'Интервал после обучения (дни)'),
                    _numRow(_easyInterval, 'Интервал "Легко" (дни)'),
                    _numRow(_maximumIntervalDays, 'Максимальный интервал (дни)'),
                    _section('Коэффициент лёгкости'),
                    _numRow(_startingEase, 'Начальный (%)'),
                    _numRow(_minEase, 'Минимальный (%)'),
                    _numRow(_easyBonusPct, 'Бонус "Легко" (%)'),
                    _numRow(_intervalModifierPct, 'Множитель интервала (%)'),
                    _numRow(_hardIntervalPct, 'Множитель "Трудно" (%)'),
                    _numRow(_newIntervalPct, 'Множитель после провала (%)'),
                    _numRow(_minimumLapseInterval, 'Минимальный интервал после провала (дни)'),
                    _section('FSRS'),
                    Text(
                      _fsrsEnabled
                          ? 'FSRS включён для всей коллекции (вкладка «Ещё»). Коэффициент лёгкости и '
                              'множители выше при этом не используются.'
                          : 'Сейчас используется SM-2. Включить FSRS можно во вкладке «Ещё».',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _numRow(_desiredRetention, 'Желаемая запоминаемость (%)'),
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: TextField(
                        controller: _fsrsParams,
                        minLines: 2,
                        maxLines: 5,
                        keyboardType: TextInputType.multiline,
                        decoration: const InputDecoration(
                          labelText: 'Параметры FSRS',
                          hintText: 'Пусто — параметры по умолчанию. Можно вставить из Anki на компьютере.',
                        ),
                      ),
                    ),
                    _numRow(_historicalRetention, 'Запоминаемость до FSRS (%)'),
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: TextField(
                        controller: _ignoreBefore,
                        decoration: const InputDecoration(
                          labelText: 'Не учитывать ответы до даты',
                          hintText: 'ГГГГ-ММ-ДД, можно оставить пустым',
                        ),
                      ),
                    ),
                    _section('Лимиты и leech'),
                    _numRow(_newPerDay, 'Новых карточек в день'),
                    _numRow(_reviewsPerDay, 'Повторений в день'),
                    _numRow(_leechThreshold, 'Порог leech (число ошибок)'),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      value: _leechSuspends,
                      onChanged: (v) => setState(() => _leechSuspends = v),
                      title: const Text('Откладывать трудные карточки'),
                      subtitle: const Text(
                        'Выключено, как в Anki: карточка только получает метку leech и остаётся в повторениях.',
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    SizedBox(
                      height: 48,
                      child: FilledButton(
                        onPressed: _saving ? null : _save,
                        child: _saving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Text('Сохранить'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _section(String title) => Padding(
        padding: const EdgeInsets.only(top: AppSpacing.xl, bottom: AppSpacing.md),
        child: Row(
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: Divider(color: context.appColors.border)),
          ],
        ),
      );

  Widget _numRow(TextEditingController controller, String label) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.md),
        child: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(labelText: label),
        ),
      );
}
