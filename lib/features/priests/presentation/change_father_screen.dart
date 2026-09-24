import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/motion/enter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/app_nav.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/priest_avatar.dart';
import '../../admin/data/admin_repository.dart';
import '../../admin/domain/admin_scope.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../booking/presentation/booking_controller.dart';
import '../data/father_transfer_repository.dart';
import '../data/priest_repository.dart';
import '../domain/father_transfer.dart';

class ChangeFatherScreen extends ConsumerStatefulWidget {
  const ChangeFatherScreen({super.key});

  @override
  ConsumerState<ChangeFatherScreen> createState() => _ChangeFatherScreenState();
}

class _ChangeFatherScreenState extends ConsumerState<ChangeFatherScreen> {
  bool _busy = false;

  Future<void> _request(String toPriestId) async {
    final user = ref.read(authControllerProvider);
    if (user == null || !user.hasFather) return;
    if (toPriestId == user.fatherId) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text(AppStrings.sameFatherError)));
      return;
    }
    setState(() => _busy = true);
    try {
      await ref
          .read(fatherTransferRepositoryProvider)
          .request(
            userId: user.id,
            fromPriestId: user.fatherId!,
            toPriestId: toPriestId,
          );
      ref.invalidate(fatherTransfersProvider);
      ref.invalidate(userNotificationsProvider);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text(AppStrings.changeFatherSent)));
      }
    } on TransferPendingException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.transferPendingError)),
        );
      }
    } on TransferInvalidException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.sameFatherError)),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _cancel(String transferId) async {
    setState(() => _busy = true);
    try {
      await ref.read(fatherTransferRepositoryProvider).cancel(transferId);
      ref.invalidate(fatherTransfersProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.changeFatherCancelled)),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider);
    final pending = ref.watch(myFatherTransferProvider);
    final priests = bookablePriests(
      ref.watch(priestsStreamProvider).value ?? const [],
      ref.watch(churchesProvider),
    );
    final current = user?.hasFather == true
        ? ref.watch(priestRepositoryProvider).byId(user!.fatherId!)
        : null;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: AppStrings.backLabel,
          onPressed: () => goBack(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
        ),
        title: const Text(AppStrings.changeFather),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.page,
          AppSpacing.sm,
          AppSpacing.page,
          AppSpacing.xxl,
        ),
        children: [
          Text(
            AppStrings.changeFatherHint,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          if (current != null) ...[
            const SizedBox(height: AppSpacing.md),
            AppCard(
              child: Row(
                children: [
                  PriestAvatar(name: current.name, seed: current.id.hashCode),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          AppStrings.currentFather,
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          current.name,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ).enter(context),
          ],
          if (pending != null) ...[
            const SizedBox(height: AppSpacing.md),
            AppCard(
              color: AppColors.warning100,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    AppStrings.changeFatherPending,
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    ref
                            .watch(priestRepositoryProvider)
                            .byId(pending.toPriestId)
                            ?.name ??
                        pending.toPriestId,
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: _busy ? null : () => _cancel(pending.id),
                    child: const Text(AppStrings.transferCancel),
                  ),
                ],
              ),
            ).enter(context, index: 1),
          ],
          const SizedBox(height: AppSpacing.lg),
          if (priests.isEmpty)
            const EmptyState(
              title: AppStrings.noPriests,
              body: AppStrings.bookFromHomeHint,
              icon: Icons.groups_outlined,
            )
          else
            for (final priest in priests)
              if (priest.id != user?.fatherId)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: AppCard(
                    onTap: _busy || pending != null
                        ? null
                        : () => _request(priest.id),
                    child: Row(
                      children: [
                        PriestAvatar(
                          name: priest.name,
                          seed: priest.id.hashCode,
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
                ),
        ],
      ),
    );
  }
}
