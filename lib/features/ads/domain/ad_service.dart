import 'package:flutter/material.dart';

import '../presentation/mock_ad_dialog.dart';

abstract class AdService {
  const AdService();

  Future<bool> showRewardAd(BuildContext context);

  Future<bool> showInterstitialAd(BuildContext context);

  Future<bool> showMockAdDialog(
    BuildContext context, {
    required String title,
    required String message,
  });
}

class MockAdService extends AdService {
  const MockAdService({
    this.countdown = const Duration(seconds: 5),
    this.showResultGate = true,
  });

  final Duration countdown;
  final bool showResultGate;

  @override
  Future<bool> showRewardAd(BuildContext context) async {
    if (showResultGate) {
      final accepted = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('검사 결과를 준비하고 있습니다.'),
          content: const Text('광고 시청 후 결과를 확인할 수 있습니다.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('광고 보기'),
            ),
          ],
        ),
      );
      if (accepted != true || !context.mounted) {
        return false;
      }
    }
    return showMockAdDialog(
      context,
      title: '결과 분석 중',
      message: '결과 분석을 준비하고 있습니다.',
    );
  }

  @override
  Future<bool> showInterstitialAd(BuildContext context) {
    return showMockAdDialog(
      context,
      title: '잠시만 기다려 주세요',
      message: '잠시 후 검사가 이어집니다.',
    );
  }

  @override
  Future<bool> showMockAdDialog(
    BuildContext context, {
    required String title,
    required String message,
  }) async {
    final watched = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) =>
          MockAdDialog(title: title, message: message, countdown: countdown),
    );
    return watched == true;
  }
}
