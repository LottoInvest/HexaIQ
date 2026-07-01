enum ScoreBand { veryLow, low, average, high, veryHigh }

extension ScoreBandInfo on ScoreBand {
  String get labelKo {
    return switch (this) {
      ScoreBand.veryLow => '매우 낮음',
      ScoreBand.low => '낮음',
      ScoreBand.average => '보통',
      ScoreBand.high => '높음',
      ScoreBand.veryHigh => '매우 높음',
    };
  }
}

ScoreBand scoreBandFor(num score) {
  final value = score.isFinite ? score.clamp(0, 100) : 0;
  if (value < 20) {
    return ScoreBand.veryLow;
  }
  if (value < 40) {
    return ScoreBand.low;
  }
  if (value < 60) {
    return ScoreBand.average;
  }
  if (value < 80) {
    return ScoreBand.high;
  }
  return ScoreBand.veryHigh;
}
