import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/app_routes.dart';
import '../../../../core/domain/intelligence_domain.dart';
import '../../../../core/responsive/layout_breakpoints.dart';
import '../../../../core/responsive/responsive_page.dart';
import '../../../../core/widgets/action_card.dart';
import '../../../../core/widgets/hexagon_chart.dart';
import '../../../result/domain/result_integrity_validator.dart';
import '../../../result/domain/test_result_payload.dart';
import '../../../test/domain/models/test_mode.dart';
import '../../domain/hexaiq_models.dart';
import '../state/hexaiq_app_state.dart';
import '../widgets/dashboard_nav.dart';
import '../widgets/hexa_iq_intro_card.dart';

class HomeDashboardScreen extends StatelessWidget {
  const HomeDashboardScreen({super.key});

  static const _validator = ResultIntegrityValidator();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<HexaIQAppState>();
    final profile = state.selectedProfile;
    return ResponsivePage(
      title: 'HexaIQ',
      currentIndex: 0,
      onDestinationSelected: (index) =>
          handleDashboardDestination(context, index),
      actions: [
        IconButton(
          tooltip: '설정',
          onPressed: () => Navigator.of(context).pushNamed(AppRoutes.settings),
          icon: const Icon(Icons.settings_outlined),
        ),
      ],
      child: profile == null && state.testSession?.isComplete != true
          ? const Center(child: Text('프로필을 먼저 선택해 주세요.'))
          : FutureBuilder<List<TestResultSummary>>(
              future: profile == null
                  ? Future.value(const <TestResultSummary>[])
                  : state.repository.loadTestHistory(profile.id),
              builder: (context, snapshot) {
                final history = (snapshot.data ?? const <TestResultSummary>[])
                    .where((result) => _validator.validate(result).isValid)
                    .toList(growable: false);
                final latest = history.isNotEmpty ? history.first : null;
                return LayoutBuilder(
                  builder: (context, constraints) {
                    final screenClass = LayoutBreakpoints.classify(
                      constraints.maxWidth,
                    );
                    final isWide = screenClass != ScreenClass.compact;
                    final isShort = MediaQuery.of(context).size.height < 760;
                    final introCard = HexaIQIntroCard(
                      compact: !isWide || isShort,
                      averageExposure: state.averageExposure,
                      onDomainTap: (domain) =>
                          _handleDomainTap(context, domain),
                    );
                    final primaryCard = latest == null
                        ? introCard
                        : _RecentResultCard(result: latest, isWide: isWide);
                    final actions = _HomeActions(isCompact: !isWide);

                    if (isWide) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: primaryCard),
                          const SizedBox(width: 16),
                          Expanded(child: actions),
                        ],
                      );
                    }

                    return Stack(
                      children: [
                        ListView(
                          padding: const EdgeInsets.only(bottom: 88),
                          children: [
                            primaryCard,
                            const SizedBox(height: 12),
                            actions,
                            const SizedBox(height: 24),
                          ],
                        ),
                        Align(
                          alignment: Alignment.bottomCenter,
                          child: SafeArea(
                            top: false,
                            child: SizedBox(
                              width: double.infinity,
                              child: FilledButton.icon(
                                icon: const Icon(Icons.play_arrow),
                                label: const Text('검사 시작'),
                                onPressed: () => Navigator.of(
                                  context,
                                ).pushNamed(AppRoutes.testTypeSelect),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
    );
  }

  void _handleDomainTap(BuildContext context, IntelligenceDomain domain) {
    Navigator.of(context).pushNamed(AppRoutes.testTypeSelect);
  }
}

class _RecentResultCard extends StatelessWidget {
  const _RecentResultCard({required this.result, required this.isWide});

  final TestResultSummary result;
  final bool isWide;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final payload = TestResultPayload.fromResult(result);
    return Card(
      key: const ValueKey('home-recent-result-card'),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('최근 검사 결과', style: theme.textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(
              '${_dateLabel(result.completedAt)} · ${_modeLabel(payload.testMode)}',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Center(
              child: HexagonChart(
                values: payload.visibleHexagonValues,
                labels: domainCatalog.map((item) => item.shortLabel).toList(),
                size: isWide ? 300 : 220,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _MetricTile(label: '최근 IQ', value: '${result.estimatedIQ}'),
                _MetricTile(label: '상위 비율', value: '${result.percentile}%'),
                _MetricTile(label: '능력 수준', value: result.abilityLevel),
                _MetricTile(
                  label: '정답',
                  value: '${payload.correctCount} / ${payload.totalQuestions}',
                ),
                _MetricTile(label: '정답률', value: '${payload.accuracyPercent}%'),
                _MetricTile(label: '풀이 시간', value: payload.elapsedLabel),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _dateLabel(DateTime date) {
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
  }

  String _modeLabel(TestMode mode) {
    return switch (mode) {
      TestMode.quickIq => '빠른 IQ',
      TestMode.fullDiagnostic => '정밀 진단',
      TestMode.domainTraining => '영역 훈련',
    };
  }
}

class _HomeActions extends StatelessWidget {
  const _HomeActions({required this.isCompact});

  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    final cards = [
      ActionCard(
        icon: Icons.play_arrow,
        title: '검사 시작',
        body: '빠른 IQ 또는 정밀 검사를 시작합니다.',
        onTap: () => Navigator.of(context).pushNamed(AppRoutes.testTypeSelect),
      ),
      ActionCard(
        icon: Icons.insights,
        title: '성장 기록',
        body: '저장된 검사 결과를 기준으로 변화 흐름을 확인합니다.',
        onTap: () => Navigator.of(context).pushNamed(AppRoutes.growthDashboard),
      ),
      ActionCard(
        icon: Icons.fitness_center,
        title: '추천 훈련',
        body: '약한 영역을 중심으로 다음 훈련을 확인합니다.',
        onTap: () =>
            Navigator.of(context).pushNamed(AppRoutes.trainingRecommendation),
      ),
    ];
    return Column(
      children: [
        for (final card in cards) ...[
          card,
          if (card != cards.last) SizedBox(height: isCompact ? 8 : 12),
        ],
      ],
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
    return SizedBox(
      width: 128,
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
