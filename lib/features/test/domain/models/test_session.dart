import '../../../hexaiq/domain/hexaiq_models.dart';

class TestSession {
  const TestSession({
    required this.sessionId,
    required this.startedAt,
    this.completedAt,
    this.currentQuestionIndex = 0,
    this.questions = const [],
    this.selectedAnswers = const {},
    this.elapsedSeconds = const {},
    this.totalElapsedSeconds = 0,
  });

  final String sessionId;
  final DateTime startedAt;
  final DateTime? completedAt;
  final int currentQuestionIndex;
  final List<TestQuestion> questions;
  final Map<String, int> selectedAnswers;
  final Map<String, int> elapsedSeconds;
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
    DateTime? completedAt,
    bool clearCompletedAt = false,
    int? currentQuestionIndex,
    List<TestQuestion>? questions,
    Map<String, int>? selectedAnswers,
    Map<String, int>? elapsedSeconds,
    int? totalElapsedSeconds,
  }) {
    return TestSession(
      sessionId: sessionId ?? this.sessionId,
      startedAt: startedAt ?? this.startedAt,
      completedAt: clearCompletedAt ? null : completedAt ?? this.completedAt,
      currentQuestionIndex: currentQuestionIndex ?? this.currentQuestionIndex,
      questions: questions ?? this.questions,
      selectedAnswers: selectedAnswers ?? this.selectedAnswers,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      totalElapsedSeconds: totalElapsedSeconds ?? this.totalElapsedSeconds,
    );
  }
}
