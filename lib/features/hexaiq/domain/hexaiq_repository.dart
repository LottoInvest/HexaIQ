import 'hexaiq_models.dart';

abstract class HexaIQRepository {
  Future<List<UserProfile>> loadProfiles();

  Future<List<TestQuestion>> loadQuestions(
    TestType testType, {
    UserProfile? profile,
  });

  Future<ReportSummary> buildReport(List<QuestionResponse> responses);

  Future<List<GrowthPoint>> loadGrowth(UserProfile profile);

  Future<bool> verifyRewardAd({required TestType testType, required int index});

  Future<bool> verifyPayment({required TestType testType});
}
