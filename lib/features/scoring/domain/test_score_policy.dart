import '../../hexaiq/domain/hexaiq_models.dart';

class TestScorePolicy {
  const TestScorePolicy({
    required this.testType,
    required this.minIq,
    required this.maxIq,
    required this.maxDifficultyWeight,
    required this.useResponseTimeBonus,
  });

  final TestType testType;
  final int minIq;
  final int maxIq;
  final double maxDifficultyWeight;
  final bool useResponseTimeBonus;

  static TestScorePolicy forTestType(TestType type) {
    return switch (type) {
      TestType.quickIq => const TestScorePolicy(
        testType: TestType.quickIq,
        minIq: 70,
        maxIq: 130,
        maxDifficultyWeight: 1.2,
        useResponseTimeBonus: false,
      ),
      TestType.basic => const TestScorePolicy(
        testType: TestType.basic,
        minIq: 60,
        maxIq: 145,
        maxDifficultyWeight: 1.4,
        useResponseTimeBonus: false,
      ),
      TestType.advanced => const TestScorePolicy(
        testType: TestType.advanced,
        minIq: 55,
        maxIq: 155,
        maxDifficultyWeight: 1.6,
        useResponseTimeBonus: true,
      ),
      TestType.professional => const TestScorePolicy(
        testType: TestType.professional,
        minIq: 50,
        maxIq: 165,
        maxDifficultyWeight: 1.8,
        useResponseTimeBonus: true,
      ),
    };
  }
}
