/// Enums for the language learning app

/// JLPT levels from easiest (N5) to hardest (N1)
enum JLPTLevel {
  N5('N5'),
  N4('N4'),
  N3('N3'),
  N2('N2'),
  N1('N1');

  final String value;
  const JLPTLevel(this.value);

  static JLPTLevel fromString(String value) {
    return JLPTLevel.values.firstWhere(
      (level) => level.value == value,
      orElse: () => JLPTLevel.N5,
    );
  }
}

/// Word learning status
enum WordStatus {
  unlearned('unlearned'),     // Never studied
  learning('learning'),       // Currently studying
  learned('learned'),         // Passed initial learning
  mastered('mastered');       // Consistently remembered

  final String value;
  const WordStatus(this.value);

  static WordStatus fromString(String value) {
    return WordStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => WordStatus.unlearned,
    );
  }
}

/// SRS card states (based on FSRS algorithm)
enum CardState {
  newCard('new'),             // Never reviewed
  learning('learning'),       // In initial learning phase
  review('review'),           // In review phase
  relearning('relearning');   // Re-learning after forgetting

  final String value;
  const CardState(this.value);

  static CardState fromString(String value) {
    return CardState.values.firstWhere(
      (state) => state.value == value,
      orElse: () => CardState.newCard,
    );
  }
}

/// User rating for SRS reviews
enum Rating {
  again(1),    // Complete failure, need to start over
  hard(2),     // Difficult to remember
  good(3),     // Correctly remembered
  easy(4);     // Very easy to remember

  final int value;
  const Rating(this.value);

  static Rating fromInt(int value) {
    return Rating.values.firstWhere(
      (rating) => rating.value == value,
      orElse: () => Rating.good,
    );
  }
}

/// Part of speech for vocabulary
enum PartOfSpeech {
  noun('noun'),
  verb('verb'),
  adjective('adjective'),
  adverb('adverb'),
  pronoun('pronoun'),
  particle('particle'),
  conjunction('conjunction'),
  interjection('interjection'),
  other('other');

  final String value;
  const PartOfSpeech(this.value);

  static PartOfSpeech fromString(String value) {
    return PartOfSpeech.values.firstWhere(
      (pos) => pos.value == value,
      orElse: () => PartOfSpeech.other,
    );
  }
}
