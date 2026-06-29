import 'package:flutter/material.dart';

import '../../../../app/app_routes.dart';

void handleDashboardDestination(BuildContext context, int index) {
  final route = switch (index) {
    0 => AppRoutes.home,
    1 => AppRoutes.growthDashboard,
    2 => AppRoutes.trainingRecommendation,
    3 => AppRoutes.settings,
    _ => AppRoutes.home,
  };
  Navigator.of(context).pushReplacementNamed(route);
}
