import 'package:flutter_test/flutter_test.dart';

import 'package:hexaiq_app/main.dart';

void main() {
  testWidgets('HexaIQ app starts at splash screen', (tester) async {
    await tester.pumpWidget(const HexaIQApp());

    expect(find.text('HexaIQ'), findsOneWidget);
    expect(find.text('6가지 인지 능력 성장 플랫폼'), findsOneWidget);
  });

  testWidgets('Onboarding can navigate to profile select', (tester) async {
    await tester.pumpWidget(const HexaIQApp());
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    expect(find.text('시작하기'), findsOneWidget);
    await tester.tap(find.text('시작하기'));
    await tester.pumpAndSettle();

    expect(find.text('프로필 선택'), findsOneWidget);
  });
}
