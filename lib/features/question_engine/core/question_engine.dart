import 'package:flutter/foundation.dart';

import '../../../core/domain/adaptive_difficulty_engine.dart';
import '../../../core/domain/difficulty_profile.dart';
import '../../../core/domain/intelligence_domain.dart';
import '../../../core/domain/question_difficulty.dart';
import '../domain/question_engine_models.dart';
import '../generators/numerical_generator.dart';
import 'age_mapper.dart';
import 'difficulty_manager.dart';
import 'generator_factory.dart';
import 'question_quality_validator.dart';
import 'question_validator.dart';
import 'seed_manager.dart';

class QuestionEngine {
  static const int maxValidationRetries = 20;

  QuestionEngine({
    GeneratorFactory? generatorFactory,
    AgeMapper? ageMapper,
    DifficultyManager? difficultyManager,
    SeedManager? seedManager,
    QuestionValidator? validator,
    QuestionQualityValidator? qualityValidator,
    AdaptiveDifficultyEngine? adaptiveDifficultyEngine,
  }) : ageMapper = ageMapper ?? AgeMapper(),
       seedManager = seedManager ?? SeedManager(),
       validator = validator ?? const QuestionValidator(),
       generatorFactory = generatorFactory ?? GeneratorFactory(),
       difficultyManager =
           difficultyManager ?? DifficultyManager(ageMapper ?? AgeMapper()),
       adaptiveDifficultyEngine =
           adaptiveDifficultyEngine ?? const AdaptiveDifficultyEngine(),
       qualityValidator =
           qualityValidator ??
           QuestionQualityValidator(
             ageMapper: ageMapper ?? AgeMapper(),
             difficultyManager:
                 difficultyManager ??
                 DifficultyManager(ageMapper ?? AgeMapper()),
           );

  final GeneratorFactory generatorFactory;
  final AgeMapper ageMapper;
  final DifficultyManager difficultyManager;
  final AdaptiveDifficultyEngine adaptiveDifficultyEngine;
  final SeedManager seedManager;
  final QuestionValidator validator;
  final QuestionQualityValidator qualityValidator;

  GeneratedQuestionDto generate(GenerateQuestionRequest request) {
    final age = ageMapper.resolve(request.ageGroup);
    final level = difficultyManager.resolveLevel(
      ageGroup: age.code,
      requestedLevel: request.level,
    );
    final difficulty = adaptiveDifficultyEngine.recommend(
      request.difficultyProfile ??
          DifficultyProfile(currentDifficulty: request.difficulty),
    );
    final adaptiveLevel = _levelForDifficulty(level, difficulty);
    final generator = generatorFactory.generatorFor(request.domain);

    for (var attempt = 0; attempt < maxValidationRetries; attempt++) {
      final typeCode = _retryTypeCode(request, attempt);
      final seed =
          request.seed ??
          seedManager.createSeed(
            profileId: request.profileId,
            testId: request.testId,
            domain: request.domain,
            typeCode: typeCode,
            index: request.index,
            retry: attempt,
          );
      final normalized = GenerateQuestionRequest(
        profileId: request.profileId,
        testId: request.testId,
        domain: request.domain,
        ageGroup: age.code,
        index: request.index,
        typeCode: typeCode,
        level: adaptiveLevel,
        seed: request.seed == null ? seed : seed + attempt,
        difficulty: difficulty,
        difficultyProfile: request.difficultyProfile,
      );

      try {
        final question = generator.generate(normalized);
        validator.validate(question);
        final qualityResult = qualityValidator.validate(question);
        if (!qualityResult.isValid) {
          _logQuestionSnapshot(question);
          debugPrint(
            '[QuestionEngine] validation failed '
            'attempt=${attempt + 1}/$maxValidationRetries '
            'type=${question.typeCode} '
            'id=${question.id} '
            'seed=${question.seed} '
            'reason=${qualityResult.reason}',
          );
          continue;
        }
        seedManager.registerSignature(
          profileId: request.profileId,
          question: question.questionText,
          answer: question.answer,
        );
        return question;
      } on Object catch (error, stackTrace) {
        debugPrint(
          '[QuestionEngine] generation failed '
          'attempt=${attempt + 1}/$maxValidationRetries '
          'type=$typeCode '
          'seed=${normalized.seed} '
          'reason=$error',
        );
        debugPrint('[QuestionEngine] stackTrace=$stackTrace');
      }
    }

    debugPrint(
      '[QuestionEngine] using fallback NR01 '
      'type=${_defaultTypeCode(request)} '
      'seed=${request.seed ?? 0} '
      'reason=validation retries exhausted',
    );
    return _fallbackNr01(request, age.code, adaptiveLevel, difficulty);
  }

