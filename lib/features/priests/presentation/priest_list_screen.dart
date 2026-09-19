import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/motion/enter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/app_nav.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/booking_stepper.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/priest_avatar.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../booking/presentation/booking_controller.dart';
import '../../booking/presentation/booking_nav.dart';
import '../data/priest_repository.dart';

class PriestListScreen extends ConsumerWidget {
  const PriestListScreen({super.key, this.rescheduleId});

  final String? rescheduleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider);
    if (user?.hasFather == true) {
      final priest = ref.watch(priestRepositoryProvider).byId(user!.fatherId!);
      final loading = ref.watch(priestsStreamProvider).isLoading;
      if (priest == null && loading) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      if (priest != null && priest.isAvailable) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!context.mounted) return;
          openMemberBooking(
            context,
            ref,
            rescheduleId: rescheduleId,
            replace: true,
          );
        });
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
    }

    final priestsAsync = ref.watch(priestsStreamProvider);
    final priests = (priestsAsync.value ?? const [])
        .where((priest) => priest.isAvailable)
        .toList();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: AppStrings.backLabel,
          onPressed: () => goBack(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
        ),
        title: const Text(AppStrings.bookConfession),
        actions: const [
          Padding(
            padding: EdgeInsetsDirectional.only(end: AppSpacing.md),
            child: BookingStepper(step: 1),
          ),
        ],
      ),
      body: priestsAsync.isLoading && priests.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : priests.isEmpty
          ? const Center(
              child: EmptyState(
                title: AppStrings.noPriests,
                body: AppStrings.bookFromHomeHint,
                icon: Icons.groups_outlined,
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.page,
                AppSpacing.xs,
                AppSpacing.page,
                AppSpacing.xl,
              ),
              itemCount: priests.length + 1,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppStrings.choosePriest,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          AppStrings.choosePriestHint,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: AppColors.textSecondary,
                                height: 1.5,
                              ),
                        ),
                      ],
                    ),
                  );
                }
                final priest = priests[index - 1];
                return AppCard(
                  key: ValueKey(priest.id),
                  onTap: priest.isAvailable
                      ? () {
                          ref
                              .read(bookingControllerProvider.notifier)
                              .start(
                                priest: priest,
                                rescheduleId: rescheduleId,
                              );
                          context.push('/booking/slot');
                        }
                      : null,
                  child: Opacity(
                    opacity: priest.isAvailable ? 1 : 0.55,
                    child: Row(
                      children: [
                        PriestAvatar(
                          name: priest.name,
                          seed: priest.id.hashCode,
                          heroTag: 'priest-${priest.id}',
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                priest.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                priest.churchName.isEmpty
                                    ? AppStrings.priestRole
                                    : priest.churchName,
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.chevron_left,
                          color: AppColors.textSecondary,
                        ),
                      ],
                    ),
                  ),
                ).enter(context, index: index);
              },
            ),
    );
  }
}
