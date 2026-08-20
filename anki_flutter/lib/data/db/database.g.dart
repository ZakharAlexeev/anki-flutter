// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $DeckConfigsTable extends DeckConfigs
    with TableInfo<$DeckConfigsTable, DeckConfig> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DeckConfigsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    clientDefault: epochMillisId,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _learningStepsMinMeta = const VerificationMeta(
    'learningStepsMin',
  );
  @override
  late final GeneratedColumn<String> learningStepsMin = GeneratedColumn<String>(
    'learning_steps_min',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('1,10'),
  );
  static const VerificationMeta _relearningStepsMinMeta =
      const VerificationMeta('relearningStepsMin');
  @override
  late final GeneratedColumn<String> relearningStepsMin =
      GeneratedColumn<String>(
        'relearning_steps_min',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('10'),
      );
  static const VerificationMeta _graduatingIntervalDaysMeta =
      const VerificationMeta('graduatingIntervalDays');
  @override
  late final GeneratedColumn<int> graduatingIntervalDays = GeneratedColumn<int>(
    'graduating_interval_days',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _easyIntervalDaysMeta = const VerificationMeta(
    'easyIntervalDays',
  );
  @override
  late final GeneratedColumn<int> easyIntervalDays = GeneratedColumn<int>(
    'easy_interval_days',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(4),
  );
  static const VerificationMeta _startingEaseMeta = const VerificationMeta(
    'startingEase',
  );
  @override
  late final GeneratedColumn<int> startingEase = GeneratedColumn<int>(
    'starting_ease',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(2500),
  );
  static const VerificationMeta _easyBonusPctMeta = const VerificationMeta(
    'easyBonusPct',
  );
  @override
  late final GeneratedColumn<int> easyBonusPct = GeneratedColumn<int>(
    'easy_bonus_pct',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(130),
  );
  static const VerificationMeta _intervalModifierPctMeta =
      const VerificationMeta('intervalModifierPct');
  @override
  late final GeneratedColumn<int> intervalModifierPct = GeneratedColumn<int>(
    'interval_modifier_pct',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(100),
  );
  static const VerificationMeta _hardIntervalPctMeta = const VerificationMeta(
    'hardIntervalPct',
  );
  @override
  late final GeneratedColumn<int> hardIntervalPct = GeneratedColumn<int>(
    'hard_interval_pct',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(120),
  );
  static const VerificationMeta _newIntervalPctMeta = const VerificationMeta(
    'newIntervalPct',
  );
  @override
  late final GeneratedColumn<int> newIntervalPct = GeneratedColumn<int>(
    'new_interval_pct',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _leechThresholdMeta = const VerificationMeta(
    'leechThreshold',
  );
  @override
  late final GeneratedColumn<int> leechThreshold = GeneratedColumn<int>(
    'leech_threshold',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(8),
  );
  static const VerificationMeta _maximumIntervalDaysMeta =
      const VerificationMeta('maximumIntervalDays');
  @override
  late final GeneratedColumn<int> maximumIntervalDays = GeneratedColumn<int>(
    'maximum_interval_days',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(36500),
  );
  static const VerificationMeta _minEaseMeta = const VerificationMeta(
    'minEase',
  );
  @override
  late final GeneratedColumn<int> minEase = GeneratedColumn<int>(
    'min_ease',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1300),
  );
  static const VerificationMeta _newPerDayMeta = const VerificationMeta(
    'newPerDay',
  );
  @override
  late final GeneratedColumn<int> newPerDay = GeneratedColumn<int>(
    'new_per_day',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(20),
  );
  static const VerificationMeta _reviewsPerDayMeta = const VerificationMeta(
    'reviewsPerDay',
  );
  @override
  late final GeneratedColumn<int> reviewsPerDay = GeneratedColumn<int>(
    'reviews_per_day',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(200),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    learningStepsMin,
    relearningStepsMin,
    graduatingIntervalDays,
    easyIntervalDays,
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
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'deck_configs';
  @override
  VerificationContext validateIntegrity(
    Insertable<DeckConfig> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('learning_steps_min')) {
      context.handle(
        _learningStepsMinMeta,
        learningStepsMin.isAcceptableOrUnknown(
          data['learning_steps_min']!,
          _learningStepsMinMeta,
        ),
      );
    }
    if (data.containsKey('relearning_steps_min')) {
      context.handle(
        _relearningStepsMinMeta,
        relearningStepsMin.isAcceptableOrUnknown(
          data['relearning_steps_min']!,
          _relearningStepsMinMeta,
        ),
      );
    }
    if (data.containsKey('graduating_interval_days')) {
      context.handle(
        _graduatingIntervalDaysMeta,
        graduatingIntervalDays.isAcceptableOrUnknown(
          data['graduating_interval_days']!,
          _graduatingIntervalDaysMeta,
        ),
      );
    }
    if (data.containsKey('easy_interval_days')) {
      context.handle(
        _easyIntervalDaysMeta,
        easyIntervalDays.isAcceptableOrUnknown(
          data['easy_interval_days']!,
          _easyIntervalDaysMeta,
        ),
      );
    }
    if (data.containsKey('starting_ease')) {
      context.handle(
        _startingEaseMeta,
        startingEase.isAcceptableOrUnknown(
          data['starting_ease']!,
          _startingEaseMeta,
        ),
      );
    }
    if (data.containsKey('easy_bonus_pct')) {
      context.handle(
        _easyBonusPctMeta,
        easyBonusPct.isAcceptableOrUnknown(
          data['easy_bonus_pct']!,
          _easyBonusPctMeta,
        ),
      );
    }
    if (data.containsKey('interval_modifier_pct')) {
      context.handle(
        _intervalModifierPctMeta,
        intervalModifierPct.isAcceptableOrUnknown(
          data['interval_modifier_pct']!,
          _intervalModifierPctMeta,
        ),
      );
    }
    if (data.containsKey('hard_interval_pct')) {
      context.handle(
        _hardIntervalPctMeta,
        hardIntervalPct.isAcceptableOrUnknown(
          data['hard_interval_pct']!,
          _hardIntervalPctMeta,
        ),
      );
    }
    if (data.containsKey('new_interval_pct')) {
      context.handle(
        _newIntervalPctMeta,
        newIntervalPct.isAcceptableOrUnknown(
          data['new_interval_pct']!,
          _newIntervalPctMeta,
        ),
      );
    }
    if (data.containsKey('leech_threshold')) {
      context.handle(
        _leechThresholdMeta,
        leechThreshold.isAcceptableOrUnknown(
          data['leech_threshold']!,
          _leechThresholdMeta,
        ),
      );
    }
    if (data.containsKey('maximum_interval_days')) {
      context.handle(
        _maximumIntervalDaysMeta,
        maximumIntervalDays.isAcceptableOrUnknown(
          data['maximum_interval_days']!,
          _maximumIntervalDaysMeta,
        ),
      );
    }
    if (data.containsKey('min_ease')) {
      context.handle(
        _minEaseMeta,
        minEase.isAcceptableOrUnknown(data['min_ease']!, _minEaseMeta),
      );
    }
    if (data.containsKey('new_per_day')) {
      context.handle(
        _newPerDayMeta,
        newPerDay.isAcceptableOrUnknown(data['new_per_day']!, _newPerDayMeta),
      );
    }
    if (data.containsKey('reviews_per_day')) {
      context.handle(
        _reviewsPerDayMeta,
        reviewsPerDay.isAcceptableOrUnknown(
          data['reviews_per_day']!,
          _reviewsPerDayMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DeckConfig map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DeckConfig(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      learningStepsMin: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}learning_steps_min'],
      )!,
      relearningStepsMin: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}relearning_steps_min'],
      )!,
      graduatingIntervalDays: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}graduating_interval_days'],
      )!,
      easyIntervalDays: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}easy_interval_days'],
      )!,
      startingEase: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}starting_ease'],
      )!,
      easyBonusPct: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}easy_bonus_pct'],
      )!,
      intervalModifierPct: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}interval_modifier_pct'],
      )!,
      hardIntervalPct: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}hard_interval_pct'],
      )!,
      newIntervalPct: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}new_interval_pct'],
      )!,
      leechThreshold: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}leech_threshold'],
      )!,
      maximumIntervalDays: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}maximum_interval_days'],
      )!,
      minEase: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}min_ease'],
      )!,
      newPerDay: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}new_per_day'],
      )!,
      reviewsPerDay: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}reviews_per_day'],
      )!,
    );
  }

  @override
  $DeckConfigsTable createAlias(String alias) {
    return $DeckConfigsTable(attachedDatabase, alias);
  }
}

class DeckConfig extends DataClass implements Insertable<DeckConfig> {
  final int id;
  final String name;
  final String learningStepsMin;
  final String relearningStepsMin;
  final int graduatingIntervalDays;
  final int easyIntervalDays;
  final int startingEase;
  final int easyBonusPct;
  final int intervalModifierPct;
  final int hardIntervalPct;
  final int newIntervalPct;
  final int leechThreshold;
  final int maximumIntervalDays;
  final int minEase;
  final int newPerDay;
  final int reviewsPerDay;
  const DeckConfig({
    required this.id,
    required this.name,
    required this.learningStepsMin,
    required this.relearningStepsMin,
    required this.graduatingIntervalDays,
    required this.easyIntervalDays,
    required this.startingEase,
    required this.easyBonusPct,
    required this.intervalModifierPct,
    required this.hardIntervalPct,
    required this.newIntervalPct,
    required this.leechThreshold,
    required this.maximumIntervalDays,
    required this.minEase,
    required this.newPerDay,
    required this.reviewsPerDay,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['learning_steps_min'] = Variable<String>(learningStepsMin);
    map['relearning_steps_min'] = Variable<String>(relearningStepsMin);
    map['graduating_interval_days'] = Variable<int>(graduatingIntervalDays);
    map['easy_interval_days'] = Variable<int>(easyIntervalDays);
    map['starting_ease'] = Variable<int>(startingEase);
    map['easy_bonus_pct'] = Variable<int>(easyBonusPct);
    map['interval_modifier_pct'] = Variable<int>(intervalModifierPct);
    map['hard_interval_pct'] = Variable<int>(hardIntervalPct);
    map['new_interval_pct'] = Variable<int>(newIntervalPct);
    map['leech_threshold'] = Variable<int>(leechThreshold);
    map['maximum_interval_days'] = Variable<int>(maximumIntervalDays);
    map['min_ease'] = Variable<int>(minEase);
    map['new_per_day'] = Variable<int>(newPerDay);
    map['reviews_per_day'] = Variable<int>(reviewsPerDay);
    return map;
  }

  DeckConfigsCompanion toCompanion(bool nullToAbsent) {
    return DeckConfigsCompanion(
      id: Value(id),
      name: Value(name),
      learningStepsMin: Value(learningStepsMin),
      relearningStepsMin: Value(relearningStepsMin),
      graduatingIntervalDays: Value(graduatingIntervalDays),
      easyIntervalDays: Value(easyIntervalDays),
      startingEase: Value(startingEase),
      easyBonusPct: Value(easyBonusPct),
      intervalModifierPct: Value(intervalModifierPct),
      hardIntervalPct: Value(hardIntervalPct),
      newIntervalPct: Value(newIntervalPct),
      leechThreshold: Value(leechThreshold),
      maximumIntervalDays: Value(maximumIntervalDays),
      minEase: Value(minEase),
      newPerDay: Value(newPerDay),
      reviewsPerDay: Value(reviewsPerDay),
    );
  }

  factory DeckConfig.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DeckConfig(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      learningStepsMin: serializer.fromJson<String>(json['learningStepsMin']),
      relearningStepsMin: serializer.fromJson<String>(
        json['relearningStepsMin'],
      ),
      graduatingIntervalDays: serializer.fromJson<int>(
        json['graduatingIntervalDays'],
      ),
      easyIntervalDays: serializer.fromJson<int>(json['easyIntervalDays']),
      startingEase: serializer.fromJson<int>(json['startingEase']),
      easyBonusPct: serializer.fromJson<int>(json['easyBonusPct']),
      intervalModifierPct: serializer.fromJson<int>(
        json['intervalModifierPct'],
      ),
      hardIntervalPct: serializer.fromJson<int>(json['hardIntervalPct']),
      newIntervalPct: serializer.fromJson<int>(json['newIntervalPct']),
      leechThreshold: serializer.fromJson<int>(json['leechThreshold']),
      maximumIntervalDays: serializer.fromJson<int>(
        json['maximumIntervalDays'],
      ),
      minEase: serializer.fromJson<int>(json['minEase']),
      newPerDay: serializer.fromJson<int>(json['newPerDay']),
      reviewsPerDay: serializer.fromJson<int>(json['reviewsPerDay']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'learningStepsMin': serializer.toJson<String>(learningStepsMin),
      'relearningStepsMin': serializer.toJson<String>(relearningStepsMin),
      'graduatingIntervalDays': serializer.toJson<int>(graduatingIntervalDays),
      'easyIntervalDays': serializer.toJson<int>(easyIntervalDays),
      'startingEase': serializer.toJson<int>(startingEase),
      'easyBonusPct': serializer.toJson<int>(easyBonusPct),
      'intervalModifierPct': serializer.toJson<int>(intervalModifierPct),
      'hardIntervalPct': serializer.toJson<int>(hardIntervalPct),
      'newIntervalPct': serializer.toJson<int>(newIntervalPct),
      'leechThreshold': serializer.toJson<int>(leechThreshold),
      'maximumIntervalDays': serializer.toJson<int>(maximumIntervalDays),
      'minEase': serializer.toJson<int>(minEase),
      'newPerDay': serializer.toJson<int>(newPerDay),
      'reviewsPerDay': serializer.toJson<int>(reviewsPerDay),
    };
  }

  DeckConfig copyWith({
    int? id,
    String? name,
    String? learningStepsMin,
    String? relearningStepsMin,
    int? graduatingIntervalDays,
    int? easyIntervalDays,
    int? startingEase,
    int? easyBonusPct,
    int? intervalModifierPct,
    int? hardIntervalPct,
    int? newIntervalPct,
    int? leechThreshold,
    int? maximumIntervalDays,
    int? minEase,
    int? newPerDay,
    int? reviewsPerDay,
  }) => DeckConfig(
    id: id ?? this.id,
    name: name ?? this.name,
    learningStepsMin: learningStepsMin ?? this.learningStepsMin,
    relearningStepsMin: relearningStepsMin ?? this.relearningStepsMin,
    graduatingIntervalDays:
        graduatingIntervalDays ?? this.graduatingIntervalDays,
    easyIntervalDays: easyIntervalDays ?? this.easyIntervalDays,
    startingEase: startingEase ?? this.startingEase,
    easyBonusPct: easyBonusPct ?? this.easyBonusPct,
    intervalModifierPct: intervalModifierPct ?? this.intervalModifierPct,
    hardIntervalPct: hardIntervalPct ?? this.hardIntervalPct,
    newIntervalPct: newIntervalPct ?? this.newIntervalPct,
    leechThreshold: leechThreshold ?? this.leechThreshold,
    maximumIntervalDays: maximumIntervalDays ?? this.maximumIntervalDays,
    minEase: minEase ?? this.minEase,
    newPerDay: newPerDay ?? this.newPerDay,
    reviewsPerDay: reviewsPerDay ?? this.reviewsPerDay,
  );
  DeckConfig copyWithCompanion(DeckConfigsCompanion data) {
    return DeckConfig(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      learningStepsMin: data.learningStepsMin.present
          ? data.learningStepsMin.value
          : this.learningStepsMin,
      relearningStepsMin: data.relearningStepsMin.present
          ? data.relearningStepsMin.value
          : this.relearningStepsMin,
      graduatingIntervalDays: data.graduatingIntervalDays.present
          ? data.graduatingIntervalDays.value
          : this.graduatingIntervalDays,
      easyIntervalDays: data.easyIntervalDays.present
          ? data.easyIntervalDays.value
          : this.easyIntervalDays,
      startingEase: data.startingEase.present
          ? data.startingEase.value
          : this.startingEase,
      easyBonusPct: data.easyBonusPct.present
          ? data.easyBonusPct.value
          : this.easyBonusPct,
      intervalModifierPct: data.intervalModifierPct.present
          ? data.intervalModifierPct.value
          : this.intervalModifierPct,
      hardIntervalPct: data.hardIntervalPct.present
          ? data.hardIntervalPct.value
          : this.hardIntervalPct,
      newIntervalPct: data.newIntervalPct.present
          ? data.newIntervalPct.value
          : this.newIntervalPct,
      leechThreshold: data.leechThreshold.present
          ? data.leechThreshold.value
          : this.leechThreshold,
      maximumIntervalDays: data.maximumIntervalDays.present
          ? data.maximumIntervalDays.value
          : this.maximumIntervalDays,
      minEase: data.minEase.present ? data.minEase.value : this.minEase,
      newPerDay: data.newPerDay.present ? data.newPerDay.value : this.newPerDay,
      reviewsPerDay: data.reviewsPerDay.present
          ? data.reviewsPerDay.value
          : this.reviewsPerDay,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DeckConfig(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('learningStepsMin: $learningStepsMin, ')
          ..write('relearningStepsMin: $relearningStepsMin, ')
          ..write('graduatingIntervalDays: $graduatingIntervalDays, ')
          ..write('easyIntervalDays: $easyIntervalDays, ')
          ..write('startingEase: $startingEase, ')
          ..write('easyBonusPct: $easyBonusPct, ')
          ..write('intervalModifierPct: $intervalModifierPct, ')
          ..write('hardIntervalPct: $hardIntervalPct, ')
          ..write('newIntervalPct: $newIntervalPct, ')
          ..write('leechThreshold: $leechThreshold, ')
          ..write('maximumIntervalDays: $maximumIntervalDays, ')
          ..write('minEase: $minEase, ')
          ..write('newPerDay: $newPerDay, ')
          ..write('reviewsPerDay: $reviewsPerDay')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    learningStepsMin,
    relearningStepsMin,
    graduatingIntervalDays,
    easyIntervalDays,
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
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DeckConfig &&
          other.id == this.id &&
          other.name == this.name &&
          other.learningStepsMin == this.learningStepsMin &&
          other.relearningStepsMin == this.relearningStepsMin &&
          other.graduatingIntervalDays == this.graduatingIntervalDays &&
          other.easyIntervalDays == this.easyIntervalDays &&
          other.startingEase == this.startingEase &&
          other.easyBonusPct == this.easyBonusPct &&
          other.intervalModifierPct == this.intervalModifierPct &&
          other.hardIntervalPct == this.hardIntervalPct &&
          other.newIntervalPct == this.newIntervalPct &&
          other.leechThreshold == this.leechThreshold &&
          other.maximumIntervalDays == this.maximumIntervalDays &&
          other.minEase == this.minEase &&
          other.newPerDay == this.newPerDay &&
          other.reviewsPerDay == this.reviewsPerDay);
}

class DeckConfigsCompanion extends UpdateCompanion<DeckConfig> {
  final Value<int> id;
  final Value<String> name;
  final Value<String> learningStepsMin;
  final Value<String> relearningStepsMin;
  final Value<int> graduatingIntervalDays;
  final Value<int> easyIntervalDays;
  final Value<int> startingEase;
  final Value<int> easyBonusPct;
  final Value<int> intervalModifierPct;
  final Value<int> hardIntervalPct;
  final Value<int> newIntervalPct;
  final Value<int> leechThreshold;
  final Value<int> maximumIntervalDays;
  final Value<int> minEase;
  final Value<int> newPerDay;
  final Value<int> reviewsPerDay;
  const DeckConfigsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.learningStepsMin = const Value.absent(),
    this.relearningStepsMin = const Value.absent(),
    this.graduatingIntervalDays = const Value.absent(),
    this.easyIntervalDays = const Value.absent(),
    this.startingEase = const Value.absent(),
    this.easyBonusPct = const Value.absent(),
    this.intervalModifierPct = const Value.absent(),
    this.hardIntervalPct = const Value.absent(),
    this.newIntervalPct = const Value.absent(),
    this.leechThreshold = const Value.absent(),
    this.maximumIntervalDays = const Value.absent(),
    this.minEase = const Value.absent(),
    this.newPerDay = const Value.absent(),
    this.reviewsPerDay = const Value.absent(),
  });
  DeckConfigsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.learningStepsMin = const Value.absent(),
    this.relearningStepsMin = const Value.absent(),
    this.graduatingIntervalDays = const Value.absent(),
    this.easyIntervalDays = const Value.absent(),
    this.startingEase = const Value.absent(),
    this.easyBonusPct = const Value.absent(),
    this.intervalModifierPct = const Value.absent(),
    this.hardIntervalPct = const Value.absent(),
    this.newIntervalPct = const Value.absent(),
    this.leechThreshold = const Value.absent(),
    this.maximumIntervalDays = const Value.absent(),
    this.minEase = const Value.absent(),
    this.newPerDay = const Value.absent(),
    this.reviewsPerDay = const Value.absent(),
  }) : name = Value(name);
  static Insertable<DeckConfig> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? learningStepsMin,
    Expression<String>? relearningStepsMin,
    Expression<int>? graduatingIntervalDays,
    Expression<int>? easyIntervalDays,
    Expression<int>? startingEase,
    Expression<int>? easyBonusPct,
    Expression<int>? intervalModifierPct,
    Expression<int>? hardIntervalPct,
    Expression<int>? newIntervalPct,
    Expression<int>? leechThreshold,
    Expression<int>? maximumIntervalDays,
    Expression<int>? minEase,
    Expression<int>? newPerDay,
    Expression<int>? reviewsPerDay,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (learningStepsMin != null) 'learning_steps_min': learningStepsMin,
      if (relearningStepsMin != null)
        'relearning_steps_min': relearningStepsMin,
      if (graduatingIntervalDays != null)
        'graduating_interval_days': graduatingIntervalDays,
      if (easyIntervalDays != null) 'easy_interval_days': easyIntervalDays,
      if (startingEase != null) 'starting_ease': startingEase,
      if (easyBonusPct != null) 'easy_bonus_pct': easyBonusPct,
      if (intervalModifierPct != null)
        'interval_modifier_pct': intervalModifierPct,
      if (hardIntervalPct != null) 'hard_interval_pct': hardIntervalPct,
      if (newIntervalPct != null) 'new_interval_pct': newIntervalPct,
      if (leechThreshold != null) 'leech_threshold': leechThreshold,
      if (maximumIntervalDays != null)
        'maximum_interval_days': maximumIntervalDays,
      if (minEase != null) 'min_ease': minEase,
      if (newPerDay != null) 'new_per_day': newPerDay,
      if (reviewsPerDay != null) 'reviews_per_day': reviewsPerDay,
    });
  }

  DeckConfigsCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<String>? learningStepsMin,
    Value<String>? relearningStepsMin,
    Value<int>? graduatingIntervalDays,
    Value<int>? easyIntervalDays,
    Value<int>? startingEase,
    Value<int>? easyBonusPct,
    Value<int>? intervalModifierPct,
    Value<int>? hardIntervalPct,
    Value<int>? newIntervalPct,
    Value<int>? leechThreshold,
    Value<int>? maximumIntervalDays,
    Value<int>? minEase,
    Value<int>? newPerDay,
    Value<int>? reviewsPerDay,
  }) {
    return DeckConfigsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      learningStepsMin: learningStepsMin ?? this.learningStepsMin,
      relearningStepsMin: relearningStepsMin ?? this.relearningStepsMin,
      graduatingIntervalDays:
          graduatingIntervalDays ?? this.graduatingIntervalDays,
      easyIntervalDays: easyIntervalDays ?? this.easyIntervalDays,
      startingEase: startingEase ?? this.startingEase,
      easyBonusPct: easyBonusPct ?? this.easyBonusPct,
      intervalModifierPct: intervalModifierPct ?? this.intervalModifierPct,
      hardIntervalPct: hardIntervalPct ?? this.hardIntervalPct,
      newIntervalPct: newIntervalPct ?? this.newIntervalPct,
      leechThreshold: leechThreshold ?? this.leechThreshold,
      maximumIntervalDays: maximumIntervalDays ?? this.maximumIntervalDays,
      minEase: minEase ?? this.minEase,
      newPerDay: newPerDay ?? this.newPerDay,
      reviewsPerDay: reviewsPerDay ?? this.reviewsPerDay,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (learningStepsMin.present) {
      map['learning_steps_min'] = Variable<String>(learningStepsMin.value);
    }
    if (relearningStepsMin.present) {
      map['relearning_steps_min'] = Variable<String>(relearningStepsMin.value);
    }
    if (graduatingIntervalDays.present) {
      map['graduating_interval_days'] = Variable<int>(
        graduatingIntervalDays.value,
      );
    }
    if (easyIntervalDays.present) {
      map['easy_interval_days'] = Variable<int>(easyIntervalDays.value);
    }
    if (startingEase.present) {
      map['starting_ease'] = Variable<int>(startingEase.value);
    }
    if (easyBonusPct.present) {
      map['easy_bonus_pct'] = Variable<int>(easyBonusPct.value);
    }
    if (intervalModifierPct.present) {
      map['interval_modifier_pct'] = Variable<int>(intervalModifierPct.value);
    }
    if (hardIntervalPct.present) {
      map['hard_interval_pct'] = Variable<int>(hardIntervalPct.value);
    }
    if (newIntervalPct.present) {
      map['new_interval_pct'] = Variable<int>(newIntervalPct.value);
    }
    if (leechThreshold.present) {
      map['leech_threshold'] = Variable<int>(leechThreshold.value);
    }
    if (maximumIntervalDays.present) {
      map['maximum_interval_days'] = Variable<int>(maximumIntervalDays.value);
    }
    if (minEase.present) {
      map['min_ease'] = Variable<int>(minEase.value);
    }
    if (newPerDay.present) {
      map['new_per_day'] = Variable<int>(newPerDay.value);
    }
    if (reviewsPerDay.present) {
      map['reviews_per_day'] = Variable<int>(reviewsPerDay.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DeckConfigsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('learningStepsMin: $learningStepsMin, ')
          ..write('relearningStepsMin: $relearningStepsMin, ')
          ..write('graduatingIntervalDays: $graduatingIntervalDays, ')
          ..write('easyIntervalDays: $easyIntervalDays, ')
          ..write('startingEase: $startingEase, ')
          ..write('easyBonusPct: $easyBonusPct, ')
          ..write('intervalModifierPct: $intervalModifierPct, ')
          ..write('hardIntervalPct: $hardIntervalPct, ')
          ..write('newIntervalPct: $newIntervalPct, ')
          ..write('leechThreshold: $leechThreshold, ')
          ..write('maximumIntervalDays: $maximumIntervalDays, ')
          ..write('minEase: $minEase, ')
          ..write('newPerDay: $newPerDay, ')
          ..write('reviewsPerDay: $reviewsPerDay')
          ..write(')'))
        .toString();
  }
}

