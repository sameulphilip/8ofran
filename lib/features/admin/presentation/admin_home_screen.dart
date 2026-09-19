import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/motion/enter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/home_tile.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../booking/presentation/booking_controller.dart';
import '../../home/presentation/app_drawer.dart';

class AdminHomeScreen extends ConsumerWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider);
    final unread = ref.watch(unreadCountProvider);
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
              AppStrings.adminDesk,
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
              ).enter(context, index: 0),
              HomeTile(
                title: AppStrings.managePriests,
                icon: Icons.groups_outlined,
                background: AppColors.tileAppointments,
                foreground: AppColors.gold700,
                onTap: () => context.push('/admin/priests'),
              ).enter(context, index: 1),
            ],
          ),
        ],
      ),
    );
  }
}
