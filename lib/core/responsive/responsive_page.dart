import 'package:flutter/material.dart';

import 'layout_breakpoints.dart';

class ResponsivePage extends StatelessWidget {
  const ResponsivePage({
    required this.title,
    required this.child,
    this.actions = const [],
    this.currentIndex,
    this.onDestinationSelected,
    super.key,
  });

  final String title;
  final Widget child;
  final List<Widget> actions;
  final int? currentIndex;
  final ValueChanged<int>? onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenClass = LayoutBreakpoints.classify(constraints.maxWidth);
        final useRail = screenClass == ScreenClass.expanded;
        final content = SafeArea(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1160),
            child: Padding(
              padding: EdgeInsets.all(useRail ? 24 : 16),
              child: child,
            ),
          ),
        );

        return Scaffold(
          appBar: AppBar(title: Text(title), actions: actions),
          body: useRail
              ? Row(
                  children: [
                    NavigationRail(
                      selectedIndex: currentIndex,
                      onDestinationSelected: onDestinationSelected,
                      labelType: NavigationRailLabelType.all,
                      destinations: const [
                        NavigationRailDestination(
                          icon: Icon(Icons.home_outlined),
                          selectedIcon: Icon(Icons.home),
                          label: Text('홈'),
                        ),
                        NavigationRailDestination(
                          icon: Icon(Icons.show_chart_outlined),
                          selectedIcon: Icon(Icons.show_chart),
                          label: Text('성장'),
                        ),
                        NavigationRailDestination(
                          icon: Icon(Icons.fitness_center_outlined),
                          selectedIcon: Icon(Icons.fitness_center),
                          label: Text('훈련'),
                        ),
                        NavigationRailDestination(
                          icon: Icon(Icons.settings_outlined),
                          selectedIcon: Icon(Icons.settings),
                          label: Text('설정'),
                        ),
                      ],
                    ),
                    const VerticalDivider(width: 1),
                    Expanded(child: Center(child: content)),
                  ],
                )
              : Center(child: content),
          bottomNavigationBar: useRail || currentIndex == null
              ? null
              : NavigationBar(
                  selectedIndex: currentIndex!,
                  onDestinationSelected: onDestinationSelected,
                  destinations: const [
                    NavigationDestination(
                      icon: Icon(Icons.home_outlined),
                      selectedIcon: Icon(Icons.home),
                      label: '홈',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.show_chart_outlined),
                      selectedIcon: Icon(Icons.show_chart),
                      label: '성장',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.fitness_center_outlined),
                      selectedIcon: Icon(Icons.fitness_center),
                      label: '훈련',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.settings_outlined),
                      selectedIcon: Icon(Icons.settings),
                      label: '설정',
                    ),
                  ],
                ),
        );
      },
    );
  }
}
