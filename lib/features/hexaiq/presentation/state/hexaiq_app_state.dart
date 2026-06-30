import 'package:flutter/material.dart';

import '../../../../core/domain/difficulty_profile.dart';
import '../../../../core/domain/intelligence_domain.dart';
import '../../../../core/domain/question_difficulty.dart';
import '../../../cat/domain/theta_estimate.dart';
import '../../../item_bank/domain/exposure_status.dart';
import '../../../question_engine/core/question_engine.dart';
import '../../../question_engine/domain/question_engine_models.dart';
import '../../../test/application/test_session_controller.dart';
import '../../../test/domain/models/test_session.dart';
import '../../domain/hexaiq_models.dart';
import '../../domain/hexaiq_repository.dart';

enum SubmitResult { nextQuestion, domainComplete }

class HexaIQAppState extends ChangeNotifier {
  HexaIQAppState({required this.repository, QuestionEngine? questionEngine})
    : questionEngine = questionEngine ?? QuestionEngine() {
    loadInitialData();
  }

  final HexaIQRepository repository;
  final QuestionEngine questionEngine;
  static const int _targetQuestionCount = 5;

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
  bool profilesLoaded = false;
  ThemeMode themeMode = ThemeMode.dark;

  TestQuestion? get currentQuestion {
    return testSessionController?.session.currentQuestion;
  }

  double get testProgress {
    final total = testSessionController?.session.targetQuestionCount ?? 0;
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
    return session.currentQuestionIndex == session.targetQuestionCount - 1;
  }

  int get correctCount {
    final session = testSession;
    if (session == null) {
      return 0;
    }
    return session.activeQuestions.where((question) {
      return session.selectedAnswerFor(question.id) == question.answerIndex;
    }).length;
  }

  int get wrongCount {
    final session = testSession;
    if (session == null) {
      return 0;
    }
    return session.activeQuestions.length - correctCount;
  }

  int get totalQuestionCount =>
      testSession?.targetQuestionCount ?? questions.length;

  double get accuracy {
    if (totalQuestionCount == 0) {
      return 0;
    }
    return correctCount / totalQuestionCount;
  }

  int get totalElapsedSeconds => testSession?.totalElapsedSeconds ?? 0;

  int get itemBankQuestionCount =>
      questionEngine.itemBankRepository.load().length;

  Map<IntelligenceDomain, int> get itemBankDomainCounts {
    return {
      for (final domain in IntelligenceDomain.values)
        domain: questionEngine.itemBankRepository.findByDomain(domain).length,
    };
  }

  List<ExposureStatus> get exposureStatuses {
    return [
      for (final item in questionEngine.itemBankRepository.load())
        questionEngine.exposureRepository.load(item.id),
    ];
  }

  List<ExposureStatus> get usedExposureStatuses {
    final statuses = exposureStatuses
        .where((status) => status.exposureCount > 0)
        .toList(growable: false);
    return statuses;
  }

  double get averageExposure {
    final statuses = exposureStatuses;
    if (statuses.isEmpty) {
      return 0;
    }
    final total = statuses.fold<int>(
      0,
      (sum, status) => sum + status.exposureCount,
    );
    return total / statuses.length;
  }

  ExposureStatus? get mostUsedExposure {
    final statuses = usedExposureStatuses;
    if (statuses.isEmpty) {
      return null;
    }
    return statuses.reduce(
      (a, b) => a.exposureCount >= b.exposureCount ? a : b,
    );
  }

  ExposureStatus? get leastUsedExposure {
    final statuses = exposureStatuses;
    if (statuses.isEmpty) {
      return null;
    }
    return statuses.reduce(
      (a, b) => a.exposureCount <= b.exposureCount ? a : b,
    );
  }

  List<ExposureStatus> get topExposureStatuses {
    final statuses = [...usedExposureStatuses];
    statuses.sort((a, b) {
      final countCompare = b.exposureCount.compareTo(a.exposureCount);
      if (countCompare != 0) {
        return countCompare;
      }
      return a.itemId.compareTo(b.itemId);
    });
    return statuses.take(5).toList(growable: false);
  }

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
    profilesLoaded = true;
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

