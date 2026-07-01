import 'package:flutter/material.dart';

import '../../../../app/app_routes.dart';

class LegalLinksSection extends StatelessWidget {
  const LegalLinksSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.privacy_tip_outlined),
          title: const Text('개인정보처리방침'),
          subtitle: const Text('수집 항목과 사용 목적 확인'),
          onTap: () => Navigator.of(context).pushNamed(AppRoutes.privacyPolicy),
        ),
        ListTile(
          leading: const Icon(Icons.description_outlined),
          title: const Text('이용약관'),
          subtitle: const Text('검사 결과와 결제 안내 확인'),
          onTap: () =>
              Navigator.of(context).pushNamed(AppRoutes.termsOfService),
        ),
        ListTile(
          leading: const Icon(Icons.balance_outlined),
          title: const Text('오픈소스 라이선스'),
          subtitle: const Text('사용한 패키지의 라이선스 보기'),
          onTap: () =>
              Navigator.of(context).pushNamed(AppRoutes.openSourceLicenses),
        ),
        ListTile(
          leading: const Icon(Icons.mail_outline),
          title: const Text('문의하기'),
          subtitle: const Text('결제, 광고, PDF, 오류 문의'),
          onTap: () =>
              Navigator.of(context).pushNamed(AppRoutes.supportContact),
        ),
      ],
    );
  }
}
