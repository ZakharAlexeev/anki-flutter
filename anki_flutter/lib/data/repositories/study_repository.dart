import 'dart:math';

import 'package:drift/drift.dart';

import '../../domain/scheduler/day_calendar.dart';
import '../../domain/scheduler/fsrs.dart';
import '../../domain/scheduler/fuzz.dart';
import '../../domain/scheduler/load_balancer.dart';
import '../../domain/scheduler/memory_state.dart';
import '../../domain/scheduler/models.dart';
import '../../domain/scheduler/scheduler.dart';
import '../db/database.dart';
import 'sched_config_mapper.dart';

class DueQueueCounts {
  final int newCount;
  final int learningCount;
  final int reviewCount;

  const DueQueueCounts({required this.newCount, required this.learningCount, required this.reviewCount});

  int get total => newCount + learningCount + reviewCount;
}

/// How far into the future to pull in not-yet-due learning/relearning cards,
/// matching Anki's own "learn ahead limit" (default 20 minutes).
const _learnAheadWindow = Duration(minutes: 20);

const _intradayLearning = [CardQueue.learning, CardQueue.relearning];
const _interdayLearning = [CardQueue.interdayLearning, CardQueue.interdayRelearning];

/// Bridges the pure scheduler (a port of Anki 26.09's) to persisted state:
/// builds the study queue, prepares each answer exactly the way Anki does
/// (SM-2 or FSRS, fuzz, load balancer), and records answers so they can be
/// undone.
class StudyRepository {
  StudyRepository(this._db);

  final AppDatabase _db;
  static const _scheduler = Scheduler();

  Future<int> today(DateTime now) async {
    final meta = await _db.select(_db.collectionMeta).getSingle();
    return dayNumber(now, DateTime.fromMillisecondsSinceEpoch(meta.createdAt), rolloverHour: meta.rolloverHour);
  }

  Future<DeckConfig> _configRowForDeck(int deckId) async {
    final deck = await (_db.select(_db.decks)..where((d) => d.id.equals(deckId))).getSingle();
    return (_db.select(_db.deckConfigs)..where((c) => c.id.equals(deck.deckConfigId))).getSingle();
  }

  // --- queue ---------------------------------------------------------------

  /// Cards ready to study right now, in the order Anki's v3 scheduler
  /// shows them by default:
  ///  1. intraday learning/relearning cards whose step has elapsed;
  ///  2. reviews (and interday learning, which Anki mixes with them) with
  ///     new cards spread evenly in between, reviews by due date and in a
  ///     stable random order within a day;
  ///  3. learning cards still counting down (20-minute learn-ahead).
  ///
  /// New/review counts are capped by what is still allowed today.
  Future<List<CardEntry>> dueQueue(int deckId, {DateTime? now}) async {
    final n = now ?? DateTime.now();
    final t = await today(n);
    return _assemble(await _gather(deckId, n, t), n, t);
  }

  /// The combined queue of every deck, ordered as one queue.
  Future<List<CardEntry>> dueQueueAll({DateTime? now}) async {
    final n = now ?? DateTime.now();
    final t = await today(n);
    final decks = await (_db.select(_db.decks)..orderBy([(d) => OrderingTerm.asc(d.name)])).get();
    final parts = _QueueParts.empty();
    for (final deck in decks) {
      parts.addAll(await _gather(deck.id, n, t));
    }
    return _assemble(parts, n, t);
  }

