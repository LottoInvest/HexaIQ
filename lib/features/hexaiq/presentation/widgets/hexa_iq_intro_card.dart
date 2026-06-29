import 'package:flutter/material.dart';

import '../../../../core/widgets/hexagon_chart.dart';

class HexaIQIntroCard extends StatelessWidget {
  const HexaIQIntroCard({super.key, this.compact = false});

  final bool compact;

  static const _labels = ['수리', '언어', '공간', '기억', '논리', '속도'];
  static const _areas = ['수리논리', '언어추론', '공간지각', '기억력', '논리추론', '처리속도'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chart = HexagonChart(
      values: const [72, 68, 70, 64, 74, 66],
      labels: _labels,
      size: compact ? 132 : 176,
    );
    final copy = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('HexaIQ는 하나의 점수가 아니라', style: theme.textTheme.titleMedium),
        const SizedBox(height: 4),
        Text(
          '6가지 인지 영역을 함께 분석합니다.',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: compact ? 8 : 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final area in _areas)
              Chip(
                visualDensity: compact ? VisualDensity.compact : null,
                label: Text(area),
              ),
          ],
        ),
      ],
    );

    return Card(
      child: Padding(
        padding: EdgeInsets.all(compact ? 12 : 16),
        child: compact
            ? Row(
                children: [
                  chart,
                  const SizedBox(width: 12),
                  Expanded(child: copy),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(child: chart),
                  const SizedBox(height: 12),
                  copy,
                ],
              ),
      ),
    );
  }
}
