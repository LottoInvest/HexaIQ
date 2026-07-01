import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hexaiq_app/features/pattern_grid/domain/pattern_cell.dart';
import 'package:hexaiq_app/features/pattern_grid/domain/pattern_difficulty.dart';
import 'package:hexaiq_app/features/pattern_grid/domain/pattern_generator.dart';
import 'package:hexaiq_app/features/pattern_grid/domain/visual_question.dart';
import 'package:hexaiq_app/features/question_layout/presentation/answer_choice_area.dart';
import 'package:hexaiq_app/features/question_layout/presentation/bottom_action_area.dart';
import 'package:hexaiq_app/features/question_layout/presentation/compact_progress_header.dart';
import 'package:hexaiq_app/features/question_layout/presentation/domain_chip_bar.dart';
import 'package:hexaiq_app/features/question_layout/presentation/hint_box.dart';
import 'package:hexaiq_app/features/question_layout/presentation/memo_panel.dart';
import 'package:hexaiq_app/features/question_layout/presentation/question_card.dart';
import 'package:hexaiq_app/features/question_layout/presentation/question_scroll_area.dart';
import 'package:hexaiq_app/features/question_layout/presentation/visual_choice_grid.dart';
import 'package:hexaiq_app/features/question_layout/presentation/visual_question_layout.dart';
import 'package:hexaiq_app/features/question_layout/presentation/visual_reference_grid.dart';

void main() {
  group('v0.9.8 Visual Question Layout', () {
    testWidgets('reference card and text choices are separated', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          SizedBox(
            height: 640,
            child: Column(
              children: [
                const CompactProgressHeader(
                  questionNumber: 2,
                  totalQuestions: 18,
                  progressPercent: 11,
                  elapsedText: '0분 12초',
                  difficultyLabel: '보통',
                ),
                QuestionScrollArea(
                  children: [
                    QuestionCard(
                      prompt: '다음 규칙을 보고 알맞은 답을 고르세요.',
                      reference: VisualReferenceGrid(grid: _grid()),
                    ),
                    AnswerChoiceArea.text(
                      choices: const ['가', '나', '다', '라'],
                      selectedIndex: 1,
                      onSelect: (_) {},
                    ),
                    const HintBox(hint: '규칙을 먼저 찾으세요.'),
                    const MemoPanel(),
                  ],
                ),
                BottomActionArea(onNext: () {}, nextLabel: '다음'),
              ],
            ),
          ),
        ),
      );

      expect(find.text('문제 2 / 18'), findsOneWidget);
      expect(find.text('다음 규칙을 보고 알맞은 답을 고르세요.'), findsOneWidget);
      expect(find.text('가'), findsOneWidget);
      expect(find.text('규칙을 먼저 찾으세요.'), findsOneWidget);
      expect(find.text('풀이 메모'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('visual layout keeps reference grid separate from choices', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(360, 640));
      await tester.pumpWidget(
        _app(
          SizedBox(
            height: 640,
            child: Column(
              children: [
                VisualQuestionLayout(
                  question: _visualQuestion(),
                  selectedIndex: 0,
                  onSelect: (_) {},
                  hint: '회전 방향을 살펴보세요.',
                ),
                BottomActionArea(onNext: () {}, nextLabel: '제출'),
              ],
            ),
          ),
        ),
      );

      expect(find.text('보기 1'), findsOneWidget);
      expect(find.text('보기 4'), findsOneWidget);
      expect(find.text('회전 방향을 살펴보세요.'), findsOneWidget);
      expect(find.text('제출'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.binding.setSurfaceSize(null);
    });

    testWidgets('domain chip bar shows current and completed states', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          const DomainChipBar(
            items: [
              DomainChipData(index: 1, label: '언어', isCompleted: true),
              DomainChipData(index: 2, label: '수리', isCurrent: true),
              DomainChipData(index: 3, label: '공간'),
            ],
          ),
        ),
      );

      expect(find.text('언어'), findsOneWidget);
      expect(find.text('수리'), findsOneWidget);
      expect(find.text('공간'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('visual choice grid wraps to one column on narrow screens', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(340, 640));
      await tester.pumpWidget(
        _app(
          VisualChoiceGrid(
            choices: [_grid(), _grid(), _grid(), _grid()],
            selectedIndex: null,
            onSelect: (_) {},
          ),
        ),
      );

      expect(find.text('보기 1'), findsOneWidget);
      expect(find.text('보기 4'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.binding.setSurfaceSize(null);
    });
  });
}

Widget _app(Widget child) {
  return MaterialApp(
    theme: ThemeData(useMaterial3: true),
    home: Scaffold(body: SafeArea(child: child)),
  );
}

VisualQuestion _visualQuestion() {
  return VisualQuestion(
    id: 'visual_1',
    type: 'matrix',
    layout: QuestionLayout.matrix,
    rule: PatternRule.rotation,
    grid: _grid(),
    choices: [_grid(), _grid(), _grid(), _grid()],
    answerIndex: 0,
    prompt: '같은 규칙의 패턴을 고르세요.',
    difficulty: PatternDifficulty.normal,
  );
}

PatternGrid _grid() {
  return PatternGrid.square(
    size: 2,
    cells: const [
      PatternCell(color: PatternColor.primary),
      PatternCell(color: PatternColor.secondary, shape: PatternShape.circle),
      PatternCell(color: PatternColor.success, shape: PatternShape.triangle),
      PatternCell(color: PatternColor.warning, shape: PatternShape.diamond),
    ],
  );
}
