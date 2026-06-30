import '../../../../core/domain/intelligence_domain.dart';
import '../stub_question_generator.dart';

class ProcessingGenerator extends StubQuestionGenerator {
  const ProcessingGenerator() : super(domain: IntelligenceDomain.processing);
}
