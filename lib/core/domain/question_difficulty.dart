enum QuestionDifficulty { veryEasy, easy, normal, hard, veryHard }

extension QuestionDifficultyInfo on QuestionDifficulty {
  String get labelKo {
    return switch (this) {
      QuestionDifficulty.veryEasy => '매우 쉬움',
      QuestionDifficulty.easy => '쉬움',
      QuestionDifficulty.normal => '보통',
      QuestionDifficulty.hard => '어려움',
      QuestionDifficulty.veryHard => '매우 어려움',
    };
  }

  String get label {
    return switch (this) {
      QuestionDifficulty.veryEasy => 'Very Easy',
      QuestionDifficulty.easy => 'Easy',
      QuestionDifficulty.normal => 'Normal',
      QuestionDifficulty.hard => 'Hard',
      QuestionDifficulty.veryHard => 'Very Hard',
    };
  }

  int get level {
    return switch (this) {
      QuestionDifficulty.veryEasy => 1,
      QuestionDifficulty.easy => 2,
      QuestionDifficulty.normal => 3,
      QuestionDifficulty.hard => 4,
      QuestionDifficulty.veryHard => 5,
    };
  }

  double get weight {
    return switch (this) {
      QuestionDifficulty.veryEasy => 0.6,
      QuestionDifficulty.easy => 0.8,
      QuestionDifficulty.normal => 1,
      QuestionDifficulty.hard => 1.2,
      QuestionDifficulty.veryHard => 1.4,
    };
  }

  QuestionDifficulty shift(int delta) {
    final values = QuestionDifficulty.values;
    final nextIndex = (index + delta).clamp(0, values.length - 1);
    return values[nextIndex];
  }
}
