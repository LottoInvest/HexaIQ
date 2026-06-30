import 'package:flutter/material.dart';

import '../../../../core/domain/intelligence_domain.dart';
import '../../../../core/widgets/hexagon_chart.dart';
import '../../domain/hexaiq_models.dart';

class HexaIQIntroCard extends StatelessWidget {
  const HexaIQIntroCard({super.key, this.compact = false, this.onDomainTap});

  final bool compact;
  final ValueChanged<IntelligenceDomain>? onDomainTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chipWidth = compact ? 84.0 : 104.0;
    final chart = HexagonChart(
      values: const [72, 68, 70, 64, 74, 66],
      labels: domainCatalog.map((item) => item.shortLabel).toList(),
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
            for (final info in domainCatalog)
              _DomainChip(
                info: info,
                width: chipWidth,
                compact: compact,
                onTap: onDomainTap == null
                    ? null
                    : () => onDomainTap!(info.domain),
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

class _DomainChip extends StatelessWidget {
  const _DomainChip({
    required this.info,
    required this.width,
    required this.compact,
    this.onTap,
  });

  final DomainInfo info;
  final double width;
  final bool compact;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final label = SizedBox(
      width: double.infinity,
      child: Text(info.label, textAlign: TextAlign.center),
    );
    final visualDensity = compact ? VisualDensity.compact : null;
    return SizedBox(
      width: width,
      child: onTap == null
          ? Chip(
              visualDensity: visualDensity,
              label: label,
              labelPadding: EdgeInsets.zero,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            )
          : ActionChip(
              visualDensity: visualDensity,
              label: label,
              labelPadding: EdgeInsets.zero,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              onPressed: onTap,
            ),
    );
  }
}
