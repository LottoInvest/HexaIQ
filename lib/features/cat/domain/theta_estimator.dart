import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../../test/domain/models/question_record.dart';
import 'irt3pl_model.dart';
import 'likelihood_calculator.dart';
import 'prior_distribution.dart';
import 'theta_estimate.dart';
import 'theta_estimation_method.dart';

class ThetaEstimator {
  const ThetaEstimator({
    this.calculator = const LikelihoodCalculator(),
    this.prior = const PriorDistribution.normal(),
    this.iterations = 5,
    this.modelType = IRTModelType.twoPL,
  });

  final LikelihoodCalculator calculator;
  final PriorDistribution prior;
  final int iterations;
  final IRTModelType modelType;

  ThetaEstimate estimate({
    required List<QuestionRecord> history,
    required ThetaEstimate current,
    ThetaEstimationMethod method = ThetaEstimationMethod.newtonRaphson,
    DateTime? updatedAt,
  }) {
    final answered = history
        .where((record) => record.correct != null)
        .toList(growable: false);
    if (method == ThetaEstimationMethod.map) {
      return _estimateMap(
        history: answered,
        current: current,
        updatedAt: updatedAt,
      );
    }
    if (method == ThetaEstimationMethod.eap) {
      return _estimateEap(
        history: answered,
        current: current,
        updatedAt: updatedAt,
      );
    }
    if (method == ThetaEstimationMethod.heuristic) {
      return _estimateHeuristic(
        history: answered,
        current: current,
        updatedAt: updatedAt,
      );
    }
    return _estimateNewton(
      history: answered,
      current: current,
      updatedAt: updatedAt,
    );
  }

  ThetaEstimate _estimateNewton({
    required List<QuestionRecord> history,
    required ThetaEstimate current,
    DateTime? updatedAt,
  }) {
    final answered = history;
    if (answered.isEmpty) {
      return current;
    }

    var theta = current.theta.isFinite ? current.theta : 0.0;
    final maxIterations = iterations.clamp(3, 5);

    for (var i = 0; i < maxIterations; i++) {
      var score = 0.0;
      var information = 0.0;

      for (final record in answered) {
        final discrimination = _safeDiscrimination(record.discrimination);
        final p = calculator.probability(
          theta: theta,
          difficultyIndex: record.difficultyIndex,
          discrimination: discrimination,
          guessing: record.guessing,
          upperAsymptote: record.upperAsymptote,
          modelType: modelType,
        );
        final observed = record.correct == true ? 1.0 : 0.0;
        score += discrimination * (observed - p);
        information += calculator.information(
          theta: theta,
          difficultyIndex: record.difficultyIndex,
          discrimination: discrimination,
          guessing: record.guessing,
          upperAsymptote: record.upperAsymptote,
          modelType: modelType,
        );
      }

      if (!score.isFinite || !information.isFinite || information <= 1e-9) {
        return current;
      }

      final step = score / information;
      if (!step.isFinite) {
        return current;
      }
      theta = (theta + step).clamp(-3.0, 3.0).toDouble();
    }

    if (!theta.isFinite) {
      return current;
    }

    final totalInformation = this.totalInformation(
      history: answered,
      theta: theta,
    );
    final standardError = standardErrorFor(totalInformation);
    final next = ThetaEstimate(
      theta: theta,
      standardError: standardError,
      answeredCount: answered.length,
      updatedAt: updatedAt ?? DateTime.now(),
      method: ThetaEstimationMethod.newtonRaphson,
      posteriorMean: theta,
      posteriorVariance: standardError * standardError,
    );

    debugPrint(
      '[ThetaEstimator] '
      'method=${next.method.label} '
      'before=${current.theta.toStringAsFixed(2)} '
      'theta=${next.theta.toStringAsFixed(2)} '
      'se=${next.standardError.toStringAsFixed(2)} '
      'info=${totalInformation.toStringAsFixed(2)}',
    );
    return next;
  }