  List<GeneratedQuestionDto> generateDomainBatch({
    required String profileId,
    required String testId,
    required IntelligenceDomain domain,
    required String ageGroup,
    required int count,
    int? level,
    QuestionDifficulty difficulty = QuestionDifficulty.normal,
    DifficultyProfile? difficultyProfile,
  }) {
    return [
      for (var index = 0; index < count; index++)
        generate(
          GenerateQuestionRequest(
            profileId: profileId,
            testId: testId,
            domain: domain,
            ageGroup: ageGroup,
            index: index,
            level: level,
            difficulty: difficulty,
            difficultyProfile: difficultyProfile,
          ),
        ),
    ];
  }

  String _defaultTypeCode(GenerateQuestionRequest request) {
    if (request.domain == IntelligenceDomain.numerical) {
      return NumericalGenerator.typeCodes[request.index %
          NumericalGenerator.typeCodes.length];
    }
    final prefix = switch (request.domain) {
      IntelligenceDomain.numerical => 'NR',
      _ => request.domain.generatorPrefix,
    };
    return '$prefix${(request.index % 20 + 1).toString().padLeft(2, '0')}';
  }

  String _retryTypeCode(GenerateQuestionRequest request, int attempt) {
    if (attempt == 0 || request.typeCode != null) {
      return request.typeCode ?? _defaultTypeCode(request);
    }
    if (request.domain == IntelligenceDomain.numerical) {
      final index =
          (request.index + attempt) % NumericalGenerator.typeCodes.length;
      return NumericalGenerator.typeCodes[index];
    }
    final base = _defaultTypeCode(request);
    final prefix = base.substring(0, 2);
    return '$prefix${((request.index + attempt) % 20 + 1).toString().padLeft(2, '0')}';
  }

  void _logQuestionSnapshot(GeneratedQuestionDto question) {
    debugPrint(
      '[QuestionEngine] dto '
      'domain=${question.domain.name} '
      'type=${question.typeCode} '
      'id=${question.id} '
      'seed=${question.seed} '
      'level=${question.level} '
      'difficulty=${question.difficulty.name} '
      'answerKey=${question.answerKey} '
      'choices=${question.choices} '
      'questionText="${question.questionText}" '
      'explanation="${question.explanation}"',
    );
  }

  GeneratedQuestionDto _fallbackNr01(
    GenerateQuestionRequest request,
    String ageGroup,
    int level,
    QuestionDifficulty difficulty,
  ) {
    final seed =
        request.seed ??
        seedManager.createSeed(
          profileId: request.profileId,
          testId: request.testId,
          domain: IntelligenceDomain.numerical,
          typeCode: 'NR01',
          index: request.index,
        );
    final start = request.index + 2;
    final diff = 3;
    final terms = [start, start + diff, start + diff * 2, start + diff * 3];
    final answer = start + diff * 4;
    return GeneratedQuestionDto.fromLegacyChoices(
      id: '${request.testId}-fallback-NR01-$seed-${request.index}',
      domain: IntelligenceDomain.numerical,
      typeCode: 'NR01',
      level: level,
      ageGroup: ageGroup,
      seed: seed,
      questionText: 'Find the next number: ${terms.join(', ')}, ?',
      choices: [
        '$answer',
        '${answer + diff}',
        '${answer - diff}',
        '${answer + 1}',
      ],
      answer: '$answer',
      explanation:
          'Each term increases by $diff, so the next number is $answer.',
      estimatedTimeSec: difficultyManager.estimatedTimeSec(level),
      difficulty: difficulty,
      metadata: QuestionMetadataDto(
        rule: 'NR01-fallback',
        difficultyFactors: const ['arithmetic_sequence', 'fallback'],
        status: 'fallback',
        message: 'Generated after validation retries were exhausted.',
      ),
      variables: {'terms': terms, 'diff': diff, 'fallback': true},
    );
  }

  int _levelForDifficulty(int baseLevel, QuestionDifficulty difficulty) {
    final delta = (difficulty.level - QuestionDifficulty.normal.level) * 2;
    return difficultyManager.clamp(baseLevel + delta, 1, 10);
  }
}
