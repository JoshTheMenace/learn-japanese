import 'enums.dart';

/// Represents a single review of a vocabulary word
class Review {
  final String id;
  final String vocabularyId;
  final Rating rating;
  final int timeSpent; // in milliseconds
  final DateTime reviewedAt;

  const Review({
    required this.id,
    required this.vocabularyId,
    required this.rating,
    required this.timeSpent,
    required this.reviewedAt,
  });

  /// Was this review successful? (Good or Easy)
  bool get wasSuccessful =>
      rating == Rating.good || rating == Rating.easy;

  /// Was this review a failure? (Again)
  bool get wasFailure => rating == Rating.again;

  /// Convert to database map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'vocabulary_id': vocabularyId,
      'rating': rating.value,
      'time_spent': timeSpent,
      'reviewed_at': reviewedAt.millisecondsSinceEpoch,
    };
  }

  /// Create from database map
  factory Review.fromMap(Map<String, dynamic> map) {
    return Review(
      id: map['id'] ?? '',
      vocabularyId: map['vocabulary_id'] ?? '',
      rating: Rating.fromInt(map['rating'] ?? 3),
      timeSpent: map['time_spent'] ?? 0,
      reviewedAt: DateTime.fromMillisecondsSinceEpoch(
        map['reviewed_at'] ?? DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  Review copyWith({
    String? id,
    String? vocabularyId,
    Rating? rating,
    int? timeSpent,
    DateTime? reviewedAt,
  }) {
    return Review(
      id: id ?? this.id,
      vocabularyId: vocabularyId ?? this.vocabularyId,
      rating: rating ?? this.rating,
      timeSpent: timeSpent ?? this.timeSpent,
      reviewedAt: reviewedAt ?? this.reviewedAt,
    );
  }
}
