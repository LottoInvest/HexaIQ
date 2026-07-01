import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/app_routes.dart';
import '../../hexaiq/domain/hexaiq_models.dart';
import '../../hexaiq/presentation/state/hexaiq_app_state.dart';

class TestIntroScreen extends StatelessWidget {
  const TestIntroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<HexaIQAppState>();
    final type = state.selectedTestType;
    final itemCount = type == TestType.quickIq ? 18 : 5;
    return Scaffold(
      appBar: AppBar(title: Text('${testTypeLabel(type)} 안내')),
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
                      '$itemCount문항',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 12),
                    Text(testTypeDescription(type)),
                    const SizedBox(height: 16),
                    Text('리포트 접근 광고: ${state.requiredAds}회'),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('검사 시작'),
                      onPressed: () async {
                        if (type == TestType.professional &&
                            !state.hasProfessionalAccess) {
                          Navigator.of(context).pushNamed(AppRoutes.payment);
                          return;
                        }
                        await context.read<HexaIQAppState>().startTest();
                        if (context.mounted) {
                          Navigator.of(
                            context,
                          ).pushReplacementNamed(AppRoutes.question);
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
    );
  }
}
