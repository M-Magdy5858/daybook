import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navShell});

  final StatefulNavigationShell navShell;

  static const compactBreakpoint = 600.0;

  void _onSelectedIndexChanged (int index) {
    navShell.goBranch(
      index,
      initialLocation: index == navShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final destinations = [
      (
        icon: Icons.dashboard_outlined,
        selected: Icons.dashboard,
        label: 'dashboard',
      ),
      (icon: Icons.task_alt_outlined, selected: Icons.task_alt, label: 'tasks'),
      (
        icon: Icons.task_alt_outlined,
        selected: Icons.task_alt,
        label: 'calendar',
      ),
      (
        icon: Icons.task_alt_outlined,
        selected: Icons.task_alt,
        label: 'habits',
      ),
      (icon: Icons.task_alt_outlined, selected: Icons.task_alt, label: 'more'),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < compactBreakpoint) {
          return Scaffold(
            body: navShell,
            bottomNavigationBar: NavigationBar(
              selectedIndex: navShell.currentIndex,
              onDestinationSelected: (index) => navShell.goBranch(
                index,
                initialLocation: index == navShell.currentIndex,
              ),
              destinations: destinations
                  .map(
                    (d) => NavigationDestination(
                      icon: Icon(d.icon),
                      selectedIcon: Icon(d.selected),
                      label: d.label,
                    ),
                  )
                  .toList(),
            ),
          );
        } else {
          return Scaffold(
            body: Row(
              children: [
                NavigationRail(
                  selectedIndex: navShell.currentIndex,
                  onDestinationSelected: _onSelectedIndexChanged,
                  labelType: NavigationRailLabelType.selected,
                  destinations: destinations
                      .map(
                        (d) => NavigationRailDestination(
                          icon: Icon(d.icon),
                          selectedIcon: Icon(d.selected),
                          label: Text(d.label),
                        ),
                      )
                      .toList(),
                ),
                const VerticalDivider(thickness: 1, width: 1),
                Expanded(child: navShell),
              ],
            ),
          );
        }
      },
    );
  }
}
