import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';

class ScaffoldWithNav extends StatelessWidget {
  const ScaffoldWithNav({super.key, required this.child});

  final Widget child;

  static const List<({IconData icon, String label, String path})>
  _destinations = <({IconData icon, String label, String path})>[
    (icon: Icons.dashboard_outlined, label: 'Dashboard', path: '/'),
    (icon: Icons.group_outlined, label: 'Gam3as', path: '/gam3as'),
    (icon: Icons.calculate_outlined, label: 'Scenario', path: '/scenario'),
  ];

  int _selectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/gam3as')) {
      return 1;
    }
    if (location.startsWith('/scenario')) {
      return 2;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool isWide = constraints.maxWidth >= 600;
        final int selectedIndex = _selectedIndex(context);

        if (isWide) {
          return Scaffold(
            backgroundColor: AppColors.background,
            body: Row(
              children: <Widget>[
                NavigationRail(
                  backgroundColor: AppColors.surface,
                  selectedIndex: selectedIndex,
                  labelType: NavigationRailLabelType.all,
                  destinations: _destinations
                      .map(
                        (d) => NavigationRailDestination(
                          icon: Icon(d.icon),
                          label: Text(d.label),
                        ),
                      )
                      .toList(),
                  onDestinationSelected: (int i) =>
                      context.go(_destinations[i].path),
                ),
                Expanded(child: child),
              ],
            ),
          );
        }

        return Scaffold(
          backgroundColor: AppColors.background,
          body: child,
          bottomNavigationBar: NavigationBar(
            backgroundColor: AppColors.surface,
            selectedIndex: selectedIndex,
            destinations: _destinations
                .map(
                  (d) =>
                      NavigationDestination(icon: Icon(d.icon), label: d.label),
                )
                .toList(),
            onDestinationSelected: (int i) => context.go(_destinations[i].path),
          ),
        );
      },
    );
  }
}
