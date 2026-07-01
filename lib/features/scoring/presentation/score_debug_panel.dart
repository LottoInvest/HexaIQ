import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../domain/cognitive_domain.dart';
import '../domain/domain_score_calculator.dart';
import '../domain/report_score_mapper.dart';

class ScoreDebugPanel extends StatelessWidget {
  const ScoreDebugPanel({super.key, required this.reportScore});

  final ReliableReportScore reportScore;

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) {
      return const SizedBox.shrink();
    }
    return ExpansionTile(
      title: const Text('점수 디버그'),
      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      children: [
        _DebugLine(label: 'IQ', value: '${reportScore.iqScore}'),
        _DebugLine(label: '종합 설명', value: reportScore.overallDescription),
        const SizedBox(height: 8),
        for (final score in reportScore.domainScores)
          _DomainDebugLine(score: score),
      ],
    );
  }
}

class _DomainDebugLine extends StatelessWidget {
  const _DomainDebugLine({required this.score});

  final ReliableDomainScore score;

  @override
  Widget build(BuildContext context) {
    final elapsed = score.averageResponseTime.inMilliseconds / 1000;
    return _DebugLine(
      label: score.domain.labelKo,
      value:
          'score=${score.score}, raw=${score.rawScore.toStringAsFixed(1)}, '
          'weighted=${score.weightedScore.toStringAsFixed(1)}, '
          'accuracy=${(score.accuracy * 100).round()}%, '
          'items=${score.totalCount}, avgTime=${elapsed.toStringAsFixed(1)}초',
    );
  }
}

class _DebugLine extends StatelessWidget {
  const _DebugLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 92,
            child: Text(label, style: Theme.of(context).textTheme.labelMedium),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}
