import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/app_routes.dart';
import '../../../../core/widgets/action_card.dart';
import '../../../../core/widgets/empty_state.dart';
import '../state/hexaiq_app_state.dart';

class ProfileSelectScreen extends StatelessWidget {
  const ProfileSelectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<HexaIQAppState>();
    return Scaffold(
      appBar: AppBar(title: const Text('프로필 선택')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: state.profiles.isEmpty
              ? EmptyState(
                  icon: Icons.person_add_alt_1,
                  title: '프로필을 만들어 주세요',
                  body: '기기당 최대 3개까지 만들 수 있고, 성장 기록은 프로필별로 분리됩니다.',
                  actionLabel: '프로필 만들기',
                  onAction: () {
                    Navigator.of(context).pushNamed(AppRoutes.profileCreate);
                  },
                )
              : ListView(
                  children: [
                    for (final profile in state.profiles)
                      ActionCard(
                        icon: Icons.account_circle,
                        title: profile.name,
                        body: '${profile.grade} · ${profile.ageGroup}',
                        trailing: Text(profile.avatar),
                        onTap: () async {
                          await context.read<HexaIQAppState>().selectProfile(
                            profile,
                          );
                          if (context.mounted) {
                            Navigator.of(
                              context,
                            ).pushReplacementNamed(AppRoutes.home);
                          }
                        },
                      ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: state.canCreateProfile
                          ? () => Navigator.of(
                              context,
                            ).pushNamed(AppRoutes.profileCreate)
                          : null,
                      icon: const Icon(Icons.add),
                      label: Text(
                        state.canCreateProfile
                            ? '프로필 추가'
                            : '프로필은 최대 3개까지 가능합니다',
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
