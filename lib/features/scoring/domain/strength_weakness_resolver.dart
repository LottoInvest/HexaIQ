import 'domain_score_calculator.dart';

class StrengthWeaknessResult {
  const StrengthWeaknessResult({
    required this.strengths,
    required this.weaknesses,
    required this.summary,
  });

  final List<ReliableDomainScore> strengths;
  final List<ReliableDomainScore> weaknesses;
  final String summary;
}

class StrengthWeaknessResolver {
  const StrengthWeaknessResolver();

  StrengthWeaknessResult resolve(List<ReliableDomainScore> scores) {
    final available = scores.where((score) => score.totalCount > 0).toList();
    if (available.isEmpty) {
      return const StrengthWeaknessResult(
        strengths: [],
        weaknesses: [],
        summary: '아직 분석할 수 있는 영역별 데이터가 없습니다.',
      );
    }
    available.sort((a, b) => b.score.compareTo(a.score));
    final spread = available.first.score - available.last.score;
    if (spread < 8) {
      return const StrengthWeaknessResult(
        strengths: [],
        weaknesses: [],
        summary: '영역 간 차이가 크지 않아 균형적인 수행으로 볼 수 있습니다.',
      );
    }
    return StrengthWeaknessResult(
      strengths: available.take(2).toList(growable: false),
      weaknesses: available.reversed.take(2).toList(growable: false),
      summary: '상대적으로 강한 영역과 보완할 영역이 구분됩니다.',
    );
  }
}
