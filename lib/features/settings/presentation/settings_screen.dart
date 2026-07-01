import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/app_routes.dart';
import '../../../app/release_config.dart';
import '../../../app/version_info.dart';
import '../../../core/responsive/responsive_page.dart';
import '../../hexaiq/presentation/state/hexaiq_app_state.dart';
import '../../hexaiq/presentation/widgets/dashboard_nav.dart';
import 'widgets/legal_links_section.dart';
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
          const ListTile(
            leading: Icon(Icons.campaign_outlined),
            title: Text('광고 안내'),
            subtitle: Text('무료 검사에는 일부 구간에서 광고가 표시될 수 있습니다.'),
          ),
          const ListTile(
            leading: Icon(Icons.workspace_premium_outlined),
            title: Text('전문 검사'),
            subtitle: Text('${ReleaseConfig.professionalPriceLabel} 일회성 결제'),
          ),
          const Divider(),
          const LegalLinksSection(),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('앱 버전'),
            subtitle: Text(
              '${VersionInfo.current.displayName}\n${VersionInfo.current.releaseName}',
            ),
          ),
        ],
      ),
    );
  }
}
