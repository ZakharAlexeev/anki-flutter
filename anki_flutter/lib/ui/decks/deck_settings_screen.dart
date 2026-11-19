import 'package:drift/drift.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/db/database.dart';
import '../../data/repositories/deck_repository.dart';
import '../../data/repositories/sched_config_mapper.dart';
import '../../data/repositories/study_repository.dart';
import '../../domain/scheduler/fsrs.dart';
import '../common/ios.dart';
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
      // "1, 10" rather than "1,10", which reads like a decimal number.
      _learningSteps.text = config.learningStepsMin.split(',').map((s) => s.trim()).join(', ');
      _relearningSteps.text = config.relearningStepsMin.split(',').map((s) => s.trim()).join(', ');
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
    final sm2Note = _fsrsEnabled ? 'Сейчас включён FSRS: эти значения не используются.' : null;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.deckName),
        actions: [NavBarAction(label: 'Сохранить', busy: _saving, onPressed: config == null ? null : _save)],
      ),
      body: config == null
          ? const Center(child: CupertinoActivityIndicator())
          : Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 620),
                child: ListView(
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.only(bottom: AppSpacing.xl),
                  children: [
                    const SectionHeader('В день'),
                    GroupedSection(children: [
                      GroupedValueField(label: 'Новых карточек', controller: _newPerDay),
                      GroupedValueField(label: 'Повторений', controller: _reviewsPerDay),
                    ]),
                    const SectionHeader('Шаги обучения'),
                    GroupedSection(children: [
                      GroupedValueField(
                        label: 'Новые карточки',
                        controller: _learningSteps,
                        numeric: false,
                        suffix: 'мин',
                        fieldWidth: 120,
                      ),
                      GroupedValueField(
                        label: 'После ошибки',
                        controller: _relearningSteps,
                        numeric: false,
                        suffix: 'мин',
                        fieldWidth: 120,
                      ),
                    ]),
                    const SectionFooter('Через запятую, например «1, 10». 1440 минут — это сутки.'),
                    const SectionHeader('Трудные карточки'),
                    GroupedSection(children: [
                      GroupedValueField(label: 'Порог (ошибок)', controller: _leechThreshold),
                      GroupedSwitchRow(
                        label: 'Откладывать',
                        value: _leechSuspends,
                        onChanged: (v) => setState(() => _leechSuspends = v),
                      ),
                    ]),
                    const SectionFooter(
                      'Карточка, которую забыли столько раз, получает метку leech. '
                      'Если «Откладывать» выключено (как в Anki), она остаётся в повторениях.',
                    ),
                    const SectionHeader('FSRS'),
                    GroupedSection(children: [
                      GroupedValueField(label: 'Желаемая запоминаемость', controller: _desiredRetention, suffix: '%'),
                      GroupedValueField(label: 'Запоминаемость до FSRS', controller: _historicalRetention, suffix: '%'),
                      GroupedValueField(
                        label: 'Не учитывать ответы до',
                        controller: _ignoreBefore,
                        numeric: false,
                        placeholder: 'ГГГГ-ММ-ДД',
                        fieldWidth: 130,
                      ),
                    ]),
                    const SectionHeader('Параметры FSRS'),
                    GroupedSection(children: [
                      GroupedTextArea(
                        controller: _fsrsParams,
                        placeholder: 'Пусто — параметры по умолчанию',
                      ),
                    ]),
                    SectionFooter(
                      '${_fsrsEnabled ? 'FSRS включён' : 'Сейчас используется SM-2; FSRS включается во вкладке «Ещё»'}. '
                      'Параметры можно подобрать в Anki на компьютере («Оптимизировать») и вставить сюда.',
                    ),
                    const SectionHeader('Интервалы'),
                    GroupedSection(children: [
                      GroupedValueField(label: 'После обучения', controller: _graduatingInterval, suffix: 'д'),
                      GroupedValueField(label: 'Для «Легко»', controller: _easyInterval, suffix: 'д'),
                      GroupedValueField(label: 'Максимальный', controller: _maximumIntervalDays, suffix: 'д'),
                      GroupedValueField(label: 'Минимум после ошибки', controller: _minimumLapseInterval, suffix: 'д'),
                    ]),
                    const SectionHeader('Лёгкость (SM-2)'),
                    GroupedSection(children: [
                      GroupedValueField(label: 'Начальная', controller: _startingEase, suffix: '%'),
                      GroupedValueField(label: 'Минимальная', controller: _minEase, suffix: '%'),
                      GroupedValueField(label: 'Бонус «Легко»', controller: _easyBonusPct, suffix: '%'),
                      GroupedValueField(label: 'Множитель интервала', controller: _intervalModifierPct, suffix: '%'),
                      GroupedValueField(label: 'Множитель «Трудно»', controller: _hardIntervalPct, suffix: '%'),
                      GroupedValueField(label: 'Множитель после ошибки', controller: _newIntervalPct, suffix: '%'),
                    ]),
                    SectionFooter(sm2Note ?? 'Настройки действуют для всех колод с этим набором параметров.'),
                  ],
                ),
              ),
            ),
    );
  }
}
