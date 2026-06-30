import '../../../../core/domain/intelligence_domain.dart';
import '../stub_question_generator.dart';

class LogicGenerator extends StubQuestionGenerator {
  const LogicGenerator() : super(domain: IntelligenceDomain.logic);
}
