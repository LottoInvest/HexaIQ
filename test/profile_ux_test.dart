import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hexaiq_app/app/app_routes.dart';
import 'package:hexaiq_app/core/domain/domain_result.dart';
import 'package:hexaiq_app/core/domain/intelligence_domain.dart';
import 'package:hexaiq_app/features/hexaiq/domain/hexaiq_models.dart';
import 'package:hexaiq_app/features/hexaiq/domain/hexaiq_repository.dart';
import 'package:hexaiq_app/features/hexaiq/presentation/screens/profile_create_screen.dart';
import 'package:hexaiq_app/features/hexaiq/presentation/screens/profile_select_screen.dart';
import 'package:hexaiq_app/features/hexaiq/presentation/state/hexaiq_app_state.dart';
import 'package:hexaiq_app/features/payment/domain/purchase_status.dart';
import 'package:hexaiq_app/features/test/domain/models/test_session.dart';
import 'package:hexaiq_app/features/training/domain/training_result.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('empty profile list opens create screen', (tester) async {
    final state = HexaIQAppState(repository: _ProfileRepository(const []));

    await tester.pumpWidget(_profileApp(state, const ProfileSelectScreen()));
    await tester.pumpAndSettle();

    expect(find.text('프로필 만들기'), findsOneWidget);
  });

  testWidgets('profile create accepts Korean grade text', (tester) async {
    final state = HexaIQAppState(repository: _ProfileRepository(const []));

    await tester.pumpWidget(_profileApp(state, const ProfileCreateScreen()));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).first, '하늘');
    await tester.enterText(find.byType(TextFormField).last, '초등 5학년');
    await tester.tap(find.text('저장'));
    await tester.pumpAndSettle();

    expect(state.profiles.length, 1);
    expect(state.profiles.first.name, '하늘');
    expect(state.profiles.first.grade, '초등 5학년');
  });

  testWidgets('profile delete updates list', (tester) async {
    final state = HexaIQAppState(repository: _ProfileRepository(_profiles));

    await tester.pumpWidget(_profileApp(state, const ProfileSelectScreen()));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.delete_outline).first);
    await tester.pumpAndSettle();
    expect(find.text('프로필을 삭제할까요?'), findsOneWidget);
    await tester.tap(find.text('삭제'));
    await tester.pumpAndSettle();

    expect(state.profiles.length, 1);
    expect(find.text('민지'), findsNothing);
    expect(find.text('서연'), findsOneWidget);
  });

  testWidgets('deleting last profile opens create screen', (tester) async {
    final state = HexaIQAppState(
      repository: _ProfileRepository([_profiles.first]),
    );

    await tester.pumpWidget(_profileApp(state, const ProfileSelectScreen()));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();
    await tester.tap(find.text('삭제'));
    await tester.pumpAndSettle();

    expect(state.profiles, isEmpty);
    expect(find.text('프로필 만들기'), findsOneWidget);
  });
}

Widget _profileApp(HexaIQAppState state, Widget home) {
  return ChangeNotifierProvider.value(
    value: state,
    child: MaterialApp(
      home: home,
      routes: {
        AppRoutes.profileCreate: (_) => const ProfileCreateScreen(),
        AppRoutes.home: (_) => const Scaffold(body: Text('Home')),
      },
    ),
  );
}

const _profiles = [
  UserProfile(
    id: 'profile-1',
    name: '민지',
    ageGroup: '초등 5-6',
    grade: '초등 5학년',
    avatar: 'M',
  ),
  UserProfile(
    id: 'profile-2',
    name: '서연',
    ageGroup: '초등 3-4',
    grade: '초등 3학년',
    avatar: 'S',
  ),
];

class _ProfileRepository implements HexaIQRepository {
  const _ProfileRepository(this.initialProfiles);

  final List<UserProfile> initialProfiles;

  @override
  Future<List<UserProfile>> loadProfiles() async => initialProfiles;

  @override
  Future<void> saveProfiles(List<UserProfile> profiles) async {}

  @override
  Future<void> saveTestResult(TestResultSummary result) async {}

  @override
  Future<List<TestResultSummary>> loadTestHistory(String profileId) async {
    return const [];
  }

  @override
  Future<void> saveTrainingResult(TrainingResult result) async {}

  @override
  Future<List<TrainingResult>> loadTrainingHistory(String profileId) async {
    return const [];
  }

  @override
  Future<void> saveActiveTestSession({
    required String profileId,
    required TestSession session,
  }) async {}

  @override
  Future<TestSession?> loadActiveTestSession(String profileId) async => null;

  @override
  Future<void> clearActiveTestSession(String profileId) async {}

  @override
  Future<PurchaseStatus> loadPurchaseStatus() async => PurchaseStatus.free;

  @override
  Future<void> savePurchaseStatus(PurchaseStatus status) async {}

  @override
  Future<ReportSummary> buildReport(List<QuestionResponse> responses) async {
    return const ReportSummary(
      overallScore: 0,
      summary: 'test',
      domainScores: [],
      recommendations: [],
      domainResults: {IntelligenceDomain.numerical: DomainResult()},
    );
  }

  @override
  Future<List<GrowthPoint>> loadGrowth(UserProfile profile) async => const [];

  @override
  Future<List<TestQuestion>> loadQuestions(
    TestType testType, {
    UserProfile? profile,
  }) async {
    return const [];
  }

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
