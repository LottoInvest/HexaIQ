import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/domain/difficulty_profile.dart';
import '../../../../core/domain/intelligence_domain.dart';
import '../../../../core/domain/question_difficulty.dart';
import '../../../../core/persistence/settings_repository.dart';
import '../../../calibration/domain/calibration_repository.dart';
import '../../../cat/domain/theta_estimate.dart';
import '../../../cat/domain/theta_estimation_method.dart';
import '../../../item_bank/domain/exposure_status.dart';
import '../../../norm/domain/norm_profile.dart';
import '../../../payment/domain/purchase_status.dart';
import '../../../question_engine/core/question_engine.dart';
import '../../../question_engine/domain/question_engine_models.dart';
import '../../../report/domain/domain_score_calculator.dart';
import '../../../report/domain/report_localization.dart';
import '../../../result/domain/result_integrity_validator.dart';
import '../../../result/domain/test_result_builder.dart';
import '../../../test/application/test_session_controller.dart';
import '../../../test/domain/adaptive/adaptive_engine.dart' as adaptive_v094;
import '../../../test/domain/generators/multi_domain_item_engine.dart';
import '../../../test/domain/models/test_session.dart';
import '../../../test/domain/models/test_mode.dart';
import '../../domain/hexaiq_models.dart';
import '../../domain/hexaiq_repository.dart';

enum SubmitResult { nextQuestion, domainComplete }

enum DomainProgressStatus { pending, current, completed }

class HexaIQAppState extends ChangeNotifier {
  HexaIQAppState({
    required this.repository,
    QuestionEngine? questionEngine,
    this.calibrationRepository,
    SettingsRepository? settingsRepository,
  }) : questionEngine = questionEngine ?? QuestionEngine(),
       settingsRepository = settingsRepository ?? InMemorySettingsRepository() {
    loadInitialData();
  }

