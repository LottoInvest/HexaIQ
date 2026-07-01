import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/app_routes.dart';
import '../../../core/domain/domain_result.dart';
import '../../../core/domain/question_difficulty.dart';
import '../../../core/widgets/hexagon_chart.dart';
import '../../export/domain/pdf_export_service.dart';
import '../../hexaiq/domain/hexaiq_models.dart';
import '../../hexaiq/presentation/state/hexaiq_app_state.dart';
import '../../test/domain/models/question_record.dart';
import '../../test/domain/models/test_mode.dart';
import '../../test/domain/models/test_session.dart';

class ReportSummaryScreen extends StatelessWidget {
  const ReportSummaryScreen({super.key});

  static const _pdfExportService = PdfExportService();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<HexaIQAppState>();
    final report = state.report;
    final session = state.testSession;
    if (report == null) {
      return const Scaffold(body: Center(child: Text('리포트를 준비하고 있습니다.')));
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
                      '종합 점수 ${report.overallScore}',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 12),
                    _ReportMetricGrid(
                      metrics: [
                        _MetricData(
                          label: '정답',
                          value:
                              '${state.correctCount} / ${state.totalQuestionCount}',
                        ),
                        _MetricData(
                          label: '정답률',
                          value: '${(state.accuracy * 100).round()}%',
                        ),
                        _MetricData(
                          label: '총 풀이 시간',
                          value: _formatElapsed(state.totalElapsedSeconds),
                        ),
                        _MetricData(
                          label: '전체 문항',
                          value: '${state.totalQuestionCount}',
                        ),
                        _MetricData(
                          label: '평균 난이도',
                          value: report.averageDifficulty.labelKo,
                        ),
                        _MetricData(
                          label: '평균 풀이 시간',
                          value: _formatElapsed(
                            session?.averageElapsedSeconds ?? 0,
                          ),
                        ),
                        if (session != null) ...[
                          _MetricData(
                            label: '추정 IQ',
                            value: '${session.estimatedIQ}',
                          ),
                          _MetricData(
                            label: '상위 비율',
                            value: '${session.percentile}%',
                          ),
                          _MetricData(
                            label: '능력 수준',
                            value: session.abilityLevel.labelKo,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: HexagonChart(
                        values: report.domainScores
                            .map((score) => score.score.toDouble())
                            .toList(),
                        labels: domainCatalog
                            .map((domain) => domain.shortLabel)
                            .toList(),
                        labelFontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(_summaryText(state.accuracy)),
                    if (session != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        '현재 IQ는 초기 추정값입니다. 향후 데이터가 축적되면 더 정확해집니다.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.radar),
                      label: const Text('영역 상세 보기'),
                      onPressed: () => Navigator.of(
                        context,
                      ).pushNamed(AppRoutes.hexagonDetail),
                    ),
                    if (session != null) ...[
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.picture_as_pdf_outlined),
                        label: Text(
                          _pdfExportService.canExportPdf(state.purchaseStatus)
                              ? 'PDF 리포트 저장'
                              : '전문 리포트 미리보기',
                        ),
                        onPressed: () => Navigator.of(
                          context,
                        ).pushNamed(AppRoutes.professionalSampleReport),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text('영역별 결과', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            _DomainResultGrid(report: report, session: session),
            if (report.recommendations.isNotEmpty) ...[
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '다음 추천 훈련',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      for (final recommendation in report.recommendations)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 3),
                          child: Text('• $recommendation'),
                        ),
                    ],
                  ),
                ),
              ),
            ],
            if (session != null && session.showDebugMetrics) ...[
              const SizedBox(height: 12),
              _DebugMetricsCard(session: session),
            ],
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

  String _summaryText(double accuracy) {
    if (accuracy <= 0.1) {
      return '이번 결과는 전체 기준 낮은 구간으로 추정됩니다. 컨디션과 풀이 환경에 따라 결과가 달라질 수 있으니 충분히 쉬고 다시 검사해 보세요.';
    }
    return '검사 결과는 응답한 영역을 기준으로 계산되었습니다. 약한 영역을 반복 훈련하면 인지 능력을 더욱 향상시킬 수 있습니다.';
  }
}

String _formatElapsed(int seconds) {
  final minutes = seconds ~/ 60;
  final remaining = seconds % 60;
  if (minutes == 0) {
    return '$remaining초';
  }
  if (remaining == 0) {
    return '$minutes분';
  }
  return '$minutes분 $remaining초';
}

class _DomainResultGrid extends StatelessWidget {
  const _DomainResultGrid({required this.report, required this.session});

  final ReportSummary report;
  final TestSession? session;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = width >= 900
            ? 3
            : width >= 560
            ? 2
            : 1;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: report.domainScores.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            mainAxisExtent: 184,
          ),
          itemBuilder: (context, index) {
            final score = report.domainScores[index];
            return _DomainResultCard(
              score: score,
              result: report.domainResults[score.domain],
              session: session,
              hideNoDataCopy: session?.mode == TestMode.quickIq,
              onTap: () =>
                  Navigator.of(context).pushNamed(AppRoutes.domainDetail),
            );
          },
        );
      },
    );
  }
}

