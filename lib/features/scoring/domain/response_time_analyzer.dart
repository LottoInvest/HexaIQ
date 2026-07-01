enum ResponseTimeCategory { tooFast, expected, slow, timeout }

class ResponseTimeAnalysis {
  const ResponseTimeAnalysis({
    required this.category,
    required this.multiplier,
    required this.note,
  });

  final ResponseTimeCategory category;
  final double multiplier;
  final String note;
}

class ResponseTimeAnalyzer {
  const ResponseTimeAnalyzer();

  ResponseTimeAnalysis analyze({
    required bool isCorrect,
    required Duration responseTime,
    required Duration estimatedTime,
    bool useBonus = true,
  }) {
    final expectedMs = estimatedTime.inMilliseconds <= 0
        ? 30000
        : estimatedTime.inMilliseconds;
    final elapsedMs = responseTime.inMilliseconds.clamp(0, 3600000);
    final ratio = elapsedMs / expectedMs;
    if (ratio < 0.18) {
      return ResponseTimeAnalysis(
        category: ResponseTimeCategory.tooFast,
        multiplier: isCorrect && useBonus ? 0.96 : 1.0,
        note: isCorrect
            ? '매우 빠른 정답입니다. 보너스는 제한적으로 반영합니다.'
            : '빠른 오답은 추측 가능성으로 기록합니다.',
      );
    }
    if (ratio > 2.5) {
      return ResponseTimeAnalysis(
        category: ResponseTimeCategory.timeout,
        multiplier: isCorrect ? 0.92 : 1.0,
        note: '예상 풀이 시간을 크게 초과했습니다.',
      );
    }
    if (ratio > 1.5) {
      return ResponseTimeAnalysis(
        category: ResponseTimeCategory.slow,
        multiplier: isCorrect ? 0.98 : 1.0,
        note: '풀이 시간이 긴 편입니다.',
      );
    }
    return ResponseTimeAnalysis(
      category: ResponseTimeCategory.expected,
      multiplier: isCorrect && useBonus ? 1.03 : 1.0,
      note: '적절한 풀이 시간입니다.',
    );
  }
}
