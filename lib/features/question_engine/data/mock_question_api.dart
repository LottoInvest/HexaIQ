import '../../../core/domain/intelligence_domain.dart';
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
  }) async {
    final levelOffset = switch (testType) {
      TestType.basic => 0,
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
    );
  }

  Future<List<GeneratedQuestionDto>> generateTestQuestions({
    required UserProfile profile,
    required TestType testType,
  }) async {
    const questionCount = 5;
    return generateQuestions(
      profile: profile,
      domain: IntelligenceDomain.numerical,
      count: questionCount,
      testType: testType,
    );
  }
}
