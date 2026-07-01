import 'package:flutter_test/flutter_test.dart';
import 'package:hexaiq_app/features/hexaiq/data/mock_hexaiq_repository.dart';
import 'package:hexaiq_app/features/hexaiq/domain/hexaiq_models.dart';
import 'package:hexaiq_app/features/hexaiq/presentation/state/hexaiq_app_state.dart';
import 'package:hexaiq_app/features/question_engine/question_engine.dart';

void main() {
  const profile = UserProfile(
    id: 'profile-v090',
    name: 'V090',
    ageGroup: 'grade5_6',
    grade: 'grade5',
    avatar: 'V',
  );

  test('v0.9 prefixes match six-domain generator contract', () {
    expect(IntelligenceDomain.numerical.generatorPrefix, 'NR');
    expect(IntelligenceDomain.verbal.generatorPrefix, 'LR');
    expect(IntelligenceDomain.spatial.generatorPrefix, 'SR');
    expect(IntelligenceDomain.memory.generatorPrefix, 'MR');
    expect(IntelligenceDomain.logic.generatorPrefix, 'LG');
    expect(IntelligenceDomain.processing.generatorPrefix, 'PS');
  });

  test('all non-numerical generators are real and support ten types', () {
    final factory = GeneratorFactory();
    for (final domain in IntelligenceDomain.values.where(
      (domain) => domain != IntelligenceDomain.numerical,
    )) {
      final generator = factory.create(domain);
      expect(generator.supportedTypeCodes.length, 10);
      expect(
        generator.supportedTypeCodes.first,
        startsWith(domain.generatorPrefix),
      );
      final dto = generator.generate(
        GenerateQuestionRequest(
          profileId: 'p',
          testId: 't',
          domain: domain,
          ageGroup: 'grade5_6',
          index: 0,
          seed: 10 + domain.index,
        ),
      );
      expect(dto.isStub, isFalse);
      expect(dto.hint, isNotEmpty);
      expect(dto.ruleName, isNotEmpty);
      expect(dto.solutionExplanation, isNotEmpty);
    }
  });

  test('verbal generator produces LR01 through LR10', () {
    final generator = VerbalGenerator();
    expect(generator.supportedTypeCodes, containsAll(['LR01', 'LR05', 'LR10']));
  });

  test('spatial generator produces SR01 through SR10', () {
    final generator = SpatialGenerator();
    expect(generator.supportedTypeCodes, containsAll(['SR01', 'SR05', 'SR10']));
  });

  test('memory generator carries 3 second prompt metadata', () {
    final dto = MemoryGenerator().generate(
      const GenerateQuestionRequest(
        profileId: 'p',
        testId: 't',
        domain: IntelligenceDomain.memory,
        ageGroup: 'grade5_6',
        index: 0,
        seed: 1,
      ),
    );

    expect(dto.variables['memoryPrompt'], isA<String>());
    expect(dto.variables['memoryDurationMs'], 3000);
  });

  test('logical generator carries rule and explanation fields', () {
    final dto = LogicalGenerator().generate(
      const GenerateQuestionRequest(
        profileId: 'p',
        testId: 't',
        domain: IntelligenceDomain.logic,
        ageGroup: 'grade5_6',
        index: 2,
        seed: 2,
      ),
    );

    expect(dto.ruleName, isNotEmpty);
    expect(dto.solutionExplanation, isNotEmpty);
  });

  test('processing speed generator uses short expected solve time', () {
    final dto = ProcessingSpeedGenerator().generate(
      const GenerateQuestionRequest(
        profileId: 'p',
        testId: 't',
        domain: IntelligenceDomain.processing,
        ageGroup: 'grade5_6',
        index: 3,
        seed: 3,
      ),
    );

    expect(dto.expectedSolveTime.inSeconds, lessThanOrEqualTo(20));
  });

  test('item bank has 300 items and 50 per domain', () {
    final repository = InMemoryItemBankRepository();
    expect(repository.load().length, greaterThanOrEqualTo(300));
    for (final domain in IntelligenceDomain.values) {
      expect(repository.findByDomain(domain).length, greaterThanOrEqualTo(50));
    }
  });

  test('item bank contains no stub items in v0.9 domains', () {
    final repository = InMemoryItemBankRepository();
    expect(repository.findByTag('stub'), isEmpty);
  });

  test('all item bank domains carry hint and solution metadata', () {
    final repository = InMemoryItemBankRepository();
    for (final domain in IntelligenceDomain.values) {
      final item = repository.findByDomain(domain).first;
      expect(item.hint, isNotEmpty);
      expect(item.ruleName, isNotEmpty);
      expect(item.solutionExplanation, isNotEmpty);
    }
  });

  test('Quick IQ mock API generates 60 six-domain questions', () async {
    final api = MockQuestionApi();
    final questions = await api.generateTestQuestions(
      profile: profile,
      testType: TestType.quickIq,
    );

    expect(questions.length, 60);
    for (final domain in IntelligenceDomain.values) {
      expect(
        questions.where((question) => question.domain == domain).length,
        10,
      );
    }
  });

  test('Mock repository loads Quick IQ as mixed questions', () async {
    final repository = MockHexaIQRepository();
    final questions = await repository.loadQuestions(
      TestType.quickIq,
      profile: profile,
    );

    expect(questions.length, 60);
    expect(questions.map((question) => question.domain).toSet().length, 6);
  });

  test('Quick IQ report uses actual domain results', () async {
    final repository = MockHexaIQRepository();
    final questions = await repository.loadQuestions(
      TestType.quickIq,
      profile: profile,
    );
    final report = await repository.buildReport([
      for (final question in questions)
        QuestionResponse(
          question: question,
          selectedIndex: question.answerIndex,
        ),
    ]);

    for (final domain in IntelligenceDomain.values) {
      expect(report.domainResults[domain]?.total, 10);
      expect(report.domainResults[domain]?.accuracy, 1.0);
    }
    expect(report.domainScores.every((score) => !score.isComingSoon), isTrue);
  });

  test('AppState starts Quick IQ with 60 target questions', () async {
    final state = HexaIQAppState(repository: MockHexaIQRepository());
    await state.loadInitialData();
    state.selectTestType(TestType.quickIq);
    await state.startTest();

    expect(state.totalQuestionCount, 60);
    expect(state.currentQuestion?.domain, IntelligenceDomain.numerical);
  });

  test('Quick IQ advances into the second domain', () async {
    final state = HexaIQAppState(repository: MockHexaIQRepository());
    await state.loadInitialData();
    state.selectTestType(TestType.quickIq);
    await state.startTest();
    for (var index = 0; index < 10; index++) {
      state.selectAnswer(state.currentQuestion!.answerIndex);
      state.nextQuestion();
    }

    expect(state.currentQuestion?.domain, IntelligenceDomain.verbal);
  });

  test('domain theta estimates are stored independently', () async {
    final state = HexaIQAppState(repository: MockHexaIQRepository());
    await state.loadInitialData();
    state.selectTestType(TestType.quickIq);
    await state.startTest();

    for (var index = 0; index < 11; index++) {
      final question = state.currentQuestion!;
      state.selectAnswer(question.answerIndex);
      state.nextQuestion();
    }

    final estimates = state.testSession!.domainThetaEstimates;
    expect(estimates.containsKey(IntelligenceDomain.verbal), isTrue);
    expect(estimates.containsKey(IntelligenceDomain.numerical), isTrue);
  });
}
