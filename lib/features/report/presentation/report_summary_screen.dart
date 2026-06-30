import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/app_routes.dart';
import '../../../core/domain/domain_result.dart';
import '../../../core/domain/question_difficulty.dart';
import '../../../core/widgets/action_card.dart';
import '../../../core/widgets/hexagon_chart.dart';
import '../../hexaiq/domain/hexaiq_models.dart';
import '../../hexaiq/presentation/state/hexaiq_app_state.dart';
import '../../item_bank/domain/exposure_status.dart';
import '../../test/domain/models/test_session.dart';

class ReportSummaryScreen extends StatelessWidget {
  const ReportSummaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<HexaIQAppState>();
    final report = state.report;
    final session = state.testSession;
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
                      label: 'Total Questions',
                      value: '${session?.questionHistory.length ?? 0}',
                    ),
                    const SizedBox(height: 8),
                    _MetricTile(
                      label: 'Average Difficulty',
                      value: report.averageDifficulty.labelKo,
                    ),
                    const SizedBox(height: 8),
                    _MetricTile(
                      label: 'Average Time',
                      value: _formatElapsed(
                        session?.averageElapsedSeconds ?? 0,
                      ),
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
            if (session != null && session.questionHistory.isNotEmpty) ...[
              const SizedBox(height: 12),
              _QuestionHistoryCard(session: session),
            ],
            const SizedBox(height: 12),
            _ItemBankCard(counts: state.itemBankDomainCounts),
            const SizedBox(height: 12),
            _ExposureSummaryCard(
              averageExposure: state.averageExposure,
              mostUsed: state.mostUsedExposure,
              leastUsed: state.leastUsedExposure,
              topItems: state.topExposureStatuses,
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

class _ItemBankCard extends StatelessWidget {
  const _ItemBankCard({required this.counts});

  final Map<CognitiveDomain, int> counts;

  @override
  Widget build(BuildContext context) {
    final total = counts.values.fold<int>(0, (sum, count) => sum + count);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Item Bank', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text('Total $total Questions'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final info in domainCatalog)
                  Chip(
                    label: Text(
                      '${info.shortLabel} ${counts[info.domain] ?? 0}',
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ExposureSummaryCard extends StatelessWidget {
  const _ExposureSummaryCard({
    required this.averageExposure,
    required this.mostUsed,
    required this.leastUsed,
    required this.topItems,
  });

  final double averageExposure;
  final ExposureStatus? mostUsed;
  final ExposureStatus? leastUsed;
  final List<ExposureStatus> topItems;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Exposure', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text('Average Exposure ${averageExposure.toStringAsFixed(2)}'),
            const SizedBox(height: 8),
            Text(
              'Most Used Item ${mostUsed?.itemId ?? '-'} '
              '(${mostUsed?.exposureCount ?? 0})',
            ),
            Text(
              'Least Used Item ${leastUsed?.itemId ?? '-'} '
              '(${leastUsed?.exposureCount ?? 0})',
            ),
            const SizedBox(height: 12),
            Text('Top 5', style: theme.textTheme.labelLarge),
            const SizedBox(height: 6),
            if (topItems.isEmpty)
              const Text('No exposure yet')
            else
              for (final status in topItems)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text('${status.itemId}  ${status.exposureCount}'),
                ),
          ],
        ),
      ),
    );
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

class _QuestionHistoryCard extends StatelessWidget {
  const _QuestionHistoryCard({required this.session});

  final TestSession session;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Question History',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            for (var i = 0; i < session.questionHistory.length; i++)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  'Q${i + 1} | item ${session.questionHistory[i].itemId} '
                  '| domain ${session.questionHistory[i].domain.name} '
                  '| ${session.questionHistory[i].difficulty.labelKo} '
                  '| b=${session.questionHistory[i].difficultyIndex.toStringAsFixed(1)} '
                  '| score=${session.questionHistory[i].selectionScore.toStringAsFixed(2)} '
                  '| ${session.questionHistory[i].correct == true ? 'Correct' : 'Wrong'} '
                  '| ${_formatElapsed(session.questionHistory[i].elapsedSeconds)}',
                ),
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
