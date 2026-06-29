import '../domain/question_engine_models.dart';
import 'question_generator.dart';

abstract class DomainGenerator implements QuestionGenerator {
  bool get isImplemented;

  GeneratedQuestionDto comingSoon(GenerateQuestionRequest request);
}
