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
  }) : correctCount = correctCount ?? correct ?? 0,
       totalCount = totalCount ?? ((correct ?? 0) + (wrong ?? 0)),
       accuracy = accuracy ?? 0,
       elapsedSeconds = elapsedSeconds ?? elapsed ?? 0;

  final IntelligenceDomain? domain;
  final int correctCount;
  final int totalCount;
  final double accuracy;
  final int elapsedSeconds;

  int get correct => correctCount;

  int get wrong => totalCount - correctCount;

  int get total => totalCount;

  int get elapsed => elapsedSeconds;
}
