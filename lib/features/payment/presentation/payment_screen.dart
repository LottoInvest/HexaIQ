import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/app_routes.dart';
import '../../hexaiq/presentation/state/hexaiq_app_state.dart';

class PaymentScreen extends StatelessWidget {
  const PaymentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<HexaIQAppState>();
    return Scaffold(
      appBar: AppBar(title: const Text('Professional 결제')),
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
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        '광고 없는 상세 검사',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 12),
                      const Text('결제와 영수증 검증은 서버 연동 전 mock으로 처리합니다.'),
                      const SizedBox(height: 24),
                      FilledButton.icon(
                        icon: const Icon(Icons.lock_open),
                        label: Text(state.isBusy ? '처리 중...' : '구매 검증 완료'),
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
            ),
          ),
        ),
      ),
    );
  }
}
