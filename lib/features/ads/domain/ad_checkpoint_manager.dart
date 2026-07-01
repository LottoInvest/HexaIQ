import '../../hexaiq/domain/hexaiq_models.dart';

class AdCheckpointState {
  const AdCheckpointState({
    this.completedMidpoints = const {},
    this.resultAdsWatched = 0,
  });

  final Set<String> completedMidpoints;
  final int resultAdsWatched;

  bool hasSeenMidpoint(TestType type, int completedDomainCount) {
    return completedMidpoints.contains(
      _midpointKey(type, completedDomainCount),
    );
  }

  AdCheckpointState recordMidAd(TestType type, int completedDomainCount) {
    return AdCheckpointState(
      completedMidpoints: {
        ...completedMidpoints,
        _midpointKey(type, completedDomainCount),
      },
      resultAdsWatched: resultAdsWatched,
    );
  }

  AdCheckpointState recordResultAd() {
    return AdCheckpointState(
      completedMidpoints: completedMidpoints,
      resultAdsWatched: resultAdsWatched + 1,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'completedMidpoints': completedMidpoints.toList(growable: false)..sort(),
      'resultAdsWatched': resultAdsWatched,
    };
  }

  factory AdCheckpointState.fromJson(Map<String, Object?> json) {
    return AdCheckpointState(
      completedMidpoints: {
        for (final value
            in json['completedMidpoints'] as List<Object?>? ?? const [])
          value.toString(),
      },
      resultAdsWatched: json['resultAdsWatched'] as int? ?? 0,
    );
  }

  static String _midpointKey(TestType type, int completedDomainCount) {
    return '${type.name}:$completedDomainCount';
  }
}

class AdCheckpointManager {
  const AdCheckpointManager();

  bool shouldShowMidAd({
    required TestType type,
    required int completedDomainCount,
    required AdCheckpointState state,
  }) {
    final requiredCheckpoint = switch (type) {
      TestType.quickIq => completedDomainCount == 3,
      TestType.advanced =>
        completedDomainCount == 2 || completedDomainCount == 4,
      _ => false,
    };
    return requiredCheckpoint &&
        !state.hasSeenMidpoint(type, completedDomainCount);
  }

  int resultAdCount(TestType type, {required bool professionalPurchased}) {
    return switch (type) {
      TestType.basic => 0,
      TestType.quickIq => 1,
      TestType.advanced => 1,
      TestType.professional => professionalPurchased ? 0 : 0,
    };
  }

  bool shouldShowResultAd({
    required TestType type,
    required bool professionalPurchased,
    required AdCheckpointState state,
  }) {
    return state.resultAdsWatched <
        resultAdCount(type, professionalPurchased: professionalPurchased);
  }
}
