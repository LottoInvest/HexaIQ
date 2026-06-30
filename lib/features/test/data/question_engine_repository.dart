import '../../../core/domain/intelligence_domain.dart';
import '../../../core/domain/question_difficulty.dart';
import '../../hexaiq/domain/hexaiq_models.dart';
import '../../question_engine/domain/question_engine_models.dart';

abstract class QuestionEngineRepository {
  Future<GeneratedQuestionDto> generate({
    required UserProfile profile,
    required IntelligenceDomain domain,
    required String typeCode,
    required int level,
    int? seed,
    QuestionDifficulty difficulty = QuestionDifficulty.normal,
  });

  Future<List<GeneratedQuestionDto>> generateBatch({
    required UserProfile profile,
    required IntelligenceDomain domain,
    required int level,
    required int count,
    QuestionDifficulty difficulty = QuestionDifficulty.normal,
  });
}
