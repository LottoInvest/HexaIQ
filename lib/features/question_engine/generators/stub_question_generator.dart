import 'dart:math';

import '../../../core/domain/intelligence_domain.dart';
import '../core/question_generator.dart';
import '../domain/question_engine_models.dart';

class StubQuestionGenerator implements QuestionGenerator {
  const StubQuestionGenerator({required this.domain});

  @override
  final IntelligenceDomain domain;

  @override
  Set<String> get supportedTypeCodes => {
    for (var i = 1; i <= 20; i++)
      '${domain.generatorPrefix}${i.toString().padLeft(2, '0')}',
  };

  @override
  GeneratedQuestionDto generate(GenerateQuestionRequest request) {
    final typeCode = request.typeCode ?? '${domain.generatorPrefix}01';
    final rng = Random((request.seed ?? request.index) + typeCode.hashCode);
    final answer = '${domain.label} 준비 중';
    final choices = [answer, '보기 A', '보기 B', '보기 C']..shuffle(rng);
    return GeneratedQuestionDto.fromLegacyChoices(
      id: '${request.testId}-${domain.name}-$typeCode-${request.index}',
      domain: domain,
      typeCode: typeCode,
      level: request.level ?? 1,
      ageGroup: request.ageGroup,
      seed: request.seed ?? request.index,
      questionText: '${domain.label} 영역은 준비 중입니다.',
      choices: choices,
      answer: answer,
      explanation: '${domain.label} 영역은 현재 mock generator 상태입니다.',
      estimatedTimeSec: 20,
      metadata: QuestionMetadataDto(
        rule: '$typeCode-stub',
        difficultyFactors: const ['stub'],
        status: 'coming_soon',
        message: '${domain.label} 영역은 준비 중입니다.',
      ),
      variables: const {'stub': true},
      isStub: true,
    );
  }
}
