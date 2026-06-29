import '../../hexaiq/domain/hexaiq_models.dart';
import '../core/question_engine.dart';
import '../domain/question_engine_models.dart';

class MockQuestionApi {
  MockQuestionApi({QuestionEngine? engine})
    : engine = engine ?? QuestionEngine();

  final QuestionEngine engine;

  Future<List<GeneratedQuestionDto>> generateTestQuestions({
    required UserProfile profile,
    required TestType testType,
  }) async {
    final perDomain = switch (testType) {
      TestType.basic => 5,
      TestType.advanced => 20,
      TestType.professional => 40,
    };
    final levelOffset = switch (testType) {
      TestType.basic => 0,
      TestType.advanced => 1,
      TestType.professional => 1,
    };
    final testId =
        'mock-${profile.id}-${testType.name}-${DateTime.now().millisecondsSinceEpoch}';
    final questions = <GeneratedQuestionDto>[];
    for (final domain in QuestionDomain.values) {
      for (var index = 0; index < perDomain; index++) {
        questions.add(
          engine.generate(
            GenerateQuestionRequest(
              profileId: profile.id,
              testId: testId,
              domain: domain,
              ageGroup: profile.ageGroup,
              index: index,
              level:
                  engine.difficultyManager.resolveLevel(
                    ageGroup: profile.ageGroup,
                    requestedLevel: null,
                    testTypeOffset: levelOffset,
                  ) +
                  (index % 3) -
                  1,
            ),
          ),
        );
      }
    }
    return questions;
  }
}
