import 'dart:math';

import '../core/question_generator.dart';
import '../domain/question_engine_models.dart';

class StubQuestionGenerator implements QuestionGenerator {
  const StubQuestionGenerator({
    required this.domain,
    required this.prefix,
    required this.label,
  });

  @override
  final QuestionDomain domain;

  final String prefix;
  final String label;

  @override
  Set<String> get supportedTypeCodes => {
    for (var i = 1; i <= 20; i++) '$prefix${i.toString().padLeft(2, '0')}',
  };

  @override
  GeneratedQuestionDto generate(GenerateQuestionRequest request) {
    final typeCode = request.typeCode ?? '${prefix}01';
    final rng = Random(request.seed ?? request.index + typeCode.hashCode);
    final choices = ['준비 중', '보기 A', '보기 B', '보기 C']..shuffle(rng);
    return GeneratedQuestionDto.fromLegacyChoices(
      id: '${request.testId}-${domain.name}-$typeCode-${request.index}',
      domain: domain,
      typeCode: typeCode,
      level: request.level ?? 1,
      ageGroup: request.ageGroup,
      seed: request.seed ?? request.index,
      questionText: '$label 영역은 준비 중입니다.',
      choices: choices,
      answer: '준비 중',
      explanation: '$label 영역은 현재 Stub 상태입니다.',
      estimatedTimeSec: 20,
      metadata: QuestionMetadataDto(
        rule: '$prefix-stub',
        difficultyFactors: const ['stub'],
        status: 'coming_soon',
        message: '$label 영역은 준비 중입니다.',
      ),
      variables: const {'stub': true},
      isStub: true,
    );
  }
}

class SpatialGenerator extends StubQuestionGenerator {
  const SpatialGenerator()
    : super(domain: QuestionDomain.spatial, prefix: 'SP', label: '공간지각');
}

class LogicalGenerator extends StubQuestionGenerator {
  const LogicalGenerator()
    : super(domain: QuestionDomain.logical, prefix: 'LG', label: '논리추론');
}

class VerbalGenerator extends StubQuestionGenerator {
  const VerbalGenerator()
    : super(domain: QuestionDomain.verbal, prefix: 'VB', label: '언어유추');
}

class MemoryGenerator extends StubQuestionGenerator {
  const MemoryGenerator()
    : super(domain: QuestionDomain.memory, prefix: 'WM', label: '작업기억');
}

class PatternGenerator extends StubQuestionGenerator {
  const PatternGenerator()
    : super(domain: QuestionDomain.pattern, prefix: 'PT', label: '추상패턴');
}
