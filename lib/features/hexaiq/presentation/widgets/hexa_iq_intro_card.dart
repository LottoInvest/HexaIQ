import 'package:flutter/material.dart';

import '../../../../core/domain/intelligence_domain.dart';
import '../../../../core/widgets/hexagon_chart.dart';
import '../../domain/hexaiq_models.dart';

class HexaIQIntroCard extends StatelessWidget {
  const HexaIQIntroCard({
    super.key,
    this.compact = false,
    this.onDomainTap,
    this.averageExposure,
  });

  final bool compact;
  final ValueChanged<IntelligenceDomain>? onDomainTap;
  final double? averageExposure;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bodyStyle = theme.textTheme.bodyLarge?.copyWith(
      fontSize: compact ? 16 : 17,
      height: 1.35,
    );
    final titleStyle = theme.textTheme.titleMedium?.copyWith(
      fontSize: compact ? 18 : 20,
      height: 1.3,
      fontWeight: FontWeight.w700,
    );
    final chartSize = compact ? 140.0 : 156.0;

    return Card(
      child: Padding(
        padding: EdgeInsets.all(compact ? 12 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: HexagonChart(
                values: const [72, 68, 70, 64, 74, 66],
                labels: domainCatalog.map((item) => item.shortLabel).toList(),
                size: chartSize,
                labelFontSize: compact ? 13 : 14,
              ),
            ),
            const SizedBox(key: Key('intro-chart-body-gap'), height: 18),
            Text(
              'HexaIQ는 하나의 점수가 아니라\n6가지 인지 영역을 함께 분석합니다.',
              style: titleStyle,
            ),
            SizedBox(height: compact ? 8 : 10),
            Text(
              '응답 결과에 따라 난이도를 조절하고,\n문항 정보를 바탕으로 다음 문제를 선택합니다.',
              style: bodyStyle,
            ),
            const SizedBox(key: Key('intro-body-domain-gap'), height: 20),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: 3.4,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  children: [
                    for (final info in domainCatalog)
                      _DomainButton(
                        info: info,
                        compact: compact,
                        onTap: onDomainTap == null
                            ? null
                            : () => onDomainTap!(info.domain),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(key: Key('intro-domain-bottom-gap'), height: 16),
          ],
        ),
      ),
    );
  }
}

class _DomainButton extends StatelessWidget {
  const _DomainButton({required this.info, required this.compact, this.onTap});

  final DomainInfo info;
  final bool compact;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final label = Text(
      info.label,
      textAlign: TextAlign.center,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
    final style = OutlinedButton.styleFrom(
      visualDensity: compact ? VisualDensity.compact : VisualDensity.standard,
      padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 12),
      textStyle: TextStyle(
        fontSize: compact ? 14 : 15,
        fontWeight: FontWeight.w600,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
    return OutlinedButton(
      style: style,
      onPressed: onTap,
      child: SizedBox(width: double.infinity, child: label),
    );
  }
}
