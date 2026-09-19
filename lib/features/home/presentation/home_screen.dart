import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/motion/enter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_formatters.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/home_tile.dart';
import '../../../core/widgets/priest_avatar.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../core/widgets/verse_banner.dart';
import '../../admin/presentation/admin_home_screen.dart';
import '../../appointments/domain/appointment.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../booking/presentation/booking_controller.dart';
import '../../booking/presentation/booking_nav.dart';
import '../../priests/data/priest_repository.dart';
import '../../care/data/care_repository.dart';
import '../../care/presentation/priest_home_screen.dart';
import 'app_drawer.dart';
import 'verse_of_day.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider);
    if (user?.isAdmin ?? false) {
      return const AdminHomeScreen();
    }
    if (user?.isPriest ?? false) {
      return const PriestHomeScreen();
    }
    ref.watch(reminderSyncProvider);
    final unread = ref.watch(unreadCountProvider);
    final appointments = ref.watch(userAppointmentsProvider);
    final next = appointments.cast<Appointment?>().firstWhere(
      (a) => a!.isUpcoming,
      orElse: () => null,
    );
    final priest = next == null
        ? null
        : ref.watch(priestRepositoryProvider).byId(next.priestId);
    final canon = ref.watch(myCanonProvider).value;
    final verse = VerseOfDay.today();
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
              '${AppStrings.welcome} ${user?.firstName ?? ''} 👋',
              style: GoogleFonts.cairo(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.text900,
              ),
            ),
            Text(
              AppStrings.peaceGreeting,
              style: GoogleFonts.cairo(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.text600,
              ),
            ),
          ],
        ),
        actions: [
          Semantics(
            button: true,
            label: unread > 0
                ? 'الإشعارات، $unread غير مقروء'
                : AppStrings.notifications,
            child: IconButton(
              tooltip: AppStrings.notifications,
              onPressed: () => context.push('/notifications'),
              icon: Badge(
                isLabelVisible: unread > 0,
                label: unread > 0 ? Text('$unread') : null,
                backgroundColor: AppColors.danger500,
                child: const Icon(Icons.notifications_none_rounded),
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          if (next != null && priest != null)
            AppCard(
              onTap: () => context.push('/appointment/${next.id}'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        AppStrings.lastAppointment,
                        style: GoogleFonts.cairo(
                          fontWeight: FontWeight.w700,
                          color: AppColors.text900,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        AppStrings.viewAll,
                        style: GoogleFonts.cairo(
                          color: AppColors.primary600,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      PriestAvatar(name: priest.name, seed: priest.id.hashCode),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppStrings.withPriest(priest.name),
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              DateFormatters.longDate(next.startsAt),
                              style: const TextStyle(
                                color: AppColors.text600,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              DateFormatters.time(next.startsAt),
                              style: const TextStyle(
                                color: AppColors.text600,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 8),
                            StatusBadge(status: next.status),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_left, color: AppColors.text500),
                    ],
                  ),
                ],
              ),
            ).enter(context)
          else
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.emptyNextInvite,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  TonalButton(
                    label: AppStrings.emptyUpcomingAction,
                    onPressed: () => openMemberBooking(context, ref),
                  ),
                ],
              ),
            ).enter(context),
          if (canon != null) ...[
            const SizedBox(height: 12),
            AppCard(
              color: AppColors.gold100,
              onTap: () => context.push('/rule'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.spiritualRule,
                    style: GoogleFonts.cairo(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    canon.rule,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(height: 1.5),
                  ),
                ],
              ),
            ).enter(context, index: 1),
          ],
          const SizedBox(height: 12),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.45,
            children: [
              HomeTile(
                title: AppStrings.tileBook,
                icon: Icons.calendar_month_outlined,
                background: AppColors.tileBook,
                foreground: AppColors.primary700,
                onTap: () => openMemberBooking(context, ref),
              ).enter(context, index: 1),
              HomeTile(
                title: AppStrings.tileAppointments,
                icon: Icons.event_available_outlined,
                background: AppColors.tileAppointments,
                foreground: AppColors.text900,
                onTap: () => context.push('/appointments'),
              ).enter(context, index: 2),
              HomeTile(
                title: AppStrings.tileRule,
                icon: Icons.auto_stories_outlined,
                background: AppColors.gold100,
                foreground: AppColors.gold700,
                onTap: () => context.push('/rule'),
              ).enter(context, index: 3),
              HomeTile(
                title: AppStrings.tileInfo,
                icon: Icons.menu_book_outlined,
                background: AppColors.tileInfo,
                foreground: AppColors.success700,
                onTap: () => context.push('/info'),
              ).enter(context, index: 4),
            ],
          ),
          const SizedBox(height: 12),
          VerseBanner(
            text: verse.text,
            reference: verse.reference,
          ).enter(context, index: 5),
        ],
      ),
    );
  }
}
