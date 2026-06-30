import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/app_routes.dart';
import '../../../core/domain/domain_result.dart';
import '../../../core/domain/question_difficulty.dart';
import '../../../core/widgets/action_card.dart';
import '../../../core/widgets/hexagon_chart.dart';
import '../../hexaiq/domain/hexaiq_models.dart';
import '../../hexaiq/presentation/state/hexaiq_app_state.dart';
import '../../test/domain/models/question_record.dart';
import '../../test/domain/models/test_session.dart';

class ReportSummaryScreen extends StatelessWidget {
  const ReportSummaryScreen({super.key});

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
                    Row(
                      children: [
                        Expanded(
                          child: _MetricTile(
                            label: '정답',
                            value:
                                '${state.correctCount} / ${state.totalQuestionCount}',
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _MetricTile(
                            label: '정확도',
                            value: '${(state.accuracy * 100).round()}%',
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _MetricTile(
                            label: '총 풀이 시간',
                            value: _formatElapsed(state.totalElapsedSeconds),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _MetricTile(
                      label: '전체 문항',
                      value: '${session?.questionHistory.length ?? 0}',
                    ),
                    const SizedBox(height: 8),
                    _MetricTile(
                      label: '평균 난이도',
                      value: report.averageDifficulty.labelKo,
                    ),
                    const SizedBox(height: 8),
                    _MetricTile(
                      label: '평균 풀이 시간',
                      value: _formatElapsed(
                        session?.averageElapsedSeconds ?? 0,
                      ),
                    ),
                    if (session != null) ...[
                      const SizedBox(height: 8),
                      _ThetaSummary(session: session),
                    ],
                    const SizedBox(height: 12),
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
                    Text(report.summary),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.radar),
                      label: const Text('영역 상세 보기'),
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
}

class _ThetaSummary extends StatelessWidget {
  const _ThetaSummary({required this.session});

  final TestSession session;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _MetricTile(
            label: '능력 추정값',
            value: session.thetaEstimate.theta.toStringAsFixed(2),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _MetricTile(
            label: '추정 안정도',
            value: _stabilityLabel(session.thetaEstimate.standardError),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _MetricTile(
            label: '평균 정보량',
            value: session.averageItemInformation.toStringAsFixed(2),
          ),
        ),
      ],
    );
  }

  String _stabilityLabel(double standardError) {
    if (!standardError.isFinite) {
      return '낮음';
    }
    if (standardError <= 0.45) {
      return '높음';
    }
    if (standardError <= 0.75) {
      return '보통';
    }
    return '낮음';
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
        ? '준비 중'
        : '${resolved.correct}/${resolved.total}  ${(resolved.accuracy * 100).round()}%';
    return ActionCard(
      icon: score.isComingSoon
          ? Icons.hourglass_empty_outlined
          : Icons.analytics_outlined,
      title: domainLabel(score.domain),
      body: body,
      trailing: score.isComingSoon ? const Text('예정') : Text('${score.score}'),
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
            Text('문항 기록', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            for (var i = 0; i < session.questionHistory.length; i++)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  '${i + 1}번 문항 | '
                  '${domainLabel(session.questionHistory[i].domain)} | '
                  '${session.questionHistory[i].difficulty.labelKo} | '
                  '${_answerLabel(session.questionHistory[i].correct)} | '
                  '${_formatElapsed(session.questionHistory[i].elapsedSeconds)}',
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
    if (minutes == 0) {
      return '$remaining초';
    }
    if (remaining == 0) {
      return '$minutes분';
    }
    return '$minutes분 $remaining초';
  }

  String _answerLabel(bool? correct) {
    return switch (correct) {
      true => '정답',
      false => '오답',
      null => '미응답',
    };
  }
}

class _DebugMetricsCard extends StatelessWidget {
  const _DebugMetricsCard({required this.session});

  final TestSession session;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('개발 디버그', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            for (var i = 0; i < session.questionHistory.length; i++)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(_debugLine(i, session.questionHistory[i])),
              ),
          ],
        ),
      ),
    );
  }

  String _debugLine(int index, QuestionRecord record) {
    return 'Q${index + 1} | item ${record.itemId} | '
        'theta=${record.thetaBefore.toStringAsFixed(2)}'
        '→${record.thetaAfter.toStringAsFixed(2)} | '
        'p=${record.expectedProbability.toStringAsFixed(2)} | '
        'likelihood=${record.likelihood.toStringAsFixed(2)} | '
        'info=${record.itemInformation.toStringAsFixed(2)} | '
        'CAT=${record.catSelectionScore.toStringAsFixed(2)}';
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
