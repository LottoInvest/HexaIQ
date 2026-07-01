import 'dart:math';

import '../../../core/domain/intelligence_domain.dart';
import '../../item_bank/domain/item.dart';
import '../core/question_generator.dart';
import '../domain/question_engine_models.dart';

typedef DomainTemplateBuilder =
    DomainQuestionTemplate Function(Random rng, int variant, int level);

class DomainQuestionTemplate {
  const DomainQuestionTemplate({
    required this.questionText,
    required this.answer,
    required this.distractors,
    required this.ruleName,
    required this.hint,
    required this.explanation,
    String? solution,
    String? solutionExplanation,
    this.factors = const [],
    this.variables = const {},
    this.estimatedTimeSec,
    this.stimulus,
    this.stimulusDuration,
    this.requiresMemoryPhase = false,
    this.timeLimit,
    this.reactionScore,
  }) : solution = solution ?? answer,
       solutionExplanation = solutionExplanation ?? explanation;

  final String questionText;
  final String answer;
  final List<String> distractors;
  final String ruleName;
  final String hint;
  final String explanation;
  final String solution;
  final String solutionExplanation;
  final List<String> factors;
  final Map<String, Object?> variables;
  final int? estimatedTimeSec;
  final String? stimulus;
  final Duration? stimulusDuration;
  final bool requiresMemoryPhase;
  final Duration? timeLimit;
  final double? reactionScore;
}

class TemplateQuestionGenerator implements QuestionGenerator {
  const TemplateQuestionGenerator({
    required this.domain,
    required this.typeCodes,
    required this.builders,
  });

  @override
  final IntelligenceDomain domain;
  final List<String> typeCodes;
  final Map<String, DomainTemplateBuilder> builders;

  @override
  Set<String> get supportedTypeCodes => typeCodes.toSet();

  @override
  GeneratedQuestionDto generate(GenerateQuestionRequest request) {
    final typeCode =
        request.typeCode ?? typeCodes[request.index % typeCodes.length];
    final builder = builders[typeCode];
    if (builder == null) {
      throw ArgumentError('Unsupported ${domain.name} typeCode: $typeCode');
    }
    final level = request.level ?? 1;
    final seed = request.seed ?? request.index;
    final rng = Random(seed + typeCode.hashCode + domain.index * 1009);
    final variant = (request.index + seed.abs()) % 97;
    final template = builder(rng, variant, level);
    final choices = _choices(template.answer, template.distractors, rng);
    return GeneratedQuestionDto.fromLegacyChoices(
      id: '${request.testId}-$typeCode-$seed-${request.index}',
      domain: domain,
      typeCode: typeCode,
      level: level,
      ageGroup: request.ageGroup,
      seed: seed,
      questionText: template.questionText,
      choices: choices,
      answer: template.answer,
      explanation: template.explanation,
      estimatedTimeSec: template.estimatedTimeSec ?? (12 + level * 4),
      difficulty: request.difficulty,
      hint: template.hint,
      ruleName: template.ruleName,
      solution: template.solution,
      solutionExplanation: template.solutionExplanation,
      stimulus: template.stimulus,
      stimulusDuration: template.stimulusDuration,
      requiresMemoryPhase: template.requiresMemoryPhase,
      timeLimit: template.timeLimit,
      reactionScore: template.reactionScore,
      metadata: QuestionMetadataDto(
        rule: typeCode,
        ruleName: template.ruleName,
        difficultyFactors: [
          'level_$level',
          'difficulty_${request.difficulty.name}',
          ...template.factors,
        ],
      ),
      variables: {
        ...template.variables,
        'ruleName': template.ruleName,
        'solution': template.solution,
        'solutionExplanation': template.solutionExplanation,
      },
    );
  }

  @override
  Item generateItem(GenerateQuestionRequest request) {
    return Item.fromGeneratedQuestion(generate(request));
  }

  @override
  GeneratedQuestionDto generateFallback(GenerateQuestionRequest request) {
    return generate(request.copyWith(typeCode: typeCodes.first));
  }

  List<String> _choices(String answer, List<String> distractors, Random rng) {
    final values = <String>[answer];
    for (final distractor in distractors) {
      if (distractor != answer && !values.contains(distractor)) {
        values.add(distractor);
      }
      if (values.length == 4) {
        break;
      }
    }
    var suffix = 1;
    while (values.length < 4) {
      final candidate = '$answer ${suffix + 1}';
      if (!values.contains(candidate)) {
        values.add(candidate);
      }
      suffix += 1;
    }
    values.shuffle(rng);
    return values;
  }
}
