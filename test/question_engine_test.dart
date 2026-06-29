import 'package:flutter_test/flutter_test.dart';
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

    expect(first.toJson(), second.toJson());
  });

  test('Different seeds generate different numerical questions', () {
    final engine = QuestionEngine();
    final first = engine.generate(
      const GenerateQuestionRequest(
        profileId: 'profile-seed',
        testId: 'test-seed',
        domain: QuestionDomain.numerical,
        ageGroup: 'grade5_6',
        index: 0,
        typeCode: 'NR05',
        level: 5,
        seed: 111,
      ),
    );
    final second = engine.generate(
      const GenerateQuestionRequest(
        profileId: 'profile-seed',
        testId: 'test-seed',
        domain: QuestionDomain.numerical,
        ageGroup: 'grade5_6',
        index: 0,
        typeCode: 'NR05',
        level: 5,
        seed: 222,
      ),
    );

    expect(
      first.questionText == second.questionText &&
          first.answer == second.answer,
      isFalse,
    );
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
}
