import '../../../core/domain/intelligence_domain.dart';
import '../../../core/domain/question_difficulty.dart';
import '../../item_bank/domain/exposure_status.dart';
import '../../item_bank/domain/item.dart';
import '../../item_bank/domain/item_selection_strategy.dart';
import 'cat_selection_score.dart';
import 'item_information.dart';
import 'theta_estimate.dart';

class CATItemSelectionStrategy implements ItemSelectionStrategy {
  const CATItemSelectionStrategy();

  @override
  Item selectNext({
    required List<Item> candidates,
    required IntelligenceDomain domain,
    required QuestionDifficulty targetDifficulty,
    required Set<String> usedItemIds,
    required int seed,
    Map<String, ExposureStatus> exposureStatuses = const {},
    ThetaEstimate? thetaEstimate,
  }) {
    final theta = thetaEstimate ?? ThetaEstimate.initial();
    final available = candidates
        .where(
          (item) => item.domain == domain && !usedItemIds.contains(item.id),
        )
        .toList(growable: false);
    if (available.isEmpty) {
      throw StateError('No unused CAT item candidates for ${domain.name}.');
    }

    final ranked = [...available]
      ..sort((a, b) {
        final scoreCompare =
            scoreForItem(
              item: b,
              targetDifficulty: targetDifficulty,
              exposureStatus: exposureStatuses[b.id],
              thetaEstimate: theta,
            ).totalScore.compareTo(
              scoreForItem(
                item: a,
                targetDifficulty: targetDifficulty,
                exposureStatus: exposureStatuses[a.id],
                thetaEstimate: theta,
              ).totalScore,
            );
        if (scoreCompare != 0) {
          return scoreCompare;
        }

        return _stableScore(a.id, seed).compareTo(_stableScore(b.id, seed));
      });

    return ranked.first;
  }

  @override
  double selectionScore({
    required Item item,
    required QuestionDifficulty targetDifficulty,
    ExposureStatus? exposureStatus,
    ThetaEstimate? thetaEstimate,
  }) {
    return scoreForItem(
      item: item,
      targetDifficulty: targetDifficulty,
      exposureStatus: exposureStatus,
      thetaEstimate: thetaEstimate ?? ThetaEstimate.initial(),
    ).totalScore;
  }

  CATSelectionScore scoreForItem({
    required Item item,
    required QuestionDifficulty targetDifficulty,
    required ThetaEstimate thetaEstimate,
    ExposureStatus? exposureStatus,
  }) {
    final informationScore = itemInformation(
      theta: thetaEstimate.theta,
      difficultyIndex: item.difficultyIndex,
      discrimination: item.discrimination,
      guessing: item.guessing,
    );
    final exposureScore =
        exposureStatus?.selectionScore ??
        const ExposureStatus(itemId: '').selectionScore;
    final difficultyMatchScore =
        1 /
        (1 +
            (item.difficultyIndex - _difficultyIndexFor(targetDifficulty))
                .abs());
    return CATSelectionScore(
      informationScore: informationScore,
      exposureScore: exposureScore,
      difficultyMatchScore: difficultyMatchScore,
    );
  }

  double _difficultyIndexFor(QuestionDifficulty difficulty) {
    return (difficulty.level - QuestionDifficulty.normal.level).toDouble();
  }

  int _stableScore(String value, int seed) {
    final primary = _hash(value);
    final secondary = _hash(value.split('').reversed.join());
    final seedMix = ((seed & 0x7fffffff) | 1);
    return (primary ^ ((secondary * seedMix) & 0x7fffffff)) & 0x7fffffff;
  }

  int _hash(String value) {
    var hash = 0x811c9dc5;
    for (final unit in value.codeUnits) {
      hash = ((hash ^ unit) * 16777619) & 0x7fffffff;
    }
    return hash;
  }
}
