import 'question_difficulty.dart';

class DifficultyProfile {
  const DifficultyProfile({
    this.currentDifficulty = QuestionDifficulty.normal,
    this.correctStreak = 0,
    this.wrongStreak = 0,
    this.history = const [],
  });

  factory DifficultyProfile.initial() {
    return const DifficultyProfile();
  }

  final QuestionDifficulty currentDifficulty;
  final int correctStreak;
  final int wrongStreak;
  final List<QuestionDifficulty> history;

  DifficultyProfile copyWith({
    QuestionDifficulty? currentDifficulty,
    int? correctStreak,
    int? wrongStreak,
    List<QuestionDifficulty>? history,
  }) {
    return DifficultyProfile(
      currentDifficulty: currentDifficulty ?? this.currentDifficulty,
      correctStreak: correctStreak ?? this.correctStreak,
      wrongStreak: wrongStreak ?? this.wrongStreak,
      history: history ?? this.history,
    );
  }
}