  final HexaIQRepository repository;
  final QuestionEngine questionEngine;
  final CalibrationRepository? calibrationRepository;
  final SettingsRepository settingsRepository;
  static const int _basicQuestionCount = 30;
  static const int _quickIqQuestionCount = 60;
  static const int _advancedQuestionCount = 90;
  static const int _professionalQuestionCount = 120;
  static const MultiDomainItemEngine _multiDomainItemEngine =
      MultiDomainItemEngine();

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
  PurchaseStatus purchaseStatus = PurchaseStatus.free;
  Set<int> _shownMidAdBreakpoints = {};
  bool isBusy = false;
  bool profilesLoaded = false;
  ThemeMode themeMode = ThemeMode.dark;
  ThetaEstimationMethod thetaEstimationMethod =
      ThetaEstimationMethod.newtonRaphson;

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
    TestType.basic => 0,
    TestType.quickIq => 2,
    TestType.advanced => 3,
    TestType.professional => 0,
  };

  bool get hasMoreQuestions => currentQuestion != null;

  List<IntelligenceDomain> get activeDomainSequence {
    return _domainSequenceFor(selectedTestType);
  }

  Map<IntelligenceDomain, DomainProgressStatus> get domainProgress {
    final sequence = activeDomainSequence;
    final status = <IntelligenceDomain, DomainProgressStatus>{
      for (final domain in sequence) domain: DomainProgressStatus.pending,
    };
    final session = testSession;
    if (session != null) {
      for (final question in session.activeQuestions) {
        if (session.selectedAnswerFor(question.id) != null &&
            status.containsKey(question.domain)) {
          status[question.domain] = DomainProgressStatus.completed;
        }
      }
    }
    final current = currentQuestion?.domain;
    if (current != null && status.containsKey(current)) {
      status[current] = DomainProgressStatus.current;
    }
    return status;
  }

  bool get canCreateProfile => profiles.length < 3;

  void setThemeMode(ThemeMode mode) {
    themeMode = mode;
    unawaited(settingsRepository.saveThemeMode(mode));
    notifyListeners();
  }

  void setThetaEstimationMethod(ThetaEstimationMethod method) {
    thetaEstimationMethod = method;
    notifyListeners();
  }

  Future<void> loadInitialData() async {
    themeMode = await settingsRepository.loadThemeMode();
    purchaseStatus = await repository.loadPurchaseStatus();
    hasProfessionalAccess = purchaseStatus.hasProfessionalAccess;
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
    final createdAt = DateTime.now();
    final profile = UserProfile(
      id: 'profile-${createdAt.microsecondsSinceEpoch}',
      name: name,
      ageGroup: ageGroup,
      grade: grade,
      avatar: name.isEmpty ? '?' : name.substring(0, 1),
    );
    profiles = [...profiles, profile];
    selectedProfile = profile;
    _clearProfileScopedState();
    await repository.saveProfiles(profiles);
    growth = await repository.loadGrowth(profile);
    notifyListeners();
  }

  Future<void> deleteProfile(UserProfile profile) async {
    profiles = profiles.where((item) => item.id != profile.id).toList();
    if (selectedProfile?.id == profile.id) {
      selectedProfile = profiles.isNotEmpty ? profiles.first : null;
      _clearProfileScopedState();
      growth = selectedProfile == null
          ? const []
          : await repository.loadGrowth(selectedProfile!);
    }
    await repository.saveProfiles(profiles);
    notifyListeners();
  }

  Future<void> selectProfile(UserProfile profile) async {
    selectedProfile = profile;
    _clearProfileScopedState();
    growth = await repository.loadGrowth(profile);
    notifyListeners();
  }

  void selectTestType(TestType type) {
    selectedTestType = type;
    _shownMidAdBreakpoints = {};
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
    final targetQuestionCount = _targetQuestionCountFor(selectedTestType);
    final testMode = testModeFromTestType(selectedTestType);
    final firstDomain = _domainForQuestionIndex(0);
    final foundationItems = _multiDomainItemEngine.generate(
      mode: testMode,
      domain: firstDomain,
      count: targetQuestionCount,
    );
    final firstQuestion = _generateDynamicQuestion(
      profile: profile,
      sessionId: sessionId,
      baseSeed: baseSeed,
      index: 0,
      domain: firstDomain,
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
        mode: testMode,
        domain: firstDomain,
        questions: [firstQuestion],
        generatedQuestions: [firstQuestion],
        items: foundationItems,
        targetQuestionCount: targetQuestionCount,
        difficultyByQuestionId: {firstQuestion.id: firstQuestion.difficulty},
        usedItemIds: {if (firstQuestion.itemId != null) firstQuestion.itemId!},
        baseSeed: baseSeed,
        thetaEstimationMethod: thetaEstimationMethod,
        normProfile: NormProfile.forAgeGroup(AgeGroup.parse(profile.ageGroup)),
      ),
      calibrationRepository: calibrationRepository,
    );
    questions = [firstQuestion];
    responses = [];
    report = null;
    questionIndex = 0;
    rewardedAdsCompleted = 0;
    _shownMidAdBreakpoints = {};
    lastCompletedDomain = null;
    isBusy = false;
    await _saveActiveSession();
    notifyListeners();
  }

  Future<bool> resumeActiveSession() async {
    final profile = selectedProfile;
    if (profile == null) {
      return false;
    }
    final session = await repository.loadActiveTestSession(profile.id);
    if (session == null) {
      return false;
    }
    testSessionController = TestSessionController(
      session,
      calibrationRepository: calibrationRepository,
    );
    questions = session.activeQuestions;
    responses = [
      for (final question in session.activeQuestions)
        if (session.selectedAnswerFor(question.id) != null)
          QuestionResponse(
            question: question,
            selectedIndex: session.selectedAnswerFor(question.id)!,
          ),
    ];
    report = null;
    questionIndex = session.currentQuestionIndex;
    lastCompletedDomain = null;
    notifyListeners();
    return true;
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
    _saveActiveSessionSoon();
    notifyListeners();
  }

  void recordElapsedTime(int seconds) {
    testSessionController?.recordElapsedTime(seconds);
    _saveActiveSessionSoon();
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
        final domain = _domainForQuestionIndex(index);
        final thetaEstimate = session.thetaForDomain(domain);
        final difficulty = _higherDifficulty(
          session.difficultyProfile.currentDifficulty,
          const adaptive_v094.AdaptiveEngine().difficultyForTheta(
            thetaEstimate.theta,
          ),
        );
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
          domain: domain,
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
          thetaEstimate: thetaEstimate,
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
    _saveActiveSessionSoon();
    notifyListeners();
  }

  bool consumeMidAdBreakForCurrentQuestion() {
    final session = testSession;
    if (session == null ||
        (selectedTestType != TestType.quickIq &&
            selectedTestType != TestType.advanced)) {
      return false;
    }
    final completedQuestionCount = session.currentQuestionIndex + 1;
    final perDomain = _questionsPerDomainFor(selectedTestType);
    if (completedQuestionCount % perDomain != 0) {
      return false;
    }
    final completedDomains = completedQuestionCount ~/ perDomain;
    final isCheckpoint = switch (selectedTestType) {
      TestType.quickIq => completedDomains == 3,
      TestType.advanced => completedDomains == 2 || completedDomains == 4,
      TestType.basic || TestType.professional => false,
    };
    if (!isCheckpoint) {
      return false;
    }
    if (_shownMidAdBreakpoints.contains(completedDomains)) {
      return false;
    }
    _shownMidAdBreakpoints = {..._shownMidAdBreakpoints, completedDomains};
    return true;
  }

  void previousQuestion() {
    testSessionController?.previousQuestion();
    questionIndex = testSessionController?.session.currentQuestionIndex ?? 0;
    _saveActiveSessionSoon();
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
    const domainScoreCalculator = DomainScoreCalculator();
    report = builtReport.copyWith(
      domainResults: session.domainResults,
      domainScores: domainScoreCalculator.scoresFromResults(
        session.domainResults,
      ),
      summary: ReportLocalization.summary,
      recommendations: ReportLocalization.trainingRecommendations(
        session.domainResults,
      ),
      averageDifficulty: session.averageDifficulty,
    );
    final profile = selectedProfile;
    if (profile != null) {
      final result = const TestResultBuilder().build(
        session: session,
        profileId: profile.id,
      );
      final integrity = const ResultIntegrityValidator().validate(result);
      if (!integrity.isValid) {
        throw StateError(
          'Invalid TestResultSummary: ${integrity.errors.join(', ')}',
        );
      }
      await repository.saveTestResult(result);
      final updatedProfile = profile.copyWith(
        recentIQ: session.estimatedIQ,
        recentPercentile: session.percentile,
        recentAbilityLevel: session.abilityLevel.labelKo,
        lastTestAt: result.completedAt,
        testCount: profile.testCount + 1,
      );
      profiles = [
        for (final item in profiles)
          item.id == updatedProfile.id ? updatedProfile : item,
      ];
      selectedProfile = updatedProfile;
      await repository.saveProfiles(profiles);
      growth = await repository.loadGrowth(updatedProfile);
      await repository.clearActiveTestSession(updatedProfile.id);
    }
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
      TestType.quickIq => 0,
      TestType.advanced => 1,
      TestType.professional => 1,
    };
  }

  QuestionDifficulty _higherDifficulty(
    QuestionDifficulty current,
    QuestionDifficulty thetaBased,
  ) {
    return current.level >= thetaBased.level ? current : thetaBased;
  }

  int _targetQuestionCountFor(TestType type) {
    return switch (type) {
      TestType.quickIq => _quickIqQuestionCount,
      TestType.advanced => _advancedQuestionCount,
      TestType.professional => _professionalQuestionCount,
      _ => _basicQuestionCount,
    };
  }

  IntelligenceDomain _domainForQuestionIndex(int index) {
    final domains = _domainSequenceFor(selectedTestType);
    final perDomain = _questionsPerDomainFor(selectedTestType);
    final domainIndex = (index ~/ perDomain).clamp(0, domains.length - 1);
    return domains[domainIndex];
  }

  List<IntelligenceDomain> _domainSequenceFor(TestType type) {
    return switch (type) {
      TestType.quickIq => IntelligenceDomain.values,
      _ => IntelligenceDomain.values,
    };
  }

  int _questionsPerDomainFor(TestType type) {
    return switch (type) {
      TestType.basic => 5,
      TestType.quickIq => 10,
      TestType.advanced => 15,
      TestType.professional => 20,
    };
  }

  void _clearProfileScopedState() {
    testSessionController = null;
    questions = [];
    responses = [];
    report = null;
    lastCompletedDomain = null;
    questionIndex = 0;
    rewardedAdsCompleted = 0;
    _shownMidAdBreakpoints = {};
    isBusy = false;
  }

  Future<void> _saveActiveSession() async {
    final profile = selectedProfile;
    final session = testSessionController?.session;
    if (profile == null || session == null || session.isComplete) {
      return;
    }
    await repository.saveActiveTestSession(
      profileId: profile.id,
      session: session,
    );
  }

  void _saveActiveSessionSoon() {
    unawaited(_saveActiveSession());
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
      upperAsymptote: dto.upperAsymptote,
      expectedSolveTime: dto.expectedSolveTime,
      itemId: dto.itemId,
      selectionScore: dto.selectionScore,
      itemInformation: dto.itemInformation,
      catSelectionScore: dto.catSelectionScore,
      hint: dto.hint,
      ruleName: dto.ruleName,
      solution: dto.solution,
      solutionExplanation: dto.solutionExplanation,
      variables: dto.variables,
      stimulus: dto.stimulus,
      stimulusDuration: dto.stimulusDuration,
      requiresMemoryPhase: dto.requiresMemoryPhase,
      timeLimit: dto.timeLimit,
      reactionScore: dto.reactionScore,
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
    final verified = await repository.verifyPayment(
      testType: TestType.professional,
    );
    if (verified) {
      purchaseStatus = PurchaseStatus.professionalPurchased;
      hasProfessionalAccess = true;
      await repository.savePurchaseStatus(purchaseStatus);
    }
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
