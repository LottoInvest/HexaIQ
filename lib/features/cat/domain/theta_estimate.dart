import 'theta_estimation_method.dart';

class ThetaEstimate {
  const ThetaEstimate({
    required this.theta,
    required this.standardError,
    required this.answeredCount,
    required this.updatedAt,
    this.method = ThetaEstimationMethod.newtonRaphson,
    this.posteriorPeak = 0,
    this.posteriorMean = 0,
    this.posteriorVariance = 0,
  });

  factory ThetaEstimate.initial({DateTime? updatedAt}) {
    return ThetaEstimate(
      theta: 0,
      standardError: 1,
      answeredCount: 0,
      updatedAt: updatedAt ?? DateTime.now(),
      method: ThetaEstimationMethod.newtonRaphson,
    );
  }

  final double theta;
  final double standardError;
  final int answeredCount;
  final DateTime updatedAt;
  final ThetaEstimationMethod method;
  final double posteriorPeak;
  final double posteriorMean;
  final double posteriorVariance;

  ThetaEstimate copyWith({
    double? theta,
    double? standardError,
    int? answeredCount,
    DateTime? updatedAt,
    ThetaEstimationMethod? method,
    double? posteriorPeak,
    double? posteriorMean,
    double? posteriorVariance,
  }) {
    return ThetaEstimate(
      theta: theta ?? this.theta,
      standardError: standardError ?? this.standardError,
      answeredCount: answeredCount ?? this.answeredCount,
      updatedAt: updatedAt ?? this.updatedAt,
      method: method ?? this.method,
      posteriorPeak: posteriorPeak ?? this.posteriorPeak,
      posteriorMean: posteriorMean ?? this.posteriorMean,
      posteriorVariance: posteriorVariance ?? this.posteriorVariance,
    );
  }
}
