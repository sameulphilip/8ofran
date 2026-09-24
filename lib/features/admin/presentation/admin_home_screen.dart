import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/motion/enter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/home_tile.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../booking/presentation/booking_controller.dart';
import '../../home/presentation/app_drawer.dart';
import '../data/admin_repository.dart';
import '../domain/admin_scope.dart';

class AdminHomeScreen extends ConsumerWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider);
    final unread = ref.watch(unreadCountProvider);
    final stats = ref.watch(adminStatsProvider);
    final churches = ref.watch(scopedChurchesProvider);
    final scopeName = user?.isSteward == true && churches.isNotEmpty
        ? churches.first.name
        : null;

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        leading: Builder(
          builder: (context) => IconButton(
            tooltip: AppStrings.menuLabel,
            onPressed: () => Scaffold.of(context).openDrawer(),
            icon: const Icon(Icons.menu_rounded),
          ),
        ),
        title: Column(
          children: [
            Text(
              '${AppStrings.welcome} ${user?.firstName ?? ''}',
              style: GoogleFonts.cairo(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.text900,
              ),
            ),
            Text(
              scopeName ??
                  (user?.isSuperAdmin == true
                      ? AppStrings.superAdminLabel
                      : AppStrings.adminDesk),
              style: GoogleFonts.cairo(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.text600,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: AppStrings.notifications,
            onPressed: () => context.push('/notifications'),
            icon: Badge(
              isLabelVisible: unread > 0,
              label: unread > 0 ? Text('$unread') : null,
              backgroundColor: AppColors.danger500,
              child: const Icon(Icons.notifications_none_rounded),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          if (stats != null) ...[
            _StatsGrid(stats: stats).enter(context),
            const SizedBox(height: 16),
          ],
          if (user?.isSteward == true)
            AppCard(
              color: AppColors.primary50,
              child: const Text(
                AppStrings.stewardHint,
                style: TextStyle(height: 1.5),
              ),
            ).enter(context, index: 1),
          if (user?.isSteward == true) const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.15,
            children: [
              HomeTile(
                title: AppStrings.churches,
                icon: Icons.church_outlined,
                background: AppColors.tileBook,
                foreground: AppColors.primary700,
                onTap: () => context.push('/admin/churches'),
              ).enter(context, index: 2),
              HomeTile(
                title: AppStrings.managePriests,
                icon: Icons.groups_outlined,
                background: AppColors.tileAppointments,
                foreground: AppColors.gold700,
                onTap: () => context.push('/admin/priests'),
              ).enter(context, index: 3),
              HomeTile(
                title: user?.isSuperAdmin == true
                    ? AppStrings.adminAccounts
                    : AppStrings.adminMembers,
                icon: Icons.people_outline,
                background: AppColors.tilePriests,
                foreground: AppColors.primary700,
                onTap: () => context.push('/admin/members'),
              ).enter(context, index: 4),
              HomeTile(
                title: AppStrings.fatherTransfers,
                icon: Icons.swap_horiz_rounded,
                background: AppColors.warning100,
                foreground: AppColors.primary700,
                onTap: () => context.push('/priest/transfers'),
              ).enter(context, index: 5),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.stats});

  final AdminStats stats;

  @override
  Widget build(BuildContext context) {
    final items = [
      (AppStrings.statMembers, stats.members, Icons.people_outline),
      (AppStrings.statPending, stats.pendingBookings, Icons.hourglass_empty),
      (AppStrings.statToday, stats.todayAppointments, Icons.today_outlined),
      (AppStrings.statPriests, stats.availablePriests, Icons.person_outline),
    ];
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.55,
      children: [
        for (final item in items)
          AppCard(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(item.$3, color: AppColors.primary600, size: 20),
                const Spacer(),
                Text(
                  '${item.$2}',
                  style: GoogleFonts.cairo(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: AppColors.text900,
                  ),
                ),
                Text(
                  item.$1,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
