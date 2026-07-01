import 'intelligence_domain.dart';

class DomainResult {
  const DomainResult({
    this.domain,
    int? correctCount,
    int? totalCount,
    int? elapsedSeconds,
    int? correct,
    int? wrong,
    double? accuracy,
    int? elapsed,
    this.theta = 0,
    this.difficulty = 0,
    this.domainScore = 0,
    this.iqContribution = 0,
  }) : correctCount = correctCount ?? correct ?? 0,
       totalCount = totalCount ?? ((correct ?? 0) + (wrong ?? 0)),
       accuracy = accuracy ?? 0,
       elapsedSeconds = elapsedSeconds ?? elapsed ?? 0;

  final IntelligenceDomain? domain;
  final int correctCount;
  final int totalCount;
  final double accuracy;
  final int elapsedSeconds;
  final double theta;
  final double difficulty;
  final double domainScore;
  final double iqContribution;

  int get correct => correctCount;

  int get wrong => totalCount - correctCount;

  int get total => totalCount;

  int get elapsed => elapsedSeconds;
}
