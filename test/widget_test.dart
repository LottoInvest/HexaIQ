import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hexaiq_app/main.dart';

void main() {
  testWidgets('HexaIQ app starts at splash screen', (tester) async {
    await tester.pumpWidget(const HexaIQApp());

    expect(find.text('HexaIQ'), findsOneWidget);
  });

  testWidgets('Onboarding can navigate to profile select', (tester) async {
    await tester.pumpWidget(const HexaIQApp());
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    await tester.drag(find.byType(Scrollable).first, const Offset(0, -500));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.arrow_forward), findsOneWidget);
    await tester.tap(find.byIcon(Icons.arrow_forward));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.account_circle), findsWidgets);
  });
}
