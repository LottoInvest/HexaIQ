import 'package:flutter_test/flutter_test.dart';
import 'package:hexaiq_app/core/domain/question_difficulty.dart';
import 'package:hexaiq_app/features/question_engine/question_engine.dart';

void main() {
  test('Item bank builds 120 mock items across six domains', () {
    final repository = InMemoryItemBankRepository();
    final items = repository.load();

    expect(items.length, 120);
    for (final domain in IntelligenceDomain.values) {
      expect(repository.findByDomain(domain).length, 20);
    }
  });

  test('Item bank supports difficulty and tag lookup', () {
    final repository = InMemoryItemBankRepository();

    expect(repository.findByDifficulty(QuestionDifficulty.normal).length, 24);
    expect(repository.findByTag('type:NR01'), isNotEmpty);
    expect(repository.findByTag('stub'), isNotEmpty);
  });

  test('Item model carries psychometric metadata', () {
    final item = InMemoryItemBankRepository()
        .findByDomain(IntelligenceDomain.numerical)
        .first;

    expect(item.id, isNotEmpty);
    expect(item.difficultyIndex, isA<double>());
    expect(item.discrimination, greaterThan(0));
    expect(item.guessing, greaterThan(0));
    expect(item.expectedSolveTime, isNot(Duration.zero));
    expect(item.version, 'v0.6.0');
  });

  test('ItemStatistics calculates accuracy', () {
    final statistics = ItemStatistics(
      attemptCount: 10,
      correctCount: 7,
      wrongCount: 3,
      averageTime: const Duration(seconds: 12),
      difficultyEstimate: 0.3,
      exposureCount: 3,
      averageResponseTime: const Duration(seconds: 9),
      lastUpdated: DateTime(2026),
      lastUsed: DateTime(2026, 1, 2),
    );

    expect(statistics.accuracy, 0.7);
    expect(statistics.selectionScore, 0.25);
    expect(statistics.averageResponseTime.inSeconds, 9);
    expect(statistics.copyWith(correctCount: 8).correctCount, 8);
  });

  test('InMemoryExposureRepository updates exposure status', () {
    final repository = InMemoryExposureRepository();

    final first = repository.update(
      'NR-001',
      correct: true,
      responseTime: const Duration(seconds: 10),
      usedAt: DateTime(2026),
    );
    final second = repository.update(
      'NR-001',
      correct: false,
      responseTime: const Duration(seconds: 20),
      usedAt: DateTime(2026, 1, 2),
    );

    expect(first.exposureCount, 1);
    expect(second.exposureCount, 2);
    expect(second.correctCount, 1);
    expect(second.wrongCount, 1);
    expect(second.averageResponseTime.inSeconds, 15);
    expect(repository.statistics().first.itemId, 'NR-001');
    repository.clear();
    expect(repository.statistics(), isEmpty);
  });

  test('CalibrationState exposes stable labels', () {
    expect(CalibrationState.notCalibrated.label, 'Not Calibrated');
    expect(CalibrationState.calibrating.label, 'Calibrating');
    expect(CalibrationState.stable.label, 'Stable');
  });

  test('QuestionEngine converts item bank entries into question DTOs', () {
    final engine = QuestionEngine();

    final question = engine.generateOne(
      seed: 42,
      domain: IntelligenceDomain.numerical,
      difficulty: QuestionDifficulty.normal,
      profileId: 'profile-item',
      testId: 'test-item',
      index: 0,
    );

    expect(question.itemId, isNotNull);
    expect(question.choices, contains(question.answer));
    expect(question.variables['itemId'], question.itemId);
  });

  test('DefaultItemSelectionStrategy excludes used item ids', () {
    final repository = InMemoryItemBankRepository();
    const strategy = DefaultItemSelectionStrategy();
    final first = strategy.selectNext(
      candidates: repository.findByDomain(IntelligenceDomain.numerical),
      domain: IntelligenceDomain.numerical,
      targetDifficulty: QuestionDifficulty.normal,
      usedItemIds: const {},
      seed: 7,
    );
    final second = strategy.selectNext(
      candidates: repository.findByDomain(IntelligenceDomain.numerical),
      domain: IntelligenceDomain.numerical,
      targetDifficulty: QuestionDifficulty.normal,
      usedItemIds: {first.id},
      seed: 7,
    );

    expect(second.id, isNot(first.id));
  });

  test('DefaultItemSelectionStrategy prefers nearest target difficulty', () {
    final repository = InMemoryItemBankRepository();
    const strategy = DefaultItemSelectionStrategy();

    final selected = strategy.selectNext(
      candidates: repository.findByDomain(IntelligenceDomain.numerical),
      domain: IntelligenceDomain.numerical,
      targetDifficulty: QuestionDifficulty.hard,
      usedItemIds: const {},
      seed: 11,
    );

    expect(selected.difficulty, QuestionDifficulty.hard);
  });

  test(
    'DefaultItemSelectionStrategy selectionScore combines difficulty and exposure',
    () {
      final item = InMemoryItemBankRepository()
          .findByDomain(IntelligenceDomain.numerical)
          .firstWhere((item) => item.difficulty == QuestionDifficulty.normal);
      const strategy = DefaultItemSelectionStrategy();

      final score = strategy.selectionScore(
        item: item,
        targetDifficulty: QuestionDifficulty.normal,
        exposureStatus: const ExposureStatus(
          itemId: 'NR-003',
          exposureCount: 1,
        ),
      );

      expect(score, 0.5);
    },
  );

  test(
    'DefaultItemSelectionStrategy prefers lower exposure before difficulty',
    () {
      final repository = InMemoryItemBankRepository();
      const strategy = DefaultItemSelectionStrategy();
      final candidates = repository.findByDomain(IntelligenceDomain.numerical);
      final hard = candidates.firstWhere(
        (item) => item.difficulty == QuestionDifficulty.hard,
      );
      final normal = candidates.firstWhere(
        (item) => item.difficulty == QuestionDifficulty.normal,
      );

      final selected = strategy.selectNext(
        candidates: [normal, hard],
        domain: IntelligenceDomain.numerical,
        targetDifficulty: QuestionDifficulty.normal,
        usedItemIds: const {},
        seed: 9,
        exposureStatuses: {
          normal.id: ExposureStatus(itemId: normal.id, exposureCount: 4),
          hard.id: ExposureStatus(itemId: hard.id, exposureCount: 0),
        },
      );

      expect(selected.id, hard.id);
    },
  );

  test('DefaultItemSelectionStrategy is deterministic for same seed/state', () {
    final repository = InMemoryItemBankRepository();
    const strategy = DefaultItemSelectionStrategy();
    final candidates = repository.findByDomain(IntelligenceDomain.numerical);

    final first = strategy.selectNext(
      candidates: candidates,
      domain: IntelligenceDomain.numerical,
      targetDifficulty: QuestionDifficulty.easy,
      usedItemIds: const {'NR-002'},
      seed: 21,
    );
    final second = strategy.selectNext(
      candidates: candidates,
      domain: IntelligenceDomain.numerical,
      targetDifficulty: QuestionDifficulty.easy,
      usedItemIds: const {'NR-002'},
      seed: 21,
    );

    expect(second.id, first.id);
  });

  test('DefaultItemSelectionStrategy can vary selection by seed', () {
    final repository = InMemoryItemBankRepository();
    const strategy = DefaultItemSelectionStrategy();
    final candidates = repository.findByDomain(IntelligenceDomain.numerical);
    final selectedIds = {
      for (var seed = 1; seed <= 40; seed++)
        strategy
            .selectNext(
              candidates: candidates,
              domain: IntelligenceDomain.numerical,
              targetDifficulty: QuestionDifficulty.veryEasy,
              usedItemIds: const {},
              seed: seed,
            )
            .id,
    };

    expect(selectedIds.length, greaterThan(1));
  });

  test('DefaultItemSelectionStrategy falls back to nearby difficulty', () {
    final repository = InMemoryItemBankRepository();
    const strategy = DefaultItemSelectionStrategy();
    final withoutHard = repository
        .findByDomain(IntelligenceDomain.numerical)
        .where((item) => item.difficulty != QuestionDifficulty.hard)
        .toList(growable: false);

    final selected = strategy.selectNext(
      candidates: withoutHard,
      domain: IntelligenceDomain.numerical,
      targetDifficulty: QuestionDifficulty.hard,
      usedItemIds: const {},
      seed: 3,
    );

    expect(selected.difficulty, QuestionDifficulty.normal);
  });

  test('QuestionEngine delegates item choice to selection strategy', () {
    final strategy = _FixedItemSelectionStrategy('NR-006');
    final engine = QuestionEngine(itemSelectionStrategy: strategy);

    final question = engine.generateOne(
      seed: 5,
      domain: IntelligenceDomain.numerical,
      difficulty: QuestionDifficulty.normal,
      profileId: 'profile-strategy',
      testId: 'test-strategy',
      index: 0,
      typeCode: 'NR06',
    );

    expect(strategy.called, isTrue);
    expect(question.itemId, 'NR-006');
  });

  test('QuestionEngine increments exposure when a question is generated', () {
    final exposureRepository = InMemoryExposureRepository();
    final engine = QuestionEngine(exposureRepository: exposureRepository);

    final question = engine.generateOne(
      seed: 42,
      domain: IntelligenceDomain.numerical,
      difficulty: QuestionDifficulty.normal,
      profileId: 'profile-exposure',
      testId: 'test-exposure',
      index: 0,
    );

    expect(exposureRepository.load(question.itemId!).exposureCount, 1);
    expect(question.selectionScore, greaterThan(0));
  });
}

class _FixedItemSelectionStrategy implements ItemSelectionStrategy {
  _FixedItemSelectionStrategy(this.itemId);

  final String itemId;
  bool called = false;

  @override
  Item selectNext({
    required List<Item> candidates,
    required IntelligenceDomain domain,
    required QuestionDifficulty targetDifficulty,
    required Set<String> usedItemIds,
    required int seed,
    Map<String, ExposureStatus> exposureStatuses = const {},
  }) {
    called = true;
    return candidates.firstWhere((item) => item.id == itemId);
  }

  @override
  double selectionScore({
    required Item item,
    required QuestionDifficulty targetDifficulty,
    ExposureStatus? exposureStatus,
  }) {
    return 0.42;
  }
}
