import 'package:flutter/foundation.dart';

class ReleaseConfig {
  const ReleaseConfig._();

  static const appName = 'HexaIQ';
  static const packageName = 'com.hexaiq.hexaiq_app';
  static const supportEmail = 'support@hexaiq.app';

  static const professionalProductId = 'hexaiq_professional_test';
  static const professionalPriceLabel = 'USD \$4.90';

  static const debugRewardAdUnitId = 'ca-app-pub-3940256099942544/5224354917';
  static const debugInterstitialAdUnitId =
      'ca-app-pub-3940256099942544/1033173712';

  static const releaseRewardAdUnitId = String.fromEnvironment(
    'HEXA_IQ_REWARD_AD_UNIT_ID',
  );
  static const releaseInterstitialAdUnitId = String.fromEnvironment(
    'HEXA_IQ_INTERSTITIAL_AD_UNIT_ID',
  );

  static String get rewardAdUnitId =>
      kReleaseMode && releaseRewardAdUnitId.isNotEmpty
      ? releaseRewardAdUnitId
      : debugRewardAdUnitId;

  static String get interstitialAdUnitId =>
      kReleaseMode && releaseInterstitialAdUnitId.isNotEmpty
      ? releaseInterstitialAdUnitId
      : debugInterstitialAdUnitId;
}
