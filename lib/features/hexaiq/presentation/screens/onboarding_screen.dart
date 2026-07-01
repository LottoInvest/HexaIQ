import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/app_routes.dart';
import '../../../../core/domain/intelligence_domain.dart';
import '../../../settings/presentation/widgets/theme_mode_selector.dart';
import '../state/hexaiq_app_state.dart';
import '../widgets/hexa_iq_intro_card.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isCompact = size.shortestSide < 600 || size.height < 760;
    final headline = size.width < 520
        ? '검사 분석, 훈련 추천,\n성장 기록을 하나의 흐름으로 연결합니다.'
        : '검사 분석, 훈련 추천, 성장 기록을 하나의 흐름으로 연결합니다.';

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Padding(
              padding: EdgeInsets.all(isCompact ? 16 : 24),
              child: Stack(
                children: [
                  ListView(
                    padding: const EdgeInsets.only(bottom: 84),
                    children: [
                      Text(
                        'HexaIQ',
                        style: Theme.of(context).textTheme.displaySmall,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        headline,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontSize: isCompact ? 18 : 20,
                          height: 1.35,
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                      SizedBox(height: isCompact ? 12 : 20),
                      ThemeModeSelector(compact: isCompact),
                      SizedBox(height: isCompact ? 12 : 20),
                      HexaIQIntroCard(
                        compact: isCompact,
                        onDomainTap: (domain) =>
                            _handleDomainTap(context, domain),
                      ),
                    ],
                  ),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: SafeArea(
                      top: false,
                      child: SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () => _start(context),
                          icon: const Icon(Icons.arrow_forward),
                          label: const Text('시작하기'),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _start(BuildContext context) async {
    final state = context.read<HexaIQAppState>();
    if (!state.profilesLoaded) {
      await state.loadInitialData();
    }
    if (!context.mounted) {
      return;
    }
    Navigator.of(context).pushReplacementNamed(
      state.profiles.isEmpty
          ? AppRoutes.profileCreate
          : AppRoutes.profileSelect,
    );
  }

  void _handleDomainTap(BuildContext context, IntelligenceDomain domain) {
    if (domain.isAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Numerical 검사는 Basic 검사에서 시작할 수 있습니다.')),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${domain.label} 영역은 Coming Soon입니다.')),
    );
  }
}