  Future<_QueueParts> _gather(int deckId, DateTime n, int t) async {
    final lookAheadSec = n.add(_learnAheadWindow).millisecondsSinceEpoch ~/ 1000;
    final deck = await (_db.select(_db.decks)..where((d) => d.id.equals(deckId))).getSingle();
    final cfg = await (_db.select(_db.deckConfigs)..where((c) => c.id.equals(deck.deckConfigId))).getSingle();

    final newLimit = deck.newPerDayOverride ?? cfg.newPerDay;
    final newShown = deck.newShownDay == t ? deck.newShownToday : 0;
    final newRemaining = max(0, newLimit - newShown);

    final reviewLimit = deck.reviewsPerDayOverride ?? cfg.reviewsPerDay;
    final reviewShown = deck.reviewsShownDay == t ? deck.reviewsShownToday : 0;
    final reviewRemaining = max(0, reviewLimit - reviewShown);

    final learning = await (_db.select(_db.cards)
          ..where((c) =>
              c.deckId.equals(deckId) &
              c.queue.isIn(_intradayLearning.map((q) => q.name)) &
              c.due.isSmallerOrEqualValue(lookAheadSec)))
        .get();

    // Interday learning counts against the review limit and comes first.
    final interday = reviewRemaining == 0
        ? <CardEntry>[]
        : await (_db.select(_db.cards)
              ..where((c) =>
                  c.deckId.equals(deckId) &
                  c.queue.isIn(_interdayLearning.map((q) => q.name)) &
                  c.due.isSmallerOrEqualValue(t))
              ..orderBy([(c) => OrderingTerm.asc(c.due)])
              ..limit(reviewRemaining))
            .get();
    final reviewSlots = reviewRemaining - interday.length;
    final reviews = reviewSlots <= 0
        ? <CardEntry>[]
        : await (_db.select(_db.cards)
              ..where((c) =>
                  c.deckId.equals(deckId) & c.queue.equalsValue(CardQueue.review) & c.due.isSmallerOrEqualValue(t))
              ..orderBy([(c) => OrderingTerm.asc(c.due)])
              ..limit(reviewSlots))
            .get();

    final news = newRemaining == 0
        ? <CardEntry>[]
        : await (_db.select(_db.cards)
              ..where((c) => c.deckId.equals(deckId) & c.queue.equalsValue(CardQueue.newCard))
              ..orderBy([(c) => OrderingTerm.asc(c.due), (c) => OrderingTerm.asc(c.id)])
              ..limit(newRemaining))
            .get();

    return _QueueParts(learning, [...interday, ...reviews], news);
  }

  List<CardEntry> _assemble(_QueueParts parts, DateTime n, int t) {
    final nowSec = n.millisecondsSinceEpoch ~/ 1000;
    final learning = parts.learning.where((c) => c.due <= nowSec).toList()..sort((a, b) => a.due.compareTo(b.due));
    final ahead = parts.learning.where((c) => c.due > nowSec).toList()..sort((a, b) => a.due.compareTo(b.due));

    // "Due date, then random", with the shuffle seeded by the day so the
    // order stays put while the queue is rebuilt after every answer.
    final reviews = [...parts.reviews]..sort((a, b) {
        final byDue = a.due.compareTo(b.due);
        return byDue != 0 ? byDue : fuzzFactor(a.id, t).compareTo(fuzzFactor(b.id, t));
      });

    return [...learning, ...intersperse(reviews, parts.news), ...ahead];
  }

  /// Spreads [news] evenly through [reviews] (Anki's "mix with reviews").
  static List<CardEntry> intersperse(List<CardEntry> reviews, List<CardEntry> news) {
    if (news.isEmpty) return reviews;
    if (reviews.isEmpty) return news;
    final total = reviews.length + news.length;
    final out = <CardEntry>[];
    var r = 0, k = 0;
    for (var i = 0; i < total; i++) {
      final newDue = k < news.length && (i + 1) * (news.length + 1) >= (k + 1) * (total + 1);
      if (r >= reviews.length || newDue) {
        out.add(news[k++]);
      } else {
        out.add(reviews[r++]);
      }
    }
    return out;
  }

  Future<DueQueueCounts> counts(int deckId, {DateTime? now}) async {
    final cards = await dueQueue(deckId, now: now);
    return DueQueueCounts(
      newCount: cards.where((c) => c.queue == CardQueue.newCard).length,
      learningCount: cards.where((c) => _intradayLearning.contains(c.queue) || _interdayLearning.contains(c.queue)).length,
      reviewCount: cards.where((c) => c.queue == CardQueue.review).length,
    );
  }

  // --- answering -----------------------------------------------------------

