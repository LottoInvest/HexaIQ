import 'package:flutter_test/flutter_test.dart';
import 'package:hexaiq_app/core/domain/question_difficulty.dart';
import 'package:hexaiq_app/features/question_engine/core/adaptive_difficulty_engine.dart';
import 'package:hexaiq_app/features/question_engine/domain/difficulty_profile.dart';

void main() {
  test('QuestionDifficulty exposes labels, levels, and weights', () {
    expect(QuestionDifficulty.veryEasy.label, 'Very Easy');
    expect(QuestionDifficulty.normal.labelKo, '보통');
    expect(QuestionDifficulty.normal.level, 3);
    expect(QuestionDifficulty.hard.weight, 1.2);
    expect(QuestionDifficulty.normal.shift(1), QuestionDifficulty.hard);
    expect(QuestionDifficulty.veryHard.shift(1), QuestionDifficulty.veryHard);
    expect(QuestionDifficulty.veryEasy.shift(-1), QuestionDifficulty.veryEasy);
  });

  test(
    'DifficultyProfile initial and copyWith keep immutable state updates',
    () {
      final profile = DifficultyProfile.initial();
      final updated = profile.copyWith(
        currentDifficulty: QuestionDifficulty.hard,
        correctStreak: 1,
        history: const [QuestionDifficulty.normal],
      );

      expect(profile.currentDifficulty, QuestionDifficulty.normal);
      expect(profile.history, isEmpty);
      expect(updated.currentDifficulty, QuestionDifficulty.hard);
      expect(updated.correctStreak, 1);
      expect(updated.wrongStreak, 0);
      expect(updated.history, const [QuestionDifficulty.normal]);
    },
  );

  test('OO raises difficulty after two correct answers', () {
    const engine = AdaptiveDifficultyEngine();
    var profile = const DifficultyProfile();

    profile = engine.recordAnswer(profile: profile, isCorrect: true);
    profile = engine.recordAnswer(profile: profile, isCorrect: true);

    expect(profile.currentDifficulty, QuestionDifficulty.hard);
    expect(profile.correctStreak, 0);
    expect(profile.wrongStreak, 0);
    expect(profile.history.last, QuestionDifficulty.hard);
  });

  test('XX lowers difficulty after two wrong answers', () {
    const engine = AdaptiveDifficultyEngine();
    var profile = const DifficultyProfile();

    profile = engine.recordAnswer(profile: profile, isCorrect: false);
    profile = engine.recordAnswer(profile: profile, isCorrect: false);

    expect(profile.currentDifficulty, QuestionDifficulty.easy);
    expect(profile.correctStreak, 0);
    expect(profile.wrongStreak, 0);
  });

  test('Adaptive engine does not move below veryEasy', () {
    const engine = AdaptiveDifficultyEngine();
    var profile = const DifficultyProfile(
      currentDifficulty: QuestionDifficulty.veryEasy,
      wrongStreak: 1,
    );

    profile = engine.update(profile: profile, isCorrect: false);

    expect(profile.currentDifficulty, QuestionDifficulty.veryEasy);
  });

  test('Adaptive engine does not move above veryHard', () {
    const engine = AdaptiveDifficultyEngine();
    var profile = const DifficultyProfile(
      currentDifficulty: QuestionDifficulty.veryHard,
      correctStreak: 1,
    );

    profile = engine.update(profile: profile, isCorrect: true);

    expect(profile.currentDifficulty, QuestionDifficulty.veryHard);
  });

  test('OX keeps difficulty stable', () {
    const engine = AdaptiveDifficultyEngine();
    var profile = const DifficultyProfile();

    profile = engine.recordAnswer(profile: profile, isCorrect: true);
    profile = engine.recordAnswer(profile: profile, isCorrect: false);

    expect(profile.currentDifficulty, QuestionDifficulty.normal);
    expect(profile.correctStreak, 0);
    expect(profile.wrongStreak, 1);
  });

  test('XO keeps difficulty stable', () {
    const engine = AdaptiveDifficultyEngine();
    var profile = const DifficultyProfile();

    profile = engine.recordAnswer(profile: profile, isCorrect: false);
    profile = engine.recordAnswer(profile: profile, isCorrect: true);

    expect(profile.currentDifficulty, QuestionDifficulty.normal);
    expect(profile.correctStreak, 1);
    expect(profile.wrongStreak, 0);
  });
}
