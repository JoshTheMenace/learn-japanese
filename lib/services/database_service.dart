import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/vocabulary_word.dart';
import '../models/user_progress.dart';
import '../models/srs_card.dart';
import '../models/lesson.dart';
import '../models/review.dart';

/// Database service for managing SQLite database
/// Singleton pattern to ensure only one instance exists
class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static Database? _database;

  factory DatabaseService() => _instance;

  DatabaseService._internal();

  /// Get database instance
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Initialize database
  Future<Database> _initDatabase() async {
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, 'japanese_learning.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// Create database tables
  Future<void> _onCreate(Database db, int version) async {
    // Vocabulary table
    await db.execute('''
      CREATE TABLE vocabulary (
        id TEXT PRIMARY KEY,
        word TEXT NOT NULL,
        reading TEXT NOT NULL,
        meanings TEXT NOT NULL,
        jlpt_level TEXT NOT NULL,
        part_of_speech TEXT,
        example_sentences TEXT,
        difficulty_order INTEGER,
        created_at INTEGER NOT NULL
      )
    ''');

    // User progress table
    await db.execute('''
      CREATE TABLE user_progress (
        id TEXT PRIMARY KEY,
        vocabulary_id TEXT NOT NULL,
        status TEXT NOT NULL,
        first_studied_at INTEGER,
        last_reviewed_at INTEGER,
        review_count INTEGER DEFAULT 0,
        correct_count INTEGER DEFAULT 0,
        created_at INTEGER NOT NULL,
        FOREIGN KEY (vocabulary_id) REFERENCES vocabulary(id)
      )
    ''');

    // SRS cards table
    await db.execute('''
      CREATE TABLE srs_cards (
        id TEXT PRIMARY KEY,
        vocabulary_id TEXT NOT NULL,
        state TEXT NOT NULL,
        stability REAL,
        difficulty REAL,
        due_date INTEGER NOT NULL,
        elapsed_days INTEGER DEFAULT 0,
        scheduled_days INTEGER DEFAULT 0,
        reps INTEGER DEFAULT 0,
        lapses INTEGER DEFAULT 0,
        last_review INTEGER,
        created_at INTEGER NOT NULL,
        FOREIGN KEY (vocabulary_id) REFERENCES vocabulary(id)
      )
    ''');

    // Lessons table
    await db.execute('''
      CREATE TABLE lessons (
        id TEXT PRIMARY KEY,
        jlpt_level TEXT NOT NULL,
        vocabulary_ids TEXT NOT NULL,
        started_at INTEGER,
        completed_at INTEGER,
        created_at INTEGER NOT NULL
      )
    ''');

    // Reviews table
    await db.execute('''
      CREATE TABLE reviews (
        id TEXT PRIMARY KEY,
        vocabulary_id TEXT NOT NULL,
        rating INTEGER NOT NULL,
        time_spent INTEGER,
        reviewed_at INTEGER NOT NULL,
        FOREIGN KEY (vocabulary_id) REFERENCES vocabulary(id)
      )
    ''');

    // User settings table
    await db.execute('''
      CREATE TABLE user_settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');

    // Create indexes for better query performance
    await db.execute('CREATE INDEX idx_vocabulary_level ON vocabulary(jlpt_level)');
    await db.execute('CREATE INDEX idx_progress_vocab ON user_progress(vocabulary_id)');
    await db.execute('CREATE INDEX idx_srs_due ON srs_cards(due_date)');
    await db.execute('CREATE INDEX idx_srs_vocab ON srs_cards(vocabulary_id)');

    print('Database tables created successfully');
  }

  /// Handle database upgrades
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Handle database schema migrations here
    // For now, we only have version 1
  }

  /// Seed database with JLPT vocabulary data
  Future<void> seedVocabulary() async {
    final db = await database;

    // Check if vocabulary already exists
    final count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM vocabulary'),
    );

    if (count != null && count > 0) {
      print('Vocabulary already seeded');
      return;
    }

    try {
      // Load JSON data from assets
      final jsonString = await rootBundle.loadString(
        'assets/vocabulary/jlpt_n5.json',
      );
      final List<dynamic> jsonData = json.decode(jsonString);

      // Insert vocabulary words
      final batch = db.batch();
      for (var item in jsonData) {
        final word = VocabularyWord.fromJson(item);
        batch.insert('vocabulary', word.toMap());
      }

      await batch.commit(noResult: true);
      print('Successfully seeded ${jsonData.length} vocabulary words');
    } catch (e) {
      print('Error seeding vocabulary: $e');
    }
  }

  /// Vocabulary CRUD operations
  Future<int> insertVocabulary(VocabularyWord word) async {
    final db = await database;
    return await db.insert('vocabulary', word.toMap());
  }

  Future<List<VocabularyWord>> getAllVocabulary({String? level}) async {
    final db = await database;
    final List<Map<String, dynamic>> maps;

    if (level != null) {
      maps = await db.query(
        'vocabulary',
        where: 'jlpt_level = ?',
        whereArgs: [level],
        orderBy: 'difficulty_order ASC',
      );
    } else {
      maps = await db.query(
        'vocabulary',
        orderBy: 'difficulty_order ASC',
      );
    }

    return maps.map((map) => VocabularyWord.fromMap(map)).toList();
  }

  Future<VocabularyWord?> getVocabularyById(String id) async {
    final db = await database;
    final maps = await db.query(
      'vocabulary',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;
    return VocabularyWord.fromMap(maps.first);
  }

  /// User Progress CRUD operations
  Future<int> insertUserProgress(UserProgress progress) async {
    final db = await database;
    return await db.insert('user_progress', progress.toMap());
  }

  Future<int> updateUserProgress(UserProgress progress) async {
    final db = await database;
    return await db.update(
      'user_progress',
      progress.toMap(),
      where: 'id = ?',
      whereArgs: [progress.id],
    );
  }

  Future<UserProgress?> getUserProgressByVocabId(String vocabId) async {
    final db = await database;
    final maps = await db.query(
      'user_progress',
      where: 'vocabulary_id = ?',
      whereArgs: [vocabId],
    );

    if (maps.isEmpty) return null;
    return UserProgress.fromMap(maps.first);
  }

  Future<List<UserProgress>> getAllUserProgress() async {
    final db = await database;
    final maps = await db.query('user_progress');
    return maps.map((map) => UserProgress.fromMap(map)).toList();
  }

  /// SRS Card CRUD operations
  Future<int> insertSRSCard(SRSCard card) async {
    final db = await database;
    return await db.insert('srs_cards', card.toMap());
  }

  Future<int> updateSRSCard(SRSCard card) async {
    final db = await database;
    return await db.update(
      'srs_cards',
      card.toMap(),
      where: 'id = ?',
      whereArgs: [card.id],
    );
  }

  Future<SRSCard?> getSRSCardByVocabId(String vocabId) async {
    final db = await database;
    final maps = await db.query(
      'srs_cards',
      where: 'vocabulary_id = ?',
      whereArgs: [vocabId],
    );

    if (maps.isEmpty) return null;
    return SRSCard.fromMap(maps.first);
  }

  Future<List<SRSCard>> getDueCards() async {
    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;
    final maps = await db.query(
      'srs_cards',
      where: 'due_date <= ?',
      whereArgs: [now],
      orderBy: 'due_date ASC',
    );

    return maps.map((map) => SRSCard.fromMap(map)).toList();
  }

  /// Lesson CRUD operations
  Future<int> insertLesson(Lesson lesson) async {
    final db = await database;
    return await db.insert('lessons', lesson.toMap());
  }

  Future<int> updateLesson(Lesson lesson) async {
    final db = await database;
    return await db.update(
      'lessons',
      lesson.toMap(),
      where: 'id = ?',
      whereArgs: [lesson.id],
    );
  }

  Future<List<Lesson>> getAllLessons({String? level}) async {
    final db = await database;
    final List<Map<String, dynamic>> maps;

    if (level != null) {
      maps = await db.query(
        'lessons',
        where: 'jlpt_level = ?',
        whereArgs: [level],
        orderBy: 'created_at DESC',
      );
    } else {
      maps = await db.query(
        'lessons',
        orderBy: 'created_at DESC',
      );
    }

    return maps.map((map) => Lesson.fromMap(map)).toList();
  }

  /// Review CRUD operations
  Future<int> insertReview(Review review) async {
    final db = await database;
    return await db.insert('reviews', review.toMap());
  }

  Future<List<Review>> getReviewsForVocabulary(String vocabId) async {
    final db = await database;
    final maps = await db.query(
      'reviews',
      where: 'vocabulary_id = ?',
      whereArgs: [vocabId],
      orderBy: 'reviewed_at DESC',
    );

    return maps.map((map) => Review.fromMap(map)).toList();
  }

  /// Settings operations
  Future<void> setSetting(String key, String value) async {
    final db = await database;
    await db.insert(
      'user_settings',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<String?> getSetting(String key) async {
    final db = await database;
    final maps = await db.query(
      'user_settings',
      where: 'key = ?',
      whereArgs: [key],
    );

    if (maps.isEmpty) return null;
    return maps.first['value'] as String?;
  }

  /// Utility methods
  Future<void> clearAllData() async {
    final db = await database;
    await db.delete('vocabulary');
    await db.delete('user_progress');
    await db.delete('srs_cards');
    await db.delete('lessons');
    await db.delete('reviews');
    await db.delete('user_settings');
  }

  /// Close database
  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}
