import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hexaiq_app/core/theme/app_theme.dart';
import 'package:hexaiq_app/core/widgets/hexagon_chart.dart';
import 'package:hexaiq_app/features/hexaiq/data/mock_hexaiq_repository.dart';
import 'package:hexaiq_app/features/hexaiq/domain/hexaiq_models.dart';
import 'package:hexaiq_app/features/hexaiq/presentation/screens/onboarding_screen.dart';
import 'package:hexaiq_app/features/hexaiq/presentation/screens/question_screen.dart';
import 'package:hexaiq_app/features/hexaiq/presentation/state/hexaiq_app_state.dart';
import 'package:hexaiq_app/features/hexaiq/presentation/widgets/hexa_iq_intro_card.dart';
import 'package:hexaiq_app/features/question/widgets/scratch_pad_widget.dart';
import 'package:hexaiq_app/features/settings/presentation/widgets/theme_mode_selector.dart';
import 'package:hexaiq_app/features/test/application/test_session_controller.dart';
import 'package:hexaiq_app/features/test/domain/models/test_session.dart';
import 'package:provider/provider.dart';

void main() {
  test('ThemeMode can be changed in app state', () {
    final state = HexaIQAppState(repository: MockHexaIQRepository());

    expect(state.themeMode, ThemeMode.dark);
    state.setThemeMode(ThemeMode.light);
    expect(state.themeMode, ThemeMode.light);
    state.setThemeMode(ThemeMode.dark);
    expect(state.themeMode, ThemeMode.dark);
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

  testWidgets('HexaIQIntroCard hides item bank and uses readable copy', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: const Scaffold(body: HexaIQIntroCard()),
      ),
    );

    expect(find.textContaining('6가지 인지 영역'), findsOneWidget);
    expect(find.textContaining('문항 정보를 바탕으로'), findsOneWidget);
    expect(find.textContaining('Item Bank'), findsNothing);
    expect(find.text('수리논리'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('수리')), findsWidgets);
  });

  testWidgets('HexaIQIntroCard area buttons use 2x3 grid', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: const Scaffold(body: HexaIQIntroCard()),
      ),
    );

    final grid = tester.widget<GridView>(find.byType(GridView));
    final delegate =
        grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
    expect(delegate.crossAxisCount, 2);
    expect(find.byType(OutlinedButton), findsNWidgets(6));
  });

  testWidgets('Onboarding headline uses natural Korean line break on phone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => HexaIQAppState(repository: MockHexaIQRepository()),
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const OnboardingScreen(),
        ),
      ),
    );

    expect(find.text('검사 분석, 훈련 추천,\n성장 기록을 하나의 흐름으로 연결합니다.'), findsOneWidget);
  });

  testWidgets('HexaIQIntroCard keeps final 8pt spacing rhythm', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: const Scaffold(body: HexaIQIntroCard()),
      ),
    );

    final chartGap = tester.widget<SizedBox>(
      find.byKey(const Key('intro-chart-body-gap')),
    );
    final chartSafeArea = tester.widget<SizedBox>(
      find.byKey(const Key('intro-chart-safe-area')),
    );
    final chart = tester.widget<HexagonChart>(find.byType(HexagonChart).last);
    final bodyGap = tester.widget<SizedBox>(
      find.byKey(const Key('intro-body-domain-gap')),
    );
    final bottomGap = tester.widget<SizedBox>(
      find.byKey(const Key('intro-domain-bottom-gap')),
    );

    expect(chartSafeArea.height, 170);
    expect(chart.size, 156);
    expect(chart.labelFontSize, 14);
    expect(chartGap.height, 18);
    expect(bodyGap.height, 20);
    expect(bottomGap.height, 16);
  });

  testWidgets('ScratchPad clear shows confirm dialog', (tester) async {
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
    await tester.drag(find.byType(Listener).last, const Offset(80, 40));
    await tester.pump();
    await tester.tap(find.byTooltip('Clear'));
    await tester.pump();
    expect(find.text('Scratch Work를 지울까요?'), findsOneWidget);
    expect(find.text('작성한 풀이 메모는 복구할 수 없습니다.'), findsOneWidget);
    await tester.tap(find.text('취소'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('QuestionScreen keeps scratch work visible for long prompt', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final state = HexaIQAppState(repository: MockHexaIQRepository());
    state.testSessionController = TestSessionController(
      TestSession(
        sessionId: 'long-question',
        startedAt: DateTime(2026),
        questions: const [_longScratchQuestion],
        generatedQuestions: const [_longScratchQuestion],
      ),
    );

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: state,
        child: MaterialApp(
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          home: const QuestionScreen(enableElapsedTimer: false),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Scratch Work'), findsOneWidget);
    expect(tester.getTopLeft(find.text('Scratch Work')).dy, lessThan(844));
    expect(find.textContaining('Question 1 / 5'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('QuestionScreen shows specific hint after delay and resets', (
    tester,
  ) async {
    final state = HexaIQAppState(repository: MockHexaIQRepository());
    state.testSessionController = TestSessionController(
      TestSession(
        sessionId: 'hint-session',
        startedAt: DateTime(2026),
        questions: const [_longScratchQuestion, _cubeHintQuestion],
        generatedQuestions: const [_longScratchQuestion, _cubeHintQuestion],
      ),
    );

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: state,
        child: MaterialApp(
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          home: const QuestionScreen(
            enableElapsedTimer: false,
            hintDelay: Duration(milliseconds: 10),
          ),
        ),
      ),
    );
    await tester.pump();

    const arithmeticHint = '등차수열입니다. 앞뒤 숫자의 차이가 일정한지 확인해보세요.';
    const cubeHint = '2³, 3³, 4³처럼 세제곱 규칙을 찾아보세요.';
    expect(find.text(arithmeticHint), findsNothing);
    await tester.pump(const Duration(milliseconds: 10));
    expect(find.text(arithmeticHint), findsOneWidget);

    state.selectAnswer(state.currentQuestion!.answerIndex);
    state.nextQuestion();
    await tester.pump();
    expect(find.text(cubeHint), findsNothing);
    await tester.pump(const Duration(milliseconds: 10));
    expect(find.text(cubeHint), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
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
          home: const QuestionScreen(enableElapsedTimer: false),
        ),
      ),
    );
    await tester.pump();

    expect(find.textContaining('Question 1 / 5'), findsOneWidget);
    expect(find.byType(GridView), findsOneWidget);
    final firstChoiceText = tester.widget<Text>(
      find.text(state.currentQuestion!.choices.first).first,
    );
    expect(firstChoiceText.textAlign, TextAlign.center);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}

const _longScratchQuestion = TestQuestion(
  id: 'long-q1',
  domain: CognitiveDomain.numerical,
  typeCode: 'NR01',
  level: 5,
  prompt:
      '다음 수열은 여러 단계의 규칙을 포함합니다. 인접한 수의 차이를 비교하고 그 차이가 다시 어떻게 변하는지 확인해보세요. 3, 7, 13, 21, 31, ?',
  choices: ['39', '41', '43', '45'],
  answerIndex: 2,
  explanation: '차이가 4, 6, 8, 10으로 증가합니다.',
);

const _cubeHintQuestion = TestQuestion(
  id: 'hint-q2',
  domain: CognitiveDomain.numerical,
  typeCode: 'NR09',
  level: 5,
  prompt: '세제곱수 규칙입니다. 8, 27, 64, 125, ?',
  choices: ['180', '196', '216', '225'],
  answerIndex: 2,
  explanation: '2³, 3³, 4³, 5³ 다음은 6³입니다.',
);
