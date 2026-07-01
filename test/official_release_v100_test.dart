import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hexaiq_app/app/app_config.dart';
import 'package:hexaiq_app/app/release_config.dart';
import 'package:hexaiq_app/app/version_info.dart';
import 'package:hexaiq_app/features/settings/presentation/open_source_license_screen.dart';
import 'package:hexaiq_app/features/settings/presentation/policy_screen.dart';
import 'package:hexaiq_app/features/settings/presentation/support_contact_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('v1.0.1 QA Stabilization Build', () {
    test('version and release config are stabilization build values', () {
      expect(VersionInfo.current.version, '1.0.1');
      expect(VersionInfo.current.buildName, '1.0.1');
      expect(VersionInfo.current.releaseName, 'QA Stabilization Build');
      expect(AppConfig.current.isReleaseCandidate, isFalse);
      expect(ReleaseConfig.appName, 'HexaIQ');
      expect(ReleaseConfig.packageName, 'com.hexaiq.hexaiq_app');
      expect(ReleaseConfig.professionalProductId, 'hexaiq_professional_test');
      expect(ReleaseConfig.professionalPriceLabel, 'USD \$4.90');
    });

    test('store and legal assets are bundled', () async {
      final privacy = await rootBundle.loadString(
        'assets/legal/privacy_policy.md',
      );
      final terms = await rootBundle.loadString(
        'assets/legal/terms_of_service.md',
      );
      final listing = await rootBundle.loadString(
        'assets/store/store_listing_ko.md',
      );
      final reviewNotes = await rootBundle.loadString(
        'assets/store/play_store_review_notes.md',
      );

      expect(privacy, contains('개인정보처리방침'));
      expect(terms, contains('공식 진단을 대체하지 않습니다'));
      expect(listing, contains('짧은 설명'));
      expect(reviewNotes, contains('hexaiq_professional_test'));
    });

    test(
      'Android manifest uses final app label and minimal internet permission',
      () {
        final manifest = File(
          'android/app/src/main/AndroidManifest.xml',
        ).readAsStringSync();
        final strings = File(
          'android/app/src/main/res/values/strings.xml',
        ).readAsStringSync();

        expect(manifest, contains('android.permission.INTERNET'));
        expect(manifest, contains('android:label="@string/app_name"'));
        expect(strings, contains('<string name="app_name">HexaIQ</string>'));
      },
    );

    testWidgets('policy screens expose user-facing Korean legal copy', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: PolicyScreen(type: PolicyDocumentType.privacy)),
      );
      expect(find.text('개인정보처리방침'), findsWidgets);
      expect(find.textContaining('필요한 최소한의 정보'), findsOneWidget);

      await tester.pumpWidget(
        const MaterialApp(home: PolicyScreen(type: PolicyDocumentType.terms)),
      );
      expect(find.text('이용약관'), findsWidgets);
      expect(find.textContaining('공식 진단을 대체하지 않습니다'), findsOneWidget);
    });

    testWidgets('support and license screens build for release settings', (
      tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: SupportContactScreen()));
      expect(find.text('문의하기'), findsWidgets);
      expect(find.textContaining(ReleaseConfig.supportEmail), findsOneWidget);
      expect(find.textContaining('개인정보'), findsOneWidget);

      await tester.pumpWidget(
        const MaterialApp(home: OpenSourceLicenseScreen()),
      );
      await tester.pump();
      expect(find.byType(LicensePage), findsOneWidget);
    });
  });
}
