import 'cognitive_domain.dart';
import 'score_band.dart';

class KoreanReportTextResolver {
  const KoreanReportTextResolver();

  String getDomainDescription(CognitiveDomain domain, ScoreBand band) {
    final subject = domain.labelKo;
    return switch (band) {
      ScoreBand.veryLow => '$subject 영역은 기초 유형부터 천천히 다시 익히는 것이 좋습니다.',
      ScoreBand.low => '$subject 영역은 기본 규칙을 반복하면 안정적으로 좋아질 수 있습니다.',
      ScoreBand.average => '$subject 영역은 현재 평균적인 수행을 보입니다.',
      ScoreBand.high => '$subject 영역에서 규칙을 잘 파악하는 편입니다.',
      ScoreBand.veryHigh => '$subject 영역에서 매우 안정적인 강점을 보입니다.',
    };
  }

  String getOverallDescription(int iqScore) {
    if (iqScore < 80) {
      return '이번 결과는 기초 훈련을 통해 개선 여지가 큰 상태로 해석됩니다.';
    }
    if (iqScore < 100) {
      return '이번 결과는 일부 영역을 보완하면 더 안정적인 수행을 기대할 수 있습니다.';
    }
    if (iqScore < 120) {
      return '이번 결과는 전반적으로 안정적인 사고 수행을 보여줍니다.';
    }
    return '이번 결과는 여러 영역에서 높은 수준의 문제 해결력을 보여줍니다.';
  }
}
