import '../../../../core/domain/intelligence_domain.dart';
import '../stub_question_generator.dart';

class MemoryGenerator extends StubQuestionGenerator {
  const MemoryGenerator() : super(domain: IntelligenceDomain.memory);
}
