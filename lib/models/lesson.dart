import 'dart:convert';
import 'enums.dart';

/// Represents a lesson containing a set of vocabulary words
class Lesson {
  final String id;
  final JLPTLevel jlptLevel;
  final List<String> vocabularyIds;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final DateTime createdAt;

  const Lesson({
    required this.id,
    required this.jlptLevel,
    required this.vocabularyIds,
    this.startedAt,
    this.completedAt,
    required this.createdAt,
  });

  /// Check if lesson is completed
  bool get isCompleted => completedAt != null;

  /// Check if lesson is in progress
  bool get isInProgress => startedAt != null && completedAt == null;

  /// Check if lesson is not started
  bool get isNotStarted => startedAt == null;

  /// Get lesson duration if completed
  Duration? get duration {
    if (startedAt == null || completedAt == null) return null;
    return completedAt!.difference(startedAt!);
  }

  /// Convert to database map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'jlpt_level': jlptLevel.value,
      'vocabulary_ids': json.encode(vocabularyIds),
      'started_at': startedAt?.millisecondsSinceEpoch,
      'completed_at': completedAt?.millisecondsSinceEpoch,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }

  /// Create from database map
  factory Lesson.fromMap(Map<String, dynamic> map) {
    return Lesson(
      id: map['id'] ?? '',
      jlptLevel: JLPTLevel.fromString(map['jlpt_level'] ?? 'N5'),
      vocabularyIds: List<String>.from(json.decode(map['vocabulary_ids'] ?? '[]')),
      startedAt: map['started_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['started_at'])
          : null,
      completedAt: map['completed_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['completed_at'])
          : null,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        map['created_at'] ?? DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  Lesson copyWith({
    String? id,
    JLPTLevel? jlptLevel,
    List<String>? vocabularyIds,
    DateTime? startedAt,
    DateTime? completedAt,
    DateTime? createdAt,
  }) {
    return Lesson(
      id: id ?? this.id,
      jlptLevel: jlptLevel ?? this.jlptLevel,
      vocabularyIds: vocabularyIds ?? this.vocabularyIds,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
