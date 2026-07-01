import 'package:flutter/material.dart';

import '../../../app/version_info.dart';

class OpenSourceLicenseScreen extends StatelessWidget {
  const OpenSourceLicenseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return LicensePage(
      applicationName: 'HexaIQ',
      applicationVersion: VersionInfo.current.version,
    );
  }
}
