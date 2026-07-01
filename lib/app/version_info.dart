class VersionInfo {
  const VersionInfo({
    required this.version,
    required this.buildName,
    required this.releaseName,
  });

  final String version;
  final String buildName;
  final String releaseName;

  static const current = VersionInfo(
    version: '1.0.1',
    buildName: '1.0.1',
    releaseName: 'QA Stabilization Build',
  );

  String get displayName => 'HexaIQ v$version';

  Map<String, Object?> toJson() {
    return {
      'version': version,
      'buildName': buildName,
      'releaseName': releaseName,
    };
  }
}
