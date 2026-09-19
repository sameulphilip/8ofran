import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/motion/enter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_formatters.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/home_tile.dart';
import '../../appointments/data/appointment_repository.dart';
import '../../appointments/domain/appointment.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../booking/presentation/booking_controller.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/status_badge.dart';
import '../data/care_repository.dart';
import '../domain/pastoral_care.dart';
import '../../home/presentation/app_drawer.dart';

class PriestHomeScreen extends ConsumerWidget {
  const PriestHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider);
    final unread = ref.watch(unreadCountProvider);
    final priestId = user?.priestId;
    final appointments = [
      for (final item in ref.watch(allAppointmentsProvider))
        if (priestId != null && item.priestId == priestId) item,
    ]..sort((a, b) => a.startsAt.compareTo(b.startsAt));
    final upcoming = [
      for (final item in appointments)
        if (item.isUpcoming && item.status == AppointmentStatus.confirmed) item,
    ];
    final pending = [
      for (final item in appointments)
        if (item.isUpcoming && item.isPending) item,
    ];
    final flock = ref.watch(flockProvider).value ?? const [];
    final overdue = [
      for (final care in flock)
        if (care.isOverdue(
          DateTime.now(),
          lastVisitFor(
            userId: care.userId,
            priestId: care.priestId,
            appointments: appointments,
          ),
        ))
          care,
    ];

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
              AppStrings.priestDesk,
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
          AppCard(
            onTap: () => context.push('/priest/schedule'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.bookingRequests,
                  style: GoogleFonts.cairo(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Text(
                  pending.isEmpty
                      ? AppStrings.emptyRequests
                      : '${pending.length} · ${DateFormatters.longDate(pending.first.startsAt)}',
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
          ).enter(context),
          const SizedBox(height: 12),
          AppCard(
            onTap: () => context.push('/priest/schedule'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.confessionSchedule,
                  style: GoogleFonts.cairo(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Text(
                  upcoming.isEmpty
                      ? AppStrings.emptySchedule
                      : '${upcoming.length} · ${DateFormatters.longDate(upcoming.first.startsAt)}',
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
          ).enter(context, index: 1),
          const SizedBox(height: 12),
          AppCard(
            color: overdue.isEmpty ? AppColors.surface : AppColors.warning100,
            onTap: () => context.push('/priest/overdue'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.overdueList,
                  style: GoogleFonts.cairo(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Text(
                  overdue.isEmpty
                      ? AppStrings.emptyOverdue
                      : '${overdue.length}',
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
          ).enter(context, index: 2),
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
                title: AppStrings.confessionSchedule,
                icon: Icons.calendar_view_week_outlined,
                background: AppColors.tileBook,
                foreground: AppColors.primary700,
                onTap: () => context.push('/priest/schedule'),
              ).enter(context, index: 3),
              HomeTile(
                title: AppStrings.flock,
                icon: Icons.groups_outlined,
                background: AppColors.tilePriests,
                foreground: AppColors.primary700,
                onTap: () => context.push('/priest/flock'),
              ).enter(context, index: 4),
            ],
          ),
        ],
      ),
    );
  }
}

class PriestScheduleScreen extends ConsumerWidget {
  const PriestScheduleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider);
    final priestId = user?.priestId;
    final people = ref.watch(directoryProvider).value ?? const {};
    final items = [
      for (final item in ref.watch(allAppointmentsProvider))
        if (priestId != null && item.priestId == priestId && item.isActive)
          item,
    ]..sort((a, b) => a.startsAt.compareTo(b.startsAt));

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
        ),
        title: const Text(AppStrings.confessionSchedule),
      ),
      body: items.isEmpty
          ? const Center(
              child: EmptyState(
                title: AppStrings.emptySchedule,
                body: AppStrings.bookFromHomeHint,
                icon: Icons.event_available_outlined,
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final item = items[index];
                final person = people[item.userId];
                return AppCard(
                  onTap: item.isPending
                      ? null
                      : () => context.push('/care/${item.userId}'),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  person?.fullName ?? item.userId,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '${DateFormatters.longDate(item.startsAt)} · ${DateFormatters.time(item.startsAt)}',
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          StatusBadge(status: item.status),
                        ],
                      ),
                      if (item.isPending) ...[
                        const SizedBox(height: 12),
                        _RequestActions(appointment: item),
                      ],
                    ],
                  ),
                ).enter(context, index: index);
              },
            ),
    );
  }
}

class PriestOverdueScreen extends ConsumerWidget {
  const PriestOverdueScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _FlockList(title: AppStrings.overdueList, overdueOnly: true);
  }
}

class PriestFlockScreen extends ConsumerWidget {
  const PriestFlockScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const _FlockList(title: AppStrings.flock, overdueOnly: false);
  }
}

class _FlockList extends ConsumerWidget {
  const _FlockList({required this.title, required this.overdueOnly});

  final String title;
  final bool overdueOnly;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appointments = ref.watch(allAppointmentsProvider);
    final people = ref.watch(directoryProvider).value ?? const {};
    var flock = ref.watch(flockProvider).value ?? const [];
    if (overdueOnly) {
      flock = [
        for (final care in flock)
          if (care.isOverdue(
            DateTime.now(),
            lastVisitFor(
              userId: care.userId,
              priestId: care.priestId,
              appointments: appointments,
            ),
          ))
            care,
      ];
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
        ),
        title: Text(title),
      ),
      body: flock.isEmpty
          ? Center(
              child: EmptyState(
                title: overdueOnly ? AppStrings.emptyOverdue : AppStrings.flock,
                body: AppStrings.choosePerson,
                icon: Icons.groups_outlined,
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
              itemCount: flock.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final care = flock[index];
                final last = lastVisitFor(
                  userId: care.userId,
                  priestId: care.priestId,
                  appointments: appointments,
                );
                final person = people[care.userId];
                return AppCard(
                  onTap: () => context.push('/care/${care.userId}'),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        person?.fullName ?? care.userId,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${AppStrings.lastVisitLabel}: ${AppStrings.daysSinceVisit(care.daysSince(DateTime.now(), last))}',
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                      Text(
                        AppStrings.everyNDays(care.intervalDays),
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ).enter(context, index: index);
              },
            ),
    );
  }
}

class _RequestActions extends ConsumerStatefulWidget {
  const _RequestActions({required this.appointment});

  final Appointment appointment;

  @override
  ConsumerState<_RequestActions> createState() => _RequestActionsState();
}

class _RequestActionsState extends ConsumerState<_RequestActions> {
  bool _busy = false;

  Future<void> _respond(bool approve) async {
    setState(() => _busy = true);
    try {
      await ref
          .read(appointmentRepositoryProvider)
          .respond(appointmentId: widget.appointment.id, approve: approve);
      ref.invalidate(appointmentsStreamProvider);
      ref.invalidate(userNotificationsProvider);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_busy) {
      return const SizedBox(
        height: 44,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }
    return Row(
      children: [
        Expanded(
          child: TonalButton(
            label: AppStrings.approveRequest,
            onPressed: () => _respond(true),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: TonalButton(
            danger: true,
            label: AppStrings.rejectRequest,
            onPressed: () => _respond(false),
          ),
        ),
      ],
    );
  }
}
