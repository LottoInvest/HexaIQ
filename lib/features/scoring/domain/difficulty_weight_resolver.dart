import '../../hexaiq/domain/hexaiq_models.dart';
import '../../pattern_grid/domain/pattern_difficulty.dart';
import 'test_score_policy.dart';

class DifficultyWeightResolver {
  const DifficultyWeightResolver();

  double weightFor(PatternDifficulty difficulty, TestType testType) {
    final base = switch (difficulty) {
      PatternDifficulty.easy => 1.0,
      PatternDifficulty.normal => 1.2,
      PatternDifficulty.hard => 1.5,
      PatternDifficulty.expert => 1.8,
    };
    final policy = TestScorePolicy.forTestType(testType);
    return base.clamp(1.0, policy.maxDifficultyWeight).toDouble();
  }
}
