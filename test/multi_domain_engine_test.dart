import 'package:flutter_test/flutter_test.dart';
import 'package:hexaiq_app/core/domain/question_difficulty.dart';
import 'package:hexaiq_app/features/hexaiq/data/mock_hexaiq_repository.dart';
import 'package:hexaiq_app/features/hexaiq/domain/hexaiq_models.dart';
import 'package:hexaiq_app/features/question_engine/question_engine.dart';
import 'package:hexaiq_app/features/report/domain/models/domain_result.dart';

void main() {
  const profile = UserProfile(
    id: 'profile-domain',
    name: 'Domain',
    ageGroup: 'grade5_6',
    grade: 'grade5',
    avatar: 'D',
  );

  test('IntelligenceDomain exposes the six HexaIQ domains', () {
    expect(IntelligenceDomain.values, const [
      IntelligenceDomain.numerical,
      IntelligenceDomain.verbal,
      IntelligenceDomain.spatial,
      IntelligenceDomain.memory,
      IntelligenceDomain.logic,
      IntelligenceDomain.processing,
    ]);
    expect(IntelligenceDomain.numerical.label, '수리논리');
    expect(IntelligenceDomain.processing.generatorPrefix, 'PR');
  });

  test('GeneratedQuestionDto stores IntelligenceDomain and typeCode', () {
    final dto = GeneratedQuestionDto.fromLegacyChoices(
      id: 'dto-1',
      domain: IntelligenceDomain.numerical,
      typeCode: 'NR01',
      level: 3,
      ageGroup: 'grade5_6',
      seed: 1,
      questionText: '1, 2, ?',
      choices: const ['2', '3', '4', '5'],
      answer: '3',
      explanation: 'Add one.',
      estimatedTimeSec: 24,
      difficulty: QuestionDifficulty.hard,
      metadata: const QuestionMetadataDto(
        rule: 'NR01',
        difficultyFactors: ['test'],
      ),
    );

    expect(dto.domain, IntelligenceDomain.numerical);
    expect(dto.typeCode, 'NR01');
    expect(dto.difficulty, QuestionDifficulty.hard);
    expect(dto.toJson()['domain'], 'numerical');
    expect(dto.toJson()['difficulty'], 'hard');
  });

  test('GeneratorFactory returns numerical and five mock generators', () {
    final factory = GeneratorFactory();

    expect(
      factory.create(IntelligenceDomain.numerical),
      isA<NumericalGenerator>(),
    );
    for (final domain in IntelligenceDomain.values.where(
      (domain) => domain != IntelligenceDomain.numerical,
    )) {
      final generator = factory.create(domain);
      expect(generator.domain, domain);
      expect(
        generator.supportedTypeCodes.first,
        startsWith(domain.generatorPrefix),
      );
    }
  });

  test('MockQuestionApi can generate by domain', () async {
    final api = MockQuestionApi();

    final numerical = await api.generateQuestions(
      profile: profile,
      domain: IntelligenceDomain.numerical,
      count: 5,
    );
    final verbal = await api.generateQuestions(
      profile: profile,
      domain: IntelligenceDomain.verbal,
      count: 2,
    );

    expect(numerical.length, 5);
    expect(
      numerical.every(
        (question) => question.domain == IntelligenceDomain.numerical,
      ),
      isTrue,
    );
    expect(verbal.length, 2);
    expect(verbal.every((question) => question.isStub), isTrue);
    expect(
      verbal.every((question) => question.domain == IntelligenceDomain.verbal),
      isTrue,
    );
  });

  test('DomainResult records score calculation fields', () {
    const result = DomainResult(
      domain: IntelligenceDomain.numerical,
      correctCount: 4,
      totalCount: 5,
      accuracy: 0.8,
      elapsedSeconds: 91,
    );

    expect(result.domain, IntelligenceDomain.numerical);
    expect(result.correctCount, 4);
    expect(result.totalCount, 5);
    expect(result.total, 5);
    expect(result.accuracy, 0.8);
    expect(result.elapsedSeconds, 91);
  });

  test('Report includes numerical result and coming soon domains', () async {
    final repository = MockHexaIQRepository();
    final questions = await repository.loadQuestions(
      TestType.basic,
      profile: profile,
    );
    final report = await repository.buildReport([
      for (final question in questions)
        QuestionResponse(
          question: question,
          selectedIndex: question.answerIndex,
        ),
    ]);

    expect(report.domainScores.length, IntelligenceDomain.values.length);
    expect(report.domainResults[IntelligenceDomain.numerical]?.correct, 5);
    expect(
      report.domainScores
          .where((score) => score.domain != IntelligenceDomain.numerical)
          .every((score) => score.isComingSoon),
      isTrue,
    );
  });
}
