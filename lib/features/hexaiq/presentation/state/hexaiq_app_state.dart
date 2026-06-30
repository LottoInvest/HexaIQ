import 'package:flutter/material.dart';

import '../../../test/application/test_session_controller.dart';
import '../../../test/domain/models/test_session.dart';
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
  TestSessionController? testSessionController;
  ReportSummary? report;
  List<GrowthPoint> growth = [];
  CognitiveDomain? lastCompletedDomain;
  int questionIndex = 0;
  int rewardedAdsCompleted = 0;
  bool hasProfessionalAccess = false;
  bool isBusy = false;
  ThemeMode themeMode = ThemeMode.system;

  TestQuestion? get currentQuestion {
    return testSessionController?.session.currentQuestion;
  }

  double get testProgress {
    final total = testSessionController?.session.questions.length ?? 0;
    if (total == 0) {
      return 0;
    }
    return (questionIndex + 1) / total;
  }

  TestSession? get testSession => testSessionController?.session;

  int? get selectedAnswerForCurrentQuestion {
    final question = currentQuestion;
    if (question == null) {
      return null;
    }
    return testSession?.selectedAnswerFor(question.id);
  }

  bool get isLastQuestion {
    final session = testSession;
    if (session == null || session.questions.isEmpty) {
      return false;
    }
    return session.currentQuestionIndex == session.questions.length - 1;
  }

  int get correctCount {
    final session = testSession;
    if (session == null) {
      return 0;
    }
    return session.questions.where((question) {
      return session.selectedAnswerFor(question.id) == question.answerIndex;
    }).length;
  }

  int get wrongCount {
    final session = testSession;
    if (session == null) {
      return 0;
    }
    return session.questions.length - correctCount;
  }

  int get totalQuestionCount =>
      testSession?.questions.length ?? questions.length;

  double get accuracy {
    if (totalQuestionCount == 0) {
      return 0;
    }
    return correctCount / totalQuestionCount;
  }

  int get totalElapsedSeconds => testSession?.totalElapsedSeconds ?? 0;

  int get requiredAds => switch (selectedTestType) {
    TestType.basic => 2,
    TestType.advanced => 6,
    TestType.professional => 0,
  };

  bool get hasMoreQuestions => currentQuestion != null;

  bool get canCreateProfile => profiles.length < 3;

  void setThemeMode(ThemeMode mode) {
    themeMode = mode;
    notifyListeners();
  }

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
    final startedAt = DateTime.now();
    testSessionController = TestSessionController(
      TestSession(
        sessionId: 'session-${startedAt.millisecondsSinceEpoch}',
        startedAt: startedAt,
        domain: CognitiveDomain.numerical,
        questions: questions,
      ),
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

  void selectAnswer(int selectedIndex) {
    testSessionController?.selectAnswer(selectedIndex);
    notifyListeners();
  }

  void recordElapsedTime(int seconds) {
    testSessionController?.recordElapsedTime(seconds);
  }

  void nextQuestion() {
    testSessionController?.nextQuestion();
    questionIndex = testSessionController?.session.currentQuestionIndex ?? 0;
    notifyListeners();
  }

  void previousQuestion() {
    testSessionController?.previousQuestion();
    questionIndex = testSessionController?.session.currentQuestionIndex ?? 0;
    notifyListeners();
  }

  Future<void> submitTest() async {
    final controller = testSessionController;
    if (controller == null) {
      return;
    }
    controller.submit();
    final session = controller.session;
    responses = [
      for (final question in session.questions)
        QuestionResponse(
          question: question,
          selectedIndex: session.selectedAnswerFor(question.id) ?? -1,
        ),
    ];
    final builtReport = await repository.buildReport(responses);
    report = builtReport.copyWith(
      domainResults: session.domainResults,
      averageDifficulty: session.averageDifficulty,
    );
    notifyListeners();
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
