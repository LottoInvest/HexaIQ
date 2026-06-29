import '../../hexaiq/domain/hexaiq_models.dart';
import '../../question_engine/domain/question_engine_models.dart';

abstract class QuestionEngineRepository {
  Future<GeneratedQuestionDto> generate({
    required UserProfile profile,
    required QuestionDomain domain,
    required String typeCode,
    required int level,
    int? seed,
  });

  Future<List<GeneratedQuestionDto>> generateBatch({
    required UserProfile profile,
    required QuestionDomain domain,
    required int level,
    required int count,
  });
}
