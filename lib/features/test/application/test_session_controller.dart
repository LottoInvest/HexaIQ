import 'dart:math' as math;
import 'dart:async';

import '../../../core/domain/adaptive_difficulty_engine.dart';
import '../../../core/domain/domain_result.dart';
import '../../../core/domain/intelligence_domain.dart';
import '../../calibration/domain/calibration_profile.dart';
import '../../calibration/domain/calibration_repository.dart';
import '../../calibration/domain/calibration_updater.dart';
import '../../cat/domain/theta_estimate.dart';
import '../../cat/domain/theta_estimator.dart';
import '../domain/models/test_session.dart';
import '../../hexaiq/domain/hexaiq_models.dart';
import '../domain/models/question_record.dart';

class TestSessionController {
  TestSessionController(
    this.session, {
    AdaptiveDifficultyEngine? adaptiveDifficultyEngine,
    ThetaEstimator? thetaEstimator,
    this.calibrationRepository,
    CalibrationUpdater? calibrationUpdater,
  }) : _adaptiveDifficultyEngine =
           adaptiveDifficultyEngine ?? const AdaptiveDifficultyEngine(),
       _thetaEstimator = thetaEstimator ?? const ThetaEstimator(),
       _calibrationUpdater = calibrationUpdater ?? const CalibrationUpdater();

