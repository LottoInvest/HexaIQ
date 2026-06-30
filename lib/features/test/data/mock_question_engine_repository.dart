import '../../hexaiq/domain/hexaiq_models.dart';
import '../../question_engine/question_engine.dart';
import 'question_engine_repository.dart';

class MockQuestionEngineRepository implements QuestionEngineRepository {
  MockQuestionEngineRepository({QuestionEngine? engine})
    : _engine = engine ?? QuestionEngine();

  final QuestionEngine _engine;

  @override
  Future<GeneratedQuestionDto> generate({
    required UserProfile profile,
    required IntelligenceDomain domain,
    required String typeCode,
    required int level,
    int? seed,
  }) async {
    return _engine.generate(
      GenerateQuestionRequest(
        profileId: profile.id,
        testId: 'mock-single',
        domain: domain,
        ageGroup: profile.ageGroup,
        index: 0,
        typeCode: typeCode,
        level: level,
        seed: seed,
      ),
    );
  }

  @override
  Future<List<GeneratedQuestionDto>> generateBatch({
    required UserProfile profile,
    required IntelligenceDomain domain,
    required int level,
    required int count,
  }) async {
    return [
      for (var index = 0; index < count; index++)
        _engine.generate(
          GenerateQuestionRequest(
            profileId: profile.id,
            testId: 'mock-batch',
            domain: domain,
            ageGroup: profile.ageGroup,
            index: index,
            level: level,
          ),
        ),
    ];
  }
}
