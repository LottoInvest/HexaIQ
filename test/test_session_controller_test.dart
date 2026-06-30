import 'package:flutter_test/flutter_test.dart';
import 'package:hexaiq_app/core/domain/intelligence_domain.dart';
import 'package:hexaiq_app/features/hexaiq/domain/hexaiq_models.dart';
import 'package:hexaiq_app/features/hexaiq/domain/hexaiq_repository.dart';
import 'package:hexaiq_app/features/hexaiq/presentation/state/hexaiq_app_state.dart';
import 'package:hexaiq_app/features/test/application/test_session_controller.dart';
import 'package:hexaiq_app/features/test/domain/models/test_session.dart';

void main() {
  test('TestSession copyWith keeps immutable state updates', () {
    final startedAt = DateTime(2026);
    final session = TestSession(
      sessionId: 'session-1',
      startedAt: startedAt,
      questions: _questions,
    );

    final updated = session.copyWith(
      currentQuestionIndex: 1,
      selectedAnswers: {'q1': 0},
    );

    expect(session.currentQuestionIndex, 0);
    expect(session.domain, IntelligenceDomain.numerical);
    expect(session.selectedAnswers, isEmpty);
    expect(updated.currentQuestionIndex, 1);
    expect(updated.selectedAnswers['q1'], 0);
  });

  test('Question navigation and answer selection are preserved', () {
    final controller = TestSessionController(
      TestSession(
        sessionId: 'session-nav',
        startedAt: DateTime(2026),
        questions: _questions,
      ),
    );

    controller.selectAnswer(1);
    controller.nextQuestion();
    controller.selectAnswer(0);
    controller.previousQuestion();

    expect(controller.session.currentQuestionIndex, 0);
    expect(controller.session.selectedAnswerFor('q1'), 1);
    expect(controller.session.selectedAnswerFor('q2'), 0);
  });

  test('Timer records question and total elapsed seconds', () {
    final controller = TestSessionController(
      TestSession(
        sessionId: 'session-time',
        startedAt: DateTime(2026),
        questions: _questions,
      ),
    );

    controller.recordElapsedTime(7);
    controller.nextQuestion();
    controller.recordElapsedTime(5);

    expect(controller.session.elapsedFor('q1'), 7);
    expect(controller.session.elapsedFor('q2'), 5);
    expect(controller.session.totalElapsedSeconds, 12);
  });

  test('Submit stores domain results on session', () {
    final controller = TestSessionController(
      TestSession(
        sessionId: 'session-domain',
        startedAt: DateTime(2026),
        domain: IntelligenceDomain.numerical,
        questions: _questions,
      ),
    );

    controller.selectAnswer(1);
    controller.nextQuestion();
    controller.selectAnswer(2);
    controller.recordElapsedTime(9);
    final session = controller.submit(completedAt: DateTime(2026, 1, 2));
    final numerical = session.domainResults[IntelligenceDomain.numerical];

    expect(session.isComplete, isTrue);
    expect(numerical?.correctCount, 2);
    expect(numerical?.totalCount, 2);
    expect(numerical?.accuracy, 1);
  });

  test(
    'Submit finishes session and AppState calculates score report',
    () async {
      final state = HexaIQAppState(repository: _FakeRepository());
      await Future<void>.delayed(Duration.zero);
      await state.startTest();

      state.selectAnswer(1);
      state.recordElapsedTime(10);
      state.nextQuestion();
      state.selectAnswer(1);
      state.recordElapsedTime(20);
      await state.submitTest();

      expect(state.testSession?.isComplete, isTrue);
      expect(state.correctCount, 1);
      expect(state.wrongCount, 1);
      expect(state.accuracy, 0.5);
      expect(state.totalElapsedSeconds, 30);
      expect(state.report, isNotNull);
    },
  );
}

const _questions = [
  TestQuestion(
    id: 'q1',
    domain: CognitiveDomain.numerical,
    typeCode: 'NR01',
    level: 1,
    prompt: '1, 2, ?',
    choices: ['2', '3', '4', '5'],
    answerIndex: 1,
    explanation: 'Add one.',
  ),
  TestQuestion(
    id: 'q2',
    domain: CognitiveDomain.numerical,
    typeCode: 'NR02',
    level: 1,
    prompt: '2, 4, ?',
    choices: ['6', '7', '8', '9'],
    answerIndex: 2,
    explanation: 'Multiply by two.',
  ),
];

class _FakeRepository implements HexaIQRepository {
  @override
  Future<ReportSummary> buildReport(List<QuestionResponse> responses) async {
    final correct = responses.where((response) => response.isCorrect).length;
    return ReportSummary(
      overallScore: (correct / responses.length * 100).round(),
      summary: 'Fake report',
      domainScores: const [
        DomainScore(
          domain: CognitiveDomain.numerical,
          score: 50,
          percentile: 50,
          growth: 0,
          comment: 'Fake',
        ),
      ],
      recommendations: const [],
    );
  }

  @override
  Future<List<GrowthPoint>> loadGrowth(UserProfile profile) async => const [];

  @override
  Future<List<TestQuestion>> loadQuestions(
    TestType testType, {
    UserProfile? profile,
  }) async {
    return _questions;
  }

  @override
  Future<List<UserProfile>> loadProfiles() async => const [
    UserProfile(
      id: 'profile',
      name: 'Profile',
      ageGroup: 'grade5_6',
      grade: 'grade5',
      avatar: 'P',
    ),
  ];

  @override
  Future<bool> verifyPayment({required TestType testType}) async => true;

  @override
  Future<bool> verifyRewardAd({
    required TestType testType,
    required int index,
  }) async {
    return true;
  }
}
