import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/app_routes.dart';
import '../../../core/widgets/action_card.dart';
import '../../hexaiq/domain/hexaiq_models.dart';
import '../../hexaiq/presentation/state/hexaiq_app_state.dart';

class TestTypeSelectScreen extends StatelessWidget {
  const TestTypeSelectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<HexaIQAppState>();
    return Scaffold(
      appBar: AppBar(title: const Text('검사 선택')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            for (final type in TestType.values)
              ActionCard(
                icon: switch (type) {
                  TestType.basic => Icons.bolt_outlined,
                  TestType.advanced => Icons.auto_graph,
                  TestType.professional => Icons.workspace_premium_outlined,
                },
                title: testTypeLabel(type),
                body: testTypeDescription(type),
                trailing: state.selectedTestType == type
                    ? Icon(
                        Icons.check_circle,
                        color: Theme.of(context).colorScheme.primary,
                      )
                    : null,
                onTap: () {
                  context.read<HexaIQAppState>().selectTestType(type);
                  Navigator.of(context).pushNamed(AppRoutes.testIntro);
                },
              ),
          ],
        ),
      ),
    );
  }
}
