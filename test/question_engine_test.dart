import 'package:flutter_test/flutter_test.dart';
import 'package:hexaiq_app/core/domain/question_difficulty.dart';
import 'package:hexaiq_app/features/hexaiq/domain/hexaiq_models.dart';
import 'package:hexaiq_app/features/question_engine/question_engine.dart';

void main() {
  test('NumericalGenerator supports NR01 through NR20', () {
    final generator = NumericalGenerator();

    expect(generator.supportedTypeCodes.length, 20);
    expect(generator.supportedTypeCodes.contains('NR01'), isTrue);
    expect(generator.supportedTypeCodes.contains('NR20'), isTrue);
  });

  test(
    'QuestionEngine generates valid numerical questions for all NR types',
    () {
      final engine = QuestionEngine();

      for (final typeCode in NumericalGenerator.typeCodes) {
        final question = engine.generate(
          GenerateQuestionRequest(
            profileId: 'profile-test',
            testId: 'test-$typeCode',
            domain: QuestionDomain.numerical,
            ageGroup: 'grade5_6',
            index: int.parse(typeCode.substring(2)),
            typeCode: typeCode,
            level: 6,
          ),
        );

        expect(question.typeCode, typeCode);
        expect(question.choices.length, 4);
        expect(question.choices.toSet().length, 4);
        expect(question.choices, contains(question.answer));
        expect(question.answerIndex, question.choices.indexOf(question.answer));
        expect(question.questionText.trim(), isNotEmpty);
        expect(question.explanation.trim(), isNotEmpty);
        expect(question.level, inInclusiveRange(1, 10));
      }
    },
  );

  test('NumericalGenerator provides structured cube hint data', () {
    final generator = NumericalGenerator();

    final question = generator.generate(
      const GenerateQuestionRequest(
        profileId: 'profile-hint',
        testId: 'test-hint',
        domain: QuestionDomain.numerical,
        ageGroup: 'grade5_6',
        index: 9,
        typeCode: 'NR09',
        level: 6,
      ),
    );

    expect(question.ruleName, '세제곱수');
    expect(question.hint, '숫자가 일정한 규칙으로 빠르게 증가합니다.');
    expect(question.solution, question.answer);
    expect(question.solutionExplanation, contains('다음은'));
    expect(question.solutionExplanation, contains('³ ='));
    expect(question.variables['ruleName'], '세제곱수');
    expect(question.variables['solution'], question.answer);
    expect(
      question.variables['solutionExplanation'],
      question.solutionExplanation,
    );
    expect(question.metadata.ruleName, '세제곱수');
  });

  test('AgeMapper clamps level to age group range', () {
    final engine = QuestionEngine();

    final kindergarten = engine.generate(
      const GenerateQuestionRequest(
        profileId: 'profile-age',
        testId: 'test-age',
        domain: QuestionDomain.numerical,
        ageGroup: 'kindergarten',
        index: 0,
        typeCode: 'NR01',
        level: 10,
      ),
    );
    final adult = engine.generate(
      const GenerateQuestionRequest(
        profileId: 'profile-age',
        testId: 'test-age',
        domain: QuestionDomain.numerical,
        ageGroup: 'adult',
        index: 1,
        typeCode: 'NR01',
        level: 1,
      ),
    );

    expect(kindergarten.level, 2);
    expect(adult.level, 8);
  });

  test('Same seed preserves deterministic request metadata', () {
    final engine = QuestionEngine();
    const request = GenerateQuestionRequest(
      profileId: 'profile-seed',
      testId: 'test-seed',
      domain: QuestionDomain.numerical,
      ageGroup: 'grade5_6',
      index: 0,
      typeCode: 'NR05',
      level: 5,
      seed: 123456,
    );

    final first = engine.generate(request);
    final second = QuestionEngine().generate(request);

    expect(second.seed, first.seed);
    expect(second.domain, first.domain);
    expect(second.typeCode, first.typeCode);
    expect(second.difficulty, first.difficulty);
    expect(second.choices.length, 4);
    expect(second.choices, contains(second.answer));
  });

  test('QuestionEngine applies requested adaptive difficulty', () {
    final engine = QuestionEngine();

    final easy = engine.generate(
      const GenerateQuestionRequest(
        profileId: 'profile-difficulty',
        testId: 'test-difficulty',
        domain: QuestionDomain.numerical,
        ageGroup: 'grade5_6',
        index: 0,
        typeCode: 'NR01',
        level: 5,
        seed: 77,
        difficulty: QuestionDifficulty.easy,
      ),
    );
    final hard = engine.generate(
      const GenerateQuestionRequest(
        profileId: 'profile-difficulty',
        testId: 'test-difficulty',
        domain: QuestionDomain.numerical,
        ageGroup: 'grade5_6',
        index: 1,
        typeCode: 'NR01',
        level: 5,
        seed: 77,
        difficulty: QuestionDifficulty.hard,
      ),
    );

    expect(easy.difficulty, QuestionDifficulty.easy);
    expect(hard.difficulty, QuestionDifficulty.hard);
    expect(easy.level, lessThan(hard.level));
  });

  test('QuestionEngine generateOne returns a validated adaptive question', () {
    final engine = QuestionEngine();

    final question = engine.generateOne(
      seed: 98765,
      domain: QuestionDomain.numerical,
      difficulty: QuestionDifficulty.hard,
      profileId: 'profile-one',
      testId: 'test-one',
      ageGroup: 'grade5_6',
      index: 2,
    );

    expect(question.domain, QuestionDomain.numerical);
    expect(question.difficulty, QuestionDifficulty.hard);
    expect(question.seed, 98765);
    expect(question.choices, contains(question.answer));
    expect(question.difficultyIndex, isNotNull);
    expect(question.discrimination, greaterThan(0));
    expect(question.guessing, greaterThan(0));
    expect(question.expectedSolveTime.inSeconds, question.estimatedTimeSec);
  });

  test('QuestionEngine generateOne uses fallback after retry failures', () {
    final engine = QuestionEngine(qualityValidator: _AlwaysInvalidValidator());

    final question = engine.generateOne(
      seed: 12345,
      domain: QuestionDomain.numerical,
      difficulty: QuestionDifficulty.easy,
      profileId: 'profile-one-fallback',
      testId: 'test-one-fallback',
      ageGroup: 'grade5_6',
      index: 0,
    );

    expect(question.typeCode, 'NR01');
    expect(question.metadata.status, 'fallback');
    expect(question.difficulty, QuestionDifficulty.easy);
  });

  test('QuestionEngine returns item bank backed questions', () {
    final engine = QuestionEngine();

    final question = engine.generate(
      const GenerateQuestionRequest(
        profileId: 'profile-item-bank',
        testId: 'test-item-bank',
        domain: QuestionDomain.numerical,
        ageGroup: 'grade5_6',
        index: 3,
        level: 5,
        seed: 111,
      ),
    );

    expect(question.itemId, isNotNull);
    expect(question.variables['itemId'], question.itemId);
    expect(question.ruleName.trim(), isNotEmpty);
    expect(question.solution, question.answer);
    expect(question.solutionExplanation.trim(), isNotEmpty);
    expect(question.hint?.trim(), isNotEmpty);
    expect(question.metadata.version, 'v0.9.4');
  });

  test('Non-numerical generators return real DTOs', () {
    final engine = QuestionEngine();

    for (final domain in QuestionDomain.values.where(
      (domain) => domain != QuestionDomain.numerical,
    )) {
      final question = engine.generate(
        GenerateQuestionRequest(
          profileId: 'profile-test',
          testId: 'test-stub',
          domain: domain,
          ageGroup: 'grade5_6',
          index: 0,
          level: 4,
        ),
      );

      expect(question.isStub, isFalse);
      expect(question.metadata.status, isNull);
      expect(question.choices, contains(question.answer));
      expect(question.hint, isNotEmpty);
      expect(question.solutionExplanation, isNotEmpty);
    }
  });

  test('QuestionQualityValidator returns invalid instead of throwing', () {
    final ageMapper = AgeMapper();
    final validator = QuestionQualityValidator(
      ageMapper: ageMapper,
      difficultyManager: DifficultyManager(ageMapper),
    );

    final result = validator.validate(
      GeneratedQuestionDto.fromLegacyChoices(
        id: 'invalid-time',
        domain: QuestionDomain.numerical,
        typeCode: 'NR01',
        level: 5,
        ageGroup: 'grade5_6',
        seed: 1,
        questionText: '2, 5, 8, ?',
        choices: const ['11', '12', '13', '14'],
        answer: '11',
        explanation: 'Add 3 each time.',
        estimatedTimeSec: 999,
        metadata: const QuestionMetadataDto(
          rule: 'NR01',
          difficultyFactors: ['test'],
        ),
      ),
    );

    expect(result.isValid, isFalse);
    expect(result.reason, isNotNull);
  });

  test(
    'QuestionEngine falls back to a valid NR01 after validation failures',
    () {
      final engine = QuestionEngine(
        qualityValidator: _AlwaysInvalidValidator(),
      );

      final question = engine.generate(
        const GenerateQuestionRequest(
          profileId: 'profile-fallback',
          testId: 'test-fallback',
          domain: QuestionDomain.numerical,
          ageGroup: 'grade5_6',
          index: 0,
          typeCode: 'NR20',
          level: 5,
        ),
      );

      expect(question.typeCode, 'NR01');
      expect(question.difficulty, QuestionDifficulty.normal);
      expect(question.metadata.status, 'fallback');
      expect(question.choices, contains(question.answer));
      expect(question.answerIndex, question.choices.indexOf(question.answer));
    },
  );

  test('QuestionEngine returns the requested five-item domain batch', () {
    final engine = QuestionEngine(qualityValidator: _AlwaysInvalidValidator());

    final questions = engine.generateDomainBatch(
      profileId: 'profile-batch',
      testId: 'test-batch',
      domain: QuestionDomain.numerical,
      ageGroup: 'grade5_6',
      count: 5,
      level: 5,
      difficulty: QuestionDifficulty.hard,
    );

    expect(questions.length, 5);
    expect(questions.every((question) => question.typeCode == 'NR01'), isTrue);
    expect(
      questions.every(
        (question) => question.difficulty == QuestionDifficulty.hard,
      ),
      isTrue,
    );
    expect(questions.every((question) => question.choices.length == 4), isTrue);
  });

  test('MockQuestionApi returns v1.0.3 test mode question counts', () async {
    final api = MockQuestionApi();

    for (final testType in TestType.values) {
      final questions = await api.generateTestQuestions(
        profile: const UserProfile(
          id: 'profile-mock',
          name: 'Mock',
          ageGroup: 'grade5_6',
          grade: 'grade5',
          avatar: 'M',
        ),
        testType: testType,
      );

      if (testType == TestType.basic) {
        expect(questions.length, 30);
        expect(questions.map((question) => question.domain).toSet().length, 6);
      } else if (testType == TestType.quickIq) {
        expect(questions.length, 60);
        expect(questions.map((question) => question.domain).toSet().length, 6);
      } else if (testType == TestType.advanced) {
        expect(questions.length, 90);
        expect(questions.map((question) => question.domain).toSet().length, 6);
      } else if (testType == TestType.professional) {
        expect(questions.length, 120);
        expect(questions.map((question) => question.domain).toSet().length, 6);
      }
      expect(
        questions.every((question) => question.choices.length == 4),
        isTrue,
      );
    }
  });
}

class _AlwaysInvalidValidator extends QuestionQualityValidator {
  _AlwaysInvalidValidator()
    : super(
        ageMapper: AgeMapper(),
        difficultyManager: DifficultyManager(AgeMapper()),
      );

  @override
  ValidationResult validate(GeneratedQuestionDto question) {
    return const ValidationResult.invalid('forced invalid for test');
  }
}
