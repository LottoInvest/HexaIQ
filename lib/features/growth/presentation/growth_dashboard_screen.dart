import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/responsive/responsive_page.dart';
import '../../hexaiq/presentation/state/hexaiq_app_state.dart';
import '../../hexaiq/presentation/widgets/dashboard_nav.dart';

class GrowthDashboardScreen extends StatelessWidget {
  const GrowthDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<HexaIQAppState>();
    return ResponsivePage(
      title: '성장 기록',
      currentIndex: 1,
      onDestinationSelected: (index) =>
          handleDashboardDestination(context, index),
      child: ListView(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${state.selectedProfile?.name ?? '프로필'}의 최근 변화',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  for (final point in state.growth)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          SizedBox(width: 48, child: Text(point.month)),
                          Expanded(
                            child: LinearProgressIndicator(
                              value: point.score / 100,
                              minHeight: 10,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text('${point.score}'),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(18),
              child: Text('재검사는 2주 간격으로 보는 것을 권장합니다.'),
            ),
          ),
        ],
      ),
    );
  }
}
