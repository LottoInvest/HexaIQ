import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app/app_router.dart';
import 'app/app_routes.dart';
import 'core/theme/app_theme.dart';
import 'features/hexaiq/data/mock_hexaiq_repository.dart';
import 'features/hexaiq/presentation/state/hexaiq_app_state.dart';

void main() {
  runApp(const HexaIQApp());
}

class HexaIQApp extends StatelessWidget {
  const HexaIQApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<MockHexaIQRepository>(create: (_) => MockHexaIQRepository()),
        ChangeNotifierProvider<HexaIQAppState>(
          create: (context) =>
              HexaIQAppState(repository: context.read<MockHexaIQRepository>()),
        ),
      ],
      child: MaterialApp(
        title: 'HexaIQ',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        initialRoute: AppRoutes.splash,
        onGenerateRoute: AppRouter.onGenerateRoute,
      ),
    );
  }
}
