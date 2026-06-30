import '../../../core/domain/domain_result.dart';
import '../../../core/domain/intelligence_domain.dart';
import '../domain/models/test_session.dart';

class TestSessionController {
  TestSessionController(this.session);

  TestSession session;

  void selectAnswer(int selectedOption) {
    final question = session.currentQuestion;
    if (question == null) {
      return;
    }
    session = session.copyWith(
      selectedAnswers: {
        ...session.selectedAnswers,
        question.id: selectedOption,
      },
    );
  }

  void nextQuestion() {
    if (session.currentQuestionIndex >= session.questions.length - 1) {
      return;
    }
    session = session.copyWith(
      currentQuestionIndex: session.currentQuestionIndex + 1,
    );
  }

  void previousQuestion() {
    if (session.currentQuestionIndex <= 0) {
      return;
    }
    session = session.copyWith(
      currentQuestionIndex: session.currentQuestionIndex - 1,
    );
  }

  void recordElapsedTime(int seconds) {
    if (seconds <= 0) {
      return;
    }
    final question = session.currentQuestion;
    if (question == null) {
      return;
    }
    final nextElapsed = {
      ...session.elapsedSeconds,
      question.id: session.elapsedFor(question.id) + seconds,
    };
    session = session.copyWith(
      elapsedSeconds: nextElapsed,
      totalElapsedSeconds: session.totalElapsedSeconds + seconds,
    );
  }

  TestSession submit({DateTime? completedAt}) {
    return finish(completedAt: completedAt);
  }

  TestSession finish({DateTime? completedAt}) {
    session = session.copyWith(
      completedAt: completedAt ?? DateTime.now(),
      domainResults: _calculateDomainResults(),
    );
    return session;
  }

  Map<IntelligenceDomain, DomainResult> _calculateDomainResults() {
    final results = <IntelligenceDomain, DomainResult>{};
    for (final domain in IntelligenceDomain.values) {
      final domainQuestions = session.questions
          .where((question) => question.domain == domain)
          .toList(growable: false);
      if (domainQuestions.isEmpty) {
        results[domain] = const DomainResult();
        continue;
      }
      final correct = domainQuestions.where((question) {
        return session.selectedAnswerFor(question.id) == question.answerIndex;
      }).length;
      final wrong = domainQuestions.length - correct;
      final elapsed = domainQuestions.fold<int>(
        0,
        (sum, question) => sum + session.elapsedFor(question.id),
      );
      results[domain] = DomainResult(
        correct: correct,
        wrong: wrong,
        accuracy: correct / domainQuestions.length,
        elapsed: elapsed,
      );
    }
    return results;
  }
}
