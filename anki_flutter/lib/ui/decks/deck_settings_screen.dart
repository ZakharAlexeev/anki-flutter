import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/db/database.dart';
import '../../data/repositories/deck_repository.dart';
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
  final _desiredRetention = TextEditingController();

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
      _desiredRetention,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    final repository = context.read<DeckRepository>();
    final config = await repository.configForDeck(widget.deckId);
    final desiredRetention = await repository.desiredRetentionForDeck(widget.deckId);
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
      _maximumIntervalDays.text = '${config.maximumIntervalDays}';
      _minEase.text = '${config.minEase / 10}';
      _newPerDay.text = '${config.newPerDay}';
      _reviewsPerDay.text = '${config.reviewsPerDay}';
      _desiredRetention.text = '${(desiredRetention * 100).round()}';
    });
  }

  int? _int(TextEditingController c) => int.tryParse(c.text.trim());
  int? _percentAsEase(TextEditingController c) {
    final pct = double.tryParse(c.text.trim());
    return pct == null ? null : (pct * 10).round();
  }

  bool _validSteps(String csv) {
    final parts = csv.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    if (parts.isEmpty) return true; // empty is valid: graduates immediately
    return parts.every((s) => (int.tryParse(s) ?? -1) > 0);
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
    final desiredRetentionPct = _int(_desiredRetention);

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
      desiredRetentionPct,
    ];
    if (numbers.any((n) => n == null || n < 0)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Все числовые поля должны быть заполнены неотрицательными числами')),
      );
      return;
    }
    if (desiredRetentionPct! < 70 || desiredRetentionPct > 99) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Желаемое запоминание должно быть от 70% до 99%')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final repository = context.read<DeckRepository>();
      await repository.updateDeckConfig(widget.deckId, DeckConfigsCompanion(
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
            maximumIntervalDays: Value(maximumIntervalDays!),
            minEase: Value(minEase!),
            newPerDay: Value(newPerDay!),
            reviewsPerDay: Value(reviewsPerDay!),
          ));
      await repository.updateDesiredRetention(widget.deckId, desiredRetentionPct / 100);
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
                    Text('Планировщик FSRS-6', style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 6),
                    Text(
                      'Современный планировщик Anki. Значения применяются только к этой колоде.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: context.appColors.muted),
                    ),
                    _section('Шаги обучения'),
                    _numRow(_learningSteps, 'Новые (мин, через запятую)'),
                    _numRow(_relearningSteps, 'Повтор после ошибки (мин, через запятую)'),
                    _section('FSRS'),
                    _numRow(_desiredRetention, 'Желаемое запоминание (%)'),
                    _numRow(_maximumIntervalDays, 'Максимальный интервал (дни)'),
                    _section('Лимиты и leech'),
                    _numRow(_newPerDay, 'Новых карточек в день'),
                    _numRow(_reviewsPerDay, 'Повторений в день'),
                    _numRow(_leechThreshold, 'Порог leech (число ошибок)'),
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
          keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: label),
        ),
      );
}
