import 'package:flutter/material.dart';

import '../features/ads/presentation/reward_ad_screen.dart';
import '../features/growth/presentation/growth_dashboard_screen.dart';
import '../features/history/presentation/history_screen.dart';
import '../features/hexaiq/presentation/screens/analysis_loading_screen.dart';
import '../features/hexaiq/presentation/screens/domain_complete_screen.dart';
import '../features/hexaiq/presentation/screens/home_dashboard_screen.dart';
import '../features/hexaiq/presentation/screens/onboarding_screen.dart';
import '../features/hexaiq/presentation/screens/profile_create_screen.dart';
import '../features/hexaiq/presentation/screens/profile_select_screen.dart';
import '../features/hexaiq/presentation/screens/question_screen.dart';
import '../features/hexaiq/presentation/screens/splash_screen.dart';
import '../features/payment/presentation/professional_purchase_screen.dart';
import '../features/payment/presentation/sample_pdf_preview_screen.dart';
import '../features/report/presentation/domain_detail_screen.dart';
import '../features/report/presentation/hexagon_detail_screen.dart';
import '../features/report/presentation/report_summary_screen.dart';
import '../features/settings/presentation/open_source_license_screen.dart';
import '../features/settings/presentation/policy_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../features/settings/presentation/support_contact_screen.dart';
import '../features/test/presentation/test_intro_screen.dart';
import '../features/test/presentation/test_type_select_screen.dart';
import '../features/training/presentation/training_recommendation_screen.dart';
import 'app_routes.dart';

class AppRouter {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    final builder = switch (settings.name) {
      AppRoutes.splash => (_) => const SplashScreen(),
      AppRoutes.onboarding => (_) => const OnboardingScreen(),
      AppRoutes.profileSelect => (_) => const ProfileSelectScreen(),
      AppRoutes.profileCreate => (_) => const ProfileCreateScreen(),
      AppRoutes.home => (_) => const HomeDashboardScreen(),
      AppRoutes.testTypeSelect => (_) => const TestTypeSelectScreen(),
      AppRoutes.testIntro => (_) => const TestIntroScreen(),
      AppRoutes.question => (_) => const QuestionScreen(),
      AppRoutes.domainComplete => (_) => const DomainCompleteScreen(),
      AppRoutes.rewardAd => (_) => const RewardAdScreen(),
      AppRoutes.payment => (_) => const ProfessionalPurchaseScreen(),
      AppRoutes.professionalSampleReport =>
        (_) => const SamplePdfPreviewScreen(),
      AppRoutes.analysisLoading => (_) => const AnalysisLoadingScreen(),
      AppRoutes.reportSummary => (_) => const ReportSummaryScreen(),
      AppRoutes.hexagonDetail => (_) => const HexagonDetailScreen(),
      AppRoutes.domainDetail => (_) => const DomainDetailScreen(),
      AppRoutes.growthDashboard => (_) => const GrowthDashboardScreen(),
      AppRoutes.history => (_) => const HistoryScreen(),
      AppRoutes.trainingRecommendation =>
        (_) => const TrainingRecommendationScreen(),
      AppRoutes.settings => (_) => const SettingsScreen(),
      AppRoutes.privacyPolicy => (_) => const PolicyScreen(
        type: PolicyDocumentType.privacy,
      ),
      AppRoutes.termsOfService => (_) => const PolicyScreen(
        type: PolicyDocumentType.terms,
      ),
      AppRoutes.openSourceLicenses => (_) => const OpenSourceLicenseScreen(),
      AppRoutes.supportContact => (_) => const SupportContactScreen(),
      _ => (_) => const SplashScreen(),
    };

    return MaterialPageRoute<dynamic>(builder: builder, settings: settings);
  }
}
