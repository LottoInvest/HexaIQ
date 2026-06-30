import '../../../core/domain/intelligence_domain.dart';
import '../../item_bank/domain/item.dart';
import '../domain/question_engine_models.dart';

abstract class QuestionGenerator {
  IntelligenceDomain get domain;

  Set<String> get supportedTypeCodes;

  GeneratedQuestionDto generate(GenerateQuestionRequest request);

  Item generateItem(GenerateQuestionRequest request) {
    return Item.fromGeneratedQuestion(generate(request));
  }

  GeneratedQuestionDto generateFallback(GenerateQuestionRequest request) {
    return generate(request);
  }
}
