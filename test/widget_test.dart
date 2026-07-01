import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:hexaiq_app/app/app_router.dart';
import 'package:hexaiq_app/features/hexaiq/data/mock_hexaiq_repository.dart';
import 'package:hexaiq_app/features/hexaiq/presentation/screens/onboarding_screen.dart';
import 'package:hexaiq_app/features/hexaiq/presentation/state/hexaiq_app_state.dart';
import 'package:hexaiq_app/main.dart';

void main() {
  testWidgets('HexaIQ app starts at splash screen', (tester) async {
    await tester.pumpWidget(const HexaIQApp());

    expect(find.text('HexaIQ'), findsOneWidget);
  });

  testWidgets('Onboarding can navigate to profile select', (tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => HexaIQAppState(repository: MockHexaIQRepository()),
        child: MaterialApp(
          home: const OnboardingScreen(),
          onGenerateRoute: AppRouter.onGenerateRoute,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.drag(find.byType(Scrollable).first, const Offset(0, -500));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.arrow_forward), findsOneWidget);
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.account_circle), findsWidgets);
  });
}
