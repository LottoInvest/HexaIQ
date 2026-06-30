class ThetaEstimate {
  const ThetaEstimate({
    required this.theta,
    required this.standardError,
    required this.answeredCount,
    required this.updatedAt,
  });

  factory ThetaEstimate.initial({DateTime? updatedAt}) {
    return ThetaEstimate(
      theta: 0,
      standardError: 1,
      answeredCount: 0,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  final double theta;
  final double standardError;
  final int answeredCount;
  final DateTime updatedAt;

  ThetaEstimate copyWith({
    double? theta,
    double? standardError,
    int? answeredCount,
    DateTime? updatedAt,
  }) {
    return ThetaEstimate(
      theta: theta ?? this.theta,
      standardError: standardError ?? this.standardError,
      answeredCount: answeredCount ?? this.answeredCount,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
