import '../../../core/domain/adaptive_difficulty_engine.dart';
import '../../../core/domain/domain_result.dart';
import '../../../core/domain/intelligence_domain.dart';
import '../domain/models/test_session.dart';

class TestSessionController {
  TestSessionController(
    this.session, {
    AdaptiveDifficultyEngine? adaptiveDifficultyEngine,
  }) : _adaptiveDifficultyEngine =
           adaptiveDifficultyEngine ?? const AdaptiveDifficultyEngine();

  TestSession session;
  final AdaptiveDifficultyEngine _adaptiveDifficultyEngine;

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
    _recordAdaptiveForCurrentQuestion();
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
    _recordAdaptiveForCurrentQuestion();
    session = session.copyWith(
      completedAt: completedAt ?? DateTime.now(),
      domainResults: _calculateDomainResults(),
    );
    return session;
  }

  void _recordAdaptiveForCurrentQuestion() {
    final question = session.currentQuestion;
    if (question == null ||
        session.adaptiveRecordedQuestionIds.contains(question.id)) {
      return;
    }
    final selected = session.selectedAnswerFor(question.id);
    if (selected == null) {
      return;
    }
    final nextProfile = _adaptiveDifficultyEngine.recordAnswer(
      profile: session.difficultyProfile,
      isCorrect: selected == question.answerIndex,
    );
    final nextQuestions = [...session.questions];
    final nextDifficultyByQuestionId = {
      ...session.difficultyByQuestionId,
      question.id: question.difficulty,
    };
    final nextIndex = session.currentQuestionIndex + 1;
    if (nextIndex < nextQuestions.length) {
      nextQuestions[nextIndex] = nextQuestions[nextIndex].copyWith(
        difficulty: nextProfile.currentDifficulty,
      );
      nextDifficultyByQuestionId[nextQuestions[nextIndex].id] =
          nextProfile.currentDifficulty;
    }
    session = session.copyWith(
      questions: nextQuestions,
      difficultyProfile: nextProfile,
      difficultyByQuestionId: nextDifficultyByQuestionId,
      adaptiveRecordedQuestionIds: {
        ...session.adaptiveRecordedQuestionIds,
        question.id,
      },
    );
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
