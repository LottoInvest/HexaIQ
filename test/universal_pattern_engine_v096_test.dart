import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hexaiq_app/features/pattern_grid/domain/asset_loader.dart';
import 'package:hexaiq_app/features/pattern_grid/domain/pattern_cell.dart';
import 'package:hexaiq_app/features/pattern_grid/domain/pattern_generator.dart';
import 'package:hexaiq_app/features/pattern_grid/domain/pattern_json_parser.dart';
import 'package:hexaiq_app/features/pattern_grid/domain/pattern_pack_manager.dart';
import 'package:hexaiq_app/features/pattern_grid/domain/pattern_theme.dart';
import 'package:hexaiq_app/features/pattern_grid/domain/visual_question.dart';
import 'package:hexaiq_app/features/pattern_grid/domain/visual_question_generator.dart';
import 'package:hexaiq_app/features/pattern_grid/presentation/pattern_renderer.dart';
import 'package:hexaiq_app/features/pattern_grid/presentation/visual_question_widget.dart';

void main() {
  group('v0.9.6 Universal Pattern Engine', () {
    testWidgets('renders shape, icon, svg, emoji, and image elements', (
      tester,
    ) async {
      final cells = [
        const PatternCell(
          element: ShapeElement(PatternShape.pentagon),
          color: PatternColor.primary,
        ),
        const PatternCell(
          element: IconElement('psychology'),
          color: PatternColor.secondary,
        ),
        const PatternCell(
          element: SvgElement('assets/patterns/shapes/sample_shape.svg'),
          color: PatternColor.success,
        ),
        const PatternCell(
          element: EmojiElement('🎲'),
          color: PatternColor.warning,
        ),
        const PatternCell(
          element: ImageElement('assets/patterns/objects/missing.webp'),
          color: PatternColor.neutral,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.indigo),
          home: Scaffold(
            body: Row(
              children: [
                for (final cell in cells)
                  SizedBox(
                    width: 48,
                    height: 48,
                    child: PatternRenderer(cell: cell),
                  ),
              ],
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(PatternRenderer), findsNWidgets(5));
      expect(find.byType(SvgPicture), findsOneWidget);
      expect(find.text('🎲'), findsOneWidget);
    });

    test('PatternTheme resolves supported theme styles', () {
      final scheme = ColorScheme.fromSeed(seedColor: Colors.indigo);

      for (final type in PatternThemeType.values) {
        final theme = PatternTheme(type: type);
        expect(theme.resolveSurface(scheme), isA<Color>());
        expect(
          theme.resolveElementColor(scheme, PatternColor.error),
          isA<Color>(),
        );
      }
    });

    test('Pattern JSON loads into a VisualQuestion', () {
      const json = '''
{
  "type": "matrix",
  "grid": "3x3",
  "elements": [
    "square",
    {"type": "icon", "name": "bolt"},
    {"type": "emoji", "emoji": "🍎"}
  ],
  "rule": "rotation",
  "answer": 2
}
''';

      final question = const PatternJsonParser().parse(json);

      expect(question.layout, QuestionLayout.matrix);
      expect(question.grid.cells, hasLength(9));
      expect(question.answerIndex, 2);
      expect(question.grid.cells[1].element, isA<IconElement>());
      expect(question.grid.cells[2].element, isA<EmojiElement>());
    });

    test('VisualQuestionGenerator creates reusable visual questions', () {
      final question = const VisualQuestionGenerator().generate(
        seed: 96,
        rule: PatternRule.color,
        layout: QuestionLayout.sequence,
        packId: 'advanced',
      );

      expect(question.id, contains('color'));
      expect(question.packId, 'advanced');
      expect(question.choices, hasLength(4));
      expect(question.asPatternQuestion().rule, PatternRule.color);
    });

    testWidgets('VisualQuestionWidget builds through common renderer path', (
      tester,
    ) async {
      final question = const VisualQuestionGenerator().generate(
        seed: 960,
        rule: PatternRule.shape,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: VisualQuestionWidget(question: question)),
        ),
      );

      expect(find.byType(VisualQuestionWidget), findsOneWidget);
      expect(find.byType(PatternRenderer), findsWidgets);
    });

    test(
      'PatternAssetLoader caches assets and PatternPackManager separates content',
      () {
        final loader = PatternAssetLoader(
          initialAssets: const ['assets/patterns/shapes/sample_shape.svg'],
        );
        loader.register('assets/patterns/foods/apple.svg');

        final pack = PatternPackManager().loadFromJsonList(
          id: 'basic-pack',
          type: PatternPackType.basic,
          items: const [
            {
              'type': 'matrix',
              'grid': '2x2',
              'elements': ['circle', 'triangle'],
              'rule': 'color',
              'answer': 1,
            },
          ],
        );

        expect(
          loader.isCached('assets/patterns/shapes/sample_shape.svg'),
          isTrue,
        );
        expect(
          loader.cachedAssets,
          contains('assets/patterns/foods/apple.svg'),
        );
        expect(pack.id, 'basic-pack');
        expect(pack.questions.single.grid.cells, hasLength(4));
      },
    );
  });
}
