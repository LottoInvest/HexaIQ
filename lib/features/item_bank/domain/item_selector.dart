import '../../../../core/domain/intelligence_domain.dart';
import '../../../../core/domain/question_difficulty.dart';
import '../../cat/domain/theta_estimate.dart';
import 'exposure_controller.dart';
import 'exposure_status.dart';
import 'item.dart';

class ItemSelector {
  const ItemSelector({this.exposureController = const ExposureController()});

  final ExposureController exposureController;

  Item select({
    required List<Item> candidates,
    required IntelligenceDomain domain,
    required QuestionDifficulty targetDifficulty,
    Set<String> excludedItems = const {},
    Map<String, ExposureStatus> exposureStatuses = const {},
    ThetaEstimate? thetaEstimate,
  }) {
    final domainCandidates = candidates
        .where((item) => item.domain == domain)
        .toList(growable: false);
    final ranked = exposureController.rank(
      items: domainCandidates,
      targetDifficulty: targetDifficulty,
      exposureStatuses: exposureStatuses,
      excludedItems: excludedItems,
    );
    if (ranked.isEmpty) {
      throw StateError('No available item for ${domain.name}.');
    }
    return ranked.first;
  }
}
