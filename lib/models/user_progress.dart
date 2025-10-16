import 'enums.dart';

/// Tracks user's learning progress for a specific vocabulary word
class UserProgress {
  final String id;
  final String vocabularyId;
  final WordStatus status;
  final DateTime? firstStudiedAt;
  final DateTime? lastReviewedAt;
  final int reviewCount;
  final int correctCount;
  final DateTime createdAt;

  const UserProgress({
    required this.id,
    required this.vocabularyId,
    required this.status,
    this.firstStudiedAt,
    this.lastReviewedAt,
    this.reviewCount = 0,
    this.correctCount = 0,
    required this.createdAt,
  });

  /// Calculate accuracy percentage
  double get accuracy {
    if (reviewCount == 0) return 0.0;
    return (correctCount / reviewCount) * 100;
  }

  /// Check if word is due for review (simple heuristic)
  bool get isDueForReview {
    if (status == WordStatus.unlearned) return false;
    if (lastReviewedAt == null) return true;

    final daysSinceReview =
        DateTime.now().difference(lastReviewedAt!).inDays;

    // Simple spacing algorithm (will be replaced by FSRS)
    switch (status) {
      case WordStatus.learning:
        return daysSinceReview >= 1;
      case WordStatus.learned:
        return daysSinceReview >= 3;
      case WordStatus.mastered:
        return daysSinceReview >= 7;
      case WordStatus.unlearned:
        return false;
    }
  }

  /// Convert to database map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'vocabulary_id': vocabularyId,
      'status': status.value,
      'first_studied_at': firstStudiedAt?.millisecondsSinceEpoch,
      'last_reviewed_at': lastReviewedAt?.millisecondsSinceEpoch,
      'review_count': reviewCount,
      'correct_count': correctCount,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }

  /// Create from database map
  factory UserProgress.fromMap(Map<String, dynamic> map) {
    return UserProgress(
      id: map['id'] ?? '',
      vocabularyId: map['vocabulary_id'] ?? '',
      status: WordStatus.fromString(map['status'] ?? 'unlearned'),
      firstStudiedAt: map['first_studied_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['first_studied_at'])
          : null,
      lastReviewedAt: map['last_reviewed_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['last_reviewed_at'])
          : null,
      reviewCount: map['review_count'] ?? 0,
      correctCount: map['correct_count'] ?? 0,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        map['created_at'] ?? DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  UserProgress copyWith({
    String? id,
    String? vocabularyId,
    WordStatus? status,
    DateTime? firstStudiedAt,
    DateTime? lastReviewedAt,
    int? reviewCount,
    int? correctCount,
    DateTime? createdAt,
  }) {
    return UserProgress(
      id: id ?? this.id,
      vocabularyId: vocabularyId ?? this.vocabularyId,
      status: status ?? this.status,
      firstStudiedAt: firstStudiedAt ?? this.firstStudiedAt,
      lastReviewedAt: lastReviewedAt ?? this.lastReviewedAt,
      reviewCount: reviewCount ?? this.reviewCount,
      correctCount: correctCount ?? this.correctCount,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