  ThetaEstimate _estimateMap({
    required List<QuestionRecord> history,
    required ThetaEstimate current,
    DateTime? updatedAt,
  }) {
    if (history.isEmpty) {
      return ThetaEstimate(
        theta: 0,
        standardError: standardErrorFor(0),
        answeredCount: 0,
        updatedAt: updatedAt ?? DateTime.now(),
        method: ThetaEstimationMethod.map,
        posteriorPeak: prior.density(0),
        posteriorMean: 0,
        posteriorVariance: 1,
      );
    }

    var bestTheta = current.theta.isFinite ? current.theta : 0.0;
    var bestLogPosterior = -double.maxFinite;
    for (final theta in _thetaGrid()) {
      final logPosterior = _logPosterior(theta, history);
      if (logPosterior.isFinite && logPosterior > bestLogPosterior) {
        bestTheta = theta;
        bestLogPosterior = logPosterior;
      }
    }

    if (!bestTheta.isFinite || !bestLogPosterior.isFinite) {
      return current;
    }

    final totalInformation = this.totalInformation(
      history: history,
      theta: bestTheta,
    );
    final standardError = standardErrorFor(totalInformation);
    final next = ThetaEstimate(
      theta: bestTheta.clamp(-3.0, 3.0).toDouble(),
      standardError: standardError,
      answeredCount: history.length,
      updatedAt: updatedAt ?? DateTime.now(),
      method: ThetaEstimationMethod.map,
      posteriorPeak: _safeExp(bestLogPosterior),
      posteriorMean: bestTheta,
      posteriorVariance: standardError * standardError,
    );
    _debugEstimate(current, next, totalInformation);
    return next;
  }

  ThetaEstimate _estimateEap({
    required List<QuestionRecord> history,
    required ThetaEstimate current,
    DateTime? updatedAt,
  }) {
    if (history.isEmpty) {
      return ThetaEstimate(
        theta: 0,
        standardError: standardErrorFor(0),
        answeredCount: 0,
        updatedAt: updatedAt ?? DateTime.now(),
        method: ThetaEstimationMethod.eap,
        posteriorPeak: prior.density(0),
        posteriorMean: 0,
        posteriorVariance: 1,
      );
    }

    final points = <({double theta, double logPosterior})>[];
    var maxLogPosterior = -double.maxFinite;
    for (final theta in _thetaGrid()) {
      final logPosterior = _logPosterior(theta, history);
      if (!logPosterior.isFinite) {
        continue;
      }
      points.add((theta: theta, logPosterior: logPosterior));
      if (logPosterior > maxLogPosterior) {
        maxLogPosterior = logPosterior;
      }
    }
    if (points.isEmpty || !maxLogPosterior.isFinite) {
      return current;
    }

    var totalWeight = 0.0;
    var weightedTheta = 0.0;
    for (final point in points) {
      final weight = _safeExp(point.logPosterior - maxLogPosterior);
      if (weight <= 0 || !weight.isFinite) {
        continue;
      }
      totalWeight += weight;
      weightedTheta += point.theta * weight;
    }
    if (!totalWeight.isFinite || totalWeight <= 0) {
      return current;
    }

    final mean = weightedTheta / totalWeight;
    if (!mean.isFinite) {
      return current;
    }
    var weightedVariance = 0.0;
    for (final point in points) {
      final weight = _safeExp(point.logPosterior - maxLogPosterior);
      if (weight <= 0 || !weight.isFinite) {
        continue;
      }
      final distance = point.theta - mean;
      weightedVariance += distance * distance * weight;
    }
    var variance = weightedVariance / totalWeight;
    if (!variance.isFinite || variance < 0) {
      variance = 0;
    }
    final standardError = math.max(0.25, math.sqrt(variance));
    final totalInformation = this.totalInformation(
      history: history,
      theta: mean,
    );
    final next = ThetaEstimate(
      theta: mean.clamp(-3.0, 3.0).toDouble(),
      standardError: standardError.isFinite
          ? standardError
          : current.standardError,
      answeredCount: history.length,
      updatedAt: updatedAt ?? DateTime.now(),
      method: ThetaEstimationMethod.eap,
      posteriorPeak: _safeExp(maxLogPosterior),
      posteriorMean: mean,
      posteriorVariance: variance,
    );
    _debugEstimate(current, next, totalInformation);
    return next;
  }

