class ItemStatistics {
  const ItemStatistics({
    this.attemptCount = 0,
    this.correctCount = 0,
    this.wrongCount = 0,
    this.averageTime = Duration.zero,
    this.difficultyEstimate = 0,
    this.exposureCount = 0,
    this.averageResponseTime = Duration.zero,
    this.lastUpdated,
    this.lastUsed,
  });

  final int attemptCount;
  final int correctCount;
  final int wrongCount;
  final Duration averageTime;
  final double difficultyEstimate;
  final int exposureCount;
  final Duration averageResponseTime;
  final DateTime? lastUpdated;
  final DateTime? lastUsed;

  double get selectionScore => 1 / (1 + exposureCount);

  double get accuracy {
    if (attemptCount == 0) {
      return 0;
    }
    return correctCount / attemptCount;
  }

  ItemStatistics copyWith({
    int? attemptCount,
    int? correctCount,
    int? wrongCount,
    Duration? averageTime,
    double? difficultyEstimate,
    int? exposureCount,
    Duration? averageResponseTime,
    DateTime? lastUpdated,
    DateTime? lastUsed,
  }) {
    return ItemStatistics(
      attemptCount: attemptCount ?? this.attemptCount,
      correctCount: correctCount ?? this.correctCount,
      wrongCount: wrongCount ?? this.wrongCount,
      averageTime: averageTime ?? this.averageTime,
      difficultyEstimate: difficultyEstimate ?? this.difficultyEstimate,
      exposureCount: exposureCount ?? this.exposureCount,
      averageResponseTime: averageResponseTime ?? this.averageResponseTime,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      lastUsed: lastUsed ?? this.lastUsed,
    );
  }
}
