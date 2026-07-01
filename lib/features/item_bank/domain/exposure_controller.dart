import '../../../../core/domain/question_difficulty.dart';
import 'exposure_status.dart';
import 'item.dart';

class ExposureController {
  const ExposureController({this.recentWindow = const Duration(days: 7)});

  final Duration recentWindow;

  bool isRecentlyUsed(ExposureStatus? status, {DateTime? now}) {
    final lastUsed = status?.lastUsed;
    if (lastUsed == null) {
      return false;
    }
    final reference = now ?? DateTime.now();
    return reference.difference(lastUsed) < recentWindow;
  }

  double selectionScore(ExposureStatus? status, {DateTime? now}) {
    if (status == null) {
      return 1;
    }
    final recencyPenalty = isRecentlyUsed(status, now: now) ? 0.1 : 1.0;
    return recencyPenalty / (1 + status.exposureCount);
  }

  List<Item> rank({
    required List<Item> items,
    required QuestionDifficulty targetDifficulty,
    Map<String, ExposureStatus> exposureStatuses = const {},
    Set<String> excludedItems = const {},
    DateTime? now,
  }) {
    final available = items
        .where((item) => !excludedItems.contains(item.id))
        .toList(growable: false);
    return [...available]..sort((a, b) {
      final aStatus = exposureStatuses[a.id];
      final bStatus = exposureStatuses[b.id];
      final aRecent = isRecentlyUsed(aStatus, now: now) ? 1 : 0;
      final bRecent = isRecentlyUsed(bStatus, now: now) ? 1 : 0;
      final recentCompare = aRecent.compareTo(bRecent);
      if (recentCompare != 0) {
        return recentCompare;
      }

      final usageCompare = (aStatus?.exposureCount ?? a.usageCount).compareTo(
        bStatus?.exposureCount ?? b.usageCount,
      );
      if (usageCompare != 0) {
        return usageCompare;
      }

      final distanceCompare = _difficultyDistance(
        a,
        targetDifficulty,
      ).compareTo(_difficultyDistance(b, targetDifficulty));
      if (distanceCompare != 0) {
        return distanceCompare;
      }

      return a.id.compareTo(b.id);
    });
  }

  int _difficultyDistance(Item item, QuestionDifficulty targetDifficulty) {
    return (item.difficulty.level - targetDifficulty.level).abs();
  }
}
