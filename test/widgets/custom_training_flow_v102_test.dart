import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hexaiq_app/core/domain/intelligence_domain.dart';
import 'package:hexaiq_app/features/hexaiq/data/mock_hexaiq_repository.dart';
import 'package:hexaiq_app/features/hexaiq/presentation/state/hexaiq_app_state.dart';
import 'package:hexaiq_app/features/training/presentation/training_recommendation_screen.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets(
    'custom training selects domain, level, count, and solves items',
    (tester) async {
      tester.view.physicalSize = const Size(1024, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final state = HexaIQAppState(repository: MockHexaIQRepository());
      await state.loadInitialData();

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: state,
          child: const MaterialApp(home: TrainingRecommendationScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('훈련 영역 선택'), findsOneWidget);
      expect(find.text(IntelligenceDomain.numerical.label), findsOneWidget);

      await tester.tap(find.text('5문항'));
      await tester.tap(find.text('기초'));
      await tester.scrollUntilVisible(find.text('훈련 시작'), 240);
      await tester.tap(find.text('훈련 시작'));
      await tester.pumpAndSettle();

      expect(find.textContaining('1 / 5'), findsOneWidget);
      expect(find.text('힌트 보기'), findsOneWidget);
      expect(find.text('정답 확인'), findsOneWidget);

      final hintButton = find.widgetWithText(OutlinedButton, '힌트 보기');
      await tester.ensureVisible(hintButton);
      await tester.tap(hintButton);
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.lightbulb_outline), findsOneWidget);

      for (var i = 0; i < 5; i++) {
        await tester.tap(find.byIcon(Icons.radio_button_unchecked).first);
        await tester.pumpAndSettle();
        final checkButton = find.widgetWithText(FilledButton, '정답 확인');
        await tester.ensureVisible(checkButton);
        await tester.tap(checkButton);
        await tester.pumpAndSettle();
        expect(find.textContaining('해설:'), findsOneWidget);
        final nextButton = find.widgetWithText(FilledButton, '다음 문제');
        await tester.ensureVisible(nextButton);
        await tester.tap(nextButton);
        await tester.pumpAndSettle();
      }

      expect(find.text('훈련 결과'), findsOneWidget);
      expect(find.textContaining('총 문항 수: 5문항'), findsOneWidget);
      expect(
        find.textContaining('훈련 결과는 IQ와 상위 비율로 표시하지 않습니다.'),
        findsOneWidget,
      );
      expect(state.report, isNull);
    },
  );
}