  TestSession session;
  final AdaptiveDifficultyEngine _adaptiveDifficultyEngine;
  final ThetaEstimator _thetaEstimator;
  final CalibrationRepository? calibrationRepository;
  final CalibrationUpdater _calibrationUpdater;

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
    session = session
        .copyWith(
          completedAt: completedAt ?? DateTime.now(),
          domainResults: _calculateDomainResults(),
        )
        .withNormEstimate();
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
    final isCorrect = selected == question.answerIndex;
    final nextProfile = _adaptiveDifficultyEngine.recordAnswer(
      profile: session.difficultyProfile,
      isCorrect: isCorrect,
    );
    final thetaBefore = session.thetaForDomain(question.domain);
    final nextQuestions = [...session.activeQuestions];
    final nextDifficultyByQuestionId = {
      ...session.difficultyByQuestionId,
      question.id: question.difficulty,
    };
    final baseRecord = QuestionRecord.fromQuestion(
      question: question,
      correct: isCorrect,
      elapsedSeconds: session.elapsedFor(question.id),
      thetaBefore: thetaBefore.theta,
      thetaAfter: thetaBefore.theta,
    );
    final baseHistory = [...session.questionHistory, baseRecord];
    final domainHistory = baseHistory
        .where((record) => record.domain == question.domain)
        .toList(growable: false);
    final thetaAfter = _thetaEstimator.estimate(
      history: domainHistory,
      current: thetaBefore,
      method: session.thetaEstimationMethod,
    );
    final expectedProbability = _thetaEstimator.calculator.probability(
      theta: thetaAfter.theta,
      difficultyIndex: question.difficultyIndex,
      discrimination: question.discrimination,
      guessing: question.guessing,
      upperAsymptote: question.upperAsymptote,
      modelType: _thetaEstimator.modelType,
    );
    final likelihood = _thetaEstimator.calculator.likelihood(
      theta: thetaAfter.theta,
      difficultyIndex: question.difficultyIndex,
      discrimination: question.discrimination,
      isCorrect: isCorrect,
      guessing: question.guessing,
      upperAsymptote: question.upperAsymptote,
      modelType: _thetaEstimator.modelType,
    );
    final logLikelihood = likelihood > 0 && likelihood.isFinite
        ? math.log(likelihood.clamp(1e-12, 1.0).toDouble())
        : 0.0;
    final priorContribution = _thetaEstimator.prior.logDensity(
      thetaAfter.theta,
    );
    final posteriorContribution =
        logLikelihood + (priorContribution.isFinite ? priorContribution : 0.0);
    final residual = _thetaEstimator.calculator.residual(
      theta: thetaAfter.theta,
      difficultyIndex: question.difficultyIndex,
      discrimination: question.discrimination,
      isCorrect: isCorrect,
      guessing: question.guessing,
      upperAsymptote: question.upperAsymptote,
      modelType: _thetaEstimator.modelType,
    );
    final itemInformation = _thetaEstimator.calculator.information(
      theta: thetaAfter.theta,
      difficultyIndex: question.difficultyIndex,
      discrimination: question.discrimination,
      guessing: question.guessing,
      upperAsymptote: question.upperAsymptote,
      modelType: _thetaEstimator.modelType,
    );
    final totalInformation = _thetaEstimator.totalInformation(
      history: domainHistory,
      theta: thetaAfter.theta,
    );
    final questionHistory = [
      ...session.questionHistory,
      baseRecord.copyWith(
        thetaAfter: thetaAfter.theta,
        thetaEstimate: thetaAfter.theta,
        itemInformation: itemInformation,
        expectedProbability: expectedProbability,
        likelihood: likelihood,
        logLikelihood: logLikelihood,
        posteriorContribution: posteriorContribution.isFinite
            ? posteriorContribution
            : 0.0,
        residual: residual,
        totalInformation: totalInformation,
      ),
    ];
    final recorded = questionHistory.last;
    final calibrationRepository = this.calibrationRepository;
    if (calibrationRepository != null) {
      unawaited(_updateCalibration(calibrationRepository, recorded));
    }
    final nextIndex = session.currentQuestionIndex + 1;
    if (nextIndex < nextQuestions.length) {
      nextQuestions[nextIndex] = nextQuestions[nextIndex].copyWith(
        difficulty: nextProfile.currentDifficulty,
      );
      nextDifficultyByQuestionId[nextQuestions[nextIndex].id] =
          nextProfile.currentDifficulty;
    }
    final domainThetaEstimates = {
      ...session.domainThetaEstimates,
      question.domain: thetaAfter,
    };
    final combinedTheta = _combineDomainTheta(
      domainThetaEstimates,
      fallback: session.thetaEstimate,
    );
    session = session.copyWith(
      questions: nextQuestions,
      generatedQuestions: session.generatedQuestions.isNotEmpty
          ? nextQuestions
          : session.generatedQuestions,
      difficultyProfile: nextProfile,
      difficultyByQuestionId: nextDifficultyByQuestionId,
      questionHistory: questionHistory,
      thetaEstimate: combinedTheta,
      domainThetaEstimates: domainThetaEstimates,
      thetaHistory: [...session.thetaHistory, combinedTheta],
      adaptiveRecordedQuestionIds: {
        ...session.adaptiveRecordedQuestionIds,
        question.id,
      },
    );
  }

  ThetaEstimate _combineDomainTheta(
    Map<IntelligenceDomain, ThetaEstimate> estimates, {
    required ThetaEstimate fallback,
  }) {
    final active = estimates.values.toList(growable: false);
    if (active.isEmpty) {
      return fallback;
    }
    final theta =
        active.fold<double>(0, (sum, estimate) => sum + estimate.theta) /
        active.length;
    final standardError =
        active.fold<double>(
          0,
          (sum, estimate) => sum + estimate.standardError,
        ) /
        active.length;
    final answeredCount = active.fold<int>(
      0,
      (sum, estimate) => sum + estimate.answeredCount,
    );
    return fallback.copyWith(
      theta: theta.clamp(-3.0, 3.0).toDouble(),
      standardError: standardError.clamp(0.25, double.infinity).toDouble(),
      answeredCount: answeredCount,
      method: active.last.method,
      posteriorPeak: active.last.posteriorPeak,
      posteriorMean: active.last.posteriorMean,
      posteriorVariance: active.last.posteriorVariance,
      updatedAt: DateTime.now(),
    );
  }

  Future<void> _updateCalibration(
    CalibrationRepository repository,
    QuestionRecord record,
  ) async {
    final current =
        await repository.load(record.itemId) ??
        CalibrationProfile(
          itemId: record.itemId,
          difficulty: record.difficultyIndex,
          discrimination: record.discrimination,
          guessing: record.guessing,
          upperAsymptote: record.upperAsymptote,
        );
    final next = _calibrationUpdater.update(current: current, response: record);
    await repository.save(next);
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
