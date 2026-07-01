import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/app_routes.dart';
import '../../../../core/widgets/action_card.dart';
import '../state/hexaiq_app_state.dart';

class ProfileSelectScreen extends StatefulWidget {
  const ProfileSelectScreen({super.key});

  @override
  State<ProfileSelectScreen> createState() => _ProfileSelectScreenState();
}

class _ProfileSelectScreenState extends State<ProfileSelectScreen> {
  bool _redirectScheduled = false;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<HexaIQAppState>();
    if (state.profilesLoaded && state.profiles.isEmpty && !_redirectScheduled) {
      _redirectScheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          Navigator.of(context).pushReplacementNamed(AppRoutes.profileCreate);
        }
      });
    }

    return Scaffold(
      appBar: AppBar(title: const Text('프로필 선택')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: state.profiles.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  children: [
                    for (final profile in state.profiles)
                      ActionCard(
                        icon: Icons.account_circle,
                        title: profile.name,
                        body:
                            '${profile.grade} · ${_ageGroupLabel(profile.ageGroup)}',
                        trailing: IconButton(
                          tooltip: '삭제',
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () =>
                              _confirmDelete(context, profile.id, profile.name),
                        ),
                        onTap: () async {
                          final navigator = Navigator.of(context);
                          await context.read<HexaIQAppState>().selectProfile(
                            profile,
                          );
                          if (context.mounted) {
                            navigator.pushReplacementNamed(AppRoutes.home);
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
                            : '프로필은 최대 3개까지 만들 수 있습니다',
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    String profileId,
    String profileName,
  ) async {
    final state = context.read<HexaIQAppState>();
    final profile = state.profiles.firstWhere((item) => item.id == profileId);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('프로필을 삭제할까요?'),
          content: Text('$profileName 프로필을 삭제하면 이 기기의 프로필 정보가 사라집니다.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('삭제'),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !context.mounted) {
      return;
    }
    await context.read<HexaIQAppState>().deleteProfile(profile);
    if (context.mounted && context.read<HexaIQAppState>().profiles.isEmpty) {
      Navigator.of(context).pushReplacementNamed(AppRoutes.profileCreate);
    }
  }

  String _ageGroupLabel(String value) {
    return switch (value) {
      'grade3_4' => '초등 3-4학년',
      'grade5_6' => '초등 5-6학년',
      'middle' => '중학생',
      'high' => '고등학생',
      'adult' => '성인',
      _ => value,
    };
  }
}
