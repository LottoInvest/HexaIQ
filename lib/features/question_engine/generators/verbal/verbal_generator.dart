import '../../../../core/domain/intelligence_domain.dart';
import '../stub_question_generator.dart';

class VerbalGenerator extends StubQuestionGenerator {
  const VerbalGenerator() : super(domain: IntelligenceDomain.verbal);
}
