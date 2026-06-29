import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/hexagon_chart.dart';
import '../../hexaiq/domain/hexaiq_models.dart';
import '../../hexaiq/presentation/state/hexaiq_app_state.dart';

class HexagonDetailScreen extends StatelessWidget {
  const HexagonDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final report = context.watch<HexaIQAppState>().report;
    final scores = report?.domainScores ?? const <DomainScore>[];
    return Scaffold(
      appBar: AppBar(title: const Text('육각형 상세')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Center(
              child: HexagonChart(
                size: 320,
                values: scores.map((score) => score.score.toDouble()).toList(),
                labels: domainCatalog.map((item) => item.shortLabel).toList(),
              ),
            ),
            const SizedBox(height: 16),
            for (final score in scores)
              ListTile(
                title: Text(domainLabel(score.domain)),
                subtitle: Text(score.comment),
                trailing: Text('${score.score}'),
              ),
          ],
        ),
      ),
    );
  }
}
