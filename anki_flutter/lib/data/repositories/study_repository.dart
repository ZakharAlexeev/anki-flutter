import 'dart:math';

import 'package:drift/drift.dart';

import '../../domain/scheduler/day_calendar.dart';
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
/// matching Anki's own "learn ahead limit" (default 20 minutes) - without
/// this, a card answered "Again" (due again in 1-10 minutes) never resurfaces
/// in the *current* session: the queue is only ever filtered by `due <= now`,
/// and by the time it's actually due the user has already moved on.
const _learnAheadWindow = Duration(minutes: 20);

/// Bridges the pure [Scheduler] to persisted state: builds each deck's due
/// queue, and applies + records answers inside a transaction.
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

  Future<DeckSchedConfig> _configForDeck(int deckId) async {
    final row = await _configRowForDeck(deckId);
    final options = await _db.customSelect(
      'SELECT desired_retention FROM fsrs_deck_options WHERE deck_config_id = ?',
      variables: [Variable.withInt(row.id)],
    ).getSingleOrNull();
    return schedConfigFromRow(
      row,
      desiredRetention: options?.read<double>('desired_retention') ?? 0.9,
    );
  }

  /// Cards ready to study right now, ordered: learning steps that have
  /// actually elapsed -> review -> new -> learning steps still counting
  /// down (pulled in early only so the session doesn't stall waiting on
  /// them, not so they cut in front of the rest of the deck) - a
  /// simplified but faithful approximation of Anki's default mix.
  ///
  /// New/review counts are capped by how many are *actually still allowed
  /// today* - the deck's per-day limit (or its override) minus how many
  /// have already been shown today per [Deck.newShownToday]/
  /// [Deck.reviewsShownToday] - not just a flat query LIMIT, so leaving and
  /// re-entering a deck doesn't hand out a fresh limit each time.
  Future<List<CardEntry>> dueQueue(int deckId, {DateTime? now}) async {
    final n = now ?? DateTime.now();
    final t = await today(n);
    final lookAheadSec = n.add(_learnAheadWindow).millisecondsSinceEpoch ~/ 1000;
    final deck = await (_db.select(_db.decks)..where((d) => d.id.equals(deckId))).getSingle();
    final cfg = await (_db.select(_db.deckConfigs)..where((c) => c.id.equals(deck.deckConfigId))).getSingle();

    final newLimit = deck.newPerDayOverride ?? cfg.newPerDay;
    final newShown = deck.newShownDay == t ? deck.newShownToday : 0;
    final newRemaining = max(0, newLimit - newShown);

    final reviewLimit = deck.reviewsPerDayOverride ?? cfg.reviewsPerDay;
    final reviewShown = deck.reviewsShownDay == t ? deck.reviewsShownToday : 0;
    final reviewRemaining = max(0, reviewLimit - reviewShown);

    final learningRows = await (_db.select(_db.cards)
          ..where((c) =>
              c.deckId.equals(deckId) &
              (c.queue.equalsValue(CardQueue.learning) | c.queue.equalsValue(CardQueue.relearning)) &
              c.due.isSmallerOrEqualValue(lookAheadSec))
          ..orderBy([(c) => OrderingTerm.asc(c.due)]))
        .get();
    // A card answered "Again"/"Hard" a moment ago has due = now + its step
    // delay (e.g. 1-10 min), which is well within the look-ahead window -
    // so without this split it re-appeared as literally the very next card
    // over and over, ahead of everything else in the deck, since it's
    // always first in the concatenation below. Only a card whose step has
    // actually elapsed (due <= now) should jump the queue like that;
    // anything still counting down waits at the back until it's ready.
    final nowSec = n.millisecondsSinceEpoch ~/ 1000;
    final learning = learningRows.where((c) => c.due <= nowSec).toList();
    final learningAhead = learningRows.where((c) => c.due > nowSec).toList();

    final review = reviewRemaining == 0
        ? <CardEntry>[]
        : await (_db.select(_db.cards)
              ..where((c) =>
                  c.deckId.equals(deckId) & c.queue.equalsValue(CardQueue.review) & c.due.isSmallerOrEqualValue(t))
              ..orderBy([(c) => OrderingTerm.asc(c.due)])
              ..limit(reviewRemaining))
            .get();

    final newCards = newRemaining == 0
        ? <CardEntry>[]
        : await (_db.select(_db.cards)
              ..where((c) => c.deckId.equals(deckId) & c.queue.equalsValue(CardQueue.newCard))
              ..orderBy([(c) => OrderingTerm.asc(c.id)])
              ..limit(newRemaining))
            .get();

    return [...learning, ...review, ...newCards, ...learningAhead];
  }

  Future<DueQueueCounts> counts(int deckId, {DateTime? now}) async {
    final cards = await dueQueue(deckId, now: now);
    return DueQueueCounts(
      newCount: cards.where((c) => c.queue == CardQueue.newCard).length,
      learningCount: cards.where((c) => c.queue == CardQueue.learning || c.queue == CardQueue.relearning).length,
      reviewCount: cards.where((c) => c.queue == CardQueue.review).length,
    );
  }

  /// What each of the four buttons would do to [cardId] right now, without
  /// persisting anything - used to render interval previews under the
  /// Again/Hard/Good/Easy buttons.
  Future<Map<Rating, CardSchedState>> previewOutcomes(int cardId, {DateTime? now}) async {
    final n = now ?? DateTime.now();
    final entry = await (_db.select(_db.cards)..where((c) => c.id.equals(cardId))).getSingle();
    final config = await _configForDeck(entry.deckId);
    final t = await today(n);
    return _scheduler.previewOutcomes(card: await _stateFromEntry(entry, config), config: config, now: n, today: t);
  }

  /// Applies [rating] to [cardId], persists the new scheduling state and
  /// appends a revlog entry (with [timeTakenMs], if the caller measured how
  /// long the card was shown for), all in one transaction. Also updates the
  /// owning deck's daily new/review counters so [dueQueue]'s per-day limits
  /// actually stick across app restarts and re-entering the deck.
  Future<AnswerOutcome> answerCard({
    required int cardId,
    required Rating rating,
    DateTime? now,
    int timeTakenMs = 0,
  }) async {
    final n = now ?? DateTime.now();
    return _db.transaction(() async {
      // Read, calculate and write under the same serialized transaction. A
      // second caller can no longer append a duplicate revlog entry based on
      // scheduling state read before the first answer was committed.
      final entry = await (_db.select(_db.cards)..where((c) => c.id.equals(cardId))).getSingle();
      final config = await _configForDeck(entry.deckId);
      final t = await today(n);
      final nowSec = n.millisecondsSinceEpoch ~/ 1000;
      final outcome = _scheduler.answerCard(
        card: await _stateFromEntry(entry, config),
        config: config,
        rating: rating,
        now: n,
        today: t,
      );

      await (_db.update(_db.cards)..where((c) => c.id.equals(cardId))).write(CardsCompanion(
        queue: Value(outcome.state.queue),
        due: Value(outcome.state.due),
        ivl: Value(outcome.state.ivl),
        ease: Value(outcome.state.ease),
        reps: Value(outcome.state.reps),
        lapses: Value(outcome.state.lapses),
        stepIndex: Value(outcome.state.stepIndex),
        lastReviewedAt: Value(nowSec),
      ));
      final stability = outcome.state.stability;
      final difficulty = outcome.state.difficulty;
      if (stability != null && difficulty != null) {
        await _db.customStatement(
          'INSERT INTO fsrs_card_state(card_id, stability, difficulty) VALUES (?, ?, ?) '
          'ON CONFLICT(card_id) DO UPDATE SET stability = excluded.stability, difficulty = excluded.difficulty',
          [cardId, stability, difficulty],
        );
      }
      await _db.into(_db.revLog).insert(RevLogCompanion.insert(
            cardId: cardId,
            reviewedAt: nowSec,
            rating: ratingToInt(rating),
            ivlBefore: entry.ivl,
            ivlAfter: outcome.state.ivl,
            easeAfter: outcome.state.ease,
            timeTakenMs: Value(timeTakenMs),
          ));

      // Count this presentation against the deck's daily budget: a new
      // card's very first answer counts against newPerDay; a review card's
      // (mature or lapsed-and-since-relearned) answer counts against
      // reviewsPerDay. Mid-(re)learning-step answers count against neither,
      // matching Anki.
      if (entry.queue == CardQueue.newCard) {
        final deck = await (_db.select(_db.decks)..where((d) => d.id.equals(entry.deckId))).getSingle();
        final shown = deck.newShownDay == t ? deck.newShownToday : 0;
        await (_db.update(_db.decks)..where((d) => d.id.equals(entry.deckId)))
            .write(DecksCompanion(newShownToday: Value(shown + 1), newShownDay: Value(t)));
      } else if (entry.queue == CardQueue.review) {
        final deck = await (_db.select(_db.decks)..where((d) => d.id.equals(entry.deckId))).getSingle();
        final shown = deck.reviewsShownDay == t ? deck.reviewsShownToday : 0;
        await (_db.update(_db.decks)..where((d) => d.id.equals(entry.deckId)))
            .write(DecksCompanion(reviewsShownToday: Value(shown + 1), reviewsShownDay: Value(t)));
      }
      return outcome;
    });
  }

  Future<CardSchedState> _stateFromEntry(CardEntry entry, DeckSchedConfig config) async {
    final memory = await _db.customSelect(
      'SELECT stability, difficulty FROM fsrs_card_state WHERE card_id = ?',
      variables: [Variable.withInt(entry.id)],
    ).getSingleOrNull();
    final state = CardSchedState(
      queue: entry.queue,
      due: entry.due,
      ivl: entry.ivl,
      ease: entry.ease,
      reps: entry.reps,
      lapses: entry.lapses,
      stepIndex: entry.stepIndex,
      stability: memory?.read<double>('stability'),
      difficulty: memory?.read<double>('difficulty'),
      lastReviewedAt: entry.lastReviewedAt,
    );
    if (memory != null || entry.reps == 0) return state;

    final history = await (_db.select(_db.revLog)
          ..where((row) => row.cardId.equals(entry.id))
          ..orderBy([(row) => OrderingTerm.asc(row.reviewedAt)]))
        .get();
    return _scheduler.rebuildMemoryState(
      card: state,
      config: config,
      reviews: [
        for (final row in history)
          SchedulingReview(reviewedAt: row.reviewedAt, rating: _ratingFromInt(row.rating)),
      ],
    );
  }

  Rating _ratingFromInt(int value) => switch (value) {
        1 => Rating.again,
        2 => Rating.hard,
        3 => Rating.good,
        4 => Rating.easy,
        _ => throw StateError('Unsupported review rating: $value'),
      };
}
