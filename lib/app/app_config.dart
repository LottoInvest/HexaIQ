import 'version_info.dart';

class AppConfig {
  const AppConfig({
    required this.versionInfo,
    this.isReleaseCandidate = false,
    this.enableDebugLogs = false,
  });

  final VersionInfo versionInfo;
  final bool isReleaseCandidate;
  final bool enableDebugLogs;

  static const current = AppConfig(versionInfo: VersionInfo.current);
}