  /// Everything Anki computes before showing the answer buttons
  /// (`card_state_updater` + `state_context`).
  Future<_Prepared> _prepare(CardEntry entry, DateTime n) async {
    final meta = await _db.select(_db.collectionMeta).getSingle();
    final createdAt = DateTime.fromMillisecondsSinceEpoch(meta.createdAt);
    final t = dayNumber(n, createdAt, rolloverHour: meta.rolloverHour);
    final nextDayAt = dayStart(t + 1, createdAt, rolloverHour: meta.rolloverHour);
    final nextDayAtSecs = nextDayAt.millisecondsSinceEpoch ~/ 1000;
    final nowSecs = n.millisecondsSinceEpoch ~/ 1000;
    final cfgRow = await _configRowForDeck(entry.deckId);
    final config = schedConfigFromRow(cfgRow);
    final seed = fuzzSeed(entry.id, entry.reps);

    var card = _stateFromEntry(entry);
    NextStates? fsrsNext;
    var allowShortTerm = false;
    double? decay;
    if (meta.fsrsEnabled) {
      final fsrs = fsrsFor(config);
      decay = Fsrs.decayFromParams(config.fsrsParams);
      if (card.stability == null && entry.queue != CardQueue.newCard) {
        // Moved/imported into FSRS after the fact: derive the memory state
        // from the review history, as Anki does on first answer.
        final memory = await _memoryFromHistory(fsrs, config, entry, nextDayAtSecs);
        card = _withMemory(card, memory);
      }
      final lastReview = entry.lastReviewedAt ?? await _lastReviewSecs(entry.id);
      final daysElapsed = lastReview == null ? 0 : max(0, nextDayAtSecs - lastReview) ~/ 86400;
      final memory = card.stability == null ? null : MemoryState(card.stability!, card.difficulty!);
      fsrsNext = fsrs.nextStates(memory, config.desiredRetention, daysElapsed);
      final p = config.fsrsParams;
      allowShortTerm = p.isEmpty || (p.length >= 19 && p[17] > 0 && p[18] > 0);
    }

    LoadBalancer? balancer;
    if (meta.loadBalancerEnabled) {
      final rows = await (_db.select(_db.cards).join([
        innerJoin(_db.decks, _db.decks.id.equalsExp(_db.cards.deckId)),
      ])
            ..where(_db.decks.deckConfigId.equals(cfgRow.id) &
                _db.cards.due.isBiggerOrEqualValue(t) &
                _db.cards.due.isSmallerThanValue(t + LoadBalancer.loadBalanceDays)))
          .get();
      balancer = LoadBalancer(
        dueByDay: bucketDueByDay(rows.map((r) => (r.readTable(_db.cards).due, r.readTable(_db.cards).noteId)), t),
        easyDays: config.easyDaysPercentages,
        nextDayAt: nextDayAt,
      );
    }

    final ctx = StateContext(
      config: config,
      fuzzFactor: fuzzFactor(entry.id, entry.reps),
      fsrsNextStates: fsrsNext,
      fsrsAllowShortTerm: allowShortTerm,
      fsrsShortTermWithSteps: meta.fsrsShortTermWithSteps,
      loadBalancer: balancer == null ? null : (i, mn, mx) => balancer!.findInterval(i, mn, mx, fuzzSeed: seed),
    );
    final current = currentCardState(
      card: card,
      config: config,
      today: t,
      nowSecs: nowSecs,
      fuzzSeedForPreviousAnswer: fuzzSeed(entry.id, entry.reps - 1),
    );
    return _Prepared(
      card: card,
      config: config,
      states: _scheduler.nextStates(current, ctx),
      today: t,
      nowSecs: nowSecs,
      secsUntilRollover: max(0, nextDayAtSecs - nowSecs),
      seed: seed,
      fsrsEnabled: meta.fsrsEnabled,
      decay: decay,
    );
  }

  /// The interval each button would give, as Anki shows it on the buttons
  /// (learning delays in seconds, anything past the day boundary in days).
  Future<Map<Rating, IntervalKind>> previewOutcomes(int cardId, {DateTime? now}) async {
    final n = now ?? DateTime.now();
    final entry = await (_db.select(_db.cards)..where((c) => c.id.equals(cardId))).getSingle();
    final p = await _prepare(entry, n);
    return {
      for (final r in Rating.values) r: intervalKindOf(p.states.forRating(r)).maybeAsDays(p.secsUntilRollover),
    };
  }

