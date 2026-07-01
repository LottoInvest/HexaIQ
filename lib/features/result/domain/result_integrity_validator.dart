import 'dart:math' as math;

import '../../hexaiq/domain/hexaiq_models.dart';
import 'test_result_payload.dart';

class ResultIntegrityReport {
  const ResultIntegrityReport({required this.errors, required this.warnings});

  final List<String> errors;
  final List<String> warnings;

  bool get isValid => errors.isEmpty;
}

class ResultIntegrityValidator {
  const ResultIntegrityValidator();

  ResultIntegrityReport validate(TestResultSummary result) {
    final payload = TestResultPayload.fromResult(result);
    final errors = <String>[];
    final warnings = <String>[];

    if (payload.resultId != result.id) {
      errors.add('resultId mismatch');
    }
    if (payload.profileId != result.profileId) {
      errors.add('profileId mismatch');
    }
    if (result.questionCount != payload.totalQuestions) {
      errors.add('questionCount mismatch');
    }
    if (payload.totalQuestions <= 0) {
      errors.add('totalQuestions must be positive');
    }
    if (payload.answeredQuestions < 0) {
      errors.add('answeredQuestions must be non-negative');
    }
    if (payload.answeredQuestions > payload.totalQuestions) {
      errors.add('answeredQuestions exceeds totalQuestions');
    }
    if (payload.correctCount < 0) {
      errors.add('correctCount must be non-negative');
    }
    if (payload.correctCount > payload.totalQuestions) {
      errors.add('correctCount exceeds totalQuestions');
    }
    if (result.completedAt.isBefore(result.startedAt)) {
      errors.add('completedAt is before startedAt');
    }
    if (!result.theta.isFinite || !result.standardError.isFinite) {
      errors.add('theta fields must be finite');
    }
    if (result.estimatedIQ < 40 || result.estimatedIQ > 160) {
      errors.add('estimatedIQ out of supported range');
    }
    if (result.percentile < 1 || result.percentile > 99) {
      errors.add('topPercent out of supported range');
    }

    final expectedAccuracy = payload.totalQuestions == 0
        ? 0.0
        : payload.correctCount / payload.totalQuestions;
    if ((payload.accuracy - expectedAccuracy).abs() > 0.01) {
      warnings.add('accuracy does not match correctCount / totalQuestions');
    }
    if (payload.questionIds.isNotEmpty &&
        payload.questionIds.length != payload.totalQuestions) {
      warnings.add('questionIds length differs from totalQuestions');
    }
    if (math.max(payload.averageElapsedSeconds, payload.totalElapsedSeconds) <
        0) {
      errors.add('elapsed time must be non-negative');
    }

    return ResultIntegrityReport(errors: errors, warnings: warnings);
  }
}
