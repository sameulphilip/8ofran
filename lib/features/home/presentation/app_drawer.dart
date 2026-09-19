import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/motion/enter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/brand_logo.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../booking/presentation/booking_controller.dart';
import '../../booking/presentation/booking_nav.dart';

class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(unreadCountProvider);
    final width = MediaQuery.sizeOf(context).width * 0.82;

    return Drawer(
      width: width,
      backgroundColor: AppColors.primary900,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            children: [
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: IconButton(
                  tooltip: AppStrings.cancel,
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.white),
                ),
              ),
              const BrandLogo(height: 92),
              const SizedBox(height: 10),
              Text(
                AppStrings.appName,
                style: GoogleFonts.cairo(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                AppStrings.tagline,
                textAlign: TextAlign.center,
                style: GoogleFonts.cairo(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 28),
              Expanded(
                child: ListView(
                  children: [
                    _item(
                      context,
                      0,
                      Icons.home_outlined,
                      AppStrings.home,
                      '/home',
                    ),
                    if (ref.watch(authControllerProvider)?.isAdmin ??
                        false) ...[
                      _item(
                        context,
                        1,
                        Icons.church_outlined,
                        AppStrings.churches,
                        '/admin/churches',
                      ),
                      _item(
                        context,
                        2,
                        Icons.groups_outlined,
                        AppStrings.managePriests,
                        '/admin/priests',
                      ),
                    ] else if (ref.watch(authControllerProvider)?.isPriest ??
                        false) ...[
                      _item(
                        context,
                        1,
                        Icons.calendar_view_week_outlined,
                        AppStrings.confessionSchedule,
                        '/priest/schedule',
                      ),
                      _item(
                        context,
                        2,
                        Icons.hourglass_empty_rounded,
                        AppStrings.overdueList,
                        '/priest/overdue',
                      ),
                      _item(
                        context,
                        3,
                        Icons.groups_outlined,
                        AppStrings.flock,
                        '/priest/flock',
                      ),
                    ] else ...[
                      _item(
                        context,
                        1,
                        Icons.edit_calendar_outlined,
                        AppStrings.bookConfession,
                        null,
                        onTap: () {
                          Navigator.pop(context);
                          openMemberBooking(context, ref);
                        },
                      ),
                      _item(
                        context,
                        2,
                        Icons.event_available_outlined,
                        AppStrings.upcomingAppointments,
                        '/appointments',
                      ),
                      _item(
                        context,
                        3,
                        Icons.auto_stories_outlined,
                        AppStrings.spiritualRule,
                        '/rule',
                      ),
                      _item(
                        context,
                        4,
                        Icons.menu_book_outlined,
                        AppStrings.infoAndGuides,
                        '/info',
                      ),
                    ],
                    _item(
                      context,
                      5,
                      Icons.notifications_none_rounded,
                      AppStrings.notifications,
                      '/notifications',
                      badge: unread,
                    ),
                    _item(
                      context,
                      6,
                      Icons.chat_bubble_outline_rounded,
                      AppStrings.contactUs,
                      '/contact',
                    ),
                    _item(
                      context,
                      7,
                      Icons.settings_outlined,
                      AppStrings.settings,
                      '/settings',
                    ),
                    const Divider(color: Colors.white24, height: 28),
                    _item(
                      context,
                      8,
                      Icons.logout_rounded,
                      AppStrings.logout,
                      null,
                      onTap: () => _logout(context, ref),
                    ),
                  ],
                ),
              ),
              Text(
                'v0.1.0',
                style: GoogleFonts.cairo(
                  color: Colors.white.withValues(alpha: 0.45),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _item(
    BuildContext context,
    int index,
    IconData icon,
    String label,
    String? route, {
    int badge = 0,
    VoidCallback? onTap,
  }) {
    final location = GoRouterState.of(context).uri.path;
    final active = route != null && location == route;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: active
            ? Colors.white.withValues(alpha: 0.10)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: ListTile(
          onTap:
              onTap ??
              () {
                Navigator.pop(context);
                if (route != null) context.go(route);
              },
          leading: Icon(
            icon,
            color: Colors.white.withValues(alpha: 0.88),
            size: 22,
          ),
          title: Text(
            label,
            style: GoogleFonts.cairo(
              color: Colors.white.withValues(alpha: active ? 1 : 0.88),
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          trailing: badge > 0
              ? Container(
                  width: 22,
                  height: 22,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: AppColors.danger500,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '$badge',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                )
              : null,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
        ),
      ),
    ).enter(context, index: index);
  }

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppStrings.logoutConfirm),
        content: const Text(AppStrings.logoutBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(AppStrings.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(AppStrings.logout),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      Navigator.pop(context);
      await ref.read(authControllerProvider.notifier).logout();
    }
  }
}