  /// Anki records at most this long per answer ("maximum answer seconds").
  static const maxAnswerMs = 60000;

  /// Applies [rating] to [cardId] exactly as Anki would, persists the new
  /// state and a revlog entry in Anki's format, updates the deck's daily
  /// counters and tags leeches. Returns what's needed to [undo] it.
  Future<AnswerResult> answerCard({
    required int cardId,
    required Rating rating,
    DateTime? now,
    int timeTakenMs = 0,
  }) async {
    final n = now ?? DateTime.now();
    final entry = await (_db.select(_db.cards)..where((c) => c.id.equals(cardId))).getSingle();
    final p = await _prepare(entry, n);
    final applied = applyAnswer(
      card: p.card,
      current: p.states.current,
      next: p.states.forRating(rating),
      config: p.config,
      today: p.today,
      nowSecs: p.nowSecs,
      secsUntilRollover: p.secsUntilRollover,
      fuzzSeed: p.seed,
    );
    var state = applied.card;
    if (applied.leeched && p.config.leechSuspends) state = state.copyWith(queue: CardQueue.suspended);

    return _db.transaction(() async {
      final deckBefore = await (_db.select(_db.decks)..where((d) => d.id.equals(entry.deckId))).getSingle();

      await (_db.update(_db.cards)..where((c) => c.id.equals(cardId))).write(CardsCompanion(
        queue: Value(state.queue),
        due: Value(state.due),
        ivl: Value(state.ivl),
        ease: Value(state.ease),
        reps: Value(state.reps),
        lapses: Value(state.lapses),
        stepIndex: Value(state.stepIndex),
        lastReviewedAt: Value(p.nowSecs),
        fsrsStability: Value(state.stability),
        fsrsDifficulty: Value(state.difficulty),
        fsrsDesiredRetention: p.fsrsEnabled ? Value(p.config.desiredRetention) : const Value.absent(),
        fsrsDecay: p.fsrsEnabled ? Value(p.decay) : const Value.absent(),
      ));
      final revlogId = await _db.into(_db.revLog).insert(RevLogCompanion.insert(
            cardId: cardId,
            reviewedAt: p.nowSecs,
            rating: ratingToInt(rating),
            ivlBefore: applied.revlogLastInterval,
            ivlAfter: applied.revlogInterval,
            easeAfter: applied.revlogEaseFactor,
            timeTakenMs: Value(timeTakenMs.clamp(0, maxAnswerMs)),
            kind: Value(applied.revlogKind),
          ));

      // Daily budgets, as Anki counts them: a new card's first answer
      // against new cards; reviews and interday learning against reviews.
      final t = p.today;
      if (entry.queue == CardQueue.newCard) {
        final shown = deckBefore.newShownDay == t ? deckBefore.newShownToday : 0;
        await (_db.update(_db.decks)..where((d) => d.id.equals(entry.deckId)))
            .write(DecksCompanion(newShownToday: Value(shown + 1), newShownDay: Value(t)));
      } else if (entry.queue == CardQueue.review || _interdayLearning.contains(entry.queue)) {
        final shown = deckBefore.reviewsShownDay == t ? deckBefore.reviewsShownToday : 0;
        await (_db.update(_db.decks)..where((d) => d.id.equals(entry.deckId)))
            .write(DecksCompanion(reviewsShownToday: Value(shown + 1), reviewsShownDay: Value(t)));
      }

      String? tagsBefore;
      if (applied.leeched) {
        final note = await (_db.select(_db.notes)..where((x) => x.id.equals(entry.noteId))).getSingle();
        final tags = note.tags.split(' ').where((s) => s.isNotEmpty).toList();
        if (!tags.any((s) => s.toLowerCase() == 'leech')) {
          tagsBefore = note.tags;
          await (_db.update(_db.notes)..where((x) => x.id.equals(entry.noteId)))
              .write(NotesCompanion(tags: Value([...tags, 'leech'].join(' '))));
        }
      }

      return AnswerResult(
        AnswerOutcome(state, becameLeech: applied.leeched),
        UndoEntry._(cardBefore: entry, deckBefore: deckBefore, revlogId: revlogId, noteTagsBefore: tagsBefore),
      );
    });
  }

