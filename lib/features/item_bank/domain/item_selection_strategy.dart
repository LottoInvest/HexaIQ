import '../../../../core/domain/intelligence_domain.dart';
import '../../../../core/domain/question_difficulty.dart';
import '../../cat/domain/theta_estimate.dart';
import 'exposure_status.dart';
import 'item.dart';

abstract class ItemSelectionStrategy {
  Item selectNext({
    required List<Item> candidates,
    required IntelligenceDomain domain,
    required QuestionDifficulty targetDifficulty,
    required Set<String> usedItemIds,
    required int seed,
    Map<String, ExposureStatus> exposureStatuses = const {},
    ThetaEstimate? thetaEstimate,
  });

  double selectionScore({
    required Item item,
    required QuestionDifficulty targetDifficulty,
    ExposureStatus? exposureStatus,
    ThetaEstimate? thetaEstimate,
  });
}
