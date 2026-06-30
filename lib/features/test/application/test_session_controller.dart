import '../../../core/domain/adaptive_difficulty_engine.dart';
import '../../../core/domain/domain_result.dart';
import '../../../core/domain/intelligence_domain.dart';
import '../domain/models/test_session.dart';
import '../../hexaiq/domain/hexaiq_models.dart';
import '../domain/models/question_record.dart';

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

  void nextQuestion({
    TestQuestion Function(TestSession session)? generateNextQuestion,
  }) {
    if (session.currentQuestionIndex >= session.targetQuestionCount - 1) {
      return;
    }
    _recordAdaptiveForCurrentQuestion();
    if (session.currentQuestionIndex >= session.activeQuestions.length - 1 &&
        session.activeQuestions.length < session.targetQuestionCount &&
        generateNextQuestion != null) {
      final generated = generateNextQuestion(session);
      final nextQuestions = [...session.activeQuestions, generated];
      session = session.copyWith(
        questions: nextQuestions,
        generatedQuestions: nextQuestions,
        difficultyByQuestionId: {
          ...session.difficultyByQuestionId,
          generated.id: generated.difficulty,
        },
        usedItemIds: {
          ...session.usedItemIds,
          if (generated.itemId != null) generated.itemId!,
        },
      );
    }
    if (session.currentQuestionIndex >= session.activeQuestions.length - 1) {
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
    final nextQuestions = [...session.activeQuestions];
    final nextDifficultyByQuestionId = {
      ...session.difficultyByQuestionId,
      question.id: question.difficulty,
    };
    final questionHistory = [
      ...session.questionHistory,
      QuestionRecord.fromQuestion(
        question: question,
        correct: selected == question.answerIndex,
        elapsedSeconds: session.elapsedFor(question.id),
      ),
    ];
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
      generatedQuestions: session.generatedQuestions.isNotEmpty
          ? nextQuestions
          : session.generatedQuestions,
      difficultyProfile: nextProfile,
      difficultyByQuestionId: nextDifficultyByQuestionId,
      questionHistory: questionHistory,
      adaptiveRecordedQuestionIds: {
        ...session.adaptiveRecordedQuestionIds,
        question.id,
      },
    );
  }

  Map<IntelligenceDomain, DomainResult> _calculateDomainResults() {
    final results = <IntelligenceDomain, DomainResult>{};
    for (final domain in IntelligenceDomain.values) {
      final domainQuestions = session.activeQuestions
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
