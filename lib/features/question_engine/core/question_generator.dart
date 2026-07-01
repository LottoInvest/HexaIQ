import '../../../core/domain/intelligence_domain.dart';
import '../../item_bank/domain/item.dart';
import '../domain/question_engine_models.dart';

abstract class QuestionGenerator {
  IntelligenceDomain get domain;

  Set<String> get supportedTypeCodes;

  QuestionDto generate(QuestionRequest request);

  Item generateItem(QuestionRequest request) {
    return Item.fromGeneratedQuestion(generate(request));
  }

  QuestionDto generateFallback(QuestionRequest request) {
    return generate(request);
  }
}