class $DecksTable extends Decks with TableInfo<$DecksTable, Deck> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DecksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    clientDefault: epochMillisId,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _deckConfigIdMeta = const VerificationMeta(
    'deckConfigId',
  );
  @override
  late final GeneratedColumn<int> deckConfigId = GeneratedColumn<int>(
    'deck_config_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES deck_configs (id)',
    ),
  );
  static const VerificationMeta _newPerDayOverrideMeta = const VerificationMeta(
    'newPerDayOverride',
  );
  @override
  late final GeneratedColumn<int> newPerDayOverride = GeneratedColumn<int>(
    'new_per_day_override',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _reviewsPerDayOverrideMeta =
      const VerificationMeta('reviewsPerDayOverride');
  @override
  late final GeneratedColumn<int> reviewsPerDayOverride = GeneratedColumn<int>(
    'reviews_per_day_override',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _collapsedMeta = const VerificationMeta(
    'collapsed',
  );
  @override
  late final GeneratedColumn<bool> collapsed = GeneratedColumn<bool>(
    'collapsed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("collapsed" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _newShownTodayMeta = const VerificationMeta(
    'newShownToday',
  );
  @override
  late final GeneratedColumn<int> newShownToday = GeneratedColumn<int>(
    'new_shown_today',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _newShownDayMeta = const VerificationMeta(
    'newShownDay',
  );
  @override
  late final GeneratedColumn<int> newShownDay = GeneratedColumn<int>(
    'new_shown_day',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(-1),
  );
  static const VerificationMeta _reviewsShownTodayMeta = const VerificationMeta(
    'reviewsShownToday',
  );
  @override
  late final GeneratedColumn<int> reviewsShownToday = GeneratedColumn<int>(
    'reviews_shown_today',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _reviewsShownDayMeta = const VerificationMeta(
    'reviewsShownDay',
  );
  @override
  late final GeneratedColumn<int> reviewsShownDay = GeneratedColumn<int>(
    'reviews_shown_day',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(-1),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    deckConfigId,
    newPerDayOverride,
    reviewsPerDayOverride,
    collapsed,
    newShownToday,
    newShownDay,
    reviewsShownToday,
    reviewsShownDay,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'decks';
  @override
  VerificationContext validateIntegrity(
    Insertable<Deck> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('deck_config_id')) {
      context.handle(
        _deckConfigIdMeta,
        deckConfigId.isAcceptableOrUnknown(
          data['deck_config_id']!,
          _deckConfigIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_deckConfigIdMeta);
    }
    if (data.containsKey('new_per_day_override')) {
      context.handle(
        _newPerDayOverrideMeta,
        newPerDayOverride.isAcceptableOrUnknown(
          data['new_per_day_override']!,
          _newPerDayOverrideMeta,
        ),
      );
    }
    if (data.containsKey('reviews_per_day_override')) {
      context.handle(
        _reviewsPerDayOverrideMeta,
        reviewsPerDayOverride.isAcceptableOrUnknown(
          data['reviews_per_day_override']!,
          _reviewsPerDayOverrideMeta,
        ),
      );
    }
    if (data.containsKey('collapsed')) {
      context.handle(
        _collapsedMeta,
        collapsed.isAcceptableOrUnknown(data['collapsed']!, _collapsedMeta),
      );
    }
    if (data.containsKey('new_shown_today')) {
      context.handle(
        _newShownTodayMeta,
        newShownToday.isAcceptableOrUnknown(
          data['new_shown_today']!,
          _newShownTodayMeta,
        ),
      );
    }
    if (data.containsKey('new_shown_day')) {
      context.handle(
        _newShownDayMeta,
        newShownDay.isAcceptableOrUnknown(
          data['new_shown_day']!,
          _newShownDayMeta,
        ),
      );
    }
    if (data.containsKey('reviews_shown_today')) {
      context.handle(
        _reviewsShownTodayMeta,
        reviewsShownToday.isAcceptableOrUnknown(
          data['reviews_shown_today']!,
          _reviewsShownTodayMeta,
        ),
      );
    }
    if (data.containsKey('reviews_shown_day')) {
      context.handle(
        _reviewsShownDayMeta,
        reviewsShownDay.isAcceptableOrUnknown(
          data['reviews_shown_day']!,
          _reviewsShownDayMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Deck map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Deck(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      deckConfigId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deck_config_id'],
      )!,
      newPerDayOverride: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}new_per_day_override'],
      ),
      reviewsPerDayOverride: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}reviews_per_day_override'],
      ),
      collapsed: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}collapsed'],
      )!,
      newShownToday: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}new_shown_today'],
      )!,
      newShownDay: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}new_shown_day'],
      )!,
      reviewsShownToday: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}reviews_shown_today'],
      )!,
      reviewsShownDay: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}reviews_shown_day'],
      )!,
    );
  }

  @override
  $DecksTable createAlias(String alias) {
    return $DecksTable(attachedDatabase, alias);
  }
}

class Deck extends DataClass implements Insertable<Deck> {
  final int id;
  final String name;
  final int deckConfigId;
  final int? newPerDayOverride;
  final int? reviewsPerDayOverride;
  final bool collapsed;

  /// How many new cards have been *first shown* today, and which collection
  /// day-number that count is for (so it lazily resets whenever `today`
  /// moves on, without needing a background job). Mirrors Anki's own
  /// per-deck `newToday`/`revToday` counters - without these, "new cards
  /// per day" is just a query LIMIT, so leaving and re-entering a deck
  /// resets it to the full limit again.
  final int newShownToday;
  final int newShownDay;
  final int reviewsShownToday;
  final int reviewsShownDay;
  const Deck({
    required this.id,
    required this.name,
    required this.deckConfigId,
    this.newPerDayOverride,
    this.reviewsPerDayOverride,
    required this.collapsed,
    required this.newShownToday,
    required this.newShownDay,
    required this.reviewsShownToday,
    required this.reviewsShownDay,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['deck_config_id'] = Variable<int>(deckConfigId);
    if (!nullToAbsent || newPerDayOverride != null) {
      map['new_per_day_override'] = Variable<int>(newPerDayOverride);
    }
    if (!nullToAbsent || reviewsPerDayOverride != null) {
      map['reviews_per_day_override'] = Variable<int>(reviewsPerDayOverride);
    }
    map['collapsed'] = Variable<bool>(collapsed);
    map['new_shown_today'] = Variable<int>(newShownToday);
    map['new_shown_day'] = Variable<int>(newShownDay);
    map['reviews_shown_today'] = Variable<int>(reviewsShownToday);
    map['reviews_shown_day'] = Variable<int>(reviewsShownDay);
    return map;
  }

  DecksCompanion toCompanion(bool nullToAbsent) {
    return DecksCompanion(
      id: Value(id),
      name: Value(name),
      deckConfigId: Value(deckConfigId),
      newPerDayOverride: newPerDayOverride == null && nullToAbsent
          ? const Value.absent()
          : Value(newPerDayOverride),
      reviewsPerDayOverride: reviewsPerDayOverride == null && nullToAbsent
          ? const Value.absent()
          : Value(reviewsPerDayOverride),
      collapsed: Value(collapsed),
      newShownToday: Value(newShownToday),
      newShownDay: Value(newShownDay),
      reviewsShownToday: Value(reviewsShownToday),
      reviewsShownDay: Value(reviewsShownDay),
    );
  }

  factory Deck.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Deck(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      deckConfigId: serializer.fromJson<int>(json['deckConfigId']),
      newPerDayOverride: serializer.fromJson<int?>(json['newPerDayOverride']),
      reviewsPerDayOverride: serializer.fromJson<int?>(
        json['reviewsPerDayOverride'],
      ),
      collapsed: serializer.fromJson<bool>(json['collapsed']),
      newShownToday: serializer.fromJson<int>(json['newShownToday']),
      newShownDay: serializer.fromJson<int>(json['newShownDay']),
      reviewsShownToday: serializer.fromJson<int>(json['reviewsShownToday']),
      reviewsShownDay: serializer.fromJson<int>(json['reviewsShownDay']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'deckConfigId': serializer.toJson<int>(deckConfigId),
      'newPerDayOverride': serializer.toJson<int?>(newPerDayOverride),
      'reviewsPerDayOverride': serializer.toJson<int?>(reviewsPerDayOverride),
      'collapsed': serializer.toJson<bool>(collapsed),
      'newShownToday': serializer.toJson<int>(newShownToday),
      'newShownDay': serializer.toJson<int>(newShownDay),
      'reviewsShownToday': serializer.toJson<int>(reviewsShownToday),
      'reviewsShownDay': serializer.toJson<int>(reviewsShownDay),
    };
  }

  Deck copyWith({
    int? id,
    String? name,
    int? deckConfigId,
    Value<int?> newPerDayOverride = const Value.absent(),
    Value<int?> reviewsPerDayOverride = const Value.absent(),
    bool? collapsed,
    int? newShownToday,
    int? newShownDay,
    int? reviewsShownToday,
    int? reviewsShownDay,
  }) => Deck(
    id: id ?? this.id,
    name: name ?? this.name,
    deckConfigId: deckConfigId ?? this.deckConfigId,
    newPerDayOverride: newPerDayOverride.present
        ? newPerDayOverride.value
        : this.newPerDayOverride,
    reviewsPerDayOverride: reviewsPerDayOverride.present
        ? reviewsPerDayOverride.value
        : this.reviewsPerDayOverride,
    collapsed: collapsed ?? this.collapsed,
    newShownToday: newShownToday ?? this.newShownToday,
    newShownDay: newShownDay ?? this.newShownDay,
    reviewsShownToday: reviewsShownToday ?? this.reviewsShownToday,
    reviewsShownDay: reviewsShownDay ?? this.reviewsShownDay,
  );
  Deck copyWithCompanion(DecksCompanion data) {
    return Deck(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      deckConfigId: data.deckConfigId.present
          ? data.deckConfigId.value
          : this.deckConfigId,
      newPerDayOverride: data.newPerDayOverride.present
          ? data.newPerDayOverride.value
          : this.newPerDayOverride,
      reviewsPerDayOverride: data.reviewsPerDayOverride.present
          ? data.reviewsPerDayOverride.value
          : this.reviewsPerDayOverride,
      collapsed: data.collapsed.present ? data.collapsed.value : this.collapsed,
      newShownToday: data.newShownToday.present
          ? data.newShownToday.value
          : this.newShownToday,
      newShownDay: data.newShownDay.present
          ? data.newShownDay.value
          : this.newShownDay,
      reviewsShownToday: data.reviewsShownToday.present
          ? data.reviewsShownToday.value
          : this.reviewsShownToday,
      reviewsShownDay: data.reviewsShownDay.present
          ? data.reviewsShownDay.value
          : this.reviewsShownDay,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Deck(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('deckConfigId: $deckConfigId, ')
          ..write('newPerDayOverride: $newPerDayOverride, ')
          ..write('reviewsPerDayOverride: $reviewsPerDayOverride, ')
          ..write('collapsed: $collapsed, ')
          ..write('newShownToday: $newShownToday, ')
          ..write('newShownDay: $newShownDay, ')
          ..write('reviewsShownToday: $reviewsShownToday, ')
          ..write('reviewsShownDay: $reviewsShownDay')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    deckConfigId,
    newPerDayOverride,
    reviewsPerDayOverride,
    collapsed,
    newShownToday,
    newShownDay,
    reviewsShownToday,
    reviewsShownDay,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Deck &&
          other.id == this.id &&
          other.name == this.name &&
          other.deckConfigId == this.deckConfigId &&
          other.newPerDayOverride == this.newPerDayOverride &&
          other.reviewsPerDayOverride == this.reviewsPerDayOverride &&
          other.collapsed == this.collapsed &&
          other.newShownToday == this.newShownToday &&
          other.newShownDay == this.newShownDay &&
          other.reviewsShownToday == this.reviewsShownToday &&
          other.reviewsShownDay == this.reviewsShownDay);
}

class DecksCompanion extends UpdateCompanion<Deck> {
  final Value<int> id;
  final Value<String> name;
  final Value<int> deckConfigId;
  final Value<int?> newPerDayOverride;
  final Value<int?> reviewsPerDayOverride;
  final Value<bool> collapsed;
  final Value<int> newShownToday;
  final Value<int> newShownDay;
  final Value<int> reviewsShownToday;
  final Value<int> reviewsShownDay;
  const DecksCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.deckConfigId = const Value.absent(),
    this.newPerDayOverride = const Value.absent(),
    this.reviewsPerDayOverride = const Value.absent(),
    this.collapsed = const Value.absent(),
    this.newShownToday = const Value.absent(),
    this.newShownDay = const Value.absent(),
    this.reviewsShownToday = const Value.absent(),
    this.reviewsShownDay = const Value.absent(),
  });
  DecksCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required int deckConfigId,
    this.newPerDayOverride = const Value.absent(),
    this.reviewsPerDayOverride = const Value.absent(),
    this.collapsed = const Value.absent(),
    this.newShownToday = const Value.absent(),
    this.newShownDay = const Value.absent(),
    this.reviewsShownToday = const Value.absent(),
    this.reviewsShownDay = const Value.absent(),
  }) : name = Value(name),
       deckConfigId = Value(deckConfigId);
  static Insertable<Deck> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<int>? deckConfigId,
    Expression<int>? newPerDayOverride,
    Expression<int>? reviewsPerDayOverride,
    Expression<bool>? collapsed,
    Expression<int>? newShownToday,
    Expression<int>? newShownDay,
    Expression<int>? reviewsShownToday,
    Expression<int>? reviewsShownDay,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (deckConfigId != null) 'deck_config_id': deckConfigId,
      if (newPerDayOverride != null) 'new_per_day_override': newPerDayOverride,
      if (reviewsPerDayOverride != null)
        'reviews_per_day_override': reviewsPerDayOverride,
      if (collapsed != null) 'collapsed': collapsed,
      if (newShownToday != null) 'new_shown_today': newShownToday,
      if (newShownDay != null) 'new_shown_day': newShownDay,
      if (reviewsShownToday != null) 'reviews_shown_today': reviewsShownToday,
      if (reviewsShownDay != null) 'reviews_shown_day': reviewsShownDay,
    });
  }

  DecksCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<int>? deckConfigId,
    Value<int?>? newPerDayOverride,
    Value<int?>? reviewsPerDayOverride,
    Value<bool>? collapsed,
    Value<int>? newShownToday,
    Value<int>? newShownDay,
    Value<int>? reviewsShownToday,
    Value<int>? reviewsShownDay,
  }) {
    return DecksCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      deckConfigId: deckConfigId ?? this.deckConfigId,
      newPerDayOverride: newPerDayOverride ?? this.newPerDayOverride,
      reviewsPerDayOverride:
          reviewsPerDayOverride ?? this.reviewsPerDayOverride,
      collapsed: collapsed ?? this.collapsed,
      newShownToday: newShownToday ?? this.newShownToday,
      newShownDay: newShownDay ?? this.newShownDay,
      reviewsShownToday: reviewsShownToday ?? this.reviewsShownToday,
      reviewsShownDay: reviewsShownDay ?? this.reviewsShownDay,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (deckConfigId.present) {
      map['deck_config_id'] = Variable<int>(deckConfigId.value);
    }
    if (newPerDayOverride.present) {
      map['new_per_day_override'] = Variable<int>(newPerDayOverride.value);
    }
    if (reviewsPerDayOverride.present) {
      map['reviews_per_day_override'] = Variable<int>(
        reviewsPerDayOverride.value,
      );
    }
    if (collapsed.present) {
      map['collapsed'] = Variable<bool>(collapsed.value);
    }
    if (newShownToday.present) {
      map['new_shown_today'] = Variable<int>(newShownToday.value);
    }
    if (newShownDay.present) {
      map['new_shown_day'] = Variable<int>(newShownDay.value);
    }
    if (reviewsShownToday.present) {
      map['reviews_shown_today'] = Variable<int>(reviewsShownToday.value);
    }
    if (reviewsShownDay.present) {
      map['reviews_shown_day'] = Variable<int>(reviewsShownDay.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DecksCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('deckConfigId: $deckConfigId, ')
          ..write('newPerDayOverride: $newPerDayOverride, ')
          ..write('reviewsPerDayOverride: $reviewsPerDayOverride, ')
          ..write('collapsed: $collapsed, ')
          ..write('newShownToday: $newShownToday, ')
          ..write('newShownDay: $newShownDay, ')
          ..write('reviewsShownToday: $reviewsShownToday, ')
          ..write('reviewsShownDay: $reviewsShownDay')
          ..write(')'))
        .toString();
  }
}

