import '../../../core/domain/intelligence_domain.dart';
import '../../hexaiq/domain/hexaiq_models.dart';

class ProgressSummary {
  const ProgressSummary({
    required this.latestIQ,
    required this.iqDelta,
    required this.testCount,
    required this.averageResponseTime,
    required this.recentTrainingCount,
    required this.domainTrend,
  });

  final int latestIQ;
  final int iqDelta;
  final int testCount;
  final int averageResponseTime;
  final int recentTrainingCount;
  final Map<String, double> domainTrend;
}

class ProgressAnalytics {
  const ProgressAnalytics();

  ProgressSummary summarize({
    required UserProfile? profile,
    required List<TestResultSummary> history,
    required List<GrowthPoint> growth,
  }) {
    final sorted = [...history]
      ..sort((a, b) => a.completedAt.compareTo(b.completedAt));
    final latest = sorted.isNotEmpty ? sorted.last.estimatedIQ : 0;
    final previous = sorted.length > 1
        ? sorted[sorted.length - 2].estimatedIQ
        : latest;
    final totalElapsed = sorted.fold<int>(
      0,
      (sum, item) => sum + item.averageElapsedSeconds,
    );
    final domainGrowthRates =
        profile?.domainGrowthRates ?? const <IntelligenceDomain, double>{};
    final domainTrend = {
      for (final entry in domainGrowthRates.entries)
        entry.key.label: entry.value,
    };
    return ProgressSummary(
      latestIQ: latest,
      iqDelta: latest - previous,
      testCount: sorted.length,
      averageResponseTime: sorted.isEmpty ? 0 : totalElapsed ~/ sorted.length,
      recentTrainingCount: sorted.length,
      domainTrend: domainTrend,
    );
  }
}
