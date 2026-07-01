import '../../../core/domain/intelligence_domain.dart';
import '../../../core/domain/question_difficulty.dart';
import '../../hexaiq/domain/hexaiq_models.dart';
import '../core/question_engine.dart';
import '../domain/question_engine_models.dart';

class MockQuestionApi {
  MockQuestionApi({QuestionEngine? engine})
    : engine = engine ?? QuestionEngine();

  final QuestionEngine engine;

  Future<List<GeneratedQuestionDto>> generateQuestions({
    required UserProfile profile,
    required IntelligenceDomain domain,
    required int count,
    TestType testType = TestType.basic,
    QuestionDifficulty difficulty = QuestionDifficulty.normal,
  }) async {
    final levelOffset = switch (testType) {
      TestType.basic => 0,
      TestType.quickIq => 0,
      TestType.advanced => 1,
      TestType.professional => 1,
    };
    final testId =
        'mock-${profile.id}-${domain.name}-${testType.name}-${DateTime.now().millisecondsSinceEpoch}';
    final level = engine.difficultyManager.resolveLevel(
      ageGroup: profile.ageGroup,
      requestedLevel: null,
      testTypeOffset: levelOffset,
    );
    return engine.generateDomainBatch(
      profileId: profile.id,
      testId: testId,
      domain: domain,
      ageGroup: profile.ageGroup,
      count: count,
      level: level,
      difficulty: difficulty,
    );
  }

  Future<List<GeneratedQuestionDto>> generateTestQuestions({
    required UserProfile profile,
    required TestType testType,
  }) async {
    final questionCount = switch (testType) {
      TestType.basic => 30,
      TestType.quickIq => 60,
      TestType.advanced => 90,
      TestType.professional => 120,
    };
    final levelOffset = switch (testType) {
      TestType.advanced || TestType.professional => 1,
      _ => 0,
    };
    final level = engine.difficultyManager.resolveLevel(
      ageGroup: profile.ageGroup,
      requestedLevel: null,
      testTypeOffset: levelOffset,
    );
    final baseSeed = DateTime.now().millisecondsSinceEpoch & 0x7fffffff;
    final generated = <GeneratedQuestionDto>[];
    for (var index = 0; index < questionCount; index++) {
      final domain = _domainForIndex(testType, index);
      generated.add(
        engine.generateOne(
          seed: baseSeed + index * 1009,
          domain: domain,
          difficulty: QuestionDifficulty.normal,
          profileId: profile.id,
          testId: 'mock-${profile.id}-${testType.name}-$baseSeed',
          ageGroup: profile.ageGroup,
          index: index,
          level: level,
        ),
      );
    }
    return generated;
  }

  IntelligenceDomain _domainForIndex(TestType testType, int index) {
    final domains = switch (testType) {
      TestType.quickIq => IntelligenceDomain.values,
      _ => IntelligenceDomain.values,
    };
    final perDomain = switch (testType) {
      TestType.basic => 5,
      TestType.quickIq => 10,
      TestType.advanced => 15,
      TestType.professional => 20,
    };
    return domains[(index ~/ perDomain).clamp(0, domains.length - 1)];
  }
}
