import '../../../core/domain/domain_result.dart';
import '../../../core/domain/intelligence_domain.dart';
import '../../../core/domain/question_difficulty.dart';
import '../../hexaiq/domain/hexaiq_models.dart';
import '../../test/domain/models/test_session.dart';
import 'test_result_payload.dart';

class TestResultBuilder {
  const TestResultBuilder();

  TestResultSummary build({
    required TestSession session,
    required String profileId,
  }) {
    final completedAt = session.completedAt ?? DateTime.now();
    final questions = session.activeQuestions;
    final totalQuestions = questions.length;
    final answeredQuestions = session.selectedAnswers.length.clamp(
      0,
      totalQuestions,
    );
    final correctCount = questions
        .where(
          (question) =>
              session.selectedAnswerFor(question.id) == question.answerIndex,
        )
        .length;
    final totalElapsed = _totalElapsedSeconds(session);
    final averageElapsed = totalQuestions == 0
        ? 0
        : (totalElapsed / totalQuestions).round();
    final payload = TestResultPayload(
      resultId: session.sessionId,
      profileId: profileId,
      testMode: session.mode,
      totalQuestions: totalQuestions,
      answeredQuestions: answeredQuestions,
      correctCount: correctCount,
      accuracy: totalQuestions == 0 ? 0 : correctCount / totalQuestions,
      totalElapsedSeconds: totalElapsed,
      averageElapsedSeconds: averageElapsed,
      questionIds: [for (final question in questions) question.id],
      domainScores: _domainScores(session),
    );

    return TestResultSummary(
      id: session.sessionId,
      profileId: profileId,
      startedAt: session.startedAt,
      completedAt: completedAt,
      theta: session.thetaEstimate.theta,
      standardError: session.thetaEstimate.standardError,
      estimatedIQ: session.estimatedIQ,
      percentile: session.percentile,
      abilityLevel: session.abilityLevel.labelKo,
      averageDifficulty: session.averageDifficulty,
      averageElapsedSeconds: averageElapsed,
      questionCount: totalQuestions,
      payloadJson: payload.encode(),
    );
  }

  int _totalElapsedSeconds(TestSession session) {
    if (session.elapsedSeconds.isNotEmpty) {
      return session.elapsedSeconds.values.fold<int>(
        0,
        (sum, item) => sum + item,
      );
    }
    if (session.questionHistory.isNotEmpty) {
      return session.questionHistory.fold<int>(
        0,
        (sum, record) => sum + record.elapsedSeconds,
      );
    }
    return session.totalElapsedSeconds;
  }

  Map<IntelligenceDomain, DomainResult> _domainScores(TestSession session) {
    if (session.domainResults.isNotEmpty) {
      return {
        for (final entry in session.domainResults.entries)
          entry.key: _normalizeDomainScore(entry.key, entry.value, session),
      };
    }

    final grouped = <IntelligenceDomain, List<TestQuestion>>{};
    for (final question in session.activeQuestions) {
      grouped.putIfAbsent(question.domain, () => []).add(question);
    }
    return {
      for (final entry in grouped.entries)
        entry.key: _domainResultFromQuestions(entry.key, entry.value, session),
    };
  }

  DomainResult _normalizeDomainScore(
    IntelligenceDomain domain,
    DomainResult result,
    TestSession session,
  ) {
    final total = result.totalCount;
    final correct = result.correctCount.clamp(0, total);
    final accuracy = total == 0 ? 0.0 : correct / total;
    return DomainResult(
      domain: domain,
      correctCount: correct,
      totalCount: total,
      accuracy: accuracy,
      elapsedSeconds: result.elapsedSeconds,
      theta: session.thetaForDomain(domain).theta,
      difficulty: result.difficulty,
      domainScore: _domainScore(accuracy: accuracy),
      iqContribution: result.iqContribution,
    );
  }

  DomainResult _domainResultFromQuestions(
    IntelligenceDomain domain,
    List<TestQuestion> questions,
    TestSession session,
  ) {
    final total = questions.length;
    final correct = questions
        .where(
          (question) =>
              session.selectedAnswerFor(question.id) == question.answerIndex,
        )
        .length;
    final elapsed = questions.fold<int>(
      0,
      (sum, question) => sum + session.elapsedFor(question.id),
    );
    final difficulty = _averageDifficulty(questions);
    final theta = session.thetaForDomain(domain).theta;
    final accuracy = total == 0 ? 0.0 : correct / total;
    return DomainResult(
      domain: domain,
      correctCount: correct,
      totalCount: total,
      accuracy: accuracy,
      elapsedSeconds: elapsed,
      theta: theta,
      difficulty: difficulty,
      domainScore: _domainScore(accuracy: accuracy),
      iqContribution: theta * 15,
    );
  }

  double _averageDifficulty(List<TestQuestion> questions) {
    if (questions.isEmpty) {
      return QuestionDifficulty.normal.level.toDouble();
    }
    return questions
            .map((question) => question.difficulty.level)
            .fold<int>(0, (sum, item) => sum + item) /
        questions.length;
  }

  double _domainScore({required double accuracy}) {
    final safeAccuracy = accuracy.isFinite ? accuracy.clamp(0.0, 1.0) : 0.0;
    return (safeAccuracy * 100).clamp(0.0, 100.0);
  }
}
