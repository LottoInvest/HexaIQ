class ExposureStatus {
  const ExposureStatus({
    required this.itemId,
    this.exposureCount = 0,
    this.correctCount = 0,
    this.wrongCount = 0,
    this.averageResponseTime = Duration.zero,
    this.lastUsed,
  });

  final String itemId;
  final int exposureCount;
  final int correctCount;
  final int wrongCount;
  final Duration averageResponseTime;
  final DateTime? lastUsed;

  double get selectionScore => 1 / (1 + exposureCount);

  ExposureStatus copyWith({
    String? itemId,
    int? exposureCount,
    int? correctCount,
    int? wrongCount,
    Duration? averageResponseTime,
    DateTime? lastUsed,
  }) {
    return ExposureStatus(
      itemId: itemId ?? this.itemId,
      exposureCount: exposureCount ?? this.exposureCount,
      correctCount: correctCount ?? this.correctCount,
      wrongCount: wrongCount ?? this.wrongCount,
      averageResponseTime: averageResponseTime ?? this.averageResponseTime,
      lastUsed: lastUsed ?? this.lastUsed,
    );
  }
}
