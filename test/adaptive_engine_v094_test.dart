import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hexaiq_app/core/domain/question_difficulty.dart';
import 'package:hexaiq_app/features/calibration/presentation/calibration_tool.dart';
import 'package:hexaiq_app/features/question/widgets/memory_interaction.dart';
import 'package:hexaiq_app/features/question/widgets/spatial_canvas.dart';
import 'package:hexaiq_app/features/question/widgets/speed_test_screen.dart';
import 'package:hexaiq_app/features/question_engine/question_engine.dart';
import 'package:hexaiq_app/features/test/domain/adaptive/adaptive_engine.dart';
import 'package:hexaiq_app/features/test/domain/generators/multi_domain_item_engine.dart';

void main() {
  test('AdaptiveEngine raises, lowers, and maps theta to difficulty', () {
    const engine = AdaptiveEngine();

    expect(
      engine.nextLevel(
        current: AdaptiveLevel.medium,
        isCorrect: true,
        correctStreak: 1,
      ),
      AdaptiveLevel.hard,
    );
    expect(
      engine.nextLevel(
        current: AdaptiveLevel.medium,
        isCorrect: true,
        correctStreak: 2,
      ),
      AdaptiveLevel.expert,
    );
    expect(
      engine.nextLevel(
        current: AdaptiveLevel.hard,
        isCorrect: false,
        wrongStreak: 1,
      ),
      AdaptiveLevel.medium,
    );
    expect(engine.difficultyForTheta(-1.2), QuestionDifficulty.easy);
    expect(engine.difficultyForTheta(0.5), QuestionDifficulty.normal);
    expect(engine.difficultyForTheta(2.0), QuestionDifficulty.veryHard);
  });

  test('AdaptiveEngine keeps independent domain state', () {
    const engine = AdaptiveEngine();
    var state = const DomainAdaptiveState();
    state = engine.recordResponse(
      state: state,
      domain: IntelligenceDomain.verbal,
      isCorrect: true,
      theta: 1.2,
    );
    state = engine.recordResponse(
      state: state,
      domain: IntelligenceDomain.memory,
      isCorrect: false,
      theta: -1.0,
    );

    expect(
      state.snapshotFor(IntelligenceDomain.verbal).level,
      AdaptiveLevel.hard,
    );
    expect(
      state.snapshotFor(IntelligenceDomain.memory).level,
      AdaptiveLevel.easy,
    );
  });

  test('Massive item bank has no duplicates and exposure controller ranks', () {
    final repository = InMemoryItemBankRepository();
    final items = repository.load();
    final ids = items.map((item) => item.id).toSet();
    const exposureController = ExposureController();
    final numerical = repository.findByDomain(IntelligenceDomain.numerical);
    final normal = numerical.firstWhere(
      (item) => item.difficulty == QuestionDifficulty.normal,
    );
    final hard = numerical.firstWhere(
      (item) => item.difficulty == QuestionDifficulty.hard,
    );
    final ranked = exposureController.rank(
      items: [normal, hard],
      targetDifficulty: QuestionDifficulty.normal,
      exposureStatuses: {
        normal.id: ExposureStatus(
          itemId: normal.id,
          exposureCount: 0,
          lastUsed: DateTime.now(),
        ),
        hard.id: ExposureStatus(itemId: hard.id, exposureCount: 1),
      },
    );

    expect(items, hasLength(2600));
    expect(ids, hasLength(items.length));
    expect(ranked.first.id, hard.id);
  });

  test('MultiDomainItemEngine generateItems excludes previous items', () {
    const engine = MultiDomainItemEngine();
    final first = engine.generateItems(
      domain: IntelligenceDomain.spatial,
      difficulty: 0.55,
      count: 4,
    );
    final second = engine.generateItems(
      domain: IntelligenceDomain.spatial,
      difficulty: 0.55,
      count: 4,
      excludedItems: first.map((item) => item.id).toSet(),
    );

    expect(first, hasLength(4));
    expect(second, hasLength(4));
    expect(
      first
          .map((item) => item.id)
          .toSet()
          .intersection(second.map((item) => item.id).toSet()),
      isEmpty,
    );
  });

  testWidgets('Spatial, memory, speed, and calibration widgets build', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              SpatialCanvas(pattern: '▲■◆'),
              MemoryInteraction(
                stimulus: '3 8 1 9',
                remainingSeconds: 3,
                isPreview: true,
              ),
              SpeedInteractionPanel(elapsedSeconds: 3),
              CalibrationTool(showDebugMetrics: true),
            ],
          ),
        ),
      ),
    );

    expect(find.byType(SpatialCanvas), findsOneWidget);
    expect(find.textContaining('3초'), findsOneWidget);
    expect(find.textContaining('처리속도'), findsOneWidget);
    expect(find.text('Calibration Mode'), findsOneWidget);
  });
}
