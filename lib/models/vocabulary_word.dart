import 'dart:convert';
import 'enums.dart';

/// Represents an example sentence for a vocabulary word
class ExampleSentence {
  final String japanese;
  final String reading;
  final String english;

  const ExampleSentence({
    required this.japanese,
    required this.reading,
    required this.english,
  });

  Map<String, dynamic> toMap() {
    return {
      'japanese': japanese,
      'reading': reading,
      'english': english,
    };
  }

  factory ExampleSentence.fromMap(Map<String, dynamic> map) {
    return ExampleSentence(
      japanese: map['japanese'] ?? '',
      reading: map['reading'] ?? '',
      english: map['english'] ?? '',
    );
  }

  String toJson() => json.encode(toMap());

  factory ExampleSentence.fromJson(String source) =>
      ExampleSentence.fromMap(json.decode(source));
}

/// Represents a vocabulary word from JLPT
class VocabularyWord {
  final String id;
  final String word;
  final String reading;
  final List<String> meanings;
  final JLPTLevel jlptLevel;
  final PartOfSpeech partOfSpeech;
  final List<ExampleSentence> exampleSentences;
  final int difficultyOrder;
  final DateTime createdAt;

  const VocabularyWord({
    required this.id,
    required this.word,
    required this.reading,
    required this.meanings,
    required this.jlptLevel,
    required this.partOfSpeech,
    required this.exampleSentences,
    required this.difficultyOrder,
    required this.createdAt,
  });

  /// Convert to database map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'word': word,
      'reading': reading,
      'meanings': json.encode(meanings),
      'jlpt_level': jlptLevel.value,
      'part_of_speech': partOfSpeech.value,
      'example_sentences': json.encode(
        exampleSentences.map((e) => e.toMap()).toList(),
      ),
      'difficulty_order': difficultyOrder,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }

  /// Create from database map
  factory VocabularyWord.fromMap(Map<String, dynamic> map) {
    return VocabularyWord(
      id: map['id'] ?? '',
      word: map['word'] ?? '',
      reading: map['reading'] ?? '',
      meanings: List<String>.from(json.decode(map['meanings'] ?? '[]')),
      jlptLevel: JLPTLevel.fromString(map['jlpt_level'] ?? 'N5'),
      partOfSpeech: PartOfSpeech.fromString(map['part_of_speech'] ?? 'noun'),
      exampleSentences: (json.decode(map['example_sentences'] ?? '[]') as List)
          .map((e) => ExampleSentence.fromMap(e))
          .toList(),
      difficultyOrder: map['difficulty_order'] ?? 0,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        map['created_at'] ?? DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  /// Create from JSON (for loading from assets)
  factory VocabularyWord.fromJson(Map<String, dynamic> json) {
    return VocabularyWord(
      id: json['id'] ?? '',
      word: json['word'] ?? '',
      reading: json['reading'] ?? '',
      meanings: List<String>.from(json['meanings'] ?? []),
      jlptLevel: JLPTLevel.fromString(json['jlpt_level'] ?? 'N5'),
      partOfSpeech: PartOfSpeech.fromString(json['part_of_speech'] ?? 'noun'),
      exampleSentences: (json['example_sentences'] as List? ?? [])
          .map((e) => ExampleSentence.fromMap(e as Map<String, dynamic>))
          .toList(),
      difficultyOrder: json['difficulty_order'] ?? 0,
      createdAt: DateTime.now(),
    );
  }

  VocabularyWord copyWith({
    String? id,
    String? word,
    String? reading,
    List<String>? meanings,
    JLPTLevel? jlptLevel,
    PartOfSpeech? partOfSpeech,
    List<ExampleSentence>? exampleSentences,
    int? difficultyOrder,
    DateTime? createdAt,
  }) {
    return VocabularyWord(
      id: id ?? this.id,
      word: word ?? this.word,
      reading: reading ?? this.reading,
      meanings: meanings ?? this.meanings,
      jlptLevel: jlptLevel ?? this.jlptLevel,
      partOfSpeech: partOfSpeech ?? this.partOfSpeech,
      exampleSentences: exampleSentences ?? this.exampleSentences,
      difficultyOrder: difficultyOrder ?? this.difficultyOrder,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
