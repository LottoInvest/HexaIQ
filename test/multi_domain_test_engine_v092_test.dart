import 'package:flutter_test/flutter_test.dart';
import 'package:hexaiq_app/core/domain/intelligence_domain.dart';
import 'package:hexaiq_app/core/domain/question_difficulty.dart';
import 'package:hexaiq_app/core/persistence/hexa_iq_database.dart';
import 'package:hexaiq_app/features/hexaiq/data/mock_hexaiq_repository.dart';
import 'package:hexaiq_app/features/hexaiq/domain/hexaiq_models.dart';
import 'package:hexaiq_app/features/report/domain/domain_score_calculator.dart';
import 'package:hexaiq_app/features/test/application/test_session_controller.dart';
import 'package:hexaiq_app/features/test/domain/generators/multi_domain_item_engine.dart';
import 'package:hexaiq_app/features/test/domain/models/test_mode.dart';
import 'package:hexaiq_app/features/test/domain/models/test_response.dart';
import 'package:hexaiq_app/features/test/domain/models/test_session.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  const engine = MultiDomainItemEngine();

  setUpAll(() {
    sqfliteFfiInit();
  });

  test('Quick IQ generates 60 items with ten items per domain', () {
    final items = engine.generate(mode: TestMode.quickIq);

    expect(items, hasLength(60));
    for (final domain in MultiDomainItemEngine.domains) {
      expect(items.where((item) => item.domain == domain.name), hasLength(10));
    }
  });

  test('Quick IQ applies easy, medium, and hard difficulty distribution', () {
    final items = engine.generateQuickIq();
    final easy = items.where((item) => item.difficulty < 0.4).length;
    final medium = items
        .where((item) => item.difficulty >= 0.4 && item.difficulty < 0.7)
        .length;
    final hard = items.where((item) => item.difficulty >= 0.7).length;

    expect(easy, 18);
    expect(medium, 24);
    expect(hard, 18);
    expect(items.every((item) => item.difficulty >= 0.2), isTrue);
    expect(items.every((item) => item.difficulty <= 1.0), isTrue);
  });

  test('Full Diagnostic keeps item count within diagnostic range', () {
    expect(engine.generate(mode: TestMode.fullDiagnostic), hasLength(30));
    expect(
      engine.generate(mode: TestMode.fullDiagnostic, count: 60),
      hasLength(60),
    );
    expect(
      engine.generate(mode: TestMode.fullDiagnostic, count: 100),
      hasLength(100),
    );
  });

  test('Domain Training generates only the selected domain', () {
    final items = engine.generate(
      mode: TestMode.domainTraining,
      domain: IntelligenceDomain.numerical,
      count: 8,
    );

    expect(items, hasLength(8));
    expect(items.every((item) => item.domain == 'numerical'), isTrue);
  });

  test('TestSession stores TestItem and TestResponse records', () {
    final item = engine.generateQuickIq().first;
    final response = TestResponse(
      itemId: item.id,
      domain: item.domain,
      selectedIndex: item.answerIndex,
      isCorrect: true,
      elapsedMs: 1200,
    );
    final session = TestSession(
      sessionId: 'session-v092',
      startedAt: DateTime(2026, 7),
      mode: TestMode.quickIq,
      items: [item],
      responses: [response],
    );

    expect(session.items.single.id, item.id);
    expect(session.responses.single.isCorrect, isTrue);
    expect(session.mode.contributesToIq, isTrue);
  });

  test('TestSessionController records TestResponse on answer selection', () {
    final question = _question();
    final controller = TestSessionController(
      TestSession(
        sessionId: 'controller-v092',
        startedAt: DateTime(2026, 7),
        questions: [question],
        generatedQuestions: [question],
      ),
    );

    controller.recordElapsedTime(2);
    controller.selectAnswer(question.answerIndex);

    expect(controller.session.responses, hasLength(1));
    expect(controller.session.responses.single.itemId, question.itemId);
    expect(controller.session.responses.single.elapsedMs, 2000);
    expect(controller.session.responses.single.isCorrect, isTrue);
  });

  test('SQLite repository saves and resumes active TestSession', () async {
    final database = HexaIQDatabase(
      factory: databaseFactoryFfi,
      databasePath: inMemoryDatabasePath,
    );
    final repository = MockHexaIQRepository(database: database);
    final question = _question();
    final session = TestSession(
      sessionId: 'resume-v092',
      startedAt: DateTime(2026, 7),
      mode: TestMode.quickIq,
      questions: [question],
      generatedQuestions: [question],
      currentQuestionIndex: 0,
      selectedAnswers: {question.id: question.answerIndex},
      responses: [
        TestResponse(
          itemId: question.itemId!,
          domain: question.domain.name,
          selectedIndex: question.answerIndex,
          isCorrect: true,
          elapsedMs: 1500,
        ),
      ],
    );

    await repository.saveActiveTestSession(
      profileId: 'profile-1',
      session: session,
    );
    final restored = await repository.loadActiveTestSession('profile-1');

    expect(restored, isNotNull);
    expect(restored!.sessionId, session.sessionId);
    expect(restored.selectedAnswerFor(question.id), question.answerIndex);
    expect(restored.responses.single.elapsedMs, 1500);

    await repository.clearActiveTestSession('profile-1');
    expect(await repository.loadActiveTestSession('profile-1'), isNull);
    await database.close();
  });

  test('Report calculation excludes unanswered domains from score data', () {
    const calculator = DomainScoreCalculator();
    final result = calculator.calculateFromResponses(
      domain: IntelligenceDomain.numerical,
      responses: [QuestionResponse(question: _question(), selectedIndex: 0)],
    );
    final empty = calculator.calculateFromResponses(
      domain: IntelligenceDomain.spatial,
      responses: [QuestionResponse(question: _question(), selectedIndex: 0)],
    );

    expect(result.total, 1);
    expect(result.domainScore, greaterThan(0));
    expect(empty.total, 0);
    expect(empty.domainScore, 0);
  });
}

TestQuestion _question() {
  return const TestQuestion(
    id: 'NR-T-001',
    domain: IntelligenceDomain.numerical,
    typeCode: 'NR01',
    level: 1,
    prompt: '2, 4, 6, ?',
    choices: ['8', '9', '10', '12'],
    answerIndex: 0,
    explanation: '2씩 증가합니다.',
    difficulty: QuestionDifficulty.normal,
    seed: 1,
    difficultyIndex: 0,
    discrimination: 1.1,
    guessing: 0.25,
    itemId: 'NR-T-001',
  );
}
