import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hexaiq_app/core/theme/app_theme.dart';
import 'package:hexaiq_app/features/hexaiq/data/mock_hexaiq_repository.dart';
import 'package:hexaiq_app/features/hexaiq/domain/hexaiq_models.dart';
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
    expect(find.textContaining('CAT 구조'), findsOneWidget);
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
    expect(find.byType(TextField), findsNothing);
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
    await tester.pump();
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

  testWidgets('QuestionScreen shows hint after five seconds and resets', (
    tester,
  ) async {
    final state = HexaIQAppState(repository: MockHexaIQRepository());
    await tester.pump();
    state.testSessionController = TestSessionController(
      TestSession(
        sessionId: 'hint-session',
        startedAt: DateTime(2026),
        questions: const [_longScratchQuestion, _secondHintQuestion],
        generatedQuestions: const [_longScratchQuestion, _secondHintQuestion],
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

    expect(find.text('등차수열 문제입니다. 차이를 비교해보세요.'), findsNothing);
    await tester.pump(const Duration(milliseconds: 10));
    expect(find.text('등차수열 문제입니다. 차이를 비교해보세요.'), findsOneWidget);

    state.selectAnswer(state.currentQuestion!.answerIndex);
    state.nextQuestion();
    await tester.pump();
    expect(find.text('등비수열 문제입니다. 곱해지는 비율을 찾아보세요.'), findsNothing);
    await tester.pump(const Duration(milliseconds: 9));
    expect(find.text('등비수열 문제입니다. 곱해지는 비율을 찾아보세요.'), findsNothing);
    await tester.pump(const Duration(milliseconds: 1));
    expect(find.text('등비수열 문제입니다. 곱해지는 비율을 찾아보세요.'), findsOneWidget);
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
    await tester.drag(find.byType(ListView).first, const Offset(0, -260));
    await tester.pump();
    expect(find.text('Next'), findsOneWidget);
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
      '다음 수열은 여러 단계의 규칙을 포함합니다. 첫 번째 규칙은 인접한 수의 차이를 비교하는 것이고, 두 번째 규칙은 그 차이가 다시 일정하게 변화하는지 확인하는 것입니다. 3, 7, 13, 21, 31, ?',
  choices: ['39', '41', '43', '45'],
  answerIndex: 2,
  explanation: '차이가 4, 6, 8, 10으로 증가합니다.',
);

const _secondHintQuestion = TestQuestion(
  id: 'hint-q2',
  domain: CognitiveDomain.numerical,
  typeCode: 'NR02',
  level: 5,
  prompt: '다음 등비수열의 빈칸에 들어갈 수는? 2, 4, 8, 16, ?',
  choices: ['24', '30', '32', '36'],
  answerIndex: 2,
  explanation: '앞 항에 2를 곱합니다.',
);
