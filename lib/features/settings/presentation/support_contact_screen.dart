import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/release_config.dart';
import '../../../app/version_info.dart';

class SupportContactScreen extends StatelessWidget {
  const SupportContactScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final subject = '[HexaIQ 문의] v${VersionInfo.current.version}';
    return Scaffold(
      appBar: AppBar(title: const Text('문의하기')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text('문의하기', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 12),
                const Text(
                  '결제, 광고, PDF, 검사 결과, 앱 오류 관련 문의를 보낼 수 있습니다. '
                  '개인정보나 결제 카드 정보는 포함하지 말아 주세요.',
                ),
                const SizedBox(height: 20),
                _InfoTile(label: '이메일', value: ReleaseConfig.supportEmail),
                _InfoTile(label: '메일 제목', value: subject),
                _InfoTile(
                  label: '앱 버전',
                  value:
                      '${VersionInfo.current.displayName} / ${VersionInfo.current.releaseName}',
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  icon: const Icon(Icons.copy),
                  label: const Text('문의 정보 복사'),
                  onPressed: () async {
                    await Clipboard.setData(
                      ClipboardData(
                        text:
                            'To: ${ReleaseConfig.supportEmail}\nSubject: $subject',
                      ),
                    );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('문의 정보가 복사되었습니다.')),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      subtitle: Text(value),
    );
  }
}
