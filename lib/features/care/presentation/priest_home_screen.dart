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
import '../../priests/data/father_transfer_repository.dart';
import '../data/care_repository.dart';
import '../domain/pastoral_care.dart';
import '../../home/presentation/app_drawer.dart';
import 'reject_reason_sheet.dart';

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
    final inbox = ref.watch(inboxTransfersProvider);
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
          AppCard(
            onTap: () => context.push('/priest/transfers'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.fatherTransfers,
                  style: GoogleFonts.cairo(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Text(
                  inbox.isEmpty
                      ? AppStrings.emptyTransfers
                      : '${inbox.length}',
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
          ).enter(context, index: 3),
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
              ).enter(context, index: 4),
              HomeTile(
                title: AppStrings.flock,
                icon: Icons.groups_outlined,
                background: AppColors.tilePriests,
                foreground: AppColors.primary700,
                onTap: () => context.push('/priest/flock'),
              ).enter(context, index: 5),
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
                      if (item.canComplete) ...[
                        const SizedBox(height: 12),
                        _CompleteVisitButton(appointment: item),
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
    return const _FlockList(
      title: AppStrings.overdueList,
      initialFilter: FlockFilter.overdue,
    );
  }
}

class PriestFlockScreen extends ConsumerWidget {
  const PriestFlockScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const _FlockList(title: AppStrings.flock);
  }
}

class _FlockList extends ConsumerStatefulWidget {
  const _FlockList({
    required this.title,
    this.initialFilter = FlockFilter.all,
  });

  final String title;
  final FlockFilter initialFilter;

  @override
  ConsumerState<_FlockList> createState() => _FlockListState();
}

class _FlockListState extends ConsumerState<_FlockList> {
  late FlockFilter _filter = widget.initialFilter;

  @override
  Widget build(BuildContext context) {
    final appointments = ref.watch(allAppointmentsProvider);
    final people = ref.watch(directoryProvider).value ?? const {};
    final canons = ref.watch(flockCanonsProvider).value ?? const {};
    final transfers = ref.watch(inboxTransfersProvider);
    final now = DateTime.now();
    final flock = [
      for (final care in ref.watch(flockProvider).value ?? const [])
        if (matchesFlockFilter(
          filter: _filter,
          care: care,
          now: now,
          last: lastVisitFor(
            userId: care.userId,
            priestId: care.priestId,
            appointments: appointments,
          ),
        ))
          care,
    ];

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
        ),
        title: Text(widget.title),
      ),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
            child: Row(
              children: [
                for (final filter in FlockFilter.values) ...[
                  ChoiceChip(
                    label: Text(_filterLabel(filter)),
                    selected: _filter == filter,
                    onSelected: (_) => setState(() => _filter = filter),
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
          Expanded(
            child: flock.isEmpty
                ? Center(
                    child: EmptyState(
                      title: _filter == FlockFilter.overdue
                          ? AppStrings.emptyOverdue
                          : AppStrings.emptyFlockFilter,
                      body: AppStrings.choosePerson,
                      icon: Icons.groups_outlined,
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
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
                      final pendingCount = appointments
                          .where(
                            (item) =>
                                item.userId == care.userId && item.isPending,
                          )
                          .length;
                      final rule = canons[care.userId]?.rule ?? '';
                      final moving = transfers.any(
                        (item) => item.userId == care.userId,
                      );
                      return AppCard(
                        onTap: () => context.push('/care/${care.userId}'),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              person?.fullName ?? care.userId,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${AppStrings.lastVisitLabel}: ${AppStrings.daysSinceVisit(care.daysSince(now, last))}',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            Text(
                              AppStrings.everyNDays(care.intervalDays),
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            if (pendingCount > 0)
                              Text(
                                '${AppStrings.pendingBookingsLabel}: $pendingCount',
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            if (rule.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                '${AppStrings.currentRuleLabel}: ${rule.length > 48 ? '${rule.substring(0, 48)}…' : rule}',
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                            if (moving) ...[
                              const SizedBox(height: 6),
                              const Text(
                                AppStrings.changeFatherPending,
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                            ],
                          ],
                        ),
                      ).enter(context, index: index);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  String _filterLabel(FlockFilter filter) {
    return switch (filter) {
      FlockFilter.all => AppStrings.flockAll,
      FlockFilter.fresh => AppStrings.flockFresh,
      FlockFilter.regular => AppStrings.flockRegular,
      FlockFilter.overdue => AppStrings.overdueList,
    };
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
    var reason = '';
    if (!approve) {
      final picked = await pickRejectReason(context);
      if (picked == null || picked.isEmpty) return;
      reason = picked;
    }
    setState(() => _busy = true);
    try {
      await ref
          .read(appointmentRepositoryProvider)
          .respond(
            appointmentId: widget.appointment.id,
            approve: approve,
            rejectReason: reason,
          );
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

class _CompleteVisitButton extends ConsumerStatefulWidget {
  const _CompleteVisitButton({required this.appointment});

  final Appointment appointment;

  @override
  ConsumerState<_CompleteVisitButton> createState() =>
      _CompleteVisitButtonState();
}

class _CompleteVisitButtonState extends ConsumerState<_CompleteVisitButton> {
  bool _busy = false;

  Future<void> _complete() async {
    setState(() => _busy = true);
    try {
      await ref
          .read(appointmentRepositoryProvider)
          .complete(widget.appointment.id);
      ref.invalidate(appointmentsStreamProvider);
      ref.invalidate(userNotificationsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.visitCompleted)),
        );
      }
    } on CompleteWindowException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.completeTooEarly)),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return TonalButton(
      label: AppStrings.markCompleted,
      icon: Icons.check_circle_outline,
      onPressed: _busy ? null : _complete,
    );
  }
}