  /// Takes an answer back, as if it had never been given.
  Future<void> undo(UndoEntry entry) async {
    await _db.transaction(() async {
      await _db.update(_db.cards).replace(entry.cardBefore);
      await (_db.delete(_db.revLog)..where((r) => r.id.equals(entry.revlogId))).go();
      final d = entry.deckBefore;
      await (_db.update(_db.decks)..where((x) => x.id.equals(d.id))).write(DecksCompanion(
        newShownToday: Value(d.newShownToday),
        newShownDay: Value(d.newShownDay),
        reviewsShownToday: Value(d.reviewsShownToday),
        reviewsShownDay: Value(d.reviewsShownDay),
      ));
      final tags = entry.noteTagsBefore;
      if (tags != null) {
        await (_db.update(_db.notes)..where((x) => x.id.equals(entry.cardBefore.noteId)))
            .write(NotesCompanion(tags: Value(tags)));
      }
    });
  }

  // --- collection-wide scheduling options ----------------------------------

  Future<CollectionMetaData> schedulingOptions() => _db.select(_db.collectionMeta).getSingle();

  Stream<CollectionMetaData> watchSchedulingOptions() => _db.select(_db.collectionMeta).watchSingle();

  /// Switches FSRS on or off for the whole collection, as in Anki. Turning
  /// it on computes every card's memory state from its review history.
  Future<void> setFsrsEnabled(bool enabled) async {
    await _db.update(_db.collectionMeta).write(CollectionMetaCompanion(fsrsEnabled: Value(enabled)));
    if (enabled) await recomputeMemoryStates();
  }

  Future<void> setLoadBalancerEnabled(bool enabled) =>
      _db.update(_db.collectionMeta).write(CollectionMetaCompanion(loadBalancerEnabled: Value(enabled)));

  Future<void> setFsrsShortTermWithSteps(bool enabled) =>
      _db.update(_db.collectionMeta).write(CollectionMetaCompanion(fsrsShortTermWithSteps: Value(enabled)));

  // --- FSRS memory states --------------------------------------------------

  /// The FSRS model for a preset; invalid stored parameters fall back to
  /// the defaults rather than blocking study.
  static Fsrs fsrsFor(DeckSchedConfig config) {
    try {
      return Fsrs(config.fsrsParams);
    } on FormatException {
      return Fsrs.defaults();
    }
  }

  Future<MemoryState?> _memoryFromHistory(Fsrs fsrs, DeckSchedConfig config, CardEntry entry, int nextDayAtSecs) async {
    final rows = await (_db.select(_db.revLog)
          ..where((r) => r.cardId.equals(entry.id))
          ..orderBy([(r) => OrderingTerm.asc(r.reviewedAt), (r) => OrderingTerm.asc(r.id)]))
        .get();
    final items = [
      for (final r in rows)
        RevlogItem(idMs: r.reviewedAt * 1000, rating: r.rating, kind: r.kind, interval: r.ivlAfter, easeFactor: r.easeAfter),
    ];
    final item = fsrsItemForMemoryState(fsrs, items, nextDayAtSecs, config.historicalRetention, config.ignoreRevlogsBeforeMs);
    return memoryStateForCard(
      fsrs: fsrs,
      item: item,
      isNew: entry.queue == CardQueue.newCard,
      interval: entry.ivl,
      easeFactor: entry.ease,
      historicalRetention: config.historicalRetention,
    );
  }

