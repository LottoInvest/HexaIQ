import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/app_routes.dart';
import '../../domain/hexaiq_models.dart';
import '../state/hexaiq_app_state.dart';

class DomainCompleteScreen extends StatelessWidget {
  const DomainCompleteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<HexaIQAppState>();
    final domain = state.lastCompletedDomain;
    final done = state.responses
        .where((response) => response.question.domain == domain)
        .length;

    return Scaffold(
      appBar: AppBar(title: const Text('영역 완료')),
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
                      Icon(
                        Icons.check_circle,
                        size: 56,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        domain == null
                            ? '검사 완료'
                            : '${domainLabel(domain)} 영역 완료',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text('$done개 문항을 제출했습니다.'),
                      const SizedBox(height: 24),
                      FilledButton(
                        onPressed: () {
                          if (state.hasMoreQuestions) {
                            Navigator.of(
                              context,
                            ).pushReplacementNamed(AppRoutes.question);
                          } else if (state.rewardedAdsCompleted <
                              state.requiredAds) {
                            Navigator.of(
                              context,
                            ).pushReplacementNamed(AppRoutes.rewardAd);
                          } else {
                            Navigator.of(
                              context,
                            ).pushReplacementNamed(AppRoutes.analysisLoading);
                          }
                        },
                        child: Text(state.hasMoreQuestions ? '다음 영역' : '결과 보기'),
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
