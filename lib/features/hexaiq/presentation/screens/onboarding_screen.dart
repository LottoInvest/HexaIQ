import 'package:flutter/material.dart';

import '../../../../app/app_routes.dart';
import '../../../settings/presentation/widgets/theme_mode_selector.dart';
import '../widgets/hexa_iq_intro_card.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isLandscape = size.width > size.height;
    final isCompact = isLandscape && size.shortestSide < 600;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: ListView(
              padding: EdgeInsets.all(isCompact ? 16 : 24),
              shrinkWrap: true,
              children: [
                Text('HexaIQ', style: Theme.of(context).textTheme.displaySmall),
                const SizedBox(height: 12),
                Text(
                  '검사 분석, 훈련 추천, 성장 기록을 하나의 흐름으로 연결합니다.',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                SizedBox(height: isCompact ? 12 : 20),
                ThemeModeSelector(compact: isCompact),
                SizedBox(height: isCompact ? 12 : 20),
                HexaIQIntroCard(compact: isCompact),
                SizedBox(height: isCompact ? 16 : 24),
                Align(
                  alignment: Alignment.centerLeft,
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.of(
                        context,
                      ).pushReplacementNamed(AppRoutes.profileSelect);
                    },
                    icon: const Icon(Icons.arrow_forward),
                    label: const Text('시작하기'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
