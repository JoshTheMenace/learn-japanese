import 'package:uuid/uuid.dart';
import '../models/lesson.dart';
import '../models/vocabulary_word.dart';
import '../models/user_progress.dart';
import '../models/enums.dart';
import 'database_service.dart';

/// Service for managing lessons and learning progress
class LessonService {
  final DatabaseService _db = DatabaseService();
  final Uuid _uuid = const Uuid();

  /// Initialize database and create test lessons
  Future<void> initializeApp() async {
    // Seed vocabulary if not already done
    await _db.seedVocabulary();

    // Check if lessons exist
    final existingLessons = await _db.getAllLessons();
    if (existingLessons.isEmpty) {
      await _createTestLessons();
    }
  }

  /// Create test lessons from existing vocabulary
  Future<void> _createTestLessons() async {
    final allVocab = await _db.getAllVocabulary(level: 'N5');

    // Create lessons with 10 words each
    const wordsPerLesson = 10;
    final lessonCount = (allVocab.length / wordsPerLesson).ceil();

    for (int i = 0; i < lessonCount; i++) {
      final startIndex = i * wordsPerLesson;
      final endIndex = (startIndex + wordsPerLesson).clamp(0, allVocab.length);
      final lessonWords = allVocab.sublist(startIndex, endIndex);

      final lesson = Lesson(
        id: _uuid.v4(),
        jlptLevel: JLPTLevel.N5,
        vocabularyIds: lessonWords.map((w) => w.id).toList(),
        createdAt: DateTime.now(),
      );

      await _db.insertLesson(lesson);

      // Create initial user progress for each word
      for (var word in lessonWords) {
        final existingProgress = await _db.getUserProgressByVocabId(word.id);
        if (existingProgress == null) {
          final progress = UserProgress(
            id: _uuid.v4(),
            vocabularyId: word.id,
            status: WordStatus.unlearned,
            createdAt: DateTime.now(),
          );
          await _db.insertUserProgress(progress);
        }
      }
    }

    print('Created $lessonCount test lessons');
  }

  /// Get all lessons
  Future<List<Lesson>> getAllLessons({String? level}) async {
    return await _db.getAllLessons(level: level);
  }

  /// Get lesson with vocabulary words
  Future<LessonWithProgress> getLessonWithProgress(Lesson lesson) async {
    final words = <VocabularyWord>[];
    final progressMap = <String, UserProgress>{};

    for (var vocabId in lesson.vocabularyIds) {
      final word = await _db.getVocabularyById(vocabId);
      if (word != null) {
        words.add(word);

        final progress = await _db.getUserProgressByVocabId(vocabId);
        if (progress != null) {
          progressMap[vocabId] = progress;
        }
      }
    }

    return LessonWithProgress(
      lesson: lesson,
      words: words,
      progressMap: progressMap,
    );
  }

  /// Get next words to study in a lesson
  Future<List<VocabularyWord>> getNextWordsToStudy(
    Lesson lesson, {
    int count = 5,
  }) async {
    final words = <VocabularyWord>[];

    for (var vocabId in lesson.vocabularyIds) {
      final progress = await _db.getUserProgressByVocabId(vocabId);

      // Get words that are unlearned or learning (not mastered)
      if (progress == null ||
          progress.status == WordStatus.unlearned ||
          progress.status == WordStatus.learning) {
        final word = await _db.getVocabularyById(vocabId);
        if (word != null) {
          words.add(word);
          if (words.length >= count) break;
        }
      }
    }

    return words;
  }

  /// Mark lesson as started
  Future<void> startLesson(Lesson lesson) async {
    if (lesson.startedAt == null) {
      final updated = Lesson(
        id: lesson.id,
        jlptLevel: lesson.jlptLevel,
        vocabularyIds: lesson.vocabularyIds,
        startedAt: DateTime.now(),
        completedAt: lesson.completedAt,
        createdAt: lesson.createdAt,
      );
      await _db.updateLesson(updated);
    }
  }

  /// Update word progress
  Future<void> updateWordProgress(
    String vocabularyId,
    WordStatus newStatus,
  ) async {
    var progress = await _db.getUserProgressByVocabId(vocabularyId);

    if (progress == null) {
      // Create new progress
      progress = UserProgress(
        id: _uuid.v4(),
        vocabularyId: vocabularyId,
        status: newStatus,
        firstStudiedAt: DateTime.now(),
        lastReviewedAt: DateTime.now(),
        createdAt: DateTime.now(),
      );
      await _db.insertUserProgress(progress);
    } else {
      // Update existing progress
      final updated = UserProgress(
        id: progress.id,
        vocabularyId: progress.vocabularyId,
        status: newStatus,
        firstStudiedAt: progress.firstStudiedAt ?? DateTime.now(),
        lastReviewedAt: DateTime.now(),
        reviewCount: progress.reviewCount,
        correctCount: progress.correctCount,
        createdAt: progress.createdAt,
      );
      await _db.updateUserProgress(updated);
    }
  }
}

/// Helper class to combine lesson with progress data
class LessonWithProgress {
  final Lesson lesson;
  final List<VocabularyWord> words;
  final Map<String, UserProgress> progressMap;

  LessonWithProgress({
    required this.lesson,
    required this.words,
    required this.progressMap,
  });

  /// Get count of words by status
  int getWordCountByStatus(WordStatus status) {
    return progressMap.values.where((p) => p.status == status).length;
  }

  /// Get total words in lesson
  int get totalWords => words.length;

  /// Get words left to learn (unlearned + learning)
  int get wordsLeftToLearn {
    return progressMap.values.where((p) =>
      p.status == WordStatus.unlearned ||
      p.status == WordStatus.learning
    ).length;
  }

  /// Get learned words count (learned + mastered)
  int get learnedWordsCount {
    return progressMap.values.where((p) =>
      p.status == WordStatus.learned ||
      p.status == WordStatus.mastered
    ).length;
  }

  /// Get progress percentage (0-100)
  double get progressPercentage {
    if (totalWords == 0) return 0.0;
    return (learnedWordsCount / totalWords * 100);
  }

  /// Check if lesson is completed
  bool get isCompleted {
    return wordsLeftToLearn == 0;
  }

  /// Check if lesson is started
  bool get isStarted => lesson.startedAt != null;
}
