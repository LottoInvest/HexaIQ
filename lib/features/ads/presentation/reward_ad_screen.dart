import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/app_routes.dart';
import '../../hexaiq/presentation/state/hexaiq_app_state.dart';

class RewardAdScreen extends StatelessWidget {
  const RewardAdScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<HexaIQAppState>();
    final remaining = state.requiredAds - state.rewardedAdsCompleted;

    return Scaffold(
      appBar: AppBar(title: const Text('결과 준비')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.ondemand_video, size: 56),
                      const SizedBox(height: 16),
                      Text(
                        '결과 확인까지 $remaining회 남았습니다.',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      const Text('잠시 후 검사 결과가 이어집니다.'),
                      const SizedBox(height: 24),
                      FilledButton.icon(
                        icon: const Icon(Icons.play_circle_outline),
                        label: const Text('계속하기'),
                        onPressed: () async {
                          await context
                              .read<HexaIQAppState>()
                              .completeRewardAd();
                          if (!context.mounted) {
                            return;
                          }
                          final updated = context.read<HexaIQAppState>();
                          Navigator.of(context).pushReplacementNamed(
                            updated.rewardedAdsCompleted < updated.requiredAds
                                ? AppRoutes.rewardAd
                                : AppRoutes.analysisLoading,
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
