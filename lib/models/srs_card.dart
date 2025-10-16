import 'enums.dart';

/// Represents an SRS (Spaced Repetition System) card using FSRS algorithm
/// This tracks the scheduling data for reviewing vocabulary
class SRSCard {
  final String id;
  final String vocabularyId;
  final CardState state;
  final double stability;    // Memory stability (FSRS parameter)
  final double difficulty;   // Card difficulty (FSRS parameter)
  final DateTime dueDate;    // When the card is due for review
  final int elapsedDays;     // Days since last review
  final int scheduledDays;   // Days until next review
  final int reps;            // Number of reviews
  final int lapses;          // Number of times forgotten
  final DateTime? lastReview;
  final DateTime createdAt;

  const SRSCard({
    required this.id,
    required this.vocabularyId,
    required this.state,
    this.stability = 0.0,
    this.difficulty = 0.0,
    required this.dueDate,
    this.elapsedDays = 0,
    this.scheduledDays = 0,
    this.reps = 0,
    this.lapses = 0,
    this.lastReview,
    required this.createdAt,
  });

  /// Check if card is due for review
  bool get isDue => DateTime.now().isAfter(dueDate);

  /// Check if card is overdue
  bool get isOverdue {
    if (!isDue) return false;
    final daysSinceDue = DateTime.now().difference(dueDate).inDays;
    return daysSinceDue > 1;
  }

  /// Get days until due (negative if overdue)
  int get daysUntilDue => dueDate.difference(DateTime.now()).inDays;

  /// Convert to database map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'vocabulary_id': vocabularyId,
      'state': state.value,
      'stability': stability,
      'difficulty': difficulty,
      'due_date': dueDate.millisecondsSinceEpoch,
      'elapsed_days': elapsedDays,
      'scheduled_days': scheduledDays,
      'reps': reps,
      'lapses': lapses,
      'last_review': lastReview?.millisecondsSinceEpoch,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }

  /// Create from database map
  factory SRSCard.fromMap(Map<String, dynamic> map) {
    return SRSCard(
      id: map['id'] ?? '',
      vocabularyId: map['vocabulary_id'] ?? '',
      state: CardState.fromString(map['state'] ?? 'new'),
      stability: map['stability']?.toDouble() ?? 0.0,
      difficulty: map['difficulty']?.toDouble() ?? 0.0,
      dueDate: DateTime.fromMillisecondsSinceEpoch(
        map['due_date'] ?? DateTime.now().millisecondsSinceEpoch,
      ),
      elapsedDays: map['elapsed_days'] ?? 0,
      scheduledDays: map['scheduled_days'] ?? 0,
      reps: map['reps'] ?? 0,
      lapses: map['lapses'] ?? 0,
      lastReview: map['last_review'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['last_review'])
          : null,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        map['created_at'] ?? DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  /// Create a new card for a vocabulary word
  factory SRSCard.newCard(String vocabularyId) {
    final now = DateTime.now();
    return SRSCard(
      id: '', // Will be set by database
      vocabularyId: vocabularyId,
      state: CardState.newCard,
      stability: 0.0,
      difficulty: 5.0, // Default difficulty
      dueDate: now,
      createdAt: now,
    );
  }

  SRSCard copyWith({
    String? id,
    String? vocabularyId,
    CardState? state,
    double? stability,
    double? difficulty,
    DateTime? dueDate,
    int? elapsedDays,
    int? scheduledDays,
    int? reps,
    int? lapses,
    DateTime? lastReview,
    DateTime? createdAt,
  }) {
    return SRSCard(
      id: id ?? this.id,
      vocabularyId: vocabularyId ?? this.vocabularyId,
      state: state ?? this.state,
      stability: stability ?? this.stability,
      difficulty: difficulty ?? this.difficulty,
      dueDate: dueDate ?? this.dueDate,
      elapsedDays: elapsedDays ?? this.elapsedDays,
      scheduledDays: scheduledDays ?? this.scheduledDays,
      reps: reps ?? this.reps,
      lapses: lapses ?? this.lapses,
      lastReview: lastReview ?? this.lastReview,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