class _DomainResultCard extends StatelessWidget {
  const _DomainResultCard({
    required this.score,
    required this.result,
    required this.session,
    required this.hideNoDataCopy,
    required this.onTap,
  });

  final DomainScore score;
  final DomainResult? result;
  final TestSession? session;
  final bool hideNoDataCopy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final resolved = result ?? DomainResult(domain: score.domain);
    final hasData = resolved.total > 0;
    final averageTime = hasData ? resolved.elapsed ~/ resolved.total : 0;
    final ability =
        session?.thetaForDomain(score.domain).theta ?? resolved.theta;
    final foreground = hasData
        ? theme.colorScheme.onSurface
        : theme.colorScheme.onSurfaceVariant;

    return Card(
      color: hasData ? null : theme.colorScheme.surfaceContainerHighest,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: DefaultTextStyle.merge(
            style: TextStyle(color: foreground),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.analytics_outlined,
                      color: hasData
                          ? theme.colorScheme.primary
                          : theme.colorScheme.outline,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        domainLabel(score.domain),
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: foreground,
                        ),
                      ),
                    ),
                    Text(
                      hasData ? '${score.score}' : '-',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: foreground,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (hasData) ...[
                  Text('정답 ${resolved.correct} / ${resolved.total}'),
                  Text('정답률 ${(resolved.accuracy * 100).round()}%'),
                  Text('능력점수 ${score.score}'),
                  Text('평균시간 ${_formatElapsed(averageTime)}'),
                  Text('능력 추정 ${ability.toStringAsFixed(2)}'),
                ] else if (hideNoDataCopy) ...[
                  const Text('Quick IQ 영역 결과'),
                  const SizedBox(height: 4),
                  const Text('6개 영역 균형 검사에 포함됩니다.'),
                ] else ...[
                  const Text('데이터 없음'),
                  const SizedBox(height: 4),
                  const Text('응답한 영역만 실제 점수로 계산합니다.'),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DebugMetricsCard extends StatelessWidget {
  const _DebugMetricsCard({required this.session});

  final TestSession session;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ExpansionTile(
        title: const Text('개발 지표'),
        subtitle: const Text('Theta / IRT / CAT / Calibration'),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Model 2PL'),
              Text('Theta Method ${session.thetaEstimate.method.label}'),
              Text('Theta ${session.thetaEstimate.theta.toStringAsFixed(2)}'),
              Text(
                'SE ${session.thetaEstimate.standardError.toStringAsFixed(2)}',
              ),
              Text(
                'Posterior Peak '
                '${session.thetaEstimate.posteriorPeak.toStringAsExponential(2)}',
              ),
              Text(
                'Posterior Mean '
                '${session.thetaEstimate.posteriorMean.toStringAsFixed(2)}',
              ),
              Text(
                'Posterior Variance '
                '${session.thetaEstimate.posteriorVariance.toStringAsFixed(2)}',
              ),
              Text('Scaled Score ${session.scaledScore.toStringAsFixed(2)}'),
              Text('Estimated IQ ${session.estimatedIQ}'),
              Text('Top Percent ${session.percentile}%'),
              Text('Ability Level ${session.abilityLevel.labelKo}'),
              const SizedBox(height: 8),
              for (var i = 0; i < session.questionHistory.length; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(_debugLine(i, session.questionHistory[i])),
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _debugLine(int index, QuestionRecord record) {
    return 'Q${index + 1} | item ${record.itemId} | '
        'theta=${record.thetaBefore.toStringAsFixed(2)}'
        '->${record.thetaAfter.toStringAsFixed(2)} | '
        'p=${record.expectedProbability.toStringAsFixed(2)} | '
        'likelihood=${record.likelihood.toStringAsFixed(2)} | '
        'logLikelihood=${record.logLikelihood.toStringAsFixed(2)} | '
        'posterior=${record.posteriorContribution.toStringAsFixed(2)} | '
        'info=${record.itemInformation.toStringAsFixed(2)} | '
        'IRT(a=${record.discrimination.toStringAsFixed(2)}, '
        'b=${record.difficultyIndex.toStringAsFixed(2)}, '
        'c=${record.guessing.toStringAsFixed(2)}) | '
        'Calibration(n/a) | '
        'CAT=${record.catSelectionScore.toStringAsFixed(2)}';
  }
}

class _ReportMetricGrid extends StatelessWidget {
  const _ReportMetricGrid({required this.metrics});

  final List<_MetricData> metrics;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = width >= 900
            ? 4
            : width >= 640
            ? 3
            : width >= 360
            ? 2
            : 1;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: metrics.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            mainAxisExtent: 76,
          ),
          itemBuilder: (context, index) {
            final metric = metrics[index];
            return _MetricTile(label: metric.label, value: metric.value);
          },
        );
      },
    );
  }
}

class _MetricData {
  const _MetricData({required this.label, required this.value});

  final String label;
  final String value;
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
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label, style: theme.textTheme.labelMedium, maxLines: 1),
            const SizedBox(height: 4),
            Text(
              value,
              style: theme.textTheme.titleMedium,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
