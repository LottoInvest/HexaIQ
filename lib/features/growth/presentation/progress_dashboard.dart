import 'package:flutter/material.dart';

import '../domain/progress_analytics.dart';

class ProgressDashboard extends StatelessWidget {
  const ProgressDashboard({super.key, required this.summary});

  final ProgressSummary summary;

  @override
  Widget build(BuildContext context) {
    final deltaPrefix = summary.iqDelta >= 0 ? '+' : '';
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _MetricCard(
          icon: Icons.insights,
          label: 'IQ 변화',
          value: '$deltaPrefix${summary.iqDelta}',
        ),
        _MetricCard(
          icon: Icons.psychology,
          label: '최근 IQ',
          value: '${summary.latestIQ}',
        ),
        _MetricCard(
          icon: Icons.assignment_turned_in,
          label: '누적 검사',
          value: '${summary.testCount}',
        ),
        _MetricCard(
          icon: Icons.timer,
          label: '평균 반응시간',
          value: '${summary.averageResponseTime}초',
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: 180,
      height: 110,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: scheme.primary),
              Text(label, style: Theme.of(context).textTheme.labelMedium),
              Text(value, style: Theme.of(context).textTheme.titleLarge),
            ],
          ),
        ),
      ),
    );
  }
}
