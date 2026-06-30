import '../../../core/domain/intelligence_domain.dart';
import '../../../core/domain/question_difficulty.dart';
import '../../hexaiq/domain/hexaiq_models.dart';
import '../../question_engine/domain/question_engine_models.dart';
import 'question_engine_repository.dart';

class ApiQuestionEngineRepository implements QuestionEngineRepository {
  const ApiQuestionEngineRepository();

  @override
  Future<GeneratedQuestionDto> generate({
    required UserProfile profile,
    required IntelligenceDomain domain,
    required String typeCode,
    required int level,
    int? seed,
    QuestionDifficulty difficulty = QuestionDifficulty.normal,
  }) {
    throw UnimplementedError(
      'FastAPI integration will call POST /api/v1/question-engine/generate.',
    );
  }

  @override
  Future<List<GeneratedQuestionDto>> generateBatch({
    required UserProfile profile,
    required IntelligenceDomain domain,
    required int level,
    required int count,
    QuestionDifficulty difficulty = QuestionDifficulty.normal,
  }) {
    throw UnimplementedError(
      'FastAPI integration will call POST /api/v1/question-engine/generate-batch.',
    );
  }
}
