import '../../../../core/domain/domain_result.dart';
import '../../../../core/domain/intelligence_domain.dart';
import '../../../hexaiq/domain/hexaiq_models.dart';

class TestSession {
  const TestSession({
    required this.sessionId,
    required this.startedAt,
    this.domain = IntelligenceDomain.numerical,
    this.completedAt,
    this.currentQuestionIndex = 0,
    this.questions = const [],
    this.selectedAnswers = const {},
    this.elapsedSeconds = const {},
    this.domainResults = const {},
    this.totalElapsedSeconds = 0,
  });

  final String sessionId;
  final DateTime startedAt;
  final IntelligenceDomain domain;
  final DateTime? completedAt;
  final int currentQuestionIndex;
  final List<TestQuestion> questions;
  final Map<String, int> selectedAnswers;
  final Map<String, int> elapsedSeconds;
  final Map<IntelligenceDomain, DomainResult> domainResults;
  final int totalElapsedSeconds;

  TestQuestion? get currentQuestion {
    if (currentQuestionIndex < 0 || currentQuestionIndex >= questions.length) {
      return null;
    }
    return questions[currentQuestionIndex];
  }

  bool get isComplete => completedAt != null;

  int? selectedAnswerFor(String questionId) => selectedAnswers[questionId];

  int elapsedFor(String questionId) => elapsedSeconds[questionId] ?? 0;

  TestSession copyWith({
    String? sessionId,
    DateTime? startedAt,
    IntelligenceDomain? domain,
    DateTime? completedAt,
    bool clearCompletedAt = false,
    int? currentQuestionIndex,
    List<TestQuestion>? questions,
    Map<String, int>? selectedAnswers,
    Map<String, int>? elapsedSeconds,
    Map<IntelligenceDomain, DomainResult>? domainResults,
    int? totalElapsedSeconds,
  }) {
    return TestSession(
      sessionId: sessionId ?? this.sessionId,
      startedAt: startedAt ?? this.startedAt,
      domain: domain ?? this.domain,
      completedAt: clearCompletedAt ? null : completedAt ?? this.completedAt,
      currentQuestionIndex: currentQuestionIndex ?? this.currentQuestionIndex,
      questions: questions ?? this.questions,
      selectedAnswers: selectedAnswers ?? this.selectedAnswers,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      domainResults: domainResults ?? this.domainResults,
      totalElapsedSeconds: totalElapsedSeconds ?? this.totalElapsedSeconds,
    );
  }
}
