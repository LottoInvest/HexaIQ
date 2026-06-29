import 'package:flutter/foundation.dart';

import '../../domain/hexaiq_models.dart';
import '../../domain/hexaiq_repository.dart';

enum SubmitResult { nextQuestion, domainComplete }

class HexaIQAppState extends ChangeNotifier {
  HexaIQAppState({required this.repository}) {
    loadInitialData();
  }

  final HexaIQRepository repository;

  List<UserProfile> profiles = [];
  UserProfile? selectedProfile;
  TestType selectedTestType = TestType.basic;
  List<TestQuestion> questions = [];
  List<QuestionResponse> responses = [];
  ReportSummary? report;
  List<GrowthPoint> growth = [];
  CognitiveDomain? lastCompletedDomain;
  int questionIndex = 0;
  int rewardedAdsCompleted = 0;
  bool hasProfessionalAccess = false;
  bool isBusy = false;

  TestQuestion? get currentQuestion {
    if (questionIndex < questions.length) {
      return questions[questionIndex];
    }
    return null;
  }

  double get testProgress {
    if (questions.isEmpty) {
      return 0;
    }
    return responses.length / questions.length;
  }

  int get requiredAds => switch (selectedTestType) {
    TestType.basic => 2,
    TestType.advanced => 6,
    TestType.professional => 0,
  };

  bool get hasMoreQuestions => currentQuestion != null;

  bool get canCreateProfile => profiles.length < 3;

  Future<void> loadInitialData() async {
    profiles = await repository.loadProfiles();
    selectedProfile = profiles.isNotEmpty ? profiles.first : null;
    if (selectedProfile != null) {
      growth = await repository.loadGrowth(selectedProfile!);
    }
    notifyListeners();
  }

  Future<void> createProfile({
    required String name,
    required String ageGroup,
    required String grade,
  }) async {
    if (!canCreateProfile) {
      return;
    }
    final profile = UserProfile(
      id: 'profile-${profiles.length + 1}',
      name: name,
      ageGroup: ageGroup,
      grade: grade,
      avatar: name.isEmpty ? '?' : name.substring(0, 1),
    );
    profiles = [...profiles, profile];
    selectedProfile = profile;
    growth = await repository.loadGrowth(profile);
    notifyListeners();
  }

  Future<void> selectProfile(UserProfile profile) async {
    selectedProfile = profile;
    growth = await repository.loadGrowth(profile);
    notifyListeners();
  }

  void selectTestType(TestType type) {
    selectedTestType = type;
    notifyListeners();
  }

  Future<void> startTest() async {
    isBusy = true;
    notifyListeners();
    questions = await repository.loadQuestions(
      selectedTestType,
      profile: selectedProfile,
    );
    responses = [];
    report = null;
    questionIndex = 0;
    rewardedAdsCompleted = 0;
    lastCompletedDomain = null;
    isBusy = false;
    notifyListeners();
  }

  SubmitResult submitAnswer(int selectedIndex) {
    final question = currentQuestion;
    if (question == null) {
      return SubmitResult.domainComplete;
    }

    responses = [
      ...responses,
      QuestionResponse(question: question, selectedIndex: selectedIndex),
    ];
    questionIndex += 1;

    final next = currentQuestion;
    if (next == null || next.domain != question.domain) {
      lastCompletedDomain = question.domain;
      notifyListeners();
      return SubmitResult.domainComplete;
    }

    notifyListeners();
    return SubmitResult.nextQuestion;
  }

  Future<void> completeRewardAd() async {
    final ok = await repository.verifyRewardAd(
      testType: selectedTestType,
      index: rewardedAdsCompleted,
    );
    if (ok) {
      rewardedAdsCompleted += 1;
      notifyListeners();
    }
  }

  Future<void> purchaseProfessional() async {
    isBusy = true;
    notifyListeners();
    hasProfessionalAccess = await repository.verifyPayment(
      testType: TestType.professional,
    );
    isBusy = false;
    notifyListeners();
  }

  Future<void> buildReport() async {
    isBusy = true;
    notifyListeners();
    await Future<void>.delayed(const Duration(milliseconds: 800));
    report = await repository.buildReport(responses);
    isBusy = false;
    notifyListeners();
  }
}
