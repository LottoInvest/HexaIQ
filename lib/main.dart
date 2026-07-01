import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app/app_router.dart';
import 'app/app_routes.dart';
import 'core/persistence/hexa_iq_database.dart';
import 'core/persistence/settings_repository.dart';
import 'core/theme/app_theme.dart';
import 'features/calibration/data/sqlite_calibration_repository.dart';
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
        Provider<HexaIQDatabase>(create: (_) => HexaIQDatabase()),
        Provider<SQLiteCalibrationRepository>(
          create: (context) =>
              SQLiteCalibrationRepository(context.read<HexaIQDatabase>()),
        ),
        Provider<SQLiteSettingsRepository>(
          create: (context) =>
              SQLiteSettingsRepository(context.read<HexaIQDatabase>()),
        ),
        Provider<MockHexaIQRepository>(
          create: (context) =>
              MockHexaIQRepository(database: context.read<HexaIQDatabase>()),
        ),
        ChangeNotifierProvider<HexaIQAppState>(
          create: (context) => HexaIQAppState(
            repository: context.read<MockHexaIQRepository>(),
            calibrationRepository: context.read<SQLiteCalibrationRepository>(),
            settingsRepository: context.read<SQLiteSettingsRepository>(),
          ),
        ),
      ],
      child: Consumer<HexaIQAppState>(
        builder: (context, state, _) {
          return MaterialApp(
            title: 'HexaIQ',
            debugShowCheckedModeBanner: false,
            themeMode: state.themeMode,
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            initialRoute: AppRoutes.splash,
            onGenerateRoute: AppRouter.onGenerateRoute,
          );
        },
      ),
    );
  }
}
