import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/app_routes.dart';
import '../../../app/release_config.dart';
import '../../hexaiq/presentation/state/hexaiq_app_state.dart';

class ProfessionalPurchaseScreen extends StatelessWidget {
  const ProfessionalPurchaseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<HexaIQAppState>();
    return Scaffold(
      appBar: AppBar(title: const Text('전문 IQ 검사')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: ListView(
              padding: const EdgeInsets.all(16),
              shrinkWrap: true,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '전문 검사 잠금 해제',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          ReleaseConfig.professionalPriceLabel,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 16),
                        const _Benefit(text: '최고 정확도'),
                        const _Benefit(text: 'CAT 기반 검사'),
                        const _Benefit(text: '전문가 분석'),
                        const _Benefit(text: 'PDF 리포트'),
                        const _Benefit(text: '결과 비교 기능'),
                        const _Benefit(text: '향후 업데이트 무료 제공'),
                        const SizedBox(height: 20),
                        OutlinedButton.icon(
                          icon: const Icon(Icons.picture_as_pdf_outlined),
                          label: const Text('예시 리포트 보기'),
                          onPressed: () => Navigator.of(
                            context,
                          ).pushNamed(AppRoutes.professionalSampleReport),
                        ),
                        const SizedBox(height: 12),
                        FilledButton.icon(
                          icon: const Icon(Icons.lock_open),
                          label: Text(
                            state.isBusy
                                ? '처리 중...'
                                : '${ReleaseConfig.professionalPriceLabel} 구매',
                          ),
                          onPressed: state.isBusy
                              ? null
                              : () async {
                                  await context
                                      .read<HexaIQAppState>()
                                      .purchaseProfessional();
                                  if (context.mounted) {
                                    Navigator.of(
                                      context,
                                    ).pushReplacementNamed(AppRoutes.testIntro);
                                  }
                                },
                        ),
                      ],
                    ),
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

class _Benefit extends StatelessWidget {
  const _Benefit({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            Icons.check_circle,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