  double totalInformation({
    required List<QuestionRecord> history,
    required double theta,
  }) {
    var total = 0.0;
    for (final record in history) {
      if (record.correct == null) {
        continue;
      }
      final value = calculator.information(
        theta: theta,
        difficultyIndex: record.difficultyIndex,
        discrimination: _safeDiscrimination(record.discrimination),
        guessing: record.guessing,
        upperAsymptote: record.upperAsymptote,
        modelType: modelType,
      );
      if (value.isFinite && value > 0) {
        total += value;
      }
    }
    return total.isFinite && total > 0 ? total : 0;
  }

  double standardErrorFor(double totalInformation) {
    if (!totalInformation.isFinite || totalInformation <= 1e-9) {
      return 1.0;
    }
    final se = 1 / math.sqrt(totalInformation);
    if (!se.isFinite) {
      return 1.0;
    }
    return se.clamp(0.25, 1.0).toDouble();
  }

  double _safeDiscrimination(double discrimination) {
    if (!discrimination.isFinite || discrimination <= 0) {
      return 1;
    }
    return discrimination;
  }

  ThetaEstimate _estimateHeuristic({
    required List<QuestionRecord> history,
    required ThetaEstimate current,
    DateTime? updatedAt,
  }) {
    if (history.isEmpty) {
      return current.copyWith(
        method: ThetaEstimationMethod.heuristic,
        updatedAt: updatedAt ?? DateTime.now(),
      );
    }
    final last = history.last;
    final delta = last.correct == true ? 0.15 : -0.12;
    final answeredCount = current.answeredCount + 1;
    final theta = (current.theta + delta).clamp(-3.0, 3.0).toDouble();
    return ThetaEstimate(
      theta: theta,
      standardError: math.max(0.25, 1 / math.sqrt(answeredCount + 1)),
      answeredCount: answeredCount,
      updatedAt: updatedAt ?? DateTime.now(),
      method: ThetaEstimationMethod.heuristic,
      posteriorMean: theta,
    );
  }

  double _logPosterior(double theta, List<QuestionRecord> history) {
    var value = prior.logDensity(theta);
    if (!value.isFinite) {
      return -double.maxFinite;
    }
    for (final record in history) {
      final p = calculator.probability(
        theta: theta,
        difficultyIndex: record.difficultyIndex,
        discrimination: _safeDiscrimination(record.discrimination),
        guessing: record.guessing,
        upperAsymptote: record.upperAsymptote,
        modelType: modelType,
      );
      final likelihood = record.correct == true ? p : 1 - p;
      if (!likelihood.isFinite || likelihood <= 0) {
        return -double.maxFinite;
      }
      value += math.log(likelihood.clamp(1e-12, 1.0).toDouble());
      if (!value.isFinite) {
        return -double.maxFinite;
      }
    }
    return value;
  }

  Iterable<double> _thetaGrid() sync* {
    for (var i = -30; i <= 30; i++) {
      yield i / 10;
    }
  }

  double _safeExp(double value) {
    if (!value.isFinite) {
      return 0;
    }
    final result = math.exp(value.clamp(-745.0, 709.0).toDouble());
    return result.isFinite ? result : 0;
  }

  void _debugEstimate(
    ThetaEstimate current,
    ThetaEstimate next,
    double totalInformation,
  ) {
    debugPrint(
      '[ThetaEstimator] '
      'method=${next.method.label} '
      'before=${current.theta.toStringAsFixed(2)} '
      'theta=${next.theta.toStringAsFixed(2)} '
      'posteriorPeak=${next.posteriorPeak.toStringAsExponential(2)} '
      'se=${next.standardError.toStringAsFixed(2)} '
      'info=${totalInformation.toStringAsFixed(2)}',
    );
  }
}
