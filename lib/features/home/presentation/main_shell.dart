import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';

class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      extendBody: true,
      body: navigationShell,
      bottomNavigationBar: Padding(
        padding: EdgeInsets.fromLTRB(16, 0, 16, 10 + bottom),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.08),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: NavigationBar(
              selectedIndex: navigationShell.currentIndex,
              onDestinationSelected: (index) {
                navigationShell.goBranch(
                  index,
                  initialLocation: index == navigationShell.currentIndex,
                );
              },
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home_rounded),
                  label: AppStrings.home,
                ),
                NavigationDestination(
                  icon: Icon(Icons.edit_calendar_outlined),
                  selectedIcon: Icon(Icons.edit_calendar_rounded),
                  label: AppStrings.bookTab,
                ),
                NavigationDestination(
                  icon: Icon(Icons.event_available_outlined),
                  selectedIcon: Icon(Icons.event_available_rounded),
                  label: AppStrings.myAppointments,
                ),
                NavigationDestination(
                  icon: Icon(Icons.more_horiz_rounded),
                  selectedIcon: Icon(Icons.more_horiz_rounded),
                  label: AppStrings.moreTab,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
