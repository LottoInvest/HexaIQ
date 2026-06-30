import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../../test/domain/models/question_record.dart';
import 'likelihood_calculator.dart';
import 'theta_estimate.dart';

class ThetaEstimator {
  const ThetaEstimator({
    this.calculator = const LikelihoodCalculator(),
    this.iterations = 5,
  });

  final LikelihoodCalculator calculator;
  final int iterations;

  ThetaEstimate estimate({
    required List<QuestionRecord> history,
    required ThetaEstimate current,
    DateTime? updatedAt,
  }) {
    final answered = history
        .where((record) => record.correct != null)
        .toList(growable: false);
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
        );
        final observed = record.correct == true ? 1.0 : 0.0;
        score += discrimination * (observed - p);
        information += calculator.information(
          theta: theta,
          difficultyIndex: record.difficultyIndex,
          discrimination: discrimination,
          guessing: record.guessing,
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
    );

    debugPrint(
      '[Theta] '
      'before=${current.theta.toStringAsFixed(2)} '
      'after=${next.theta.toStringAsFixed(2)} '
      'SE=${next.standardError.toStringAsFixed(2)} '
      'info=${totalInformation.toStringAsFixed(2)}',
    );
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
}