  Future<void> deleteProfile(UserProfile profile) async {
    profiles = profiles.where((item) => item.id != profile.id).toList();
    if (selectedProfile?.id == profile.id) {
      selectedProfile = profiles.isNotEmpty ? profiles.first : null;
      growth = selectedProfile == null
          ? const []
          : await repository.loadGrowth(selectedProfile!);
    }
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
    if (selectedProfile == null) {
      if (profiles.isEmpty) {
        profiles = await repository.loadProfiles();
      }
      selectedProfile = profiles.isNotEmpty ? profiles.first : null;
    }
    final profile = selectedProfile;
    if (profile == null) {
      isBusy = false;
      notifyListeners();
      return;
    }
    final startedAt = DateTime.now();
    final sessionId = 'session-${startedAt.millisecondsSinceEpoch}';
    final baseSeed = startedAt.millisecondsSinceEpoch & 0x7fffffff;
    final firstQuestion = _generateDynamicQuestion(
      profile: profile,
      sessionId: sessionId,
      baseSeed: baseSeed,
      index: 0,
      domain: IntelligenceDomain.numerical,
      difficulty: QuestionDifficulty.normal,
      difficultyProfile: DifficultyProfile.initial(),
      usedSeeds: const {},
      usedItemIds: const {},
      thetaEstimate: ThetaEstimate.initial(),
    );
    testSessionController = TestSessionController(
      TestSession(
        sessionId: sessionId,
        startedAt: startedAt,
        domain: CognitiveDomain.numerical,
        questions: [firstQuestion],
        generatedQuestions: [firstQuestion],
        targetQuestionCount: _targetQuestionCount,
        difficultyByQuestionId: {firstQuestion.id: firstQuestion.difficulty},
        usedItemIds: {if (firstQuestion.itemId != null) firstQuestion.itemId!},
        baseSeed: baseSeed,
      ),
    );
    questions = [firstQuestion];
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
    final controller = testSessionController;
    final profile = selectedProfile;
    if (controller == null || profile == null) {
      return;
    }
    controller.nextQuestion(
      generateNextQuestion: (session) {
        final index = session.activeQuestions.length;
        final difficulty = session.difficultyProfile.currentDifficulty;
        final previousDifficulty = session.questionHistory.isEmpty
            ? QuestionDifficulty.normal
            : session.questionHistory.last.difficulty;
        final reason = _adaptiveReason(session);
        debugPrint(
          '[Adaptive] Question${index + 1} '
          '${previousDifficulty.label} -> ${difficulty.label} '
          'Reason $reason',
        );
        final generated = _generateDynamicQuestion(
          profile: profile,
          sessionId: session.sessionId,
          baseSeed: session.baseSeed,
          index: index,
          domain: session.domain,
          difficulty: difficulty,
          difficultyProfile: session.difficultyProfile,
          usedSeeds: {
            for (final question in session.activeQuestions) question.seed,
            for (final record in session.questionHistory) record.seed,
          },
          usedItemIds: {
            ...session.usedItemIds,
            for (final question in session.activeQuestions)
              if (question.itemId != null) question.itemId!,
            for (final record in session.questionHistory) record.itemId,
          },
          thetaEstimate: session.thetaEstimate,
        );
        debugPrint(
          '[QuestionEngine] Generated Question${index + 1} '
          'difficulty=${generated.difficulty.name} seed=${generated.seed}',
        );
        return generated;
      },
    );
    questions = controller.session.activeQuestions;
    questionIndex = controller.session.currentQuestionIndex;
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
      for (final question in session.activeQuestions)
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

  TestQuestion _generateDynamicQuestion({
    required UserProfile profile,
    required String sessionId,
    required int baseSeed,
    required int index,
    required IntelligenceDomain domain,
    required QuestionDifficulty difficulty,
    required DifficultyProfile difficultyProfile,
    required Set<int> usedSeeds,
    required Set<String> usedItemIds,
    required ThetaEstimate thetaEstimate,
  }) {
    final seed = _dynamicSeed(
      baseSeed: baseSeed,
      index: index,
      difficulty: difficulty,
      domain: domain,
      usedSeeds: usedSeeds,
    );
    final level = questionEngine.difficultyManager.resolveLevel(
      ageGroup: profile.ageGroup,
      requestedLevel: null,
      testTypeOffset: _testTypeOffset(selectedTestType),
    );
    final dto = questionEngine.generateOne(
      seed: seed,
      domain: domain,
      difficulty: difficulty,
      profileId: profile.id,
      testId: sessionId,
      ageGroup: profile.ageGroup,
      index: index,
      level: level,
      difficultyProfile: difficultyProfile,
      usedItemIds: usedItemIds,
      thetaEstimate: thetaEstimate,
    );
    return _toTestQuestion(dto);
  }

  int _dynamicSeed({
    required int baseSeed,
    required int index,
    required QuestionDifficulty difficulty,
    required IntelligenceDomain domain,
    required Set<int> usedSeeds,
  }) {
    var seed =
        baseSeed + index * 1009 + difficulty.level * 37 + domain.index * 7919;
    while (usedSeeds.contains(seed)) {
      seed += 104729;
    }
    return seed;
  }

  int _testTypeOffset(TestType type) {
    return switch (type) {
      TestType.basic => 0,
      TestType.advanced => 1,
      TestType.professional => 1,
    };
  }

  String _adaptiveReason(TestSession session) {
    final marks = session.questionHistory
        .map((record) => record.correct == true ? 'O' : 'X')
        .toList(growable: false);
    if (marks.length >= 2) {
      return marks.sublist(marks.length - 2).join();
    }
    return marks.isEmpty ? 'initial' : marks.last;
  }

  TestQuestion _toTestQuestion(GeneratedQuestionDto dto) {
    return TestQuestion(
      id: dto.id,
      domain: dto.domain,
      typeCode: dto.typeCode,
      level: dto.level,
      prompt: dto.question,
      choices: dto.choices,
      answerIndex: dto.answerIndex,
      explanation: dto.explanation,
      difficulty: dto.difficulty,
      seed: dto.seed,
      difficultyIndex: dto.difficultyIndex,
      discrimination: dto.discrimination,
      guessing: dto.guessing,
      expectedSolveTime: dto.expectedSolveTime,
      itemId: dto.itemId,
      selectionScore: dto.selectionScore,
      itemInformation: dto.itemInformation,
      catSelectionScore: dto.catSelectionScore,
      hint: dto.hint,
    );
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
