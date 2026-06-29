import 'package:flutter/material.dart';

import '../../../../app/app_routes.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'HexaIQ',
                    style: Theme.of(context).textTheme.displaySmall,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '검사, 분석, 훈련 추천, 성장 기록을 하나의 흐름으로 연결합니다.',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 28),
                  const Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _Pill(label: '수리 추론'),
                      _Pill(label: '공간 지각'),
                      _Pill(label: '논리 추론'),
                      _Pill(label: '언어 추론'),
                      _Pill(label: '작업 기억'),
                      _Pill(label: '추상 패턴'),
                    ],
                  ),
                  const SizedBox(height: 32),
                  FilledButton.icon(
                    onPressed: () {
                      Navigator.of(
                        context,
                      ).pushReplacementNamed(AppRoutes.profileSelect);
                    },
                    icon: const Icon(Icons.arrow_forward),
                    label: const Text('시작하기'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(label: Text(label));
  }
}
