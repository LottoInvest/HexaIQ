import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/responsive/responsive_page.dart';
import '../../hexaiq/domain/hexaiq_models.dart';
import '../../hexaiq/presentation/state/hexaiq_app_state.dart';
import '../../hexaiq/presentation/widgets/dashboard_nav.dart';
import '../../result/domain/result_integrity_validator.dart';
import '../../result/domain/test_result_payload.dart';
import '../../test/domain/models/test_mode.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  static const _validator = ResultIntegrityValidator();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<HexaIQAppState>();
    final profile = state.selectedProfile;
    return ResponsivePage(
      title: '검사 이력',
      currentIndex: 1,
      onDestinationSelected: (index) =>
          handleDashboardDestination(context, index),
      child: profile == null
          ? const Center(child: Text('프로필을 먼저 선택해 주세요.'))
          : FutureBuilder<List<TestResultSummary>>(
              future: state.repository.loadTestHistory(profile.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                final history = snapshot.data ?? const <TestResultSummary>[];
                final validHistory = history
                    .where((result) => _validator.validate(result).isValid)
                    .toList(growable: false);
                if (history.isEmpty) {
                  return const Center(child: Text('아직 저장된 검사 이력이 없습니다.'));
                }
                if (validHistory.isEmpty) {
                  return const Center(
                    child: Text('검사 결과를 불러올 수 없습니다. 다시 검사해 주세요.'),
                  );
                }
                return ListView.separated(
                  itemCount: validHistory.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final result = validHistory[index];
                    return _HistoryResultCard(result: result);
                  },
                );
              },
            ),
    );
  }
}

class _HistoryResultCard extends StatelessWidget {
  const _HistoryResultCard({required this.result});

  final TestResultSummary result;

  @override
  Widget build(BuildContext context) {
    final payload = TestResultPayload.fromResult(result);
    return Card(
      key: ValueKey('history-result-${result.id}'),
      child: ListTile(
        leading: const Icon(Icons.history),
        title: Text(
          '${_dateLabel(result.completedAt)} · ${_modeLabel(payload.testMode)}',
        ),
        subtitle: Text(
          '정답 ${payload.correctCount} / ${payload.totalQuestions} · '
          '정답률 ${payload.accuracyPercent}% · '
          '풀이 시간 ${payload.elapsedLabel}',
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'IQ ${result.estimatedIQ}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text('상위 비율 ${result.percentile}%'),
          ],
        ),
        onTap: () => _showResultDetail(context, result, payload),
      ),
    );
  }

  void _showResultDetail(
    BuildContext context,
    TestResultSummary result,
    TestResultPayload payload,
  ) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('검사 결과 상세', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              Text('결과 ID: ${result.id}'),
              Text('문항 수: ${payload.totalQuestions}개'),
              Text('응답 문항: ${payload.answeredQuestions}개'),
              Text('정답: ${payload.correctCount}개'),
              Text('추정 IQ: ${result.estimatedIQ}'),
              Text('상위 비율: ${result.percentile}%'),
              Text('풀이 시간: ${payload.elapsedLabel}'),
            ],
          ),
        );
      },
    );
  }

  String _dateLabel(DateTime date) {
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')} 검사';
  }

  String _modeLabel(TestMode mode) {
    return switch (mode) {
      TestMode.quickIq => '빠른 IQ',
      TestMode.fullDiagnostic => '정밀 진단',
      TestMode.domainTraining => '영역 훈련',
    };
  }
}
