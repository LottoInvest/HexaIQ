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
    const questionCount = 5;
    final levelOffset = switch (testType) {
      TestType.basic => 0,
      TestType.advanced => 1,
      TestType.professional => 1,
    };
    final testId =
        'mock-${profile.id}-${testType.name}-${DateTime.now().millisecondsSinceEpoch}';
    final questions = <GeneratedQuestionDto>[];
    for (var index = 0; index < questionCount; index++) {
      questions.add(
        engine.generate(
          GenerateQuestionRequest(
            profileId: profile.id,
            testId: testId,
            domain: QuestionDomain.numerical,
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
    return questions.take(questionCount).toList(growable: false);
  }
}
