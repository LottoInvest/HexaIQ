import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hexaiq_app/features/hexaiq/domain/hexaiq_models.dart';
import 'package:hexaiq_app/features/pattern_grid/domain/asset_loader.dart';
import 'package:hexaiq_app/features/pattern_grid/domain/pattern_cell.dart';
import 'package:hexaiq_app/features/pattern_grid/domain/pattern_difficulty.dart';
import 'package:hexaiq_app/features/pattern_grid/domain/pattern_difficulty_resolver.dart';
import 'package:hexaiq_app/features/pattern_grid/domain/pattern_json_parser.dart';
import 'package:hexaiq_app/features/pattern_grid/domain/pattern_pack_manager.dart';
import 'package:hexaiq_app/features/pattern_grid/domain/pattern_pack_manifest.dart';
import 'package:hexaiq_app/features/pattern_grid/domain/pattern_pack_runtime.dart';
import 'package:hexaiq_app/features/pattern_grid/domain/pattern_question_validator.dart';
import 'package:hexaiq_app/features/pattern_grid/domain/result_metadata.dart';
import 'package:hexaiq_app/features/pattern_grid/domain/visual_question_runtime_adapter.dart';
import 'package:hexaiq_app/features/pattern_grid/presentation/pattern_pack_debug_screen.dart';
import 'package:hexaiq_app/features/pattern_grid/presentation/pattern_renderer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('v0.9.7 Pattern Pack Runtime', () {
    test('loads sample manifests and questions from assets', () async {
      final runtime = PatternPackRuntime();
      final result = await runtime.load(type: TestType.advanced);

      expect(result.packs, hasLength(4));
      expect(
        result.packs.fold<int>(0, (sum, pack) => sum + pack.questions.length),
        63,
      );
      expect(result.validQuestions, isNotEmpty);
      expect(result.invalidQuestions, isEmpty);
    });

    test('manager filters packs by test type and premium lock', () {
      final manager = PatternPackManager();
      manager.loadFromJsonList(
        id: 'professional_pack',
        type: PatternPackType.professional,
        manifest: const PatternPackManifest(
          packId: 'professional_pack',
          name: 'Professional Pack',
          version: '1.0.0',
          target: 'professional',
          difficultyRange: [PatternDifficulty.hard, PatternDifficulty.expert],
          questionCount: 1,
          supportedElements: ['image', 'svg'],
          requiresPremium: true,
          price: 4.9,
          currency: 'USD',
        ),
        items: const [
          {
            'id': 'professional_image_logic_001',
            'packId': 'professional_pack',
            'type': 'matrix',
            'grid': '3x3',
            'elements': [
              {'type': 'image', 'assetPath': 'assets/patterns/objects/pro.png'},
            ],
            'rule': 'missingBlock',
            'difficulty': 'expert',
            'answer': 1,
            'premiumOnly': true,
            'explanation': 'Professional image pattern.',
          },
        ],
      );

      expect(manager.getQuestionsByTestType(TestType.professional), isEmpty);
      expect(
        manager.getQuestionsByTestType(TestType.professional, hasPremium: true),
        hasLength(1),
      );
    });

    test('parser supports operational JSON format', () {
      final question = const PatternJsonParser().parseMap(const {
        'id': 'basic_shape_rotation_001',
        'packId': 'basic_pack',
        'type': 'matrix',
        'domain': 'visual_reasoning',
        'difficulty': 'easy',
        'grid': {'rows': 3, 'cols': 3},
        'cells': [
          {
            'element': {'type': 'shape', 'shape': 'square'},
            'color': 'primary',
            'rotation': 90,
            'scale': 1.2,
            'filled': true,
            'opacity': 0.9,
            'border': true,
          },
        ],
        'rule': {'type': 'rotation', 'step': 90},
        'answer': 2,
        'explanation': 'Rotates clockwise.',
        'tags': ['shape', 'rotation'],
        'estimatedTime': 30,
        'version': '1.0.0',
      });

      expect(question.id, 'basic_shape_rotation_001');
      expect(question.grid.cells, hasLength(9));
      expect(question.difficulty, PatternDifficulty.easy);
      expect(question.explanation, isNotEmpty);
      expect(question.grid.cells.first.scale, 1.2);
    });

    test('validator excludes invalid questions and reports useful errors', () {
      final question = const PatternJsonParser().parseMap(const {
        'id': 'bad',
        'type': 'matrix',
        'grid': '3x3',
        'elements': ['square'],
        'rule': 'rotation',
        'answer': 9,
      });

      final result = const PatternQuestionValidator().validate(question);

      expect(result.isValid, isFalse);
      expect(result.errors, contains('answer index out of range'));
      expect(result.debugLog(), contains('[PatternValidator]'));
    });

    test(
      'difficulty resolver prefers declared difficulty and warns on mismatch',
      () {
        final question = const PatternJsonParser().parseMap(const {
          'id': 'basic_shape_rotation_001',
          'type': 'matrix',
          'difficulty': 'easy',
          'grid': '5x5',
          'elements': [
            'square',
            {
              'type': 'svg',
              'assetPath': 'assets/patterns/shapes/sample_shape.svg',
            },
          ],
          'rule': 'missingBlock',
          'answer': 1,
          'tags': ['compound'],
          'explanation': 'Complex but declared easy.',
        });

        final resolution = const PatternDifficultyResolver().resolveDetailed(
          question,
        );

        expect(resolution.difficulty, PatternDifficulty.easy);
        expect(resolution.warning, isNotNull);
      },
    );

    test(
      'runtime adapter creates legacy questions without breaking fallback',
      () {
        final visualQuestion = PatternPackRuntime().fallbackQuestion();
        final legacy = const VisualQuestionRuntimeAdapter().toLegacyQuestion(
          visualQuestion,
        );

        expect(legacy.id, visualQuestion.id);
        expect(legacy.itemId, visualQuestion.id);
        expect(legacy.variables['packId'], visualQuestion.packId);
        expect(legacy.choices, hasLength(4));
      },
    );

    test('result metadata keeps analysis fields', () {
      final metadata = const PatternResultMetadata(
        questionId: 'basic_shape_rotation_001',
        packId: 'basic_pack',
        testType: 'basic',
        domain: 'visual_reasoning',
        difficulty: 'easy',
        ruleType: 'rotation',
        elementType: 'shape',
        isCorrect: true,
        responseTime: Duration(seconds: 2),
        selectedAnswer: 2,
        correctAnswer: 2,
      );

      expect(metadata.toJson()['questionId'], 'basic_shape_rotation_001');
      expect(metadata.toJson()['responseTimeMs'], 2000);
    });

    test('asset loader caches success and records failed preload', () async {
      final loader = PatternAssetLoader();

      final ok = await loader.preload(
        'assets/patterns/shapes/sample_shape.svg',
      );
      final missing = await loader.preload('assets/patterns/missing.svg');

      expect(ok, isTrue);
      expect(
        loader.isCached('assets/patterns/shapes/sample_shape.svg'),
        isTrue,
      );
      expect(missing, isFalse);
      expect(loader.hasFailed('assets/patterns/missing.svg'), isTrue);
    });

    testWidgets('renderer clamps unsafe values and debug screen builds', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                const SizedBox(
                  width: 56,
                  height: 56,
                  child: PatternRenderer(
                    cell: PatternCell(
                      element: SvgElement('assets/patterns/missing.svg'),
                      color: PatternColor.primary,
                      rotation: double.infinity,
                      scale: 0,
                      opacity: 2,
                    ),
                  ),
                ),
                Expanded(child: PatternPackDebugScreen()),
              ],
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(PatternRenderer), findsOneWidget);
      expect(find.byType(PatternPackDebugScreen), findsOneWidget);
    });
  });
}
