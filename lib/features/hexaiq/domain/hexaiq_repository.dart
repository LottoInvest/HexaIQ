import 'hexaiq_models.dart';
import '../../payment/domain/purchase_status.dart';
import '../../test/domain/models/test_session.dart';
import '../../training/domain/training_result.dart';

abstract class HexaIQRepository {
  Future<List<UserProfile>> loadProfiles();
  Future<void> saveProfiles(List<UserProfile> profiles) async {}
  Future<void> saveTestResult(TestResultSummary result) async {}
  Future<List<TestResultSummary>> loadTestHistory(String profileId) async {
    return const [];
  }

  Future<void> saveTrainingResult(TrainingResult result) async {}

  Future<List<TrainingResult>> loadTrainingHistory(String profileId) async {
    return const [];
  }

  Future<void> saveActiveTestSession({
    required String profileId,
    required TestSession session,
  }) async {}

  Future<TestSession?> loadActiveTestSession(String profileId) async {
    return null;
  }

  Future<void> clearActiveTestSession(String profileId) async {}

  Future<PurchaseStatus> loadPurchaseStatus() async {
    return PurchaseStatus.free;
  }

  Future<void> savePurchaseStatus(PurchaseStatus status) async {}

  Future<List<TestQuestion>> loadQuestions(
    TestType testType, {
    UserProfile? profile,
  });

  Future<ReportSummary> buildReport(List<QuestionResponse> responses);

  Future<List<GrowthPoint>> loadGrowth(UserProfile profile);

  Future<bool> verifyRewardAd({required TestType testType, required int index});

  Future<bool> verifyPayment({required TestType testType});
}
