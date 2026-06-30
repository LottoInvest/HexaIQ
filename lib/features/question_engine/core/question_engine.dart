import 'package:flutter/foundation.dart';

import '../../../core/domain/adaptive_difficulty_engine.dart';
import '../../../core/domain/difficulty_profile.dart';
import '../../../core/domain/intelligence_domain.dart';
import '../../../core/domain/question_difficulty.dart';
import '../../item_bank/data/in_memory_item_bank_repository.dart';
import '../../item_bank/data/exposure_repository.dart';
import '../../item_bank/data/in_memory_exposure_repository.dart';
import '../../item_bank/data/item_bank_repository.dart';
import '../../item_bank/domain/default_item_selection_strategy.dart';
import '../../item_bank/domain/item.dart';
import '../../item_bank/domain/item_selection_strategy.dart';
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
    ItemBankRepository? itemBankRepository,
    ItemSelectionStrategy? itemSelectionStrategy,
    ExposureRepository? exposureRepository,
  }) : ageMapper = ageMapper ?? AgeMapper(),
       seedManager = seedManager ?? SeedManager(),
       validator = validator ?? const QuestionValidator(),
       generatorFactory = generatorFactory ?? GeneratorFactory(),
       itemBankRepository =
           itemBankRepository ??
           InMemoryItemBankRepository(
             generatorFactory: generatorFactory ?? GeneratorFactory(),
           ),
       itemSelectionStrategy =
           itemSelectionStrategy ?? const DefaultItemSelectionStrategy(),
       exposureRepository = exposureRepository ?? InMemoryExposureRepository(),
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
  final ItemBankRepository itemBankRepository;
  final ItemSelectionStrategy itemSelectionStrategy;
  final ExposureRepository exposureRepository;

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
    for (var attempt = 0; attempt < maxValidationRetries; attempt++) {
      final typeCode = request.typeCode == null
          ? null
          : _retryTypeCode(request, attempt);
      final seedTypeCode = typeCode ?? _defaultTypeCode(request);
      final seed =
          request.seed ??
          seedManager.createSeed(
            profileId: request.profileId,
            testId: request.testId,
            domain: request.domain,
            typeCode: seedTypeCode,
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
        usedItemIds: request.usedItemIds,
      );

      try {
        final selected = _selectItem(normalized, attempt);
        final question = _itemToQuestionDto(
          selected.item,
          normalized,
          selected.selectionScore,
        );
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
        _recordExposure(question.itemId);
        return question;
      } on Object catch (error, stackTrace) {
        debugPrint(
          '[QuestionEngine] generation failed '
          'attempt=${attempt + 1}/$maxValidationRetries '
          'type=${typeCode ?? 'strategy'} '
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
    final fallback = _fallbackNr01(
      request,
      age.code,
      adaptiveLevel,
      difficulty,
    );
    _recordExposure(fallback.itemId);
    return fallback;
  }

  GeneratedQuestionDto generateOne({
    required int seed,
    required IntelligenceDomain domain,
    required QuestionDifficulty difficulty,
    String profileId = 'dynamic-profile',
    String testId = 'dynamic-test',
    String ageGroup = 'grade5_6',
    int index = 0,
    int? level,
    String? typeCode,
    DifficultyProfile? difficultyProfile,
    Set<String> usedItemIds = const {},
  }) {
    return generate(
      GenerateQuestionRequest(
        profileId: profileId,
        testId: testId,
        domain: domain,
        ageGroup: ageGroup,
        index: index,
        typeCode: typeCode,
        level: level,
        seed: seed,
        difficulty: difficulty,
        difficultyProfile:
            difficultyProfile ??
            DifficultyProfile(currentDifficulty: difficulty),
        usedItemIds: usedItemIds,
      ),
    );
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

  _SelectedItem _selectItem(GenerateQuestionRequest request, int attempt) {
    var candidates = itemBankRepository.findCandidates(
      domain: request.domain,
      difficulty: request.difficulty,
    );
    if (request.typeCode != null) {
      candidates = candidates
          .where((item) => item.typeCode == request.typeCode)
          .toList(growable: false);
    }
    if (candidates.isEmpty) {
      throw StateError(
        'No item bank candidates for '
        'domain=${request.domain.name} '
        'type=${request.typeCode ?? 'any'} '
        'difficulty=${request.difficulty.name}',
      );
    }
    final seed = request.seed ?? request.index;
    final exposureStatuses = {
      for (final item in candidates) item.id: exposureRepository.load(item.id),
    };
    final selected = itemSelectionStrategy.selectNext(
      candidates: candidates,
      domain: request.domain,
      targetDifficulty: request.difficulty,
      usedItemIds: request.usedItemIds,
      seed: seed + attempt,
      exposureStatuses: exposureStatuses,
    );
    final selectionScore = itemSelectionStrategy.selectionScore(
      item: selected,
      targetDifficulty: request.difficulty,
      exposureStatus: exposureStatuses[selected.id],
    );
    debugPrint(
      '[ItemSelection] '
      'domain=${request.domain.name} '
      'target=${request.difficulty.name} '
      'candidates=${candidates.length} '
      'used=${request.usedItemIds.length} '
      'selected=${selected.id} '
      'difficulty=${selected.difficulty.name} '
      'difficultyIndex=${selected.difficultyIndex} '
      'exposure=${exposureStatuses[selected.id]?.exposureCount ?? 0} '
      'selectionScore=${selectionScore.toStringAsFixed(3)}',
    );
    return _SelectedItem(item: selected, selectionScore: selectionScore);
  }

  GeneratedQuestionDto _itemToQuestionDto(
    Item item,
    GenerateQuestionRequest request,
    double selectionScore,
  ) {
    final estimatedSeconds = item.expectedSolveTime.inSeconds > 0
        ? item.expectedSolveTime.inSeconds
        : difficultyManager.estimatedTimeSec(request.level ?? 1);
    return GeneratedQuestionDto.fromLegacyChoices(
      id: '${request.testId}-${item.id}-${request.index}',
      domain: item.domain,
      typeCode: item.typeCode,
      level: request.level ?? item.difficulty.level,
      ageGroup: request.ageGroup,
      seed: request.seed ?? request.index,
      questionText: item.question,
      choices: item.choices,
      answer: item.answer,
      explanation: item.explanation,
      estimatedTimeSec: estimatedSeconds,
      metadata: QuestionMetadataDto(
        rule: item.typeCode,
        difficultyFactors: item.tags,
        version: item.version,
        status: item.hasTag('stub') ? 'coming_soon' : null,
        message: item.hasTag('stub')
            ? '${item.domain.label} domain is coming soon.'
            : null,
      ),
      difficulty: request.difficulty,
      difficultyIndex: item.difficultyIndex,
      discrimination: item.discrimination,
      guessing: item.guessing,
      expectedSolveTime: item.expectedSolveTime,
      itemId: item.id,
      selectionScore: selectionScore,
      variables: {
        'itemId': item.id,
        'itemVersion': item.version,
        'selectionScore': selectionScore,
      },
      isStub: item.hasTag('stub'),
    );
  }

  void _recordExposure(String? itemId) {
    if (itemId == null) {
      return;
    }
    final status = exposureRepository.update(itemId);
    debugPrint(
      '[Exposure] item=$itemId count=${status.exposureCount} '
      'averageResponseMs=${status.averageResponseTime.inMilliseconds}',
    );
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
      difficultyIndex: (difficulty.level - QuestionDifficulty.normal.level)
          .toDouble(),
      discrimination: 1,
      guessing: 0.25,
      expectedSolveTime: Duration(
        seconds: difficultyManager.estimatedTimeSec(level),
      ),
      itemId: 'fallback-NR01-${request.index}',
      selectionScore: 0,
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

class _SelectedItem {
  const _SelectedItem({required this.item, required this.selectionScore});

  final Item item;
  final double selectionScore;
}
