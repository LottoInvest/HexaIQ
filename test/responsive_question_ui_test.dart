import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hexaiq_app/core/theme/app_theme.dart';
import 'package:hexaiq_app/features/hexaiq/data/mock_hexaiq_repository.dart';
import 'package:hexaiq_app/features/hexaiq/presentation/screens/question_screen.dart';
import 'package:hexaiq_app/features/hexaiq/presentation/state/hexaiq_app_state.dart';
import 'package:hexaiq_app/features/hexaiq/presentation/widgets/hexa_iq_intro_card.dart';
import 'package:hexaiq_app/features/question/widgets/scratch_pad_widget.dart';
import 'package:hexaiq_app/features/settings/presentation/widgets/theme_mode_selector.dart';
import 'package:provider/provider.dart';

void main() {
  test('ThemeMode can be changed in app state', () {
    final state = HexaIQAppState(repository: MockHexaIQRepository());

    expect(state.themeMode, ThemeMode.system);
    state.setThemeMode(ThemeMode.dark);
    expect(state.themeMode, ThemeMode.dark);
    state.setThemeMode(ThemeMode.light);
    expect(state.themeMode, ThemeMode.light);
  });

  testWidgets('ScratchPad compact mode builds', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: const Scaffold(
          body: SizedBox(
            width: 240,
            height: 180,
            child: ScratchPadWidget(resetToken: 'q1', compact: true),
          ),
        ),
      ),
    );

    expect(find.text('Scratch Work'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets('ThemeModeSelector builds and changes state', (tester) async {
    final state = HexaIQAppState(repository: MockHexaIQRepository());
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: state,
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const Scaffold(body: ThemeModeSelector()),
        ),
      ),
    );

    expect(find.text('시스템'), findsOneWidget);
    await tester.tap(find.text('다크'));
    await tester.pump();
    expect(state.themeMode, ThemeMode.dark);
  });

  testWidgets('HexaIQIntroCard builds', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: const Scaffold(body: HexaIQIntroCard()),
      ),
    );

    expect(find.textContaining('6가지 인지 영역'), findsOneWidget);
    expect(find.textContaining('Adaptive Intelligence Test'), findsOneWidget);
    expect(find.text('수리논리'), findsOneWidget);
  });

  testWidgets('HexaIQIntroCard area chips use equal width', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: const Scaffold(body: HexaIQIntroCard()),
      ),
    );

    final suRiWidth = tester
        .getSize(
          find
              .ancestor(of: find.text('수리논리'), matching: find.byType(SizedBox))
              .first,
        )
        .width;
    final memoryWidth = tester
        .getSize(
          find
              .ancestor(of: find.text('기억력'), matching: find.byType(SizedBox))
              .first,
        )
        .width;

    expect(suRiWidth, memoryWidth);
  });

  testWidgets('ScratchPad drawing mode and clear build', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: const Scaffold(
          body: SizedBox(
            width: 320,
            height: 220,
            child: ScratchPadWidget(resetToken: 'q1'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Draw'));
    await tester.pump();
    expect(find.byType(TextField), findsNothing);
    await tester.drag(find.byType(Listener).last, const Offset(80, 40));
    await tester.pump();
    await tester.tap(find.byTooltip('Clear'));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('QuestionScreen builds on small phone landscape', (tester) async {
    tester.view.physicalSize = const Size(844, 390);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final state = HexaIQAppState(repository: MockHexaIQRepository());
    await state.startTest();

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: state,
        child: MaterialApp(
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          home: const QuestionScreen(),
        ),
      ),
    );
    await tester.pump();

    expect(find.textContaining('Question 1 / 5'), findsOneWidget);
    expect(find.text('Scratch Work'), findsOneWidget);
    expect(find.byType(GridView), findsOneWidget);
    final firstChoiceText = tester.widget<Text>(
      find.text(state.currentQuestion!.choices.first).first,
    );
    expect(firstChoiceText.textAlign, TextAlign.center);
    await tester.drag(find.byType(ListView).first, const Offset(0, -260));
    await tester.pump();
    expect(find.text('Next'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
