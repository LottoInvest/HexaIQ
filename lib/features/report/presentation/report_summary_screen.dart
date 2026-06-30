import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/app_routes.dart';
import '../../../core/domain/domain_result.dart';
import '../../../core/domain/question_difficulty.dart';
import '../../../core/widgets/action_card.dart';
import '../../../core/widgets/hexagon_chart.dart';
import '../../hexaiq/domain/hexaiq_models.dart';
import '../../hexaiq/presentation/state/hexaiq_app_state.dart';

class ReportSummaryScreen extends StatelessWidget {
  const ReportSummaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<HexaIQAppState>();
    final report = state.report;
    if (report == null) {
      return const Scaffold(body: Center(child: Text('Report is not ready.')));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Test Report')),
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
                      'Overall score ${report.overallScore}',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _MetricTile(
                            label: 'Correct',
                            value:
                                '${state.correctCount} / ${state.totalQuestionCount}',
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _MetricTile(
                            label: 'Accuracy',
                            value: '${(state.accuracy * 100).round()}%',
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _MetricTile(
                            label: 'Elapsed',
                            value: _formatElapsed(state.totalElapsedSeconds),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _MetricTile(
                      label: 'Average Difficulty',
                      value: report.averageDifficulty.labelKo,
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
                      label: const Text('Hexagon detail'),
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
              _DomainResultCard(
                score: score,
                result: report.domainResults[score.domain],
                onTap: () =>
                    Navigator.of(context).pushNamed(AppRoutes.domainDetail),
              ),
            const SizedBox(height: 12),
            FilledButton.icon(
              icon: const Icon(Icons.home),
              label: const Text('Home'),
              onPressed: () => Navigator.of(
                context,
              ).pushNamedAndRemoveUntil(AppRoutes.home, (route) => false),
            ),
          ],
        ),
      ),
    );
  }

  String _formatElapsed(int seconds) {
    final minutes = seconds ~/ 60;
    final remaining = seconds % 60;
    return '${minutes}m ${remaining.toString().padLeft(2, '0')}s';
  }
}

class _DomainResultCard extends StatelessWidget {
  const _DomainResultCard({
    required this.score,
    required this.result,
    required this.onTap,
  });

  final DomainScore score;
  final DomainResult? result;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final resolved = result ?? const DomainResult();
    final body = score.isComingSoon
        ? 'Coming Soon'
        : '${resolved.correct}/${resolved.total}  ${(resolved.accuracy * 100).round()}%';
    return ActionCard(
      icon: score.isComingSoon
          ? Icons.hourglass_empty_outlined
          : Icons.analytics_outlined,
      title: domainLabel(score.domain),
      body: body,
      trailing: score.isComingSoon
          ? const Text('Soon')
          : Text('${score.score}'),
      onTap: onTap,
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: theme.textTheme.labelMedium),
            const SizedBox(height: 4),
            Text(value, style: theme.textTheme.titleMedium),
          ],
        ),
      ),
    );
  }
}