  /// Recomputes every card's memory state from its history - what Anki
  /// does when FSRS is switched on or a preset's parameters change.
  /// Scheduling (due dates) is left as is, like Anki's default.
  Future<int> recomputeMemoryStates({int? deckConfigId, DateTime? now}) async {
    final n = now ?? DateTime.now();
    final meta = await _db.select(_db.collectionMeta).getSingle();
    final createdAt = DateTime.fromMillisecondsSinceEpoch(meta.createdAt);
    final t = dayNumber(n, createdAt, rolloverHour: meta.rolloverHour);
    final nextDayAtSecs = dayStart(t + 1, createdAt, rolloverHour: meta.rolloverHour).millisecondsSinceEpoch ~/ 1000;

    final decks = await _db.select(_db.decks).get();
    var updated = 0;
    for (final deck in decks) {
      if (deckConfigId != null && deck.deckConfigId != deckConfigId) continue;
      final config = schedConfigFromRow(await _configRowForDeck(deck.id));
      final fsrs = fsrsFor(config);
      final cards = await (_db.select(_db.cards)..where((c) => c.deckId.equals(deck.id))).get();
      await _db.transaction(() async {
        for (final c in cards) {
          final memory = await _memoryFromHistory(fsrs, config, c, nextDayAtSecs);
          await (_db.update(_db.cards)..where((x) => x.id.equals(c.id))).write(CardsCompanion(
            fsrsStability: Value(memory?.stability),
            fsrsDifficulty: Value(memory?.difficulty),
            fsrsDesiredRetention: Value(memory == null ? null : config.desiredRetention),
            fsrsDecay: Value(memory == null ? null : Fsrs.decayFromParams(config.fsrsParams)),
          ));
          updated++;
        }
      });
    }
    return updated;
  }

  Future<int?> _lastReviewSecs(int cardId) async {
    final row = await (_db.select(_db.revLog)
          ..where((r) => r.cardId.equals(cardId) & r.rating.isBiggerThanValue(0))
          ..orderBy([(r) => OrderingTerm.desc(r.reviewedAt)])
          ..limit(1))
        .getSingleOrNull();
    return row?.reviewedAt;
  }

  static CardSchedState _withMemory(CardSchedState c, MemoryState? m) => CardSchedState(
        queue: c.queue,
        due: c.due,
        ivl: c.ivl,
        ease: c.ease,
        reps: c.reps,
        lapses: c.lapses,
        stepIndex: c.stepIndex,
        stability: m?.stability,
        difficulty: m?.difficulty,
      );

  CardSchedState _stateFromEntry(CardEntry entry) => CardSchedState(
        queue: entry.queue,
        due: entry.due,
        ivl: entry.ivl,
        ease: entry.ease,
        reps: entry.reps,
        lapses: entry.lapses,
        stepIndex: entry.stepIndex,
        stability: entry.fsrsStability,
        difficulty: entry.fsrsDifficulty,
      );
}

class _Prepared {
  const _Prepared({
    required this.card,
    required this.config,
    required this.states,
    required this.today,
    required this.nowSecs,
    required this.secsUntilRollover,
    required this.seed,
    required this.fsrsEnabled,
    required this.decay,
  });
  final CardSchedState card;
  final DeckSchedConfig config;
  final SchedulingStates states;
  final int today;
  final int nowSecs;
  final int secsUntilRollover;
  final int seed;
  final bool fsrsEnabled;
  final double? decay;
}

class AnswerResult {
  const AnswerResult(this.outcome, this.undo);
  final AnswerOutcome outcome;
  final UndoEntry undo;
}

/// Everything [StudyRepository.undo] needs to take one answer back.
class UndoEntry {
  const UndoEntry._({
    required this.cardBefore,
    required this.deckBefore,
    required this.revlogId,
    this.noteTagsBefore,
  });

  final CardEntry cardBefore;
  final Deck deckBefore;
  final int revlogId;
  final String? noteTagsBefore;

  int get cardId => cardBefore.id;
}

class _QueueParts {
  _QueueParts(this.learning, this.reviews, this.news);
  _QueueParts.empty()
      : learning = [],
        reviews = [],
        news = [];

  final List<CardEntry> learning;
  final List<CardEntry> reviews;
  final List<CardEntry> news;

  void addAll(_QueueParts other) {
    learning.addAll(other.learning);
    reviews.addAll(other.reviews);
    news.addAll(other.news);
  }
}
