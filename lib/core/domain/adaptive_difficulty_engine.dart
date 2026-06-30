import 'package:flutter/foundation.dart';

import 'difficulty_profile.dart';
import 'question_difficulty.dart';

class AdaptiveDifficultyEngine {
  const AdaptiveDifficultyEngine();

  DifficultyProfile update({
    required DifficultyProfile profile,
    required bool isCorrect,
  }) {
    return recordAnswer(profile: profile, isCorrect: isCorrect);
  }

  DifficultyProfile recordAnswer({
    required DifficultyProfile profile,
    required bool isCorrect,
  }) {
    final currentDifficulty = profile.currentDifficulty;
    final correctStreak = isCorrect ? profile.correctStreak + 1 : 0;
    final wrongStreak = isCorrect ? 0 : profile.wrongStreak + 1;
    var nextDifficulty = currentDifficulty;
    var nextCorrectStreak = correctStreak;
    var nextWrongStreak = wrongStreak;

    if (correctStreak >= 2) {
      nextDifficulty = nextDifficulty.shift(1);
      nextCorrectStreak = 0;
      nextWrongStreak = 0;
    }

    if (wrongStreak >= 2) {
      nextDifficulty = nextDifficulty.shift(-1);
      nextCorrectStreak = 0;
      nextWrongStreak = 0;
    }

    debugPrint(
      '[AdaptiveDifficulty] current=${currentDifficulty.name} '
      'correctStreak=$correctStreak wrongStreak=$wrongStreak '
      'next=${nextDifficulty.name}',
    );

    return DifficultyProfile(
      currentDifficulty: nextDifficulty,
      correctStreak: nextCorrectStreak,
      wrongStreak: nextWrongStreak,
      history: [...profile.history, nextDifficulty],
    );
  }

  QuestionDifficulty recommend(DifficultyProfile profile) {
    return profile.currentDifficulty;
  }
}
