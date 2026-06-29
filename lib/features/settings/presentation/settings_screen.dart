import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/app_routes.dart';
import '../../../core/responsive/responsive_page.dart';
import '../../hexaiq/presentation/state/hexaiq_app_state.dart';
import '../../hexaiq/presentation/widgets/dashboard_nav.dart';
import 'widgets/theme_mode_selector.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<HexaIQAppState>();
    return ResponsivePage(
      title: '설정',
      currentIndex: 3,
      onDestinationSelected: (index) =>
          handleDashboardDestination(context, index),
      child: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('현재 프로필'),
            subtitle: Text(state.selectedProfile?.name ?? '선택되지 않음'),
            trailing: TextButton(
              onPressed: () =>
                  Navigator.of(context).pushNamed(AppRoutes.profileSelect),
              child: const Text('변경'),
            ),
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: ThemeModeSelector(),
          ),
          const Divider(),
          SwitchListTile(
            value: true,
            onChanged: (_) {},
            title: const Text('학습 알림'),
            subtitle: const Text('MVP mock 설정입니다.'),
          ),
          const ListTile(
            leading: Icon(Icons.privacy_tip_outlined),
            title: Text('개인정보 처리방침'),
            subtitle: Text('출시 전 문서 연결 예정'),
          ),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('앱 버전'),
            subtitle: Text('1.0.0 MVP'),
          ),
        ],
      ),
    );
  }
}
