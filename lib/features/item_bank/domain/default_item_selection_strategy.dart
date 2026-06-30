import '../../../../core/domain/intelligence_domain.dart';
import '../../../../core/domain/question_difficulty.dart';
import 'exposure_status.dart';
import 'item.dart';
import 'item_selection_strategy.dart';

class DefaultItemSelectionStrategy implements ItemSelectionStrategy {
  const DefaultItemSelectionStrategy();

  @override
  Item selectNext({
    required List<Item> candidates,
    required IntelligenceDomain domain,
    required QuestionDifficulty targetDifficulty,
    required Set<String> usedItemIds,
    required int seed,
    Map<String, ExposureStatus> exposureStatuses = const {},
  }) {
    final domainCandidates = candidates
        .where((item) => item.domain == domain)
        .toList(growable: false);
    final available = domainCandidates
        .where((item) => !usedItemIds.contains(item.id))
        .toList(growable: false);
    if (available.isEmpty) {
      throw StateError('No unused item candidates for ${domain.name}.');
    }

    final targetIndex = _difficultyIndexFor(targetDifficulty);
    final ranked = [...available]
      ..sort((a, b) {
        final exposureCompare = _exposureCount(
          a,
          exposureStatuses,
        ).compareTo(_exposureCount(b, exposureStatuses));
        if (exposureCompare != 0) {
          return exposureCompare;
        }

        final scoreCompare =
            selectionScore(
              item: b,
              targetDifficulty: targetDifficulty,
              exposureStatus: exposureStatuses[b.id],
            ).compareTo(
              selectionScore(
                item: a,
                targetDifficulty: targetDifficulty,
                exposureStatus: exposureStatuses[a.id],
              ),
            );
        if (scoreCompare != 0) {
          return scoreCompare;
        }

        final indexCompare = (a.difficultyIndex - targetIndex).abs().compareTo(
          (b.difficultyIndex - targetIndex).abs(),
        );
        if (indexCompare != 0) {
          return indexCompare;
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
  }) {
    final difficultyScore =
        1 / (1 + _difficultyDistance(item.difficulty, targetDifficulty));
    final exposureScore =
        exposureStatus?.selectionScore ??
        const ExposureStatus(itemId: '').selectionScore;
    return difficultyScore * exposureScore;
  }

  int _difficultyDistance(
    QuestionDifficulty difficulty,
    QuestionDifficulty targetDifficulty,
  ) {
    return (difficulty.level - targetDifficulty.level).abs();
  }

  double _difficultyIndexFor(QuestionDifficulty difficulty) {
    return (difficulty.level - QuestionDifficulty.normal.level).toDouble();
  }

  int _exposureCount(Item item, Map<String, ExposureStatus> exposureStatuses) {
    return exposureStatuses[item.id]?.exposureCount ?? 0;
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
