import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../hexaiq/domain/hexaiq_models.dart';
import '../../hexaiq/presentation/state/hexaiq_app_state.dart';

class DomainDetailScreen extends StatelessWidget {
  const DomainDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final report = context.watch<HexaIQAppState>().report;
    final scores = report?.domainScores ?? const <DomainScore>[];
    return Scaffold(
      appBar: AppBar(title: const Text('영역 상세')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            for (final score in scores)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        domainLabel(score.domain),
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text('점수 ${score.score} · 참고 백분위 ${score.percentile}'),
                      const SizedBox(height: 8),
                      Text(score.comment),
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
