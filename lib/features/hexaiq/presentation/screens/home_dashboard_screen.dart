import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/app_routes.dart';
import '../../../../core/domain/intelligence_domain.dart';
import '../../../../core/responsive/layout_breakpoints.dart';
import '../../../../core/responsive/responsive_page.dart';
import '../../../../core/widgets/action_card.dart';
import '../../../../core/widgets/hexagon_chart.dart';
import '../../domain/hexaiq_models.dart';
import '../state/hexaiq_app_state.dart';
import '../widgets/dashboard_nav.dart';
import '../widgets/hexa_iq_intro_card.dart';

class HomeDashboardScreen extends StatelessWidget {
  const HomeDashboardScreen({super.key});

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
      child: LayoutBuilder(
        builder: (context, constraints) {
          final screenClass = LayoutBreakpoints.classify(constraints.maxWidth);
          final isWide = screenClass != ScreenClass.compact;
          final isShort = MediaQuery.of(context).size.height < 760;
          final domainIntro = HexaIQIntroCard(
            compact: !isWide || isShort,
            averageExposure: state.averageExposure,
            onDomainTap: (domain) => _handleDomainTap(context, domain),
          );
          final summaryCard = Card(
            child: Padding(
              padding: EdgeInsets.all(isShort ? 12 : 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    profile == null ? '프로필을 선택해 주세요' : '${profile.name}의 최근 요약',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  SizedBox(height: isShort ? 10 : 18),
                  Center(
                    child: HexagonChart(
                      values: const [74, 66, 79, 62, 58, 72],
                      labels: domainCatalog
                          .map((item) => item.shortLabel)
                          .toList(),
                      size: isWide
                          ? 300
                          : isShort
                          ? 160
                          : 220,
                    ),
                  ),
                ],
              ),
            ),
          );
          final startAction = ActionCard(
            icon: Icons.play_arrow,
            title: '검사 시작',
            body: 'Basic 검사로 전체 인지 프로필을 확인합니다.',
            onTap: () => Navigator.of(context).pushNamed(AppRoutes.testTypeSelect),
          );
          final secondaryActions = Column(
            children: [
              ActionCard(
                icon: Icons.insights,
                title: '성장 기록',
                body: '최근 점수 변화와 학습 흐름을 확인합니다.',
                onTap: () =>
                    Navigator.of(context).pushNamed(AppRoutes.growthDashboard),
              ),
              ActionCard(
                icon: Icons.fitness_center,
                title: '추천 훈련',
                body: '약한 영역부터 짧게 반복하는 훈련 계획을 봅니다.',
                onTap: () => Navigator.of(
                  context,
                ).pushNamed(AppRoutes.trainingRecommendation),
              ),
            ],
          );
          final actions = Column(children: [startAction, secondaryActions]);

          if (isWide) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: summaryCard),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    children: [
                      domainIntro,
                      const SizedBox(height: 12),
                      actions,
                    ],
                  ),
                ),
              ],
            );
          }

          return Stack(
            children: [
              ListView(
                padding: const EdgeInsets.only(bottom: 88),
                children: [
                  if (!isShort) ...[summaryCard, const SizedBox(height: 12)],
                  domainIntro,
                  const SizedBox(height: 12),
                  secondaryActions,
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
      ),
    );
  }

  void _handleDomainTap(BuildContext context, IntelligenceDomain domain) {
    if (domain.isAvailable) {
      Navigator.of(context).pushNamed(AppRoutes.testTypeSelect);
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${domain.label} 영역은 Coming Soon입니다')),
    );
  }
}
