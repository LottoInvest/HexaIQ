import 'package:flutter_test/flutter_test.dart';
import 'package:hexaiq_app/core/domain/intelligence_domain.dart';
import 'package:hexaiq_app/core/domain/question_difficulty.dart';
import 'package:hexaiq_app/features/cat/domain/cat_item_selection_strategy.dart';
import 'package:hexaiq_app/features/cat/domain/likelihood_calculator.dart';
import 'package:hexaiq_app/features/cat/domain/theta_estimate.dart';
import 'package:hexaiq_app/features/cat/domain/theta_estimation_method.dart';
import 'package:hexaiq_app/features/cat/domain/theta_estimator.dart';
import 'package:hexaiq_app/features/hexaiq/domain/hexaiq_models.dart';
import 'package:hexaiq_app/features/item_bank/domain/item.dart';
import 'package:hexaiq_app/features/test/domain/models/question_record.dart';

void main() {
  test('ThetaEstimate initial and copyWith work', () {
    final initial = ThetaEstimate.initial(updatedAt: DateTime(2026));
    final updated = initial.copyWith(theta: 0.4, standardError: 0.7);

    expect(initial.theta, 0);
    expect(updated.theta, 0.4);
    expect(updated.standardError, 0.7);
  });

  test('LikelihoodCalculator calculates finite 2PL probability', () {
    const calculator = LikelihoodCalculator();

    final easy = calculator.probability(
      theta: 1,
      difficultyIndex: -1,
      discrimination: 1,
    );
    final hard = calculator.probability(
      theta: -1,
      difficultyIndex: 1,
      discrimination: 1,
    );

    expect(easy, greaterThan(hard));
    expect(
      calculator.probability(
        theta: double.infinity,
        difficultyIndex: 0,
        discrimination: 1,
      ),
      0.5,
    );
  });

  test('ThetaEstimator supports Newton, MAP, and EAP without NaN', () {
    const estimator = ThetaEstimator();
    final current = ThetaEstimate.initial(updatedAt: DateTime(2026));

    final mapEmpty = estimator.estimate(
      history: const [],
      current: current,
      method: ThetaEstimationMethod.map,
      updatedAt: DateTime(2026),
    );
    expect(mapEmpty.theta, 0);
    expect(mapEmpty.method, ThetaEstimationMethod.map);

    final correct = estimator.estimate(
      history: [_record(correct: true)],
      current: current,
      method: ThetaEstimationMethod.newtonRaphson,
      updatedAt: DateTime(2026),
    );
    final wrong = estimator.estimate(
      history: [_record(correct: false)],
      current: current,
      method: ThetaEstimationMethod.eap,
      updatedAt: DateTime(2026),
    );

    expect(correct.theta.isFinite, isTrue);
    expect(wrong.theta.isFinite, isTrue);
    expect(correct.theta, greaterThan(current.theta));
    expect(wrong.theta, lessThan(current.theta));
    expect(correct.standardError, inInclusiveRange(0.25, 1.0));
    expect(wrong.standardError, greaterThanOrEqualTo(0.25));
  });

  test('CATItemSelectionStrategy uses theta and avoids used items', () {
    const strategy = CATItemSelectionStrategy();
    final selected = strategy.selectNext(
      candidates: [
        _item(id: 'easy', difficultyIndex: -2),
        _item(id: 'target', difficultyIndex: 1),
        _item(id: 'used', difficultyIndex: 1.1),
      ],
      domain: IntelligenceDomain.numerical,
      targetDifficulty: QuestionDifficulty.hard,
      usedItemIds: const {'used'},
      seed: 42,
      thetaEstimate: ThetaEstimate.initial().copyWith(theta: 1),
    );

    expect(selected.id, isNot('used'));
    expect(selected.domain, IntelligenceDomain.numerical);
  });

  test('QuestionRecord stores theta and CAT fields', () {
    final question = _question(itemInformation: 0.3, catSelectionScore: 0.8);
    final record = QuestionRecord.fromQuestion(
      question: question,
      correct: true,
      elapsedSeconds: 12,
      thetaBefore: 0,
      thetaAfter: 0.2,
    );

    expect(record.itemId, 'NR-001');
    expect(record.thetaBefore, 0);
    expect(record.thetaAfter, 0.2);
    expect(record.itemInformation, 0.3);
    expect(record.catSelectionScore, 0.8);
  });
}

Item _item({
  required String id,
  double difficultyIndex = 0,
  double discrimination = 1,
}) {
  return Item(
    id: id,
    domain: IntelligenceDomain.numerical,
    difficulty: QuestionDifficulty.normal,
    difficultyIndex: difficultyIndex,
    discrimination: discrimination,
    guessing: 0.25,
    expectedSolveTime: const Duration(seconds: 30),
    question: '1, 2, ?',
    choices: const ['2', '3', '4', '5'],
    answer: '3',
    explanation: '1씩 증가합니다.',
    tags: const ['type:NR01'],
    version: 'test',
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
  );
}

TestQuestion _question({
  double itemInformation = 0,
  double catSelectionScore = 0,
  double difficultyIndex = 0,
  double discrimination = 1,
}) {
  return TestQuestion(
    id: 'q1',
    domain: IntelligenceDomain.numerical,
    typeCode: 'NR01',
    level: 5,
    prompt: '1, 2, ?',
    choices: const ['2', '3', '4', '5'],
    answerIndex: 1,
    explanation: '1씩 증가합니다.',
    difficulty: QuestionDifficulty.normal,
    difficultyIndex: difficultyIndex,
    discrimination: discrimination,
    itemId: 'NR-001',
    selectionScore: catSelectionScore,
    itemInformation: itemInformation,
    catSelectionScore: catSelectionScore,
  );
}

QuestionRecord _record({required bool correct}) {
  return QuestionRecord.fromQuestion(
    question: _question(difficultyIndex: 0, discrimination: 1),
    correct: correct,
    elapsedSeconds: 10,
  );
}