class $NotetypesTable extends Notetypes
    with TableInfo<$NotetypesTable, Notetype> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $NotetypesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    clientDefault: epochMillisId,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cssMeta = const VerificationMeta('css');
  @override
  late final GeneratedColumn<String> css = GeneratedColumn<String>(
    'css',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _sortFieldIndexMeta = const VerificationMeta(
    'sortFieldIndex',
  );
  @override
  late final GeneratedColumn<int> sortFieldIndex = GeneratedColumn<int>(
    'sort_field_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, css, sortFieldIndex];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'notetypes';
  @override
  VerificationContext validateIntegrity(
    Insertable<Notetype> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('css')) {
      context.handle(
        _cssMeta,
        css.isAcceptableOrUnknown(data['css']!, _cssMeta),
      );
    }
    if (data.containsKey('sort_field_index')) {
      context.handle(
        _sortFieldIndexMeta,
        sortFieldIndex.isAcceptableOrUnknown(
          data['sort_field_index']!,
          _sortFieldIndexMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Notetype map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Notetype(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      css: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}css'],
      )!,
      sortFieldIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_field_index'],
      )!,
    );
  }

  @override
  $NotetypesTable createAlias(String alias) {
    return $NotetypesTable(attachedDatabase, alias);
  }
}

class Notetype extends DataClass implements Insertable<Notetype> {
  final int id;
  final String name;
  final String css;
  final int sortFieldIndex;
  const Notetype({
    required this.id,
    required this.name,
    required this.css,
    required this.sortFieldIndex,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['css'] = Variable<String>(css);
    map['sort_field_index'] = Variable<int>(sortFieldIndex);
    return map;
  }

  NotetypesCompanion toCompanion(bool nullToAbsent) {
    return NotetypesCompanion(
      id: Value(id),
      name: Value(name),
      css: Value(css),
      sortFieldIndex: Value(sortFieldIndex),
    );
  }

  factory Notetype.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Notetype(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      css: serializer.fromJson<String>(json['css']),
      sortFieldIndex: serializer.fromJson<int>(json['sortFieldIndex']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'css': serializer.toJson<String>(css),
      'sortFieldIndex': serializer.toJson<int>(sortFieldIndex),
    };
  }

  Notetype copyWith({
    int? id,
    String? name,
    String? css,
    int? sortFieldIndex,
  }) => Notetype(
    id: id ?? this.id,
    name: name ?? this.name,
    css: css ?? this.css,
    sortFieldIndex: sortFieldIndex ?? this.sortFieldIndex,
  );
  Notetype copyWithCompanion(NotetypesCompanion data) {
    return Notetype(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      css: data.css.present ? data.css.value : this.css,
      sortFieldIndex: data.sortFieldIndex.present
          ? data.sortFieldIndex.value
          : this.sortFieldIndex,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Notetype(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('css: $css, ')
          ..write('sortFieldIndex: $sortFieldIndex')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, css, sortFieldIndex);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Notetype &&
          other.id == this.id &&
          other.name == this.name &&
          other.css == this.css &&
          other.sortFieldIndex == this.sortFieldIndex);
}

class NotetypesCompanion extends UpdateCompanion<Notetype> {
  final Value<int> id;
  final Value<String> name;
  final Value<String> css;
  final Value<int> sortFieldIndex;
  const NotetypesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.css = const Value.absent(),
    this.sortFieldIndex = const Value.absent(),
  });
  NotetypesCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.css = const Value.absent(),
    this.sortFieldIndex = const Value.absent(),
  }) : name = Value(name);
  static Insertable<Notetype> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? css,
    Expression<int>? sortFieldIndex,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (css != null) 'css': css,
      if (sortFieldIndex != null) 'sort_field_index': sortFieldIndex,
    });
  }

  NotetypesCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<String>? css,
    Value<int>? sortFieldIndex,
  }) {
    return NotetypesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      css: css ?? this.css,
      sortFieldIndex: sortFieldIndex ?? this.sortFieldIndex,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (css.present) {
      map['css'] = Variable<String>(css.value);
    }
    if (sortFieldIndex.present) {
      map['sort_field_index'] = Variable<int>(sortFieldIndex.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('NotetypesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('css: $css, ')
          ..write('sortFieldIndex: $sortFieldIndex')
          ..write(')'))
        .toString();
  }
}

class $NotetypeFieldsTable extends NotetypeFields
    with TableInfo<$NotetypeFieldsTable, NotetypeField> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $NotetypeFieldsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _notetypeIdMeta = const VerificationMeta(
    'notetypeId',
  );
  @override
  late final GeneratedColumn<int> notetypeId = GeneratedColumn<int>(
    'notetype_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES notetypes (id)',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ordMeta = const VerificationMeta('ord');
  @override
  late final GeneratedColumn<int> ord = GeneratedColumn<int>(
    'ord',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, notetypeId, name, ord];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'notetype_fields';
  @override
  VerificationContext validateIntegrity(
    Insertable<NotetypeField> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('notetype_id')) {
      context.handle(
        _notetypeIdMeta,
        notetypeId.isAcceptableOrUnknown(data['notetype_id']!, _notetypeIdMeta),
      );
    } else if (isInserting) {
      context.missing(_notetypeIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('ord')) {
      context.handle(
        _ordMeta,
        ord.isAcceptableOrUnknown(data['ord']!, _ordMeta),
      );
    } else if (isInserting) {
      context.missing(_ordMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  NotetypeField map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return NotetypeField(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      notetypeId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}notetype_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      ord: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ord'],
      )!,
    );
  }

  @override
  $NotetypeFieldsTable createAlias(String alias) {
    return $NotetypeFieldsTable(attachedDatabase, alias);
  }
}

class NotetypeField extends DataClass implements Insertable<NotetypeField> {
  final int id;
  final int notetypeId;
  final String name;
  final int ord;
  const NotetypeField({
    required this.id,
    required this.notetypeId,
    required this.name,
    required this.ord,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['notetype_id'] = Variable<int>(notetypeId);
    map['name'] = Variable<String>(name);
    map['ord'] = Variable<int>(ord);
    return map;
  }

  NotetypeFieldsCompanion toCompanion(bool nullToAbsent) {
    return NotetypeFieldsCompanion(
      id: Value(id),
      notetypeId: Value(notetypeId),
      name: Value(name),
      ord: Value(ord),
    );
  }

  factory NotetypeField.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return NotetypeField(
      id: serializer.fromJson<int>(json['id']),
      notetypeId: serializer.fromJson<int>(json['notetypeId']),
      name: serializer.fromJson<String>(json['name']),
      ord: serializer.fromJson<int>(json['ord']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'notetypeId': serializer.toJson<int>(notetypeId),
      'name': serializer.toJson<String>(name),
      'ord': serializer.toJson<int>(ord),
    };
  }

  NotetypeField copyWith({int? id, int? notetypeId, String? name, int? ord}) =>
      NotetypeField(
        id: id ?? this.id,
        notetypeId: notetypeId ?? this.notetypeId,
        name: name ?? this.name,
        ord: ord ?? this.ord,
      );
  NotetypeField copyWithCompanion(NotetypeFieldsCompanion data) {
    return NotetypeField(
      id: data.id.present ? data.id.value : this.id,
      notetypeId: data.notetypeId.present
          ? data.notetypeId.value
          : this.notetypeId,
      name: data.name.present ? data.name.value : this.name,
      ord: data.ord.present ? data.ord.value : this.ord,
    );
  }

  @override
  String toString() {
    return (StringBuffer('NotetypeField(')
          ..write('id: $id, ')
          ..write('notetypeId: $notetypeId, ')
          ..write('name: $name, ')
          ..write('ord: $ord')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, notetypeId, name, ord);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is NotetypeField &&
          other.id == this.id &&
          other.notetypeId == this.notetypeId &&
          other.name == this.name &&
          other.ord == this.ord);
}

class NotetypeFieldsCompanion extends UpdateCompanion<NotetypeField> {
  final Value<int> id;
  final Value<int> notetypeId;
  final Value<String> name;
  final Value<int> ord;
  const NotetypeFieldsCompanion({
    this.id = const Value.absent(),
    this.notetypeId = const Value.absent(),
    this.name = const Value.absent(),
    this.ord = const Value.absent(),
  });
  NotetypeFieldsCompanion.insert({
    this.id = const Value.absent(),
    required int notetypeId,
    required String name,
    required int ord,
  }) : notetypeId = Value(notetypeId),
       name = Value(name),
       ord = Value(ord);
  static Insertable<NotetypeField> custom({
    Expression<int>? id,
    Expression<int>? notetypeId,
    Expression<String>? name,
    Expression<int>? ord,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (notetypeId != null) 'notetype_id': notetypeId,
      if (name != null) 'name': name,
      if (ord != null) 'ord': ord,
    });
  }

  NotetypeFieldsCompanion copyWith({
    Value<int>? id,
    Value<int>? notetypeId,
    Value<String>? name,
    Value<int>? ord,
  }) {
    return NotetypeFieldsCompanion(
      id: id ?? this.id,
      notetypeId: notetypeId ?? this.notetypeId,
      name: name ?? this.name,
      ord: ord ?? this.ord,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (notetypeId.present) {
      map['notetype_id'] = Variable<int>(notetypeId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (ord.present) {
      map['ord'] = Variable<int>(ord.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('NotetypeFieldsCompanion(')
          ..write('id: $id, ')
          ..write('notetypeId: $notetypeId, ')
          ..write('name: $name, ')
          ..write('ord: $ord')
          ..write(')'))
        .toString();
  }
}

class $NotetypeTemplatesTable extends NotetypeTemplates
    with TableInfo<$NotetypeTemplatesTable, NotetypeTemplate> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $NotetypeTemplatesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _notetypeIdMeta = const VerificationMeta(
    'notetypeId',
  );
  @override
  late final GeneratedColumn<int> notetypeId = GeneratedColumn<int>(
    'notetype_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES notetypes (id)',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ordMeta = const VerificationMeta('ord');
  @override
  late final GeneratedColumn<int> ord = GeneratedColumn<int>(
    'ord',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _questionFormatMeta = const VerificationMeta(
    'questionFormat',
  );
  @override
  late final GeneratedColumn<String> questionFormat = GeneratedColumn<String>(
    'question_format',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _answerFormatMeta = const VerificationMeta(
    'answerFormat',
  );
  @override
  late final GeneratedColumn<String> answerFormat = GeneratedColumn<String>(
    'answer_format',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    notetypeId,
    name,
    ord,
    questionFormat,
    answerFormat,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'notetype_templates';
  @override
  VerificationContext validateIntegrity(
    Insertable<NotetypeTemplate> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('notetype_id')) {
      context.handle(
        _notetypeIdMeta,
        notetypeId.isAcceptableOrUnknown(data['notetype_id']!, _notetypeIdMeta),
      );
    } else if (isInserting) {
      context.missing(_notetypeIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('ord')) {
      context.handle(
        _ordMeta,
        ord.isAcceptableOrUnknown(data['ord']!, _ordMeta),
      );
    } else if (isInserting) {
      context.missing(_ordMeta);
    }
    if (data.containsKey('question_format')) {
      context.handle(
        _questionFormatMeta,
        questionFormat.isAcceptableOrUnknown(
          data['question_format']!,
          _questionFormatMeta,
        ),
      );
    }
    if (data.containsKey('answer_format')) {
      context.handle(
        _answerFormatMeta,
        answerFormat.isAcceptableOrUnknown(
          data['answer_format']!,
          _answerFormatMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  NotetypeTemplate map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return NotetypeTemplate(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      notetypeId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}notetype_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      ord: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ord'],
      )!,
      questionFormat: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}question_format'],
      )!,
      answerFormat: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}answer_format'],
      )!,
    );
  }

  @override
  $NotetypeTemplatesTable createAlias(String alias) {
    return $NotetypeTemplatesTable(attachedDatabase, alias);
  }
}

class NotetypeTemplate extends DataClass
    implements Insertable<NotetypeTemplate> {
  final int id;
  final int notetypeId;
  final String name;
  final int ord;
  final String questionFormat;
  final String answerFormat;
  const NotetypeTemplate({
    required this.id,
    required this.notetypeId,
    required this.name,
    required this.ord,
    required this.questionFormat,
    required this.answerFormat,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['notetype_id'] = Variable<int>(notetypeId);
    map['name'] = Variable<String>(name);
    map['ord'] = Variable<int>(ord);
    map['question_format'] = Variable<String>(questionFormat);
    map['answer_format'] = Variable<String>(answerFormat);
    return map;
  }

  NotetypeTemplatesCompanion toCompanion(bool nullToAbsent) {
    return NotetypeTemplatesCompanion(
      id: Value(id),
      notetypeId: Value(notetypeId),
      name: Value(name),
      ord: Value(ord),
      questionFormat: Value(questionFormat),
      answerFormat: Value(answerFormat),
    );
  }

  factory NotetypeTemplate.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return NotetypeTemplate(
      id: serializer.fromJson<int>(json['id']),
      notetypeId: serializer.fromJson<int>(json['notetypeId']),
      name: serializer.fromJson<String>(json['name']),
      ord: serializer.fromJson<int>(json['ord']),
      questionFormat: serializer.fromJson<String>(json['questionFormat']),
      answerFormat: serializer.fromJson<String>(json['answerFormat']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'notetypeId': serializer.toJson<int>(notetypeId),
      'name': serializer.toJson<String>(name),
      'ord': serializer.toJson<int>(ord),
      'questionFormat': serializer.toJson<String>(questionFormat),
      'answerFormat': serializer.toJson<String>(answerFormat),
    };
  }

  NotetypeTemplate copyWith({
    int? id,
    int? notetypeId,
    String? name,
    int? ord,
    String? questionFormat,
    String? answerFormat,
  }) => NotetypeTemplate(
    id: id ?? this.id,
    notetypeId: notetypeId ?? this.notetypeId,
    name: name ?? this.name,
    ord: ord ?? this.ord,
    questionFormat: questionFormat ?? this.questionFormat,
    answerFormat: answerFormat ?? this.answerFormat,
  );
  NotetypeTemplate copyWithCompanion(NotetypeTemplatesCompanion data) {
    return NotetypeTemplate(
      id: data.id.present ? data.id.value : this.id,
      notetypeId: data.notetypeId.present
          ? data.notetypeId.value
          : this.notetypeId,
      name: data.name.present ? data.name.value : this.name,
      ord: data.ord.present ? data.ord.value : this.ord,
      questionFormat: data.questionFormat.present
          ? data.questionFormat.value
          : this.questionFormat,
      answerFormat: data.answerFormat.present
          ? data.answerFormat.value
          : this.answerFormat,
    );
  }

  @override
  String toString() {
    return (StringBuffer('NotetypeTemplate(')
          ..write('id: $id, ')
          ..write('notetypeId: $notetypeId, ')
          ..write('name: $name, ')
          ..write('ord: $ord, ')
          ..write('questionFormat: $questionFormat, ')
          ..write('answerFormat: $answerFormat')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, notetypeId, name, ord, questionFormat, answerFormat);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is NotetypeTemplate &&
          other.id == this.id &&
          other.notetypeId == this.notetypeId &&
          other.name == this.name &&
          other.ord == this.ord &&
          other.questionFormat == this.questionFormat &&
          other.answerFormat == this.answerFormat);
}

class NotetypeTemplatesCompanion extends UpdateCompanion<NotetypeTemplate> {
  final Value<int> id;
  final Value<int> notetypeId;
  final Value<String> name;
  final Value<int> ord;
  final Value<String> questionFormat;
  final Value<String> answerFormat;
  const NotetypeTemplatesCompanion({
    this.id = const Value.absent(),
    this.notetypeId = const Value.absent(),
    this.name = const Value.absent(),
    this.ord = const Value.absent(),
    this.questionFormat = const Value.absent(),
    this.answerFormat = const Value.absent(),
  });
  NotetypeTemplatesCompanion.insert({
    this.id = const Value.absent(),
    required int notetypeId,
    required String name,
    required int ord,
    this.questionFormat = const Value.absent(),
    this.answerFormat = const Value.absent(),
  }) : notetypeId = Value(notetypeId),
       name = Value(name),
       ord = Value(ord);
  static Insertable<NotetypeTemplate> custom({
    Expression<int>? id,
    Expression<int>? notetypeId,
    Expression<String>? name,
    Expression<int>? ord,
    Expression<String>? questionFormat,
    Expression<String>? answerFormat,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (notetypeId != null) 'notetype_id': notetypeId,
      if (name != null) 'name': name,
      if (ord != null) 'ord': ord,
      if (questionFormat != null) 'question_format': questionFormat,
      if (answerFormat != null) 'answer_format': answerFormat,
    });
  }

  NotetypeTemplatesCompanion copyWith({
    Value<int>? id,
    Value<int>? notetypeId,
    Value<String>? name,
    Value<int>? ord,
    Value<String>? questionFormat,
    Value<String>? answerFormat,
  }) {
    return NotetypeTemplatesCompanion(
      id: id ?? this.id,
      notetypeId: notetypeId ?? this.notetypeId,
      name: name ?? this.name,
      ord: ord ?? this.ord,
      questionFormat: questionFormat ?? this.questionFormat,
      answerFormat: answerFormat ?? this.answerFormat,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (notetypeId.present) {
      map['notetype_id'] = Variable<int>(notetypeId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (ord.present) {
      map['ord'] = Variable<int>(ord.value);
    }
    if (questionFormat.present) {
      map['question_format'] = Variable<String>(questionFormat.value);
    }
    if (answerFormat.present) {
      map['answer_format'] = Variable<String>(answerFormat.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('NotetypeTemplatesCompanion(')
          ..write('id: $id, ')
          ..write('notetypeId: $notetypeId, ')
          ..write('name: $name, ')
          ..write('ord: $ord, ')
          ..write('questionFormat: $questionFormat, ')
          ..write('answerFormat: $answerFormat')
          ..write(')'))
        .toString();
  }
}

class $NotesTable extends Notes with TableInfo<$NotesTable, Note> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $NotesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    clientDefault: epochMillisId,
  );
  static const VerificationMeta _notetypeIdMeta = const VerificationMeta(
    'notetypeId',
  );
  @override
  late final GeneratedColumn<int> notetypeId = GeneratedColumn<int>(
    'notetype_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES notetypes (id)',
    ),
  );
  static const VerificationMeta _fieldsJsonMeta = const VerificationMeta(
    'fieldsJson',
  );
  @override
  late final GeneratedColumn<String> fieldsJson = GeneratedColumn<String>(
    'fields_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tagsMeta = const VerificationMeta('tags');
  @override
  late final GeneratedColumn<String> tags = GeneratedColumn<String>(
    'tags',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    clientDefault: epochMillisNow,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    notetypeId,
    fieldsJson,
    tags,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'notes';
  @override
  VerificationContext validateIntegrity(
    Insertable<Note> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('notetype_id')) {
      context.handle(
        _notetypeIdMeta,
        notetypeId.isAcceptableOrUnknown(data['notetype_id']!, _notetypeIdMeta),
      );
    } else if (isInserting) {
      context.missing(_notetypeIdMeta);
    }
    if (data.containsKey('fields_json')) {
      context.handle(
        _fieldsJsonMeta,
        fieldsJson.isAcceptableOrUnknown(data['fields_json']!, _fieldsJsonMeta),
      );
    } else if (isInserting) {
      context.missing(_fieldsJsonMeta);
    }
    if (data.containsKey('tags')) {
      context.handle(
        _tagsMeta,
        tags.isAcceptableOrUnknown(data['tags']!, _tagsMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Note map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Note(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      notetypeId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}notetype_id'],
      )!,
      fieldsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}fields_json'],
      )!,
      tags: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tags'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $NotesTable createAlias(String alias) {
    return $NotesTable(attachedDatabase, alias);
  }
}

class Note extends DataClass implements Insertable<Note> {
  final int id;
  final int notetypeId;

  /// JSON-encoded `List<String>`, one entry per NotetypeField, in `ord` order.
  final String fieldsJson;

  /// Space-separated, same convention Anki uses.
  final String tags;
  final int createdAt;
  const Note({
    required this.id,
    required this.notetypeId,
    required this.fieldsJson,
    required this.tags,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['notetype_id'] = Variable<int>(notetypeId);
    map['fields_json'] = Variable<String>(fieldsJson);
    map['tags'] = Variable<String>(tags);
    map['created_at'] = Variable<int>(createdAt);
    return map;
  }

  NotesCompanion toCompanion(bool nullToAbsent) {
    return NotesCompanion(
      id: Value(id),
      notetypeId: Value(notetypeId),
      fieldsJson: Value(fieldsJson),
      tags: Value(tags),
      createdAt: Value(createdAt),
    );
  }

  factory Note.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Note(
      id: serializer.fromJson<int>(json['id']),
      notetypeId: serializer.fromJson<int>(json['notetypeId']),
      fieldsJson: serializer.fromJson<String>(json['fieldsJson']),
      tags: serializer.fromJson<String>(json['tags']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'notetypeId': serializer.toJson<int>(notetypeId),
      'fieldsJson': serializer.toJson<String>(fieldsJson),
      'tags': serializer.toJson<String>(tags),
      'createdAt': serializer.toJson<int>(createdAt),
    };
  }

  Note copyWith({
    int? id,
    int? notetypeId,
    String? fieldsJson,
    String? tags,
    int? createdAt,
  }) => Note(
    id: id ?? this.id,
    notetypeId: notetypeId ?? this.notetypeId,
    fieldsJson: fieldsJson ?? this.fieldsJson,
    tags: tags ?? this.tags,
    createdAt: createdAt ?? this.createdAt,
  );
  Note copyWithCompanion(NotesCompanion data) {
    return Note(
      id: data.id.present ? data.id.value : this.id,
      notetypeId: data.notetypeId.present
          ? data.notetypeId.value
          : this.notetypeId,
      fieldsJson: data.fieldsJson.present
          ? data.fieldsJson.value
          : this.fieldsJson,
      tags: data.tags.present ? data.tags.value : this.tags,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Note(')
          ..write('id: $id, ')
          ..write('notetypeId: $notetypeId, ')
          ..write('fieldsJson: $fieldsJson, ')
          ..write('tags: $tags, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, notetypeId, fieldsJson, tags, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Note &&
          other.id == this.id &&
          other.notetypeId == this.notetypeId &&
          other.fieldsJson == this.fieldsJson &&
          other.tags == this.tags &&
          other.createdAt == this.createdAt);
}

class NotesCompanion extends UpdateCompanion<Note> {
  final Value<int> id;
  final Value<int> notetypeId;
  final Value<String> fieldsJson;
  final Value<String> tags;
  final Value<int> createdAt;
  const NotesCompanion({
    this.id = const Value.absent(),
    this.notetypeId = const Value.absent(),
    this.fieldsJson = const Value.absent(),
    this.tags = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  NotesCompanion.insert({
    this.id = const Value.absent(),
    required int notetypeId,
    required String fieldsJson,
    this.tags = const Value.absent(),
    this.createdAt = const Value.absent(),
  }) : notetypeId = Value(notetypeId),
       fieldsJson = Value(fieldsJson);
  static Insertable<Note> custom({
    Expression<int>? id,
    Expression<int>? notetypeId,
    Expression<String>? fieldsJson,
    Expression<String>? tags,
    Expression<int>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (notetypeId != null) 'notetype_id': notetypeId,
      if (fieldsJson != null) 'fields_json': fieldsJson,
      if (tags != null) 'tags': tags,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  NotesCompanion copyWith({
    Value<int>? id,
    Value<int>? notetypeId,
    Value<String>? fieldsJson,
    Value<String>? tags,
    Value<int>? createdAt,
  }) {
    return NotesCompanion(
      id: id ?? this.id,
      notetypeId: notetypeId ?? this.notetypeId,
      fieldsJson: fieldsJson ?? this.fieldsJson,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (notetypeId.present) {
      map['notetype_id'] = Variable<int>(notetypeId.value);
    }
    if (fieldsJson.present) {
      map['fields_json'] = Variable<String>(fieldsJson.value);
    }
    if (tags.present) {
      map['tags'] = Variable<String>(tags.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('NotesCompanion(')
          ..write('id: $id, ')
          ..write('notetypeId: $notetypeId, ')
          ..write('fieldsJson: $fieldsJson, ')
          ..write('tags: $tags, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $CardsTable extends Cards with TableInfo<$CardsTable, CardEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CardsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    clientDefault: epochMillisId,
  );
  static const VerificationMeta _noteIdMeta = const VerificationMeta('noteId');
  @override
  late final GeneratedColumn<int> noteId = GeneratedColumn<int>(
    'note_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES notes (id)',
    ),
  );
  static const VerificationMeta _deckIdMeta = const VerificationMeta('deckId');
  @override
  late final GeneratedColumn<int> deckId = GeneratedColumn<int>(
    'deck_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES decks (id)',
    ),
  );
  static const VerificationMeta _templateOrdMeta = const VerificationMeta(
    'templateOrd',
  );
  @override
  late final GeneratedColumn<int> templateOrd = GeneratedColumn<int>(
    'template_ord',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<CardQueue, String> queue =
      GeneratedColumn<String>(
        'queue',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: Constant(CardQueue.newCard.name),
      ).withConverter<CardQueue>($CardsTable.$converterqueue);
  static const VerificationMeta _dueMeta = const VerificationMeta('due');
  @override
  late final GeneratedColumn<int> due = GeneratedColumn<int>(
    'due',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _ivlMeta = const VerificationMeta('ivl');
  @override
  late final GeneratedColumn<int> ivl = GeneratedColumn<int>(
    'ivl',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _easeMeta = const VerificationMeta('ease');
  @override
  late final GeneratedColumn<int> ease = GeneratedColumn<int>(
    'ease',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(2500),
  );
  static const VerificationMeta _repsMeta = const VerificationMeta('reps');
  @override
  late final GeneratedColumn<int> reps = GeneratedColumn<int>(
    'reps',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lapsesMeta = const VerificationMeta('lapses');
  @override
  late final GeneratedColumn<int> lapses = GeneratedColumn<int>(
    'lapses',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _stepIndexMeta = const VerificationMeta(
    'stepIndex',
  );
  @override
  late final GeneratedColumn<int> stepIndex = GeneratedColumn<int>(
    'step_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastReviewedAtMeta = const VerificationMeta(
    'lastReviewedAt',
  );
  @override
  late final GeneratedColumn<int> lastReviewedAt = GeneratedColumn<int>(
    'last_reviewed_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    noteId,
    deckId,
    templateOrd,
    queue,
    due,
    ivl,
    ease,
    reps,
    lapses,
    stepIndex,
    lastReviewedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cards';
  @override
  VerificationContext validateIntegrity(
    Insertable<CardEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('note_id')) {
      context.handle(
        _noteIdMeta,
        noteId.isAcceptableOrUnknown(data['note_id']!, _noteIdMeta),
      );
    } else if (isInserting) {
      context.missing(_noteIdMeta);
    }
    if (data.containsKey('deck_id')) {
      context.handle(
        _deckIdMeta,
        deckId.isAcceptableOrUnknown(data['deck_id']!, _deckIdMeta),
      );
    } else if (isInserting) {
      context.missing(_deckIdMeta);
    }
    if (data.containsKey('template_ord')) {
      context.handle(
        _templateOrdMeta,
        templateOrd.isAcceptableOrUnknown(
          data['template_ord']!,
          _templateOrdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_templateOrdMeta);
    }
    if (data.containsKey('due')) {
      context.handle(
        _dueMeta,
        due.isAcceptableOrUnknown(data['due']!, _dueMeta),
      );
    }
    if (data.containsKey('ivl')) {
      context.handle(
        _ivlMeta,
        ivl.isAcceptableOrUnknown(data['ivl']!, _ivlMeta),
      );
    }
    if (data.containsKey('ease')) {
      context.handle(
        _easeMeta,
        ease.isAcceptableOrUnknown(data['ease']!, _easeMeta),
      );
    }
    if (data.containsKey('reps')) {
      context.handle(
        _repsMeta,
        reps.isAcceptableOrUnknown(data['reps']!, _repsMeta),
      );
    }
    if (data.containsKey('lapses')) {
      context.handle(
        _lapsesMeta,
        lapses.isAcceptableOrUnknown(data['lapses']!, _lapsesMeta),
      );
    }
    if (data.containsKey('step_index')) {
      context.handle(
        _stepIndexMeta,
        stepIndex.isAcceptableOrUnknown(data['step_index']!, _stepIndexMeta),
      );
    }
    if (data.containsKey('last_reviewed_at')) {
      context.handle(
        _lastReviewedAtMeta,
        lastReviewedAt.isAcceptableOrUnknown(
          data['last_reviewed_at']!,
          _lastReviewedAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CardEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CardEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      noteId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}note_id'],
      )!,
      deckId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deck_id'],
      )!,
      templateOrd: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}template_ord'],
      )!,
      queue: $CardsTable.$converterqueue.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}queue'],
        )!,
      ),
      due: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}due'],
      )!,
      ivl: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ivl'],
      )!,
      ease: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ease'],
      )!,
      reps: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}reps'],
      )!,
      lapses: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}lapses'],
      )!,
      stepIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}step_index'],
      )!,
      lastReviewedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_reviewed_at'],
      ),
    );
  }

  @override
  $CardsTable createAlias(String alias) {
    return $CardsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<CardQueue, String, String> $converterqueue =
      const EnumNameConverter<CardQueue>(CardQueue.values);
}

class CardEntry extends DataClass implements Insertable<CardEntry> {
  final int id;
  final int noteId;
  final int deckId;
  final int templateOrd;
  final CardQueue queue;

  /// Day-number while [queue] is review/suspended; epoch-seconds while
  /// learning/relearning; a stable per-deck ordering key while new.
  final int due;
  final int ivl;
  final int ease;
  final int reps;
  final int lapses;
  final int stepIndex;
  final int? lastReviewedAt;
  const CardEntry({
    required this.id,
    required this.noteId,
    required this.deckId,
    required this.templateOrd,
    required this.queue,
    required this.due,
    required this.ivl,
    required this.ease,
    required this.reps,
    required this.lapses,
    required this.stepIndex,
    this.lastReviewedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['note_id'] = Variable<int>(noteId);
    map['deck_id'] = Variable<int>(deckId);
    map['template_ord'] = Variable<int>(templateOrd);
    {
      map['queue'] = Variable<String>($CardsTable.$converterqueue.toSql(queue));
    }
    map['due'] = Variable<int>(due);
    map['ivl'] = Variable<int>(ivl);
    map['ease'] = Variable<int>(ease);
    map['reps'] = Variable<int>(reps);
    map['lapses'] = Variable<int>(lapses);
    map['step_index'] = Variable<int>(stepIndex);
    if (!nullToAbsent || lastReviewedAt != null) {
      map['last_reviewed_at'] = Variable<int>(lastReviewedAt);
    }
    return map;
  }

  CardsCompanion toCompanion(bool nullToAbsent) {
    return CardsCompanion(
      id: Value(id),
      noteId: Value(noteId),
      deckId: Value(deckId),
      templateOrd: Value(templateOrd),
      queue: Value(queue),
      due: Value(due),
      ivl: Value(ivl),
      ease: Value(ease),
      reps: Value(reps),
      lapses: Value(lapses),
      stepIndex: Value(stepIndex),
      lastReviewedAt: lastReviewedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastReviewedAt),
    );
  }

  factory CardEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CardEntry(
      id: serializer.fromJson<int>(json['id']),
      noteId: serializer.fromJson<int>(json['noteId']),
      deckId: serializer.fromJson<int>(json['deckId']),
      templateOrd: serializer.fromJson<int>(json['templateOrd']),
      queue: $CardsTable.$converterqueue.fromJson(
        serializer.fromJson<String>(json['queue']),
      ),
      due: serializer.fromJson<int>(json['due']),
      ivl: serializer.fromJson<int>(json['ivl']),
      ease: serializer.fromJson<int>(json['ease']),
      reps: serializer.fromJson<int>(json['reps']),
      lapses: serializer.fromJson<int>(json['lapses']),
      stepIndex: serializer.fromJson<int>(json['stepIndex']),
      lastReviewedAt: serializer.fromJson<int?>(json['lastReviewedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'noteId': serializer.toJson<int>(noteId),
      'deckId': serializer.toJson<int>(deckId),
      'templateOrd': serializer.toJson<int>(templateOrd),
      'queue': serializer.toJson<String>(
        $CardsTable.$converterqueue.toJson(queue),
      ),
      'due': serializer.toJson<int>(due),
      'ivl': serializer.toJson<int>(ivl),
      'ease': serializer.toJson<int>(ease),
      'reps': serializer.toJson<int>(reps),
      'lapses': serializer.toJson<int>(lapses),
      'stepIndex': serializer.toJson<int>(stepIndex),
      'lastReviewedAt': serializer.toJson<int?>(lastReviewedAt),
    };
  }

  CardEntry copyWith({
    int? id,
    int? noteId,
    int? deckId,
    int? templateOrd,
    CardQueue? queue,
    int? due,
    int? ivl,
    int? ease,
    int? reps,
    int? lapses,
    int? stepIndex,
    Value<int?> lastReviewedAt = const Value.absent(),
  }) => CardEntry(
    id: id ?? this.id,
    noteId: noteId ?? this.noteId,
    deckId: deckId ?? this.deckId,
    templateOrd: templateOrd ?? this.templateOrd,
    queue: queue ?? this.queue,
    due: due ?? this.due,
    ivl: ivl ?? this.ivl,
    ease: ease ?? this.ease,
    reps: reps ?? this.reps,
    lapses: lapses ?? this.lapses,
    stepIndex: stepIndex ?? this.stepIndex,
    lastReviewedAt: lastReviewedAt.present
        ? lastReviewedAt.value
        : this.lastReviewedAt,
  );
  CardEntry copyWithCompanion(CardsCompanion data) {
    return CardEntry(
      id: data.id.present ? data.id.value : this.id,
      noteId: data.noteId.present ? data.noteId.value : this.noteId,
      deckId: data.deckId.present ? data.deckId.value : this.deckId,
      templateOrd: data.templateOrd.present
          ? data.templateOrd.value
          : this.templateOrd,
      queue: data.queue.present ? data.queue.value : this.queue,
      due: data.due.present ? data.due.value : this.due,
      ivl: data.ivl.present ? data.ivl.value : this.ivl,
      ease: data.ease.present ? data.ease.value : this.ease,
      reps: data.reps.present ? data.reps.value : this.reps,
      lapses: data.lapses.present ? data.lapses.value : this.lapses,
      stepIndex: data.stepIndex.present ? data.stepIndex.value : this.stepIndex,
      lastReviewedAt: data.lastReviewedAt.present
          ? data.lastReviewedAt.value
          : this.lastReviewedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CardEntry(')
          ..write('id: $id, ')
          ..write('noteId: $noteId, ')
          ..write('deckId: $deckId, ')
          ..write('templateOrd: $templateOrd, ')
          ..write('queue: $queue, ')
          ..write('due: $due, ')
          ..write('ivl: $ivl, ')
          ..write('ease: $ease, ')
          ..write('reps: $reps, ')
          ..write('lapses: $lapses, ')
          ..write('stepIndex: $stepIndex, ')
          ..write('lastReviewedAt: $lastReviewedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    noteId,
    deckId,
    templateOrd,
    queue,
    due,
    ivl,
    ease,
    reps,
    lapses,
    stepIndex,
    lastReviewedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CardEntry &&
          other.id == this.id &&
          other.noteId == this.noteId &&
          other.deckId == this.deckId &&
          other.templateOrd == this.templateOrd &&
          other.queue == this.queue &&
          other.due == this.due &&
          other.ivl == this.ivl &&
          other.ease == this.ease &&
          other.reps == this.reps &&
          other.lapses == this.lapses &&
          other.stepIndex == this.stepIndex &&
          other.lastReviewedAt == this.lastReviewedAt);
}

class CardsCompanion extends UpdateCompanion<CardEntry> {
  final Value<int> id;
  final Value<int> noteId;
  final Value<int> deckId;
  final Value<int> templateOrd;
  final Value<CardQueue> queue;
  final Value<int> due;
  final Value<int> ivl;
  final Value<int> ease;
  final Value<int> reps;
  final Value<int> lapses;
  final Value<int> stepIndex;
  final Value<int?> lastReviewedAt;
  const CardsCompanion({
    this.id = const Value.absent(),
    this.noteId = const Value.absent(),
    this.deckId = const Value.absent(),
    this.templateOrd = const Value.absent(),
    this.queue = const Value.absent(),
    this.due = const Value.absent(),
    this.ivl = const Value.absent(),
    this.ease = const Value.absent(),
    this.reps = const Value.absent(),
    this.lapses = const Value.absent(),
    this.stepIndex = const Value.absent(),
    this.lastReviewedAt = const Value.absent(),
  });
  CardsCompanion.insert({
    this.id = const Value.absent(),
    required int noteId,
    required int deckId,
    required int templateOrd,
    this.queue = const Value.absent(),
    this.due = const Value.absent(),
    this.ivl = const Value.absent(),
    this.ease = const Value.absent(),
    this.reps = const Value.absent(),
    this.lapses = const Value.absent(),
    this.stepIndex = const Value.absent(),
    this.lastReviewedAt = const Value.absent(),
  }) : noteId = Value(noteId),
       deckId = Value(deckId),
       templateOrd = Value(templateOrd);
  static Insertable<CardEntry> custom({
    Expression<int>? id,
    Expression<int>? noteId,
    Expression<int>? deckId,
    Expression<int>? templateOrd,
    Expression<String>? queue,
    Expression<int>? due,
    Expression<int>? ivl,
    Expression<int>? ease,
    Expression<int>? reps,
    Expression<int>? lapses,
    Expression<int>? stepIndex,
    Expression<int>? lastReviewedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (noteId != null) 'note_id': noteId,
      if (deckId != null) 'deck_id': deckId,
      if (templateOrd != null) 'template_ord': templateOrd,
      if (queue != null) 'queue': queue,
      if (due != null) 'due': due,
      if (ivl != null) 'ivl': ivl,
      if (ease != null) 'ease': ease,
      if (reps != null) 'reps': reps,
      if (lapses != null) 'lapses': lapses,
      if (stepIndex != null) 'step_index': stepIndex,
      if (lastReviewedAt != null) 'last_reviewed_at': lastReviewedAt,
    });
  }

  CardsCompanion copyWith({
    Value<int>? id,
    Value<int>? noteId,
    Value<int>? deckId,
    Value<int>? templateOrd,
    Value<CardQueue>? queue,
    Value<int>? due,
    Value<int>? ivl,
    Value<int>? ease,
    Value<int>? reps,
    Value<int>? lapses,
    Value<int>? stepIndex,
    Value<int?>? lastReviewedAt,
  }) {
    return CardsCompanion(
      id: id ?? this.id,
      noteId: noteId ?? this.noteId,
      deckId: deckId ?? this.deckId,
      templateOrd: templateOrd ?? this.templateOrd,
      queue: queue ?? this.queue,
      due: due ?? this.due,
      ivl: ivl ?? this.ivl,
      ease: ease ?? this.ease,
      reps: reps ?? this.reps,
      lapses: lapses ?? this.lapses,
      stepIndex: stepIndex ?? this.stepIndex,
      lastReviewedAt: lastReviewedAt ?? this.lastReviewedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (noteId.present) {
      map['note_id'] = Variable<int>(noteId.value);
    }
    if (deckId.present) {
      map['deck_id'] = Variable<int>(deckId.value);
    }
    if (templateOrd.present) {
      map['template_ord'] = Variable<int>(templateOrd.value);
    }
    if (queue.present) {
      map['queue'] = Variable<String>(
        $CardsTable.$converterqueue.toSql(queue.value),
      );
    }
    if (due.present) {
      map['due'] = Variable<int>(due.value);
    }
    if (ivl.present) {
      map['ivl'] = Variable<int>(ivl.value);
    }
    if (ease.present) {
      map['ease'] = Variable<int>(ease.value);
    }
    if (reps.present) {
      map['reps'] = Variable<int>(reps.value);
    }
    if (lapses.present) {
      map['lapses'] = Variable<int>(lapses.value);
    }
    if (stepIndex.present) {
      map['step_index'] = Variable<int>(stepIndex.value);
    }
    if (lastReviewedAt.present) {
      map['last_reviewed_at'] = Variable<int>(lastReviewedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CardsCompanion(')
          ..write('id: $id, ')
          ..write('noteId: $noteId, ')
          ..write('deckId: $deckId, ')
          ..write('templateOrd: $templateOrd, ')
          ..write('queue: $queue, ')
          ..write('due: $due, ')
          ..write('ivl: $ivl, ')
          ..write('ease: $ease, ')
          ..write('reps: $reps, ')
          ..write('lapses: $lapses, ')
          ..write('stepIndex: $stepIndex, ')
          ..write('lastReviewedAt: $lastReviewedAt')
          ..write(')'))
        .toString();
  }
}

class $RevLogTable extends RevLog with TableInfo<$RevLogTable, RevLogData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RevLogTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _cardIdMeta = const VerificationMeta('cardId');
  @override
  late final GeneratedColumn<int> cardId = GeneratedColumn<int>(
    'card_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES cards (id)',
    ),
  );
  static const VerificationMeta _reviewedAtMeta = const VerificationMeta(
    'reviewedAt',
  );
  @override
  late final GeneratedColumn<int> reviewedAt = GeneratedColumn<int>(
    'reviewed_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ratingMeta = const VerificationMeta('rating');
  @override
  late final GeneratedColumn<int> rating = GeneratedColumn<int>(
    'rating',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ivlBeforeMeta = const VerificationMeta(
    'ivlBefore',
  );
  @override
  late final GeneratedColumn<int> ivlBefore = GeneratedColumn<int>(
    'ivl_before',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ivlAfterMeta = const VerificationMeta(
    'ivlAfter',
  );
  @override
  late final GeneratedColumn<int> ivlAfter = GeneratedColumn<int>(
    'ivl_after',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _easeAfterMeta = const VerificationMeta(
    'easeAfter',
  );
  @override
  late final GeneratedColumn<int> easeAfter = GeneratedColumn<int>(
    'ease_after',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _timeTakenMsMeta = const VerificationMeta(
    'timeTakenMs',
  );
  @override
  late final GeneratedColumn<int> timeTakenMs = GeneratedColumn<int>(
    'time_taken_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    cardId,
    reviewedAt,
    rating,
    ivlBefore,
    ivlAfter,
    easeAfter,
    timeTakenMs,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'rev_log';
  @override
  VerificationContext validateIntegrity(
    Insertable<RevLogData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('card_id')) {
      context.handle(
        _cardIdMeta,
        cardId.isAcceptableOrUnknown(data['card_id']!, _cardIdMeta),
      );
    } else if (isInserting) {
      context.missing(_cardIdMeta);
    }
    if (data.containsKey('reviewed_at')) {
      context.handle(
        _reviewedAtMeta,
        reviewedAt.isAcceptableOrUnknown(data['reviewed_at']!, _reviewedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_reviewedAtMeta);
    }
    if (data.containsKey('rating')) {
      context.handle(
        _ratingMeta,
        rating.isAcceptableOrUnknown(data['rating']!, _ratingMeta),
      );
    } else if (isInserting) {
      context.missing(_ratingMeta);
    }
    if (data.containsKey('ivl_before')) {
      context.handle(
        _ivlBeforeMeta,
        ivlBefore.isAcceptableOrUnknown(data['ivl_before']!, _ivlBeforeMeta),
      );
    } else if (isInserting) {
      context.missing(_ivlBeforeMeta);
    }
    if (data.containsKey('ivl_after')) {
      context.handle(
        _ivlAfterMeta,
        ivlAfter.isAcceptableOrUnknown(data['ivl_after']!, _ivlAfterMeta),
      );
    } else if (isInserting) {
      context.missing(_ivlAfterMeta);
    }
    if (data.containsKey('ease_after')) {
      context.handle(
        _easeAfterMeta,
        easeAfter.isAcceptableOrUnknown(data['ease_after']!, _easeAfterMeta),
      );
    } else if (isInserting) {
      context.missing(_easeAfterMeta);
    }
    if (data.containsKey('time_taken_ms')) {
      context.handle(
        _timeTakenMsMeta,
        timeTakenMs.isAcceptableOrUnknown(
          data['time_taken_ms']!,
          _timeTakenMsMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RevLogData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RevLogData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      cardId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}card_id'],
      )!,
      reviewedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}reviewed_at'],
      )!,
      rating: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}rating'],
      )!,
      ivlBefore: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ivl_before'],
      )!,
      ivlAfter: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ivl_after'],
      )!,
      easeAfter: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ease_after'],
      )!,
      timeTakenMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}time_taken_ms'],
      )!,
    );
  }

  @override
  $RevLogTable createAlias(String alias) {
    return $RevLogTable(attachedDatabase, alias);
  }
}

class RevLogData extends DataClass implements Insertable<RevLogData> {
  final int id;
  final int cardId;
  final int reviewedAt;

  /// 1=Again, 2=Hard, 3=Good, 4=Easy - matches Anki's revlog.ease convention.
  final int rating;
  final int ivlBefore;
  final int ivlAfter;
  final int easeAfter;
  final int timeTakenMs;
  const RevLogData({
    required this.id,
    required this.cardId,
    required this.reviewedAt,
    required this.rating,
    required this.ivlBefore,
    required this.ivlAfter,
    required this.easeAfter,
    required this.timeTakenMs,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['card_id'] = Variable<int>(cardId);
    map['reviewed_at'] = Variable<int>(reviewedAt);
    map['rating'] = Variable<int>(rating);
    map['ivl_before'] = Variable<int>(ivlBefore);
    map['ivl_after'] = Variable<int>(ivlAfter);
    map['ease_after'] = Variable<int>(easeAfter);
    map['time_taken_ms'] = Variable<int>(timeTakenMs);
    return map;
  }

  RevLogCompanion toCompanion(bool nullToAbsent) {
    return RevLogCompanion(
      id: Value(id),
      cardId: Value(cardId),
      reviewedAt: Value(reviewedAt),
      rating: Value(rating),
      ivlBefore: Value(ivlBefore),
      ivlAfter: Value(ivlAfter),
      easeAfter: Value(easeAfter),
      timeTakenMs: Value(timeTakenMs),
    );
  }

  factory RevLogData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RevLogData(
      id: serializer.fromJson<int>(json['id']),
      cardId: serializer.fromJson<int>(json['cardId']),
      reviewedAt: serializer.fromJson<int>(json['reviewedAt']),
      rating: serializer.fromJson<int>(json['rating']),
      ivlBefore: serializer.fromJson<int>(json['ivlBefore']),
      ivlAfter: serializer.fromJson<int>(json['ivlAfter']),
      easeAfter: serializer.fromJson<int>(json['easeAfter']),
      timeTakenMs: serializer.fromJson<int>(json['timeTakenMs']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'cardId': serializer.toJson<int>(cardId),
      'reviewedAt': serializer.toJson<int>(reviewedAt),
      'rating': serializer.toJson<int>(rating),
      'ivlBefore': serializer.toJson<int>(ivlBefore),
      'ivlAfter': serializer.toJson<int>(ivlAfter),
      'easeAfter': serializer.toJson<int>(easeAfter),
      'timeTakenMs': serializer.toJson<int>(timeTakenMs),
    };
  }

  RevLogData copyWith({
    int? id,
    int? cardId,
    int? reviewedAt,
    int? rating,
    int? ivlBefore,
    int? ivlAfter,
    int? easeAfter,
    int? timeTakenMs,
  }) => RevLogData(
    id: id ?? this.id,
    cardId: cardId ?? this.cardId,
    reviewedAt: reviewedAt ?? this.reviewedAt,
    rating: rating ?? this.rating,
    ivlBefore: ivlBefore ?? this.ivlBefore,
    ivlAfter: ivlAfter ?? this.ivlAfter,
    easeAfter: easeAfter ?? this.easeAfter,
    timeTakenMs: timeTakenMs ?? this.timeTakenMs,
  );
  RevLogData copyWithCompanion(RevLogCompanion data) {
    return RevLogData(
      id: data.id.present ? data.id.value : this.id,
      cardId: data.cardId.present ? data.cardId.value : this.cardId,
      reviewedAt: data.reviewedAt.present
          ? data.reviewedAt.value
          : this.reviewedAt,
      rating: data.rating.present ? data.rating.value : this.rating,
      ivlBefore: data.ivlBefore.present ? data.ivlBefore.value : this.ivlBefore,
      ivlAfter: data.ivlAfter.present ? data.ivlAfter.value : this.ivlAfter,
      easeAfter: data.easeAfter.present ? data.easeAfter.value : this.easeAfter,
      timeTakenMs: data.timeTakenMs.present
          ? data.timeTakenMs.value
          : this.timeTakenMs,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RevLogData(')
          ..write('id: $id, ')
          ..write('cardId: $cardId, ')
          ..write('reviewedAt: $reviewedAt, ')
          ..write('rating: $rating, ')
          ..write('ivlBefore: $ivlBefore, ')
          ..write('ivlAfter: $ivlAfter, ')
          ..write('easeAfter: $easeAfter, ')
          ..write('timeTakenMs: $timeTakenMs')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    cardId,
    reviewedAt,
    rating,
    ivlBefore,
    ivlAfter,
    easeAfter,
    timeTakenMs,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RevLogData &&
          other.id == this.id &&
          other.cardId == this.cardId &&
          other.reviewedAt == this.reviewedAt &&
          other.rating == this.rating &&
          other.ivlBefore == this.ivlBefore &&
          other.ivlAfter == this.ivlAfter &&
          other.easeAfter == this.easeAfter &&
          other.timeTakenMs == this.timeTakenMs);
}

class RevLogCompanion extends UpdateCompanion<RevLogData> {
  final Value<int> id;
  final Value<int> cardId;
  final Value<int> reviewedAt;
  final Value<int> rating;
  final Value<int> ivlBefore;
  final Value<int> ivlAfter;
  final Value<int> easeAfter;
  final Value<int> timeTakenMs;
  const RevLogCompanion({
    this.id = const Value.absent(),
    this.cardId = const Value.absent(),
    this.reviewedAt = const Value.absent(),
    this.rating = const Value.absent(),
    this.ivlBefore = const Value.absent(),
    this.ivlAfter = const Value.absent(),
    this.easeAfter = const Value.absent(),
    this.timeTakenMs = const Value.absent(),
  });
  RevLogCompanion.insert({
    this.id = const Value.absent(),
    required int cardId,
    required int reviewedAt,
    required int rating,
    required int ivlBefore,
    required int ivlAfter,
    required int easeAfter,
    this.timeTakenMs = const Value.absent(),
  }) : cardId = Value(cardId),
       reviewedAt = Value(reviewedAt),
       rating = Value(rating),
       ivlBefore = Value(ivlBefore),
       ivlAfter = Value(ivlAfter),
       easeAfter = Value(easeAfter);
  static Insertable<RevLogData> custom({
    Expression<int>? id,
    Expression<int>? cardId,
    Expression<int>? reviewedAt,
    Expression<int>? rating,
    Expression<int>? ivlBefore,
    Expression<int>? ivlAfter,
    Expression<int>? easeAfter,
    Expression<int>? timeTakenMs,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (cardId != null) 'card_id': cardId,
      if (reviewedAt != null) 'reviewed_at': reviewedAt,
      if (rating != null) 'rating': rating,
      if (ivlBefore != null) 'ivl_before': ivlBefore,
      if (ivlAfter != null) 'ivl_after': ivlAfter,
      if (easeAfter != null) 'ease_after': easeAfter,
      if (timeTakenMs != null) 'time_taken_ms': timeTakenMs,
    });
  }

  RevLogCompanion copyWith({
    Value<int>? id,
    Value<int>? cardId,
    Value<int>? reviewedAt,
    Value<int>? rating,
    Value<int>? ivlBefore,
    Value<int>? ivlAfter,
    Value<int>? easeAfter,
    Value<int>? timeTakenMs,
  }) {
    return RevLogCompanion(
      id: id ?? this.id,
      cardId: cardId ?? this.cardId,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      rating: rating ?? this.rating,
      ivlBefore: ivlBefore ?? this.ivlBefore,
      ivlAfter: ivlAfter ?? this.ivlAfter,
      easeAfter: easeAfter ?? this.easeAfter,
      timeTakenMs: timeTakenMs ?? this.timeTakenMs,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (cardId.present) {
      map['card_id'] = Variable<int>(cardId.value);
    }
    if (reviewedAt.present) {
      map['reviewed_at'] = Variable<int>(reviewedAt.value);
    }
    if (rating.present) {
      map['rating'] = Variable<int>(rating.value);
    }
    if (ivlBefore.present) {
      map['ivl_before'] = Variable<int>(ivlBefore.value);
    }
    if (ivlAfter.present) {
      map['ivl_after'] = Variable<int>(ivlAfter.value);
    }
    if (easeAfter.present) {
      map['ease_after'] = Variable<int>(easeAfter.value);
    }
    if (timeTakenMs.present) {
      map['time_taken_ms'] = Variable<int>(timeTakenMs.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RevLogCompanion(')
          ..write('id: $id, ')
          ..write('cardId: $cardId, ')
          ..write('reviewedAt: $reviewedAt, ')
          ..write('rating: $rating, ')
          ..write('ivlBefore: $ivlBefore, ')
          ..write('ivlAfter: $ivlAfter, ')
          ..write('easeAfter: $easeAfter, ')
          ..write('timeTakenMs: $timeTakenMs')
          ..write(')'))
        .toString();
  }
}

class $CollectionMetaTable extends CollectionMeta
    with TableInfo<$CollectionMetaTable, CollectionMetaData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CollectionMetaTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    clientDefault: epochMillisNow,
  );
  static const VerificationMeta _rolloverHourMeta = const VerificationMeta(
    'rolloverHour',
  );
  @override
  late final GeneratedColumn<int> rolloverHour = GeneratedColumn<int>(
    'rollover_hour',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(4),
  );
  @override
  List<GeneratedColumn> get $columns => [id, createdAt, rolloverHour];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'collection_meta';
  @override
  VerificationContext validateIntegrity(
    Insertable<CollectionMetaData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('rollover_hour')) {
      context.handle(
        _rolloverHourMeta,
        rolloverHour.isAcceptableOrUnknown(
          data['rollover_hour']!,
          _rolloverHourMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CollectionMetaData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CollectionMetaData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      rolloverHour: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}rollover_hour'],
      )!,
    );
  }

  @override
  $CollectionMetaTable createAlias(String alias) {
    return $CollectionMetaTable(attachedDatabase, alias);
  }
}

class CollectionMetaData extends DataClass
    implements Insertable<CollectionMetaData> {
  final int id;
  final int createdAt;
  final int rolloverHour;
  const CollectionMetaData({
    required this.id,
    required this.createdAt,
    required this.rolloverHour,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['created_at'] = Variable<int>(createdAt);
    map['rollover_hour'] = Variable<int>(rolloverHour);
    return map;
  }

  CollectionMetaCompanion toCompanion(bool nullToAbsent) {
    return CollectionMetaCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      rolloverHour: Value(rolloverHour),
    );
  }

  factory CollectionMetaData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CollectionMetaData(
      id: serializer.fromJson<int>(json['id']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      rolloverHour: serializer.fromJson<int>(json['rolloverHour']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'createdAt': serializer.toJson<int>(createdAt),
      'rolloverHour': serializer.toJson<int>(rolloverHour),
    };
  }

  CollectionMetaData copyWith({int? id, int? createdAt, int? rolloverHour}) =>
      CollectionMetaData(
        id: id ?? this.id,
        createdAt: createdAt ?? this.createdAt,
        rolloverHour: rolloverHour ?? this.rolloverHour,
      );
  CollectionMetaData copyWithCompanion(CollectionMetaCompanion data) {
    return CollectionMetaData(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      rolloverHour: data.rolloverHour.present
          ? data.rolloverHour.value
          : this.rolloverHour,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CollectionMetaData(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('rolloverHour: $rolloverHour')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, createdAt, rolloverHour);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CollectionMetaData &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.rolloverHour == this.rolloverHour);
}

class CollectionMetaCompanion extends UpdateCompanion<CollectionMetaData> {
  final Value<int> id;
  final Value<int> createdAt;
  final Value<int> rolloverHour;
  const CollectionMetaCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rolloverHour = const Value.absent(),
  });
  CollectionMetaCompanion.insert({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rolloverHour = const Value.absent(),
  });
  static Insertable<CollectionMetaData> custom({
    Expression<int>? id,
    Expression<int>? createdAt,
    Expression<int>? rolloverHour,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (rolloverHour != null) 'rollover_hour': rolloverHour,
    });
  }

  CollectionMetaCompanion copyWith({
    Value<int>? id,
    Value<int>? createdAt,
    Value<int>? rolloverHour,
  }) {
    return CollectionMetaCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      rolloverHour: rolloverHour ?? this.rolloverHour,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (rolloverHour.present) {
      map['rollover_hour'] = Variable<int>(rolloverHour.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CollectionMetaCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('rolloverHour: $rolloverHour')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $DeckConfigsTable deckConfigs = $DeckConfigsTable(this);
  late final $DecksTable decks = $DecksTable(this);
  late final $NotetypesTable notetypes = $NotetypesTable(this);
  late final $NotetypeFieldsTable notetypeFields = $NotetypeFieldsTable(this);
  late final $NotetypeTemplatesTable notetypeTemplates =
      $NotetypeTemplatesTable(this);
  late final $NotesTable notes = $NotesTable(this);
  late final $CardsTable cards = $CardsTable(this);
  late final $RevLogTable revLog = $RevLogTable(this);
  late final $CollectionMetaTable collectionMeta = $CollectionMetaTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    deckConfigs,
    decks,
    notetypes,
    notetypeFields,
    notetypeTemplates,
    notes,
    cards,
    revLog,
    collectionMeta,
  ];
}

typedef $$DeckConfigsTableCreateCompanionBuilder =
    DeckConfigsCompanion Function({
      Value<int> id,
      required String name,
      Value<String> learningStepsMin,
      Value<String> relearningStepsMin,
      Value<int> graduatingIntervalDays,
      Value<int> easyIntervalDays,
      Value<int> startingEase,
      Value<int> easyBonusPct,
      Value<int> intervalModifierPct,
      Value<int> hardIntervalPct,
      Value<int> newIntervalPct,
      Value<int> leechThreshold,
      Value<int> maximumIntervalDays,
      Value<int> minEase,
      Value<int> newPerDay,
      Value<int> reviewsPerDay,
    });
typedef $$DeckConfigsTableUpdateCompanionBuilder =
    DeckConfigsCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<String> learningStepsMin,
      Value<String> relearningStepsMin,
      Value<int> graduatingIntervalDays,
      Value<int> easyIntervalDays,
      Value<int> startingEase,
      Value<int> easyBonusPct,
      Value<int> intervalModifierPct,
      Value<int> hardIntervalPct,
      Value<int> newIntervalPct,
      Value<int> leechThreshold,
      Value<int> maximumIntervalDays,
      Value<int> minEase,
      Value<int> newPerDay,
      Value<int> reviewsPerDay,
    });

final class $$DeckConfigsTableReferences
    extends BaseReferences<_$AppDatabase, $DeckConfigsTable, DeckConfig> {
  $$DeckConfigsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$DecksTable, List<Deck>> _decksRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.decks,
    aliasName: 'deck_configs__id__decks__deck_config_id',
  );

  $$DecksTableProcessedTableManager get decksRefs {
    final manager = $$DecksTableTableManager(
      $_db,
      $_db.decks,
    ).filter((f) => f.deckConfigId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_decksRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$DeckConfigsTableFilterComposer
    extends Composer<_$AppDatabase, $DeckConfigsTable> {
  $$DeckConfigsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get learningStepsMin => $composableBuilder(
    column: $table.learningStepsMin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get relearningStepsMin => $composableBuilder(
    column: $table.relearningStepsMin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get graduatingIntervalDays => $composableBuilder(
    column: $table.graduatingIntervalDays,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get easyIntervalDays => $composableBuilder(
    column: $table.easyIntervalDays,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get startingEase => $composableBuilder(
    column: $table.startingEase,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get easyBonusPct => $composableBuilder(
    column: $table.easyBonusPct,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get intervalModifierPct => $composableBuilder(
    column: $table.intervalModifierPct,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get hardIntervalPct => $composableBuilder(
    column: $table.hardIntervalPct,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get newIntervalPct => $composableBuilder(
    column: $table.newIntervalPct,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get leechThreshold => $composableBuilder(
    column: $table.leechThreshold,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get maximumIntervalDays => $composableBuilder(
    column: $table.maximumIntervalDays,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get minEase => $composableBuilder(
    column: $table.minEase,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get newPerDay => $composableBuilder(
    column: $table.newPerDay,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get reviewsPerDay => $composableBuilder(
    column: $table.reviewsPerDay,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> decksRefs(
    Expression<bool> Function($$DecksTableFilterComposer f) f,
  ) {
    final $$DecksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.decks,
      getReferencedColumn: (t) => t.deckConfigId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DecksTableFilterComposer(
            $db: $db,
            $table: $db.decks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$DeckConfigsTableOrderingComposer
    extends Composer<_$AppDatabase, $DeckConfigsTable> {
  $$DeckConfigsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get learningStepsMin => $composableBuilder(
    column: $table.learningStepsMin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get relearningStepsMin => $composableBuilder(
    column: $table.relearningStepsMin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get graduatingIntervalDays => $composableBuilder(
    column: $table.graduatingIntervalDays,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get easyIntervalDays => $composableBuilder(
    column: $table.easyIntervalDays,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get startingEase => $composableBuilder(
    column: $table.startingEase,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get easyBonusPct => $composableBuilder(
    column: $table.easyBonusPct,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get intervalModifierPct => $composableBuilder(
    column: $table.intervalModifierPct,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get hardIntervalPct => $composableBuilder(
    column: $table.hardIntervalPct,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get newIntervalPct => $composableBuilder(
    column: $table.newIntervalPct,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get leechThreshold => $composableBuilder(
    column: $table.leechThreshold,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get maximumIntervalDays => $composableBuilder(
    column: $table.maximumIntervalDays,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get minEase => $composableBuilder(
    column: $table.minEase,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get newPerDay => $composableBuilder(
    column: $table.newPerDay,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get reviewsPerDay => $composableBuilder(
    column: $table.reviewsPerDay,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DeckConfigsTableAnnotationComposer
    extends Composer<_$AppDatabase, $DeckConfigsTable> {
  $$DeckConfigsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get learningStepsMin => $composableBuilder(
    column: $table.learningStepsMin,
    builder: (column) => column,
  );

  GeneratedColumn<String> get relearningStepsMin => $composableBuilder(
    column: $table.relearningStepsMin,
    builder: (column) => column,
  );

  GeneratedColumn<int> get graduatingIntervalDays => $composableBuilder(
    column: $table.graduatingIntervalDays,
    builder: (column) => column,
  );

  GeneratedColumn<int> get easyIntervalDays => $composableBuilder(
    column: $table.easyIntervalDays,
    builder: (column) => column,
  );

  GeneratedColumn<int> get startingEase => $composableBuilder(
    column: $table.startingEase,
    builder: (column) => column,
  );

  GeneratedColumn<int> get easyBonusPct => $composableBuilder(
    column: $table.easyBonusPct,
    builder: (column) => column,
  );

  GeneratedColumn<int> get intervalModifierPct => $composableBuilder(
    column: $table.intervalModifierPct,
    builder: (column) => column,
  );

  GeneratedColumn<int> get hardIntervalPct => $composableBuilder(
    column: $table.hardIntervalPct,
    builder: (column) => column,
  );

  GeneratedColumn<int> get newIntervalPct => $composableBuilder(
    column: $table.newIntervalPct,
    builder: (column) => column,
  );

  GeneratedColumn<int> get leechThreshold => $composableBuilder(
    column: $table.leechThreshold,
    builder: (column) => column,
  );

  GeneratedColumn<int> get maximumIntervalDays => $composableBuilder(
    column: $table.maximumIntervalDays,
    builder: (column) => column,
  );

  GeneratedColumn<int> get minEase =>
      $composableBuilder(column: $table.minEase, builder: (column) => column);

  GeneratedColumn<int> get newPerDay =>
      $composableBuilder(column: $table.newPerDay, builder: (column) => column);

  GeneratedColumn<int> get reviewsPerDay => $composableBuilder(
    column: $table.reviewsPerDay,
    builder: (column) => column,
  );

  Expression<T> decksRefs<T extends Object>(
    Expression<T> Function($$DecksTableAnnotationComposer a) f,
  ) {
    final $$DecksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.decks,
      getReferencedColumn: (t) => t.deckConfigId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DecksTableAnnotationComposer(
            $db: $db,
            $table: $db.decks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$DeckConfigsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DeckConfigsTable,
          DeckConfig,
          $$DeckConfigsTableFilterComposer,
          $$DeckConfigsTableOrderingComposer,
          $$DeckConfigsTableAnnotationComposer,
          $$DeckConfigsTableCreateCompanionBuilder,
          $$DeckConfigsTableUpdateCompanionBuilder,
          (DeckConfig, $$DeckConfigsTableReferences),
          DeckConfig,
          PrefetchHooks Function({bool decksRefs})
        > {
  $$DeckConfigsTableTableManager(_$AppDatabase db, $DeckConfigsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DeckConfigsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DeckConfigsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DeckConfigsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> learningStepsMin = const Value.absent(),
                Value<String> relearningStepsMin = const Value.absent(),
                Value<int> graduatingIntervalDays = const Value.absent(),
                Value<int> easyIntervalDays = const Value.absent(),
                Value<int> startingEase = const Value.absent(),
                Value<int> easyBonusPct = const Value.absent(),
                Value<int> intervalModifierPct = const Value.absent(),
                Value<int> hardIntervalPct = const Value.absent(),
                Value<int> newIntervalPct = const Value.absent(),
                Value<int> leechThreshold = const Value.absent(),
                Value<int> maximumIntervalDays = const Value.absent(),
                Value<int> minEase = const Value.absent(),
                Value<int> newPerDay = const Value.absent(),
                Value<int> reviewsPerDay = const Value.absent(),
              }) => DeckConfigsCompanion(
                id: id,
                name: name,
                learningStepsMin: learningStepsMin,
                relearningStepsMin: relearningStepsMin,
                graduatingIntervalDays: graduatingIntervalDays,
                easyIntervalDays: easyIntervalDays,
                startingEase: startingEase,
                easyBonusPct: easyBonusPct,
                intervalModifierPct: intervalModifierPct,
                hardIntervalPct: hardIntervalPct,
                newIntervalPct: newIntervalPct,
                leechThreshold: leechThreshold,
                maximumIntervalDays: maximumIntervalDays,
                minEase: minEase,
                newPerDay: newPerDay,
                reviewsPerDay: reviewsPerDay,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                Value<String> learningStepsMin = const Value.absent(),
                Value<String> relearningStepsMin = const Value.absent(),
                Value<int> graduatingIntervalDays = const Value.absent(),
                Value<int> easyIntervalDays = const Value.absent(),
                Value<int> startingEase = const Value.absent(),
                Value<int> easyBonusPct = const Value.absent(),
                Value<int> intervalModifierPct = const Value.absent(),
                Value<int> hardIntervalPct = const Value.absent(),
                Value<int> newIntervalPct = const Value.absent(),
                Value<int> leechThreshold = const Value.absent(),
                Value<int> maximumIntervalDays = const Value.absent(),
                Value<int> minEase = const Value.absent(),
                Value<int> newPerDay = const Value.absent(),
                Value<int> reviewsPerDay = const Value.absent(),
              }) => DeckConfigsCompanion.insert(
                id: id,
                name: name,
                learningStepsMin: learningStepsMin,
                relearningStepsMin: relearningStepsMin,
                graduatingIntervalDays: graduatingIntervalDays,
                easyIntervalDays: easyIntervalDays,
                startingEase: startingEase,
                easyBonusPct: easyBonusPct,
                intervalModifierPct: intervalModifierPct,
                hardIntervalPct: hardIntervalPct,
                newIntervalPct: newIntervalPct,
                leechThreshold: leechThreshold,
                maximumIntervalDays: maximumIntervalDays,
                minEase: minEase,
                newPerDay: newPerDay,
                reviewsPerDay: reviewsPerDay,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$DeckConfigsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({decksRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (decksRefs) db.decks],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (decksRefs)
                    await $_getPrefetchedData<
                      DeckConfig,
                      $DeckConfigsTable,
                      Deck
                    >(
                      currentTable: table,
                      referencedTable: $$DeckConfigsTableReferences
                          ._decksRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$DeckConfigsTableReferences(db, table, p0).decksRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where(
                            (e) => e.deckConfigId == item.id,
                          ),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$DeckConfigsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DeckConfigsTable,
      DeckConfig,
      $$DeckConfigsTableFilterComposer,
      $$DeckConfigsTableOrderingComposer,
      $$DeckConfigsTableAnnotationComposer,
      $$DeckConfigsTableCreateCompanionBuilder,
      $$DeckConfigsTableUpdateCompanionBuilder,
      (DeckConfig, $$DeckConfigsTableReferences),
      DeckConfig,
      PrefetchHooks Function({bool decksRefs})
    >;
typedef $$DecksTableCreateCompanionBuilder =
    DecksCompanion Function({
      Value<int> id,
      required String name,
      required int deckConfigId,
      Value<int?> newPerDayOverride,
      Value<int?> reviewsPerDayOverride,
      Value<bool> collapsed,
      Value<int> newShownToday,
      Value<int> newShownDay,
      Value<int> reviewsShownToday,
      Value<int> reviewsShownDay,
    });
typedef $$DecksTableUpdateCompanionBuilder =
    DecksCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<int> deckConfigId,
      Value<int?> newPerDayOverride,
      Value<int?> reviewsPerDayOverride,
      Value<bool> collapsed,
      Value<int> newShownToday,
      Value<int> newShownDay,
      Value<int> reviewsShownToday,
      Value<int> reviewsShownDay,
    });

final class $$DecksTableReferences
    extends BaseReferences<_$AppDatabase, $DecksTable, Deck> {
  $$DecksTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $DeckConfigsTable _deckConfigIdTable(_$AppDatabase db) =>
      db.deckConfigs.createAlias('decks__deck_config_id__deck_configs__id');

  $$DeckConfigsTableProcessedTableManager get deckConfigId {
    final $_column = $_itemColumn<int>('deck_config_id')!;

    final manager = $$DeckConfigsTableTableManager(
      $_db,
      $_db.deckConfigs,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_deckConfigIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$CardsTable, List<CardEntry>> _cardsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.cards,
    aliasName: 'decks__id__cards__deck_id',
  );

  $$CardsTableProcessedTableManager get cardsRefs {
    final manager = $$CardsTableTableManager(
      $_db,
      $_db.cards,
    ).filter((f) => f.deckId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_cardsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$DecksTableFilterComposer extends Composer<_$AppDatabase, $DecksTable> {
  $$DecksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get newPerDayOverride => $composableBuilder(
    column: $table.newPerDayOverride,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get reviewsPerDayOverride => $composableBuilder(
    column: $table.reviewsPerDayOverride,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get collapsed => $composableBuilder(
    column: $table.collapsed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get newShownToday => $composableBuilder(
    column: $table.newShownToday,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get newShownDay => $composableBuilder(
    column: $table.newShownDay,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get reviewsShownToday => $composableBuilder(
    column: $table.reviewsShownToday,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get reviewsShownDay => $composableBuilder(
    column: $table.reviewsShownDay,
    builder: (column) => ColumnFilters(column),
  );

  $$DeckConfigsTableFilterComposer get deckConfigId {
    final $$DeckConfigsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.deckConfigId,
      referencedTable: $db.deckConfigs,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DeckConfigsTableFilterComposer(
            $db: $db,
            $table: $db.deckConfigs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> cardsRefs(
    Expression<bool> Function($$CardsTableFilterComposer f) f,
  ) {
    final $$CardsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.cards,
      getReferencedColumn: (t) => t.deckId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CardsTableFilterComposer(
            $db: $db,
            $table: $db.cards,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$DecksTableOrderingComposer
    extends Composer<_$AppDatabase, $DecksTable> {
  $$DecksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get newPerDayOverride => $composableBuilder(
    column: $table.newPerDayOverride,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get reviewsPerDayOverride => $composableBuilder(
    column: $table.reviewsPerDayOverride,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get collapsed => $composableBuilder(
    column: $table.collapsed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get newShownToday => $composableBuilder(
    column: $table.newShownToday,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get newShownDay => $composableBuilder(
    column: $table.newShownDay,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get reviewsShownToday => $composableBuilder(
    column: $table.reviewsShownToday,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get reviewsShownDay => $composableBuilder(
    column: $table.reviewsShownDay,
    builder: (column) => ColumnOrderings(column),
  );

  $$DeckConfigsTableOrderingComposer get deckConfigId {
    final $$DeckConfigsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.deckConfigId,
      referencedTable: $db.deckConfigs,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DeckConfigsTableOrderingComposer(
            $db: $db,
            $table: $db.deckConfigs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DecksTableAnnotationComposer
    extends Composer<_$AppDatabase, $DecksTable> {
  $$DecksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get newPerDayOverride => $composableBuilder(
    column: $table.newPerDayOverride,
    builder: (column) => column,
  );

  GeneratedColumn<int> get reviewsPerDayOverride => $composableBuilder(
    column: $table.reviewsPerDayOverride,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get collapsed =>
      $composableBuilder(column: $table.collapsed, builder: (column) => column);

  GeneratedColumn<int> get newShownToday => $composableBuilder(
    column: $table.newShownToday,
    builder: (column) => column,
  );

  GeneratedColumn<int> get newShownDay => $composableBuilder(
    column: $table.newShownDay,
    builder: (column) => column,
  );

  GeneratedColumn<int> get reviewsShownToday => $composableBuilder(
    column: $table.reviewsShownToday,
    builder: (column) => column,
  );

  GeneratedColumn<int> get reviewsShownDay => $composableBuilder(
    column: $table.reviewsShownDay,
    builder: (column) => column,
  );

  $$DeckConfigsTableAnnotationComposer get deckConfigId {
    final $$DeckConfigsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.deckConfigId,
      referencedTable: $db.deckConfigs,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DeckConfigsTableAnnotationComposer(
            $db: $db,
            $table: $db.deckConfigs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> cardsRefs<T extends Object>(
    Expression<T> Function($$CardsTableAnnotationComposer a) f,
  ) {
    final $$CardsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.cards,
      getReferencedColumn: (t) => t.deckId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CardsTableAnnotationComposer(
            $db: $db,
            $table: $db.cards,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$DecksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DecksTable,
          Deck,
          $$DecksTableFilterComposer,
          $$DecksTableOrderingComposer,
          $$DecksTableAnnotationComposer,
          $$DecksTableCreateCompanionBuilder,
          $$DecksTableUpdateCompanionBuilder,
          (Deck, $$DecksTableReferences),
          Deck,
          PrefetchHooks Function({bool deckConfigId, bool cardsRefs})
        > {
  $$DecksTableTableManager(_$AppDatabase db, $DecksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DecksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DecksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DecksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> deckConfigId = const Value.absent(),
                Value<int?> newPerDayOverride = const Value.absent(),
                Value<int?> reviewsPerDayOverride = const Value.absent(),
                Value<bool> collapsed = const Value.absent(),
                Value<int> newShownToday = const Value.absent(),
                Value<int> newShownDay = const Value.absent(),
                Value<int> reviewsShownToday = const Value.absent(),
                Value<int> reviewsShownDay = const Value.absent(),
              }) => DecksCompanion(
                id: id,
                name: name,
                deckConfigId: deckConfigId,
                newPerDayOverride: newPerDayOverride,
                reviewsPerDayOverride: reviewsPerDayOverride,
                collapsed: collapsed,
                newShownToday: newShownToday,
                newShownDay: newShownDay,
                reviewsShownToday: reviewsShownToday,
                reviewsShownDay: reviewsShownDay,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                required int deckConfigId,
                Value<int?> newPerDayOverride = const Value.absent(),
                Value<int?> reviewsPerDayOverride = const Value.absent(),
                Value<bool> collapsed = const Value.absent(),
                Value<int> newShownToday = const Value.absent(),
                Value<int> newShownDay = const Value.absent(),
                Value<int> reviewsShownToday = const Value.absent(),
                Value<int> reviewsShownDay = const Value.absent(),
              }) => DecksCompanion.insert(
                id: id,
                name: name,
                deckConfigId: deckConfigId,
                newPerDayOverride: newPerDayOverride,
                reviewsPerDayOverride: reviewsPerDayOverride,
                collapsed: collapsed,
                newShownToday: newShownToday,
                newShownDay: newShownDay,
                reviewsShownToday: reviewsShownToday,
                reviewsShownDay: reviewsShownDay,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$DecksTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback: ({deckConfigId = false, cardsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (cardsRefs) db.cards],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (deckConfigId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.deckConfigId,
                                referencedTable: $$DecksTableReferences
                                    ._deckConfigIdTable(db),
                                referencedColumn: $$DecksTableReferences
                                    ._deckConfigIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (cardsRefs)
                    await $_getPrefetchedData<Deck, $DecksTable, CardEntry>(
                      currentTable: table,
                      referencedTable: $$DecksTableReferences._cardsRefsTable(
                        db,
                      ),
                      managerFromTypedResult: (p0) =>
                          $$DecksTableReferences(db, table, p0).cardsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.deckId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$DecksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DecksTable,
      Deck,
      $$DecksTableFilterComposer,
      $$DecksTableOrderingComposer,
      $$DecksTableAnnotationComposer,
      $$DecksTableCreateCompanionBuilder,
      $$DecksTableUpdateCompanionBuilder,
      (Deck, $$DecksTableReferences),
      Deck,
      PrefetchHooks Function({bool deckConfigId, bool cardsRefs})
    >;
typedef $$NotetypesTableCreateCompanionBuilder =
    NotetypesCompanion Function({
      Value<int> id,
      required String name,
      Value<String> css,
      Value<int> sortFieldIndex,
    });
typedef $$NotetypesTableUpdateCompanionBuilder =
    NotetypesCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<String> css,
      Value<int> sortFieldIndex,
    });

final class $$NotetypesTableReferences
    extends BaseReferences<_$AppDatabase, $NotetypesTable, Notetype> {
  $$NotetypesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$NotetypeFieldsTable, List<NotetypeField>>
  _notetypeFieldsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.notetypeFields,
    aliasName: 'notetypes__id__notetype_fields__notetype_id',
  );

  $$NotetypeFieldsTableProcessedTableManager get notetypeFieldsRefs {
    final manager = $$NotetypeFieldsTableTableManager(
      $_db,
      $_db.notetypeFields,
    ).filter((f) => f.notetypeId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_notetypeFieldsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$NotetypeTemplatesTable, List<NotetypeTemplate>>
  _notetypeTemplatesRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.notetypeTemplates,
        aliasName: 'notetypes__id__notetype_templates__notetype_id',
      );

  $$NotetypeTemplatesTableProcessedTableManager get notetypeTemplatesRefs {
    final manager = $$NotetypeTemplatesTableTableManager(
      $_db,
      $_db.notetypeTemplates,
    ).filter((f) => f.notetypeId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _notetypeTemplatesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$NotesTable, List<Note>> _notesRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.notes,
    aliasName: 'notetypes__id__notes__notetype_id',
  );

  $$NotesTableProcessedTableManager get notesRefs {
    final manager = $$NotesTableTableManager(
      $_db,
      $_db.notes,
    ).filter((f) => f.notetypeId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_notesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$NotetypesTableFilterComposer
    extends Composer<_$AppDatabase, $NotetypesTable> {
  $$NotetypesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get css => $composableBuilder(
    column: $table.css,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortFieldIndex => $composableBuilder(
    column: $table.sortFieldIndex,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> notetypeFieldsRefs(
    Expression<bool> Function($$NotetypeFieldsTableFilterComposer f) f,
  ) {
    final $$NotetypeFieldsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.notetypeFields,
      getReferencedColumn: (t) => t.notetypeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NotetypeFieldsTableFilterComposer(
            $db: $db,
            $table: $db.notetypeFields,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> notetypeTemplatesRefs(
    Expression<bool> Function($$NotetypeTemplatesTableFilterComposer f) f,
  ) {
    final $$NotetypeTemplatesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.notetypeTemplates,
      getReferencedColumn: (t) => t.notetypeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NotetypeTemplatesTableFilterComposer(
            $db: $db,
            $table: $db.notetypeTemplates,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> notesRefs(
    Expression<bool> Function($$NotesTableFilterComposer f) f,
  ) {
    final $$NotesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.notes,
      getReferencedColumn: (t) => t.notetypeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NotesTableFilterComposer(
            $db: $db,
            $table: $db.notes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$NotetypesTableOrderingComposer
    extends Composer<_$AppDatabase, $NotetypesTable> {
  $$NotetypesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get css => $composableBuilder(
    column: $table.css,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortFieldIndex => $composableBuilder(
    column: $table.sortFieldIndex,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$NotetypesTableAnnotationComposer
    extends Composer<_$AppDatabase, $NotetypesTable> {
  $$NotetypesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get css =>
      $composableBuilder(column: $table.css, builder: (column) => column);

  GeneratedColumn<int> get sortFieldIndex => $composableBuilder(
    column: $table.sortFieldIndex,
    builder: (column) => column,
  );

  Expression<T> notetypeFieldsRefs<T extends Object>(
    Expression<T> Function($$NotetypeFieldsTableAnnotationComposer a) f,
  ) {
    final $$NotetypeFieldsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.notetypeFields,
      getReferencedColumn: (t) => t.notetypeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NotetypeFieldsTableAnnotationComposer(
            $db: $db,
            $table: $db.notetypeFields,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> notetypeTemplatesRefs<T extends Object>(
    Expression<T> Function($$NotetypeTemplatesTableAnnotationComposer a) f,
  ) {
    final $$NotetypeTemplatesTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.notetypeTemplates,
          getReferencedColumn: (t) => t.notetypeId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$NotetypeTemplatesTableAnnotationComposer(
                $db: $db,
                $table: $db.notetypeTemplates,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> notesRefs<T extends Object>(
    Expression<T> Function($$NotesTableAnnotationComposer a) f,
  ) {
    final $$NotesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.notes,
      getReferencedColumn: (t) => t.notetypeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NotesTableAnnotationComposer(
            $db: $db,
            $table: $db.notes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$NotetypesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $NotetypesTable,
          Notetype,
          $$NotetypesTableFilterComposer,
          $$NotetypesTableOrderingComposer,
          $$NotetypesTableAnnotationComposer,
          $$NotetypesTableCreateCompanionBuilder,
          $$NotetypesTableUpdateCompanionBuilder,
          (Notetype, $$NotetypesTableReferences),
          Notetype,
          PrefetchHooks Function({
            bool notetypeFieldsRefs,
            bool notetypeTemplatesRefs,
            bool notesRefs,
          })
        > {
  $$NotetypesTableTableManager(_$AppDatabase db, $NotetypesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$NotetypesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$NotetypesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$NotetypesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> css = const Value.absent(),
                Value<int> sortFieldIndex = const Value.absent(),
              }) => NotetypesCompanion(
                id: id,
                name: name,
                css: css,
                sortFieldIndex: sortFieldIndex,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                Value<String> css = const Value.absent(),
                Value<int> sortFieldIndex = const Value.absent(),
              }) => NotetypesCompanion.insert(
                id: id,
                name: name,
                css: css,
                sortFieldIndex: sortFieldIndex,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$NotetypesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                notetypeFieldsRefs = false,
                notetypeTemplatesRefs = false,
                notesRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (notetypeFieldsRefs) db.notetypeFields,
                    if (notetypeTemplatesRefs) db.notetypeTemplates,
                    if (notesRefs) db.notes,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (notetypeFieldsRefs)
                        await $_getPrefetchedData<
                          Notetype,
                          $NotetypesTable,
                          NotetypeField
                        >(
                          currentTable: table,
                          referencedTable: $$NotetypesTableReferences
                              ._notetypeFieldsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$NotetypesTableReferences(
                                db,
                                table,
                                p0,
                              ).notetypeFieldsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.notetypeId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (notetypeTemplatesRefs)
                        await $_getPrefetchedData<
                          Notetype,
                          $NotetypesTable,
                          NotetypeTemplate
                        >(
                          currentTable: table,
                          referencedTable: $$NotetypesTableReferences
                              ._notetypeTemplatesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$NotetypesTableReferences(
                                db,
                                table,
                                p0,
                              ).notetypeTemplatesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.notetypeId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (notesRefs)
                        await $_getPrefetchedData<
                          Notetype,
                          $NotetypesTable,
                          Note
                        >(
                          currentTable: table,
                          referencedTable: $$NotetypesTableReferences
                              ._notesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$NotetypesTableReferences(
                                db,
                                table,
                                p0,
                              ).notesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.notetypeId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$NotetypesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $NotetypesTable,
      Notetype,
      $$NotetypesTableFilterComposer,
      $$NotetypesTableOrderingComposer,
      $$NotetypesTableAnnotationComposer,
      $$NotetypesTableCreateCompanionBuilder,
      $$NotetypesTableUpdateCompanionBuilder,
      (Notetype, $$NotetypesTableReferences),
      Notetype,
      PrefetchHooks Function({
        bool notetypeFieldsRefs,
        bool notetypeTemplatesRefs,
        bool notesRefs,
      })
    >;
typedef $$NotetypeFieldsTableCreateCompanionBuilder =
    NotetypeFieldsCompanion Function({
      Value<int> id,
      required int notetypeId,
      required String name,
      required int ord,
    });
typedef $$NotetypeFieldsTableUpdateCompanionBuilder =
    NotetypeFieldsCompanion Function({
      Value<int> id,
      Value<int> notetypeId,
      Value<String> name,
      Value<int> ord,
    });

final class $$NotetypeFieldsTableReferences
    extends BaseReferences<_$AppDatabase, $NotetypeFieldsTable, NotetypeField> {
  $$NotetypeFieldsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $NotetypesTable _notetypeIdTable(_$AppDatabase db) =>
      db.notetypes.createAlias('notetype_fields__notetype_id__notetypes__id');

  $$NotetypesTableProcessedTableManager get notetypeId {
    final $_column = $_itemColumn<int>('notetype_id')!;

    final manager = $$NotetypesTableTableManager(
      $_db,
      $_db.notetypes,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_notetypeIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$NotetypeFieldsTableFilterComposer
    extends Composer<_$AppDatabase, $NotetypeFieldsTable> {
  $$NotetypeFieldsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get ord => $composableBuilder(
    column: $table.ord,
    builder: (column) => ColumnFilters(column),
  );

  $$NotetypesTableFilterComposer get notetypeId {
    final $$NotetypesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.notetypeId,
      referencedTable: $db.notetypes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NotetypesTableFilterComposer(
            $db: $db,
            $table: $db.notetypes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$NotetypeFieldsTableOrderingComposer
    extends Composer<_$AppDatabase, $NotetypeFieldsTable> {
  $$NotetypeFieldsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get ord => $composableBuilder(
    column: $table.ord,
    builder: (column) => ColumnOrderings(column),
  );

  $$NotetypesTableOrderingComposer get notetypeId {
    final $$NotetypesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.notetypeId,
      referencedTable: $db.notetypes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NotetypesTableOrderingComposer(
            $db: $db,
            $table: $db.notetypes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$NotetypeFieldsTableAnnotationComposer
    extends Composer<_$AppDatabase, $NotetypeFieldsTable> {
  $$NotetypeFieldsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get ord =>
      $composableBuilder(column: $table.ord, builder: (column) => column);

  $$NotetypesTableAnnotationComposer get notetypeId {
    final $$NotetypesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.notetypeId,
      referencedTable: $db.notetypes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NotetypesTableAnnotationComposer(
            $db: $db,
            $table: $db.notetypes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$NotetypeFieldsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $NotetypeFieldsTable,
          NotetypeField,
          $$NotetypeFieldsTableFilterComposer,
          $$NotetypeFieldsTableOrderingComposer,
          $$NotetypeFieldsTableAnnotationComposer,
          $$NotetypeFieldsTableCreateCompanionBuilder,
          $$NotetypeFieldsTableUpdateCompanionBuilder,
          (NotetypeField, $$NotetypeFieldsTableReferences),
          NotetypeField,
          PrefetchHooks Function({bool notetypeId})
        > {
  $$NotetypeFieldsTableTableManager(
    _$AppDatabase db,
    $NotetypeFieldsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$NotetypeFieldsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$NotetypeFieldsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$NotetypeFieldsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> notetypeId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> ord = const Value.absent(),
              }) => NotetypeFieldsCompanion(
                id: id,
                notetypeId: notetypeId,
                name: name,
                ord: ord,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int notetypeId,
                required String name,
                required int ord,
              }) => NotetypeFieldsCompanion.insert(
                id: id,
                notetypeId: notetypeId,
                name: name,
                ord: ord,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$NotetypeFieldsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({notetypeId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (notetypeId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.notetypeId,
                                referencedTable: $$NotetypeFieldsTableReferences
                                    ._notetypeIdTable(db),
                                referencedColumn:
                                    $$NotetypeFieldsTableReferences
                                        ._notetypeIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$NotetypeFieldsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $NotetypeFieldsTable,
      NotetypeField,
      $$NotetypeFieldsTableFilterComposer,
      $$NotetypeFieldsTableOrderingComposer,
      $$NotetypeFieldsTableAnnotationComposer,
      $$NotetypeFieldsTableCreateCompanionBuilder,
      $$NotetypeFieldsTableUpdateCompanionBuilder,
      (NotetypeField, $$NotetypeFieldsTableReferences),
      NotetypeField,
      PrefetchHooks Function({bool notetypeId})
    >;
typedef $$NotetypeTemplatesTableCreateCompanionBuilder =
    NotetypeTemplatesCompanion Function({
      Value<int> id,
      required int notetypeId,
      required String name,
      required int ord,
      Value<String> questionFormat,
      Value<String> answerFormat,
    });
typedef $$NotetypeTemplatesTableUpdateCompanionBuilder =
    NotetypeTemplatesCompanion Function({
      Value<int> id,
      Value<int> notetypeId,
      Value<String> name,
      Value<int> ord,
      Value<String> questionFormat,
      Value<String> answerFormat,
    });

final class $$NotetypeTemplatesTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $NotetypeTemplatesTable,
          NotetypeTemplate
        > {
  $$NotetypeTemplatesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $NotetypesTable _notetypeIdTable(_$AppDatabase db) => db.notetypes
      .createAlias('notetype_templates__notetype_id__notetypes__id');

  $$NotetypesTableProcessedTableManager get notetypeId {
    final $_column = $_itemColumn<int>('notetype_id')!;

    final manager = $$NotetypesTableTableManager(
      $_db,
      $_db.notetypes,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_notetypeIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$NotetypeTemplatesTableFilterComposer
    extends Composer<_$AppDatabase, $NotetypeTemplatesTable> {
  $$NotetypeTemplatesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get ord => $composableBuilder(
    column: $table.ord,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get questionFormat => $composableBuilder(
    column: $table.questionFormat,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get answerFormat => $composableBuilder(
    column: $table.answerFormat,
    builder: (column) => ColumnFilters(column),
  );

  $$NotetypesTableFilterComposer get notetypeId {
    final $$NotetypesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.notetypeId,
      referencedTable: $db.notetypes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NotetypesTableFilterComposer(
            $db: $db,
            $table: $db.notetypes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$NotetypeTemplatesTableOrderingComposer
    extends Composer<_$AppDatabase, $NotetypeTemplatesTable> {
  $$NotetypeTemplatesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get ord => $composableBuilder(
    column: $table.ord,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get questionFormat => $composableBuilder(
    column: $table.questionFormat,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get answerFormat => $composableBuilder(
    column: $table.answerFormat,
    builder: (column) => ColumnOrderings(column),
  );

  $$NotetypesTableOrderingComposer get notetypeId {
    final $$NotetypesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.notetypeId,
      referencedTable: $db.notetypes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NotetypesTableOrderingComposer(
            $db: $db,
            $table: $db.notetypes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$NotetypeTemplatesTableAnnotationComposer
    extends Composer<_$AppDatabase, $NotetypeTemplatesTable> {
  $$NotetypeTemplatesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get ord =>
      $composableBuilder(column: $table.ord, builder: (column) => column);

  GeneratedColumn<String> get questionFormat => $composableBuilder(
    column: $table.questionFormat,
    builder: (column) => column,
  );

  GeneratedColumn<String> get answerFormat => $composableBuilder(
    column: $table.answerFormat,
    builder: (column) => column,
  );

  $$NotetypesTableAnnotationComposer get notetypeId {
    final $$NotetypesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.notetypeId,
      referencedTable: $db.notetypes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NotetypesTableAnnotationComposer(
            $db: $db,
            $table: $db.notetypes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$NotetypeTemplatesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $NotetypeTemplatesTable,
          NotetypeTemplate,
          $$NotetypeTemplatesTableFilterComposer,
          $$NotetypeTemplatesTableOrderingComposer,
          $$NotetypeTemplatesTableAnnotationComposer,
          $$NotetypeTemplatesTableCreateCompanionBuilder,
          $$NotetypeTemplatesTableUpdateCompanionBuilder,
          (NotetypeTemplate, $$NotetypeTemplatesTableReferences),
          NotetypeTemplate,
          PrefetchHooks Function({bool notetypeId})
        > {
  $$NotetypeTemplatesTableTableManager(
    _$AppDatabase db,
    $NotetypeTemplatesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$NotetypeTemplatesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$NotetypeTemplatesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$NotetypeTemplatesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> notetypeId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> ord = const Value.absent(),
                Value<String> questionFormat = const Value.absent(),
                Value<String> answerFormat = const Value.absent(),
              }) => NotetypeTemplatesCompanion(
                id: id,
                notetypeId: notetypeId,
                name: name,
                ord: ord,
                questionFormat: questionFormat,
                answerFormat: answerFormat,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int notetypeId,
                required String name,
                required int ord,
                Value<String> questionFormat = const Value.absent(),
                Value<String> answerFormat = const Value.absent(),
              }) => NotetypeTemplatesCompanion.insert(
                id: id,
                notetypeId: notetypeId,
                name: name,
                ord: ord,
                questionFormat: questionFormat,
                answerFormat: answerFormat,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$NotetypeTemplatesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({notetypeId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (notetypeId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.notetypeId,
                                referencedTable:
                                    $$NotetypeTemplatesTableReferences
                                        ._notetypeIdTable(db),
                                referencedColumn:
                                    $$NotetypeTemplatesTableReferences
                                        ._notetypeIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$NotetypeTemplatesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $NotetypeTemplatesTable,
      NotetypeTemplate,
      $$NotetypeTemplatesTableFilterComposer,
      $$NotetypeTemplatesTableOrderingComposer,
      $$NotetypeTemplatesTableAnnotationComposer,
      $$NotetypeTemplatesTableCreateCompanionBuilder,
      $$NotetypeTemplatesTableUpdateCompanionBuilder,
      (NotetypeTemplate, $$NotetypeTemplatesTableReferences),
      NotetypeTemplate,
      PrefetchHooks Function({bool notetypeId})
    >;
typedef $$NotesTableCreateCompanionBuilder =
    NotesCompanion Function({
      Value<int> id,
      required int notetypeId,
      required String fieldsJson,
      Value<String> tags,
      Value<int> createdAt,
    });
typedef $$NotesTableUpdateCompanionBuilder =
    NotesCompanion Function({
      Value<int> id,
      Value<int> notetypeId,
      Value<String> fieldsJson,
      Value<String> tags,
      Value<int> createdAt,
    });

final class $$NotesTableReferences
    extends BaseReferences<_$AppDatabase, $NotesTable, Note> {
  $$NotesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $NotetypesTable _notetypeIdTable(_$AppDatabase db) =>
      db.notetypes.createAlias('notes__notetype_id__notetypes__id');

  $$NotetypesTableProcessedTableManager get notetypeId {
    final $_column = $_itemColumn<int>('notetype_id')!;

    final manager = $$NotetypesTableTableManager(
      $_db,
      $_db.notetypes,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_notetypeIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$CardsTable, List<CardEntry>> _cardsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.cards,
    aliasName: 'notes__id__cards__note_id',
  );

  $$CardsTableProcessedTableManager get cardsRefs {
    final manager = $$CardsTableTableManager(
      $_db,
      $_db.cards,
    ).filter((f) => f.noteId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_cardsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$NotesTableFilterComposer extends Composer<_$AppDatabase, $NotesTable> {
  $$NotesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fieldsJson => $composableBuilder(
    column: $table.fieldsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tags => $composableBuilder(
    column: $table.tags,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$NotetypesTableFilterComposer get notetypeId {
    final $$NotetypesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.notetypeId,
      referencedTable: $db.notetypes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NotetypesTableFilterComposer(
            $db: $db,
            $table: $db.notetypes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> cardsRefs(
    Expression<bool> Function($$CardsTableFilterComposer f) f,
  ) {
    final $$CardsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.cards,
      getReferencedColumn: (t) => t.noteId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CardsTableFilterComposer(
            $db: $db,
            $table: $db.cards,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$NotesTableOrderingComposer
    extends Composer<_$AppDatabase, $NotesTable> {
  $$NotesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fieldsJson => $composableBuilder(
    column: $table.fieldsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tags => $composableBuilder(
    column: $table.tags,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$NotetypesTableOrderingComposer get notetypeId {
    final $$NotetypesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.notetypeId,
      referencedTable: $db.notetypes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NotetypesTableOrderingComposer(
            $db: $db,
            $table: $db.notetypes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$NotesTableAnnotationComposer
    extends Composer<_$AppDatabase, $NotesTable> {
  $$NotesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get fieldsJson => $composableBuilder(
    column: $table.fieldsJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get tags =>
      $composableBuilder(column: $table.tags, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$NotetypesTableAnnotationComposer get notetypeId {
    final $$NotetypesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.notetypeId,
      referencedTable: $db.notetypes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NotetypesTableAnnotationComposer(
            $db: $db,
            $table: $db.notetypes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> cardsRefs<T extends Object>(
    Expression<T> Function($$CardsTableAnnotationComposer a) f,
  ) {
    final $$CardsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.cards,
      getReferencedColumn: (t) => t.noteId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CardsTableAnnotationComposer(
            $db: $db,
            $table: $db.cards,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$NotesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $NotesTable,
          Note,
          $$NotesTableFilterComposer,
          $$NotesTableOrderingComposer,
          $$NotesTableAnnotationComposer,
          $$NotesTableCreateCompanionBuilder,
          $$NotesTableUpdateCompanionBuilder,
          (Note, $$NotesTableReferences),
          Note,
          PrefetchHooks Function({bool notetypeId, bool cardsRefs})
        > {
  $$NotesTableTableManager(_$AppDatabase db, $NotesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$NotesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$NotesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$NotesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> notetypeId = const Value.absent(),
                Value<String> fieldsJson = const Value.absent(),
                Value<String> tags = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
              }) => NotesCompanion(
                id: id,
                notetypeId: notetypeId,
                fieldsJson: fieldsJson,
                tags: tags,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int notetypeId,
                required String fieldsJson,
                Value<String> tags = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
              }) => NotesCompanion.insert(
                id: id,
                notetypeId: notetypeId,
                fieldsJson: fieldsJson,
                tags: tags,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$NotesTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback: ({notetypeId = false, cardsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (cardsRefs) db.cards],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (notetypeId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.notetypeId,
                                referencedTable: $$NotesTableReferences
                                    ._notetypeIdTable(db),
                                referencedColumn: $$NotesTableReferences
                                    ._notetypeIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (cardsRefs)
                    await $_getPrefetchedData<Note, $NotesTable, CardEntry>(
                      currentTable: table,
                      referencedTable: $$NotesTableReferences._cardsRefsTable(
                        db,
                      ),
                      managerFromTypedResult: (p0) =>
                          $$NotesTableReferences(db, table, p0).cardsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.noteId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$NotesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $NotesTable,
      Note,
      $$NotesTableFilterComposer,
      $$NotesTableOrderingComposer,
      $$NotesTableAnnotationComposer,
      $$NotesTableCreateCompanionBuilder,
      $$NotesTableUpdateCompanionBuilder,
      (Note, $$NotesTableReferences),
      Note,
      PrefetchHooks Function({bool notetypeId, bool cardsRefs})
    >;
typedef $$CardsTableCreateCompanionBuilder =
    CardsCompanion Function({
      Value<int> id,
      required int noteId,
      required int deckId,
      required int templateOrd,
      Value<CardQueue> queue,
      Value<int> due,
      Value<int> ivl,
      Value<int> ease,
      Value<int> reps,
      Value<int> lapses,
      Value<int> stepIndex,
      Value<int?> lastReviewedAt,
    });
typedef $$CardsTableUpdateCompanionBuilder =
    CardsCompanion Function({
      Value<int> id,
      Value<int> noteId,
      Value<int> deckId,
      Value<int> templateOrd,
      Value<CardQueue> queue,
      Value<int> due,
      Value<int> ivl,
      Value<int> ease,
      Value<int> reps,
      Value<int> lapses,
      Value<int> stepIndex,
      Value<int?> lastReviewedAt,
    });

final class $$CardsTableReferences
    extends BaseReferences<_$AppDatabase, $CardsTable, CardEntry> {
  $$CardsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $NotesTable _noteIdTable(_$AppDatabase db) =>
      db.notes.createAlias('cards__note_id__notes__id');

  $$NotesTableProcessedTableManager get noteId {
    final $_column = $_itemColumn<int>('note_id')!;

    final manager = $$NotesTableTableManager(
      $_db,
      $_db.notes,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_noteIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $DecksTable _deckIdTable(_$AppDatabase db) =>
      db.decks.createAlias('cards__deck_id__decks__id');

  $$DecksTableProcessedTableManager get deckId {
    final $_column = $_itemColumn<int>('deck_id')!;

    final manager = $$DecksTableTableManager(
      $_db,
      $_db.decks,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_deckIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$RevLogTable, List<RevLogData>> _revLogRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.revLog,
    aliasName: 'cards__id__rev_log__card_id',
  );

  $$RevLogTableProcessedTableManager get revLogRefs {
    final manager = $$RevLogTableTableManager(
      $_db,
      $_db.revLog,
    ).filter((f) => f.cardId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_revLogRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$CardsTableFilterComposer extends Composer<_$AppDatabase, $CardsTable> {
  $$CardsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get templateOrd => $composableBuilder(
    column: $table.templateOrd,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<CardQueue, CardQueue, String> get queue =>
      $composableBuilder(
        column: $table.queue,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<int> get due => $composableBuilder(
    column: $table.due,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get ivl => $composableBuilder(
    column: $table.ivl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get ease => $composableBuilder(
    column: $table.ease,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get reps => $composableBuilder(
    column: $table.reps,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lapses => $composableBuilder(
    column: $table.lapses,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get stepIndex => $composableBuilder(
    column: $table.stepIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastReviewedAt => $composableBuilder(
    column: $table.lastReviewedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$NotesTableFilterComposer get noteId {
    final $$NotesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.noteId,
      referencedTable: $db.notes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NotesTableFilterComposer(
            $db: $db,
            $table: $db.notes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$DecksTableFilterComposer get deckId {
    final $$DecksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.deckId,
      referencedTable: $db.decks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DecksTableFilterComposer(
            $db: $db,
            $table: $db.decks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> revLogRefs(
    Expression<bool> Function($$RevLogTableFilterComposer f) f,
  ) {
    final $$RevLogTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.revLog,
      getReferencedColumn: (t) => t.cardId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RevLogTableFilterComposer(
            $db: $db,
            $table: $db.revLog,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CardsTableOrderingComposer
    extends Composer<_$AppDatabase, $CardsTable> {
  $$CardsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get templateOrd => $composableBuilder(
    column: $table.templateOrd,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get queue => $composableBuilder(
    column: $table.queue,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get due => $composableBuilder(
    column: $table.due,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get ivl => $composableBuilder(
    column: $table.ivl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get ease => $composableBuilder(
    column: $table.ease,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get reps => $composableBuilder(
    column: $table.reps,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lapses => $composableBuilder(
    column: $table.lapses,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get stepIndex => $composableBuilder(
    column: $table.stepIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastReviewedAt => $composableBuilder(
    column: $table.lastReviewedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$NotesTableOrderingComposer get noteId {
    final $$NotesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.noteId,
      referencedTable: $db.notes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NotesTableOrderingComposer(
            $db: $db,
            $table: $db.notes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$DecksTableOrderingComposer get deckId {
    final $$DecksTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.deckId,
      referencedTable: $db.decks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DecksTableOrderingComposer(
            $db: $db,
            $table: $db.decks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CardsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CardsTable> {
  $$CardsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get templateOrd => $composableBuilder(
    column: $table.templateOrd,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<CardQueue, String> get queue =>
      $composableBuilder(column: $table.queue, builder: (column) => column);

  GeneratedColumn<int> get due =>
      $composableBuilder(column: $table.due, builder: (column) => column);

  GeneratedColumn<int> get ivl =>
      $composableBuilder(column: $table.ivl, builder: (column) => column);

  GeneratedColumn<int> get ease =>
      $composableBuilder(column: $table.ease, builder: (column) => column);

  GeneratedColumn<int> get reps =>
      $composableBuilder(column: $table.reps, builder: (column) => column);

  GeneratedColumn<int> get lapses =>
      $composableBuilder(column: $table.lapses, builder: (column) => column);

  GeneratedColumn<int> get stepIndex =>
      $composableBuilder(column: $table.stepIndex, builder: (column) => column);

  GeneratedColumn<int> get lastReviewedAt => $composableBuilder(
    column: $table.lastReviewedAt,
    builder: (column) => column,
  );

  $$NotesTableAnnotationComposer get noteId {
    final $$NotesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.noteId,
      referencedTable: $db.notes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NotesTableAnnotationComposer(
            $db: $db,
            $table: $db.notes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$DecksTableAnnotationComposer get deckId {
    final $$DecksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.deckId,
      referencedTable: $db.decks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DecksTableAnnotationComposer(
            $db: $db,
            $table: $db.decks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> revLogRefs<T extends Object>(
    Expression<T> Function($$RevLogTableAnnotationComposer a) f,
  ) {
    final $$RevLogTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.revLog,
      getReferencedColumn: (t) => t.cardId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RevLogTableAnnotationComposer(
            $db: $db,
            $table: $db.revLog,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CardsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CardsTable,
          CardEntry,
          $$CardsTableFilterComposer,
          $$CardsTableOrderingComposer,
          $$CardsTableAnnotationComposer,
          $$CardsTableCreateCompanionBuilder,
          $$CardsTableUpdateCompanionBuilder,
          (CardEntry, $$CardsTableReferences),
          CardEntry,
          PrefetchHooks Function({bool noteId, bool deckId, bool revLogRefs})
        > {
  $$CardsTableTableManager(_$AppDatabase db, $CardsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CardsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CardsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CardsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> noteId = const Value.absent(),
                Value<int> deckId = const Value.absent(),
                Value<int> templateOrd = const Value.absent(),
                Value<CardQueue> queue = const Value.absent(),
                Value<int> due = const Value.absent(),
                Value<int> ivl = const Value.absent(),
                Value<int> ease = const Value.absent(),
                Value<int> reps = const Value.absent(),
                Value<int> lapses = const Value.absent(),
                Value<int> stepIndex = const Value.absent(),
                Value<int?> lastReviewedAt = const Value.absent(),
              }) => CardsCompanion(
                id: id,
                noteId: noteId,
                deckId: deckId,
                templateOrd: templateOrd,
                queue: queue,
                due: due,
                ivl: ivl,
                ease: ease,
                reps: reps,
                lapses: lapses,
                stepIndex: stepIndex,
                lastReviewedAt: lastReviewedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int noteId,
                required int deckId,
                required int templateOrd,
                Value<CardQueue> queue = const Value.absent(),
                Value<int> due = const Value.absent(),
                Value<int> ivl = const Value.absent(),
                Value<int> ease = const Value.absent(),
                Value<int> reps = const Value.absent(),
                Value<int> lapses = const Value.absent(),
                Value<int> stepIndex = const Value.absent(),
                Value<int?> lastReviewedAt = const Value.absent(),
              }) => CardsCompanion.insert(
                id: id,
                noteId: noteId,
                deckId: deckId,
                templateOrd: templateOrd,
                queue: queue,
                due: due,
                ivl: ivl,
                ease: ease,
                reps: reps,
                lapses: lapses,
                stepIndex: stepIndex,
                lastReviewedAt: lastReviewedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$CardsTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback:
              ({noteId = false, deckId = false, revLogRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [if (revLogRefs) db.revLog],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (noteId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.noteId,
                                    referencedTable: $$CardsTableReferences
                                        ._noteIdTable(db),
                                    referencedColumn: $$CardsTableReferences
                                        ._noteIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }
                        if (deckId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.deckId,
                                    referencedTable: $$CardsTableReferences
                                        ._deckIdTable(db),
                                    referencedColumn: $$CardsTableReferences
                                        ._deckIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (revLogRefs)
                        await $_getPrefetchedData<
                          CardEntry,
                          $CardsTable,
                          RevLogData
                        >(
                          currentTable: table,
                          referencedTable: $$CardsTableReferences
                              ._revLogRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CardsTableReferences(db, table, p0).revLogRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.cardId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$CardsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CardsTable,
      CardEntry,
      $$CardsTableFilterComposer,
      $$CardsTableOrderingComposer,
      $$CardsTableAnnotationComposer,
      $$CardsTableCreateCompanionBuilder,
      $$CardsTableUpdateCompanionBuilder,
      (CardEntry, $$CardsTableReferences),
      CardEntry,
      PrefetchHooks Function({bool noteId, bool deckId, bool revLogRefs})
    >;
typedef $$RevLogTableCreateCompanionBuilder =
    RevLogCompanion Function({
      Value<int> id,
      required int cardId,
      required int reviewedAt,
      required int rating,
      required int ivlBefore,
      required int ivlAfter,
      required int easeAfter,
      Value<int> timeTakenMs,
    });
typedef $$RevLogTableUpdateCompanionBuilder =
    RevLogCompanion Function({
      Value<int> id,
      Value<int> cardId,
      Value<int> reviewedAt,
      Value<int> rating,
      Value<int> ivlBefore,
      Value<int> ivlAfter,
      Value<int> easeAfter,
      Value<int> timeTakenMs,
    });

final class $$RevLogTableReferences
    extends BaseReferences<_$AppDatabase, $RevLogTable, RevLogData> {
  $$RevLogTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $CardsTable _cardIdTable(_$AppDatabase db) =>
      db.cards.createAlias('rev_log__card_id__cards__id');

  $$CardsTableProcessedTableManager get cardId {
    final $_column = $_itemColumn<int>('card_id')!;

    final manager = $$CardsTableTableManager(
      $_db,
      $_db.cards,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_cardIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$RevLogTableFilterComposer
    extends Composer<_$AppDatabase, $RevLogTable> {
  $$RevLogTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get reviewedAt => $composableBuilder(
    column: $table.reviewedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get rating => $composableBuilder(
    column: $table.rating,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get ivlBefore => $composableBuilder(
    column: $table.ivlBefore,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get ivlAfter => $composableBuilder(
    column: $table.ivlAfter,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get easeAfter => $composableBuilder(
    column: $table.easeAfter,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get timeTakenMs => $composableBuilder(
    column: $table.timeTakenMs,
    builder: (column) => ColumnFilters(column),
  );

  $$CardsTableFilterComposer get cardId {
    final $$CardsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.cardId,
      referencedTable: $db.cards,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CardsTableFilterComposer(
            $db: $db,
            $table: $db.cards,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RevLogTableOrderingComposer
    extends Composer<_$AppDatabase, $RevLogTable> {
  $$RevLogTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get reviewedAt => $composableBuilder(
    column: $table.reviewedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get rating => $composableBuilder(
    column: $table.rating,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get ivlBefore => $composableBuilder(
    column: $table.ivlBefore,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get ivlAfter => $composableBuilder(
    column: $table.ivlAfter,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get easeAfter => $composableBuilder(
    column: $table.easeAfter,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get timeTakenMs => $composableBuilder(
    column: $table.timeTakenMs,
    builder: (column) => ColumnOrderings(column),
  );

  $$CardsTableOrderingComposer get cardId {
    final $$CardsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.cardId,
      referencedTable: $db.cards,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CardsTableOrderingComposer(
            $db: $db,
            $table: $db.cards,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RevLogTableAnnotationComposer
    extends Composer<_$AppDatabase, $RevLogTable> {
  $$RevLogTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get reviewedAt => $composableBuilder(
    column: $table.reviewedAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get rating =>
      $composableBuilder(column: $table.rating, builder: (column) => column);

  GeneratedColumn<int> get ivlBefore =>
      $composableBuilder(column: $table.ivlBefore, builder: (column) => column);

  GeneratedColumn<int> get ivlAfter =>
      $composableBuilder(column: $table.ivlAfter, builder: (column) => column);

  GeneratedColumn<int> get easeAfter =>
      $composableBuilder(column: $table.easeAfter, builder: (column) => column);

  GeneratedColumn<int> get timeTakenMs => $composableBuilder(
    column: $table.timeTakenMs,
    builder: (column) => column,
  );

  $$CardsTableAnnotationComposer get cardId {
    final $$CardsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.cardId,
      referencedTable: $db.cards,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CardsTableAnnotationComposer(
            $db: $db,
            $table: $db.cards,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RevLogTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RevLogTable,
          RevLogData,
          $$RevLogTableFilterComposer,
          $$RevLogTableOrderingComposer,
          $$RevLogTableAnnotationComposer,
          $$RevLogTableCreateCompanionBuilder,
          $$RevLogTableUpdateCompanionBuilder,
          (RevLogData, $$RevLogTableReferences),
          RevLogData,
          PrefetchHooks Function({bool cardId})
        > {
  $$RevLogTableTableManager(_$AppDatabase db, $RevLogTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RevLogTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RevLogTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RevLogTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> cardId = const Value.absent(),
                Value<int> reviewedAt = const Value.absent(),
                Value<int> rating = const Value.absent(),
                Value<int> ivlBefore = const Value.absent(),
                Value<int> ivlAfter = const Value.absent(),
                Value<int> easeAfter = const Value.absent(),
                Value<int> timeTakenMs = const Value.absent(),
              }) => RevLogCompanion(
                id: id,
                cardId: cardId,
                reviewedAt: reviewedAt,
                rating: rating,
                ivlBefore: ivlBefore,
                ivlAfter: ivlAfter,
                easeAfter: easeAfter,
                timeTakenMs: timeTakenMs,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int cardId,
                required int reviewedAt,
                required int rating,
                required int ivlBefore,
                required int ivlAfter,
                required int easeAfter,
                Value<int> timeTakenMs = const Value.absent(),
              }) => RevLogCompanion.insert(
                id: id,
                cardId: cardId,
                reviewedAt: reviewedAt,
                rating: rating,
                ivlBefore: ivlBefore,
                ivlAfter: ivlAfter,
                easeAfter: easeAfter,
                timeTakenMs: timeTakenMs,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$RevLogTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback: ({cardId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (cardId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.cardId,
                                referencedTable: $$RevLogTableReferences
                                    ._cardIdTable(db),
                                referencedColumn: $$RevLogTableReferences
                                    ._cardIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$RevLogTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RevLogTable,
      RevLogData,
      $$RevLogTableFilterComposer,
      $$RevLogTableOrderingComposer,
      $$RevLogTableAnnotationComposer,
      $$RevLogTableCreateCompanionBuilder,
      $$RevLogTableUpdateCompanionBuilder,
      (RevLogData, $$RevLogTableReferences),
      RevLogData,
      PrefetchHooks Function({bool cardId})
    >;
typedef $$CollectionMetaTableCreateCompanionBuilder =
    CollectionMetaCompanion Function({
      Value<int> id,
      Value<int> createdAt,
      Value<int> rolloverHour,
    });
typedef $$CollectionMetaTableUpdateCompanionBuilder =
    CollectionMetaCompanion Function({
      Value<int> id,
      Value<int> createdAt,
      Value<int> rolloverHour,
    });

class $$CollectionMetaTableFilterComposer
    extends Composer<_$AppDatabase, $CollectionMetaTable> {
  $$CollectionMetaTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get rolloverHour => $composableBuilder(
    column: $table.rolloverHour,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CollectionMetaTableOrderingComposer
    extends Composer<_$AppDatabase, $CollectionMetaTable> {
  $$CollectionMetaTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get rolloverHour => $composableBuilder(
    column: $table.rolloverHour,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CollectionMetaTableAnnotationComposer
    extends Composer<_$AppDatabase, $CollectionMetaTable> {
  $$CollectionMetaTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get rolloverHour => $composableBuilder(
    column: $table.rolloverHour,
    builder: (column) => column,
  );
}

class $$CollectionMetaTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CollectionMetaTable,
          CollectionMetaData,
          $$CollectionMetaTableFilterComposer,
          $$CollectionMetaTableOrderingComposer,
          $$CollectionMetaTableAnnotationComposer,
          $$CollectionMetaTableCreateCompanionBuilder,
          $$CollectionMetaTableUpdateCompanionBuilder,
          (
            CollectionMetaData,
            BaseReferences<
              _$AppDatabase,
              $CollectionMetaTable,
              CollectionMetaData
            >,
          ),
          CollectionMetaData,
          PrefetchHooks Function()
        > {
  $$CollectionMetaTableTableManager(
    _$AppDatabase db,
    $CollectionMetaTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CollectionMetaTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CollectionMetaTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CollectionMetaTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> rolloverHour = const Value.absent(),
              }) => CollectionMetaCompanion(
                id: id,
                createdAt: createdAt,
                rolloverHour: rolloverHour,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> rolloverHour = const Value.absent(),
              }) => CollectionMetaCompanion.insert(
                id: id,
                createdAt: createdAt,
                rolloverHour: rolloverHour,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CollectionMetaTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CollectionMetaTable,
      CollectionMetaData,
      $$CollectionMetaTableFilterComposer,
      $$CollectionMetaTableOrderingComposer,
      $$CollectionMetaTableAnnotationComposer,
      $$CollectionMetaTableCreateCompanionBuilder,
      $$CollectionMetaTableUpdateCompanionBuilder,
      (
        CollectionMetaData,
        BaseReferences<_$AppDatabase, $CollectionMetaTable, CollectionMetaData>,
      ),
      CollectionMetaData,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$DeckConfigsTableTableManager get deckConfigs =>
      $$DeckConfigsTableTableManager(_db, _db.deckConfigs);
  $$DecksTableTableManager get decks =>
      $$DecksTableTableManager(_db, _db.decks);
  $$NotetypesTableTableManager get notetypes =>
      $$NotetypesTableTableManager(_db, _db.notetypes);
  $$NotetypeFieldsTableTableManager get notetypeFields =>
      $$NotetypeFieldsTableTableManager(_db, _db.notetypeFields);
  $$NotetypeTemplatesTableTableManager get notetypeTemplates =>
      $$NotetypeTemplatesTableTableManager(_db, _db.notetypeTemplates);
  $$NotesTableTableManager get notes =>
      $$NotesTableTableManager(_db, _db.notes);
  $$CardsTableTableManager get cards =>
      $$CardsTableTableManager(_db, _db.cards);
  $$RevLogTableTableManager get revLog =>
      $$RevLogTableTableManager(_db, _db.revLog);
  $$CollectionMetaTableTableManager get collectionMeta =>
      $$CollectionMetaTableTableManager(_db, _db.collectionMeta);
}
