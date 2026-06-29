import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/app_routes.dart';
import '../../../core/widgets/action_card.dart';
import '../../../core/widgets/hexagon_chart.dart';
import '../../hexaiq/domain/hexaiq_models.dart';
import '../../hexaiq/presentation/state/hexaiq_app_state.dart';

class ReportSummaryScreen extends StatelessWidget {
  const ReportSummaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final report = context.watch<HexaIQAppState>().report;
    if (report == null) {
      return const Scaffold(body: Center(child: Text('리포트가 아직 없습니다.')));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('검사 리포트')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '종합 참고 점수 ${report.overallScore}',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: HexagonChart(
                        values: report.domainScores
                            .map((score) => score.score.toDouble())
                            .toList(),
                        labels: domainCatalog
                            .map((domain) => domain.shortLabel)
                            .toList(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(report.summary),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.radar),
                      label: const Text('육각형 상세 보기'),
                      onPressed: () => Navigator.of(
                        context,
                      ).pushNamed(AppRoutes.hexagonDetail),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            for (final score in report.domainScores)
              ActionCard(
                icon: Icons.analytics_outlined,
                title: domainLabel(score.domain),
                body: '점수 ${score.score} · 참고 백분위 ${score.percentile}',
                onTap: () =>
                    Navigator.of(context).pushNamed(AppRoutes.domainDetail),
              ),
            const SizedBox(height: 12),
            FilledButton.icon(
              icon: const Icon(Icons.home),
              label: const Text('홈으로'),
              onPressed: () => Navigator.of(
                context,
              ).pushNamedAndRemoveUntil(AppRoutes.home, (route) => false),
            ),
          ],
        ),
      ),
    );
  }
}
