import '../../../../core/domain/domain_result.dart';
import '../../../../core/domain/difficulty_profile.dart';
import '../../../../core/domain/intelligence_domain.dart';
import '../../../../core/domain/question_difficulty.dart';
import '../../../cat/domain/theta_estimate.dart';
import '../../../hexaiq/domain/hexaiq_models.dart';
import 'question_record.dart';

class TestSession {
  TestSession({
    required this.sessionId,
    required this.startedAt,
    this.domain = IntelligenceDomain.numerical,
    this.completedAt,
    this.currentQuestionIndex = 0,
    this.questions = const [],
    this.generatedQuestions = const [],
    this.targetQuestionCount = 5,
    this.selectedAnswers = const {},
    this.elapsedSeconds = const {},
    this.domainResults = const {},
    this.difficultyProfile = const DifficultyProfile(),
    this.difficultyByQuestionId = const {},
    this.questionHistory = const [],
    ThetaEstimate? thetaEstimate,
    List<ThetaEstimate>? thetaHistory,
    this.adaptiveRecordedQuestionIds = const {},
    this.usedItemIds = const {},
    this.totalElapsedSeconds = 0,
    this.baseSeed = 0,
    this.showDebugMetrics = false,
  }) : thetaEstimate = thetaEstimate ?? ThetaEstimate.initial(),
       thetaHistory = thetaHistory ?? const [];

  final String sessionId;
  final DateTime startedAt;
  final IntelligenceDomain domain;
  final DateTime? completedAt;
  final int currentQuestionIndex;
  final List<TestQuestion> questions;
  final List<TestQuestion> generatedQuestions;
  final int targetQuestionCount;
  final Map<String, int> selectedAnswers;
  final Map<String, int> elapsedSeconds;
  final Map<IntelligenceDomain, DomainResult> domainResults;
  final DifficultyProfile difficultyProfile;
  final Map<String, QuestionDifficulty> difficultyByQuestionId;
  final List<QuestionRecord> questionHistory;
  final ThetaEstimate thetaEstimate;
  final List<ThetaEstimate> thetaHistory;
  final Set<String> adaptiveRecordedQuestionIds;
  final Set<String> usedItemIds;
  final int totalElapsedSeconds;
  final int baseSeed;
  final bool showDebugMetrics;

  List<TestQuestion> get activeQuestions {
    return generatedQuestions.isNotEmpty ? generatedQuestions : questions;
  }

  TestQuestion? get currentQuestion {
    if (currentQuestionIndex < 0 ||
        currentQuestionIndex >= activeQuestions.length) {
      return null;
    }
    return activeQuestions[currentQuestionIndex];
  }

  bool get isComplete => completedAt != null;

  int? selectedAnswerFor(String questionId) => selectedAnswers[questionId];

  int elapsedFor(String questionId) => elapsedSeconds[questionId] ?? 0;

  QuestionDifficulty get averageDifficulty {
    final historyValues = questionHistory
        .map((record) => record.difficulty)
        .toList(growable: false);
    final values = historyValues.isNotEmpty
        ? historyValues
        : difficultyByQuestionId.isNotEmpty
        ? difficultyByQuestionId.values.toList(growable: false)
        : activeQuestions
              .map((question) => question.difficulty)
              .toList(growable: false);
    if (values.isEmpty) {
      return QuestionDifficulty.normal;
    }
    final average =
        values.map((difficulty) => difficulty.level).reduce((a, b) => a + b) /
        values.length;
    return QuestionDifficulty.values.reduce((nearest, difficulty) {
      final nearestDistance = (nearest.level - average).abs();
      final currentDistance = (difficulty.level - average).abs();
      return currentDistance < nearestDistance ? difficulty : nearest;
    });
  }

  int get averageElapsedSeconds {
    if (questionHistory.isEmpty) {
      return 0;
    }
    final total = questionHistory.fold<int>(
      0,
      (sum, record) => sum + record.elapsedSeconds,
    );
    return (total / questionHistory.length).round();
  }

  double get averageItemInformation {
    if (questionHistory.isEmpty) {
      return 0;
    }
    final total = questionHistory.fold<double>(
      0,
      (sum, record) => sum + record.itemInformation,
    );
    return total / questionHistory.length;
  }

  double get averageCatSelectionScore {
    if (questionHistory.isEmpty) {
      return 0;
    }
    final total = questionHistory.fold<double>(
      0,
      (sum, record) => sum + record.catSelectionScore,
    );
    return total / questionHistory.length;
  }

  TestSession copyWith({
    String? sessionId,
    DateTime? startedAt,
    IntelligenceDomain? domain,
    DateTime? completedAt,
    bool clearCompletedAt = false,
    int? currentQuestionIndex,
    List<TestQuestion>? questions,
    List<TestQuestion>? generatedQuestions,
    int? targetQuestionCount,
    Map<String, int>? selectedAnswers,
    Map<String, int>? elapsedSeconds,
    Map<IntelligenceDomain, DomainResult>? domainResults,
    DifficultyProfile? difficultyProfile,
    Map<String, QuestionDifficulty>? difficultyByQuestionId,
    List<QuestionRecord>? questionHistory,
    ThetaEstimate? thetaEstimate,
    List<ThetaEstimate>? thetaHistory,
    Set<String>? adaptiveRecordedQuestionIds,
    Set<String>? usedItemIds,
    int? totalElapsedSeconds,
    int? baseSeed,
    bool? showDebugMetrics,
  }) {
    return TestSession(
      sessionId: sessionId ?? this.sessionId,
      startedAt: startedAt ?? this.startedAt,
      domain: domain ?? this.domain,
      completedAt: clearCompletedAt ? null : completedAt ?? this.completedAt,
      currentQuestionIndex: currentQuestionIndex ?? this.currentQuestionIndex,
      questions: questions ?? this.questions,
      generatedQuestions: generatedQuestions ?? this.generatedQuestions,
      targetQuestionCount: targetQuestionCount ?? this.targetQuestionCount,
      selectedAnswers: selectedAnswers ?? this.selectedAnswers,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      domainResults: domainResults ?? this.domainResults,
      difficultyProfile: difficultyProfile ?? this.difficultyProfile,
      difficultyByQuestionId:
          difficultyByQuestionId ?? this.difficultyByQuestionId,
      questionHistory: questionHistory ?? this.questionHistory,
      thetaEstimate: thetaEstimate ?? this.thetaEstimate,
      thetaHistory: thetaHistory ?? this.thetaHistory,
      adaptiveRecordedQuestionIds:
          adaptiveRecordedQuestionIds ?? this.adaptiveRecordedQuestionIds,
      usedItemIds: usedItemIds ?? this.usedItemIds,
      totalElapsedSeconds: totalElapsedSeconds ?? this.totalElapsedSeconds,
      baseSeed: baseSeed ?? this.baseSeed,
      showDebugMetrics: showDebugMetrics ?? this.showDebugMetrics,
    );
  }
}
