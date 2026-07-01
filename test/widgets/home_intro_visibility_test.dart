import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hexaiq_app/core/domain/question_difficulty.dart';
import 'package:hexaiq_app/features/hexaiq/domain/hexaiq_models.dart';
import 'package:hexaiq_app/features/hexaiq/domain/hexaiq_repository.dart';
import 'package:hexaiq_app/features/hexaiq/presentation/screens/home_dashboard_screen.dart';
import 'package:hexaiq_app/features/hexaiq/presentation/state/hexaiq_app_state.dart';
import 'package:hexaiq_app/features/hexaiq/presentation/widgets/hexa_iq_intro_card.dart';
import 'package:hexaiq_app/features/payment/domain/purchase_status.dart';
import 'package:hexaiq_app/features/result/domain/test_result_payload.dart';
import 'package:hexaiq_app/features/test/domain/models/test_mode.dart';
import 'package:hexaiq_app/features/test/domain/models/test_session.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('home shows intro card only before the first saved result', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) =>
            HexaIQAppState(repository: _WidgetRepository(results: const [])),
        child: const MaterialApp(home: HomeDashboardScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(HexaIQIntroCard), findsOneWidget);
    expect(find.byKey(const ValueKey('home-recent-result-card')), findsNothing);
  });

  testWidgets('home hides intro card when a saved result exists', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) =>
            HexaIQAppState(repository: _WidgetRepository(results: [_result()])),
        child: const MaterialApp(home: HomeDashboardScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(HexaIQIntroCard), findsNothing);
    expect(
      find.byKey(const ValueKey('home-recent-result-card')),
      findsOneWidget,
    );
    expect(find.text('최근 검사 결과'), findsOneWidget);
    expect(find.text('112'), findsOneWidget);
    expect(find.text('73%'), findsOneWidget);
  });
}

class _WidgetRepository extends HexaIQRepository {
  _WidgetRepository({required this.results});

  final List<TestResultSummary> results;
  final _profile = const UserProfile(
    id: 'profile-1',
    name: '테스터',
    ageGroup: 'adult',
    grade: '성인',
    avatar: '테',
  );

  @override
  Future<List<UserProfile>> loadProfiles() async => [_profile];

  @override
  Future<List<TestResultSummary>> loadTestHistory(String profileId) async {
    return results.where((result) => result.profileId == profileId).toList();
  }

  @override
  Future<List<GrowthPoint>> loadGrowth(UserProfile profile) async => [
    for (var i = 0; i < results.length; i++)
      GrowthPoint(month: 'T${i + 1}', score: results[i].estimatedIQ),
  ];

  @override
  Future<PurchaseStatus> loadPurchaseStatus() async => PurchaseStatus.free;

  @override
  Future<List<TestQuestion>> loadQuestions(
    TestType testType, {
    UserProfile? profile,
  }) async => const [];

  @override
  Future<ReportSummary> buildReport(List<QuestionResponse> responses) async {
    return const ReportSummary(
      overallScore: 0,
      summary: '',
      domainScores: [],
      recommendations: [],
    );
  }

  @override
  Future<TestSession?> loadActiveTestSession(String profileId) async => null;

  @override
  Future<bool> verifyRewardAd({
    required TestType testType,
    required int index,
  }) async => true;

  @override
  Future<bool> verifyPayment({required TestType testType}) async => true;
}

TestResultSummary _result() {
  final payload = TestResultPayload(
    resultId: 'home-1',
    profileId: 'profile-1',
    testMode: TestMode.quickIq,
    totalQuestions: 18,
    answeredQuestions: 18,
    correctCount: 13,
    accuracy: 13 / 18,
    totalElapsedSeconds: 180,
    averageElapsedSeconds: 10,
    questionIds: List.generate(18, (index) => 'q-$index'),
    domainScores: const {},
  );
  return TestResultSummary(
    id: 'home-1',
    profileId: 'profile-1',
    startedAt: DateTime(2026, 7),
    completedAt: DateTime(2026, 7, 1, 0, 3),
    theta: 0.4,
    standardError: 0.5,
    estimatedIQ: 112,
    percentile: 73,
    abilityLevel: '평균 이상',
    averageDifficulty: QuestionDifficulty.normal,
    averageElapsedSeconds: 10,
    questionCount: 18,
    payloadJson: payload.encode(),
  );
}
