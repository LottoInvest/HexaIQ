import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/app_routes.dart';
import '../../../core/responsive/responsive_page.dart';
import '../../hexaiq/domain/hexaiq_models.dart';
import '../../hexaiq/presentation/state/hexaiq_app_state.dart';
import '../../hexaiq/presentation/widgets/dashboard_nav.dart';
import '../../result/domain/test_result_payload.dart';

class GrowthDashboardScreen extends StatelessWidget {
  const GrowthDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<HexaIQAppState>();
    final profile = state.selectedProfile;
    return ResponsivePage(
      title: '성장 분석',
      currentIndex: 1,
      onDestinationSelected: (index) =>
          handleDashboardDestination(context, index),
      child: profile == null
          ? const Center(child: Text('프로필을 먼저 선택해 주세요.'))
          : FutureBuilder<List<TestResultSummary>>(
              future: state.repository.loadTestHistory(profile.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                final history = snapshot.data ?? const <TestResultSummary>[];
                if (history.isEmpty) {
                  return const _EmptyGrowthState();
                }
                final chronological = history.reversed.toList(growable: false);
                final latest = history.first;
                final latestPayload = TestResultPayload.fromResult(latest);
                final previous = history.length >= 2 ? history[1] : null;
                final delta = previous == null
                    ? null
                    : latest.estimatedIQ - previous.estimatedIQ;

                return ListView(
                  children: [
                    _SummaryCard(
                      latest: latest,
                      payload: latestPayload,
                      delta: delta,
                      testCount: history.length,
                    ),
                    const SizedBox(height: 12),
                    _GrowthChart(results: chronological.take(6).toList()),
                    const SizedBox(height: 12),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('검사 결과는 저장된 이력만 기준으로 계산됩니다.'),
                            const SizedBox(height: 12),
                            FilledButton.icon(
                              onPressed: () => Navigator.pushNamed(
                                context,
                                AppRoutes.history,
                              ),
                              icon: const Icon(Icons.history),
                              label: const Text('검사 이력 보기'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }
}

class _EmptyGrowthState extends StatelessWidget {
  const _EmptyGrowthState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text('아직 성장 기록이 없습니다. 검사를 완료하면 이곳에 변화가 표시됩니다.'),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.latest,
    required this.payload,
    required this.delta,
    required this.testCount,
  });

  final TestResultSummary latest;
  final TestResultPayload payload;
  final int? delta;
  final int testCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final deltaText = delta == null
        ? '첫 검사 결과가 저장되었습니다.'
        : delta! > 0
        ? '+$delta'
        : '$delta';
    return Card(
      key: const ValueKey('growth-summary-card'),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('최근 성장 요약', style: theme.textTheme.titleLarge),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _Metric(label: '최근 IQ', value: '${latest.estimatedIQ}'),
                _Metric(label: '검사 횟수', value: '$testCount회'),
                _Metric(
                  label: '평균 풀이 시간',
                  value: '${payload.averageElapsedSeconds}초',
                ),
                _Metric(label: '변화량', value: deltaText),
              ],
            ),
            if (delta == null) ...[
              const SizedBox(height: 12),
              const Text('두 번째 검사부터 변화량과 추세를 확인할 수 있습니다.'),
            ],
          ],
        ),
      ),
    );
  }
}

class _GrowthChart extends StatelessWidget {
  const _GrowthChart({required this.results});

  final List<TestResultSummary> results;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('최근 결과 흐름', style: theme.textTheme.titleLarge),
            const SizedBox(height: 16),
            for (var i = 0; i < results.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    SizedBox(width: 48, child: Text('T${i + 1}')),
                    Expanded(
                      child: LinearProgressIndicator(
                        value: (results[i].estimatedIQ / 160).clamp(0, 1),
                        minHeight: 10,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text('${results[i].estimatedIQ}'),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 132,
      child: DecoratedBox(
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
      ),
    );
  }
}
