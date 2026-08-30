import 'dart:math';

import 'package:fsrs/fsrs.dart' as fsrs;

import 'models.dart';

/// Adapter around FSRS-6, the scheduler used by current Anki releases.
///
/// The app keeps Anki-compatible queue/due fields in its own database while
/// FSRS owns the memory model (difficulty and stability) and interval maths.
class Scheduler {
  const Scheduler();

  AnswerOutcome answerCard({
    required CardSchedState card,
    required DeckSchedConfig config,
    required Rating rating,
    required DateTime now,
    required int today,
    Random? random,
  }) {
    if (card.queue == CardQueue.suspended) {
      throw StateError('Cannot answer a suspended card.');
    }

    final nowUtc = now.toUtc();
    final scheduler = random == null
        ? fsrs.Scheduler(
            parameters: config.fsrsParameters,
            desiredRetention: config.desiredRetention,
            learningSteps: _durations(config.learningStepsMin),
            relearningSteps: _durations(config.relearningStepsMin),
            maximumInterval: config.maximumIntervalDays,
            enableFuzzing: true,
          )
        : fsrs.Scheduler.customRandom(
            random,
            parameters: config.fsrsParameters,
            desiredRetention: config.desiredRetention,
            learningSteps: _durations(config.learningStepsMin),
            relearningSteps: _durations(config.relearningStepsMin),
            maximumInterval: config.maximumIntervalDays,
            enableFuzzing: true,
          );

    final reviewed = scheduler.reviewCard(
      _toFsrsCard(card, nowUtc),
      _toFsrsRating(rating),
      reviewDateTime: nowUtc,
    ).card;
    return _outcome(card, reviewed, config, rating, nowUtc, today);
  }

  /// Deterministic button previews: answer labels do not include random fuzz.
  Map<Rating, CardSchedState> previewOutcomes({
    required CardSchedState card,
    required DeckSchedConfig config,
    required DateTime now,
    required int today,
  }) {
    if (card.queue == CardQueue.suspended) {
      throw StateError('Cannot preview a suspended card.');
    }
    final nowUtc = now.toUtc();
    final scheduler = fsrs.Scheduler(
      parameters: config.fsrsParameters,
      desiredRetention: config.desiredRetention,
      learningSteps: _durations(config.learningStepsMin),
      relearningSteps: _durations(config.relearningStepsMin),
      maximumInterval: config.maximumIntervalDays,
      enableFuzzing: false,
    );
    return {
      for (final rating in Rating.values)
        rating: _outcome(
          card,
          scheduler.reviewCard(
            _toFsrsCard(card, nowUtc),
            _toFsrsRating(rating),
            reviewDateTime: nowUtc,
          ).card,
          config,
          rating,
          nowUtc,
          today,
        ).state,
    };
  }

  /// Reconstructs FSRS memory state from Anki-compatible review history.
  /// This is used lazily for cards created/imported before FSRS state was
  /// stored, instead of discarding their learning history.
  CardSchedState rebuildMemoryState({
    required CardSchedState card,
    required DeckSchedConfig config,
    required List<SchedulingReview> reviews,
  }) {
    if (reviews.isEmpty) return card;
    final scheduler = fsrs.Scheduler(
      parameters: config.fsrsParameters,
      desiredRetention: config.desiredRetention,
      learningSteps: _durations(config.learningStepsMin),
      relearningSteps: _durations(config.relearningStepsMin),
      maximumInterval: config.maximumIntervalDays,
      enableFuzzing: false,
    );
    final ordered = [...reviews]..sort((a, b) => a.reviewedAt.compareTo(b.reviewedAt));
    var reconstructed = fsrs.Card(
      cardId: 0,
      state: fsrs.State.learning,
      step: 0,
      due: DateTime.fromMillisecondsSinceEpoch(ordered.first.reviewedAt * 1000, isUtc: true),
    );
    for (final review in ordered) {
      reconstructed = scheduler.reviewCard(
        reconstructed,
        _toFsrsRating(review.rating),
        reviewDateTime: DateTime.fromMillisecondsSinceEpoch(review.reviewedAt * 1000, isUtc: true),
      ).card;
    }
    return card.copyWith(
      stability: reconstructed.stability,
      difficulty: reconstructed.difficulty,
      lastReviewedAt: ordered.last.reviewedAt,
    );
  }

  fsrs.Card _toFsrsCard(CardSchedState card, DateTime nowUtc) {
    final state = switch (card.queue) {
      CardQueue.newCard || CardQueue.learning => fsrs.State.learning,
      CardQueue.review => fsrs.State.review,
      CardQueue.relearning => fsrs.State.relearning,
      CardQueue.suspended => throw StateError('Cannot schedule a suspended card.'),
    };

    // Older databases have no FSRS memory state. Anki likewise falls back
    // to the existing interval when state is missing; the ease-derived
    // difficulty provides a continuous first migration review.
    final isEstablished = state != fsrs.State.learning || card.reps > 0;
    final stability = card.stability ?? (isEstablished ? max(0.1, card.ivl.toDouble()) : null);
    final difficulty = card.difficulty ??
        (isEstablished ? (10 - ((card.ease / 1000) - 1.3) * 4).clamp(1.0, 10.0).toDouble() : null);
    final lastReview = card.lastReviewedAt == null
        ? (isEstablished ? nowUtc.subtract(Duration(days: max(1, card.ivl))) : null)
        : DateTime.fromMillisecondsSinceEpoch(card.lastReviewedAt! * 1000, isUtc: true);

    return fsrs.Card(
      cardId: 0,
      state: state,
      step: state == fsrs.State.review ? null : card.stepIndex,
      stability: stability,
      difficulty: difficulty,
      due: nowUtc,
      lastReview: lastReview,
    );
  }

  AnswerOutcome _outcome(
    CardSchedState previous,
    fsrs.Card reviewed,
    DeckSchedConfig config,
    Rating rating,
    DateTime nowUtc,
    int today,
  ) {
    final queue = switch (reviewed.state) {
      fsrs.State.learning => CardQueue.learning,
      fsrs.State.review => CardQueue.review,
      fsrs.State.relearning => CardQueue.relearning,
    };
    final interval = reviewed.state == fsrs.State.review
        ? max(1, reviewed.due.difference(nowUtc).inDays)
        : previous.ivl;
    final due = reviewed.state == fsrs.State.review
        ? today + interval
        : reviewed.due.millisecondsSinceEpoch ~/ 1000;
    final lapsed = previous.queue == CardQueue.review && rating == Rating.again;
    final lapses = previous.lapses + (lapsed ? 1 : 0);
    final becameLeech = lapsed && config.leechThreshold > 0 && lapses % config.leechThreshold == 0;

    return AnswerOutcome(
      CardSchedState(
        queue: becameLeech ? CardQueue.suspended : queue,
        due: due,
        ivl: interval,
        ease: previous.ease,
        reps: previous.reps + 1,
        lapses: lapses,
        stepIndex: reviewed.step ?? 0,
        stability: reviewed.stability,
        difficulty: reviewed.difficulty,
        lastReviewedAt: nowUtc.millisecondsSinceEpoch ~/ 1000,
      ),
      becameLeech: becameLeech,
    );
  }

  List<Duration> _durations(List<int> minutes) => [for (final value in minutes) Duration(minutes: value)];

  fsrs.Rating _toFsrsRating(Rating rating) => switch (rating) {
        Rating.again => fsrs.Rating.again,
        Rating.hard => fsrs.Rating.hard,
        Rating.good => fsrs.Rating.good,
        Rating.easy => fsrs.Rating.easy,
      };
}
