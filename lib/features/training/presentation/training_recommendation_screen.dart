import 'package:flutter/material.dart';

import '../../../core/responsive/responsive_page.dart';
import '../../hexaiq/domain/hexaiq_models.dart';
import '../../hexaiq/presentation/widgets/dashboard_nav.dart';

class TrainingRecommendationScreen extends StatelessWidget {
  const TrainingRecommendationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ResponsivePage(
      title: '추천 훈련',
      currentIndex: 2,
      onDestinationSelected: (index) =>
          handleDashboardDestination(context, index),
      child: ListView(
        children: [
          for (final info in domainCatalog)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.checklist,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            info.label,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 6),
                          Text('${info.description}. 하루 10분, 5문항 단위로 반복하세요.'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
