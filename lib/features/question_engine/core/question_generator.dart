import '../domain/question_engine_models.dart';

abstract class QuestionGenerator {
  QuestionDomain get domain;

  Set<String> get supportedTypeCodes;

  GeneratedQuestionDto generate(GenerateQuestionRequest request);
}
