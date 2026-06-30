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

  test('NumericalGenerator provides specific cube hint', () {
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

    expect(question.hint, '세제곱수 규칙입니다. 2³, 3³, 4³처럼 생각해보세요.');
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

  test('Same seed reproduces the same question', () {
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
    final second = engine.generate(request);

    final firstJson = Map<String, Object?>.from(first.toJson())
      ..remove('selectionScore')
      ..remove('catSelectionScore');
    final secondJson = Map<String, Object?>.from(second.toJson())
      ..remove('selectionScore')
      ..remove('catSelectionScore');

    expect(firstJson, secondJson);
    expect(second.selectionScore, lessThan(first.selectionScore));
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
    expect(question.metadata.version, 'v0.6.0');
  });

  test('Stub generators return valid placeholder DTOs', () {
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

      expect(question.isStub, isTrue);
      expect(question.metadata.status, 'coming_soon');
      expect(question.choices, contains(question.answer));
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

  test('MockQuestionApi always returns five generated questions', () async {
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

      expect(questions.length, 5);
      expect(
        questions.every(
          (question) => question.domain == QuestionDomain.numerical,
        ),
        isTrue,
      );
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
