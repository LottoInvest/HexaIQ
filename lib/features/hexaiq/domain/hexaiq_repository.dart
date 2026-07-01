import 'hexaiq_models.dart';

abstract class HexaIQRepository {
  Future<List<UserProfile>> loadProfiles();
  Future<void> saveProfiles(List<UserProfile> profiles) async {}
  Future<void> saveTestResult(TestResultSummary result) async {}
  Future<List<TestResultSummary>> loadTestHistory(String profileId) async {
    return const [];
  }

  Future<List<TestQuestion>> loadQuestions(
    TestType testType, {
    UserProfile? profile,
  });

  Future<ReportSummary> buildReport(List<QuestionResponse> responses);

  Future<List<GrowthPoint>> loadGrowth(UserProfile profile);

  Future<bool> verifyRewardAd({required TestType testType, required int index});

  Future<bool> verifyPayment({required TestType testType});
}
