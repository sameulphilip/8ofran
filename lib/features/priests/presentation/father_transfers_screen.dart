import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/motion/enter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/app_nav.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/empty_state.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../booking/presentation/booking_controller.dart';
import '../../care/data/care_repository.dart';
import '../data/father_transfer_repository.dart';
import '../data/priest_repository.dart';
import '../domain/father_transfer.dart';

class FatherTransfersScreen extends ConsumerWidget {
  const FatherTransfersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(inboxTransfersProvider);
    final people = ref.watch(directoryProvider).value ?? const {};
    final priests = ref.watch(priestRepositoryProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: AppStrings.backLabel,
          onPressed: () => goBack(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
        ),
        title: const Text(AppStrings.fatherTransfers),
      ),
      body: items.isEmpty
          ? const Center(
              child: EmptyState(
                title: AppStrings.emptyTransfers,
                body: AppStrings.emptyTransfersHint,
                icon: Icons.swap_horiz_rounded,
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.page,
                AppSpacing.sm,
                AppSpacing.page,
                AppSpacing.xxl,
              ),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final item = items[index];
                final person = people[item.userId];
                final from = priests.byId(item.fromPriestId)?.name ?? item.fromPriestId;
                final to = priests.byId(item.toPriestId)?.name ?? item.toPriestId;
                return AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        person?.fullName ?? item.userId,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '$from → $to',
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _roleLabel(ref, item),
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 12),
                      _TransferActions(transfer: item),
                    ],
                  ),
                ).enter(context, index: index);
              },
            ),
    );
  }

  String _roleLabel(WidgetRef ref, FatherTransfer item) {
    final user = ref.watch(authControllerProvider);
    if (user?.isAdmin ?? false) return AppStrings.adminDesk;
    if (user?.priestId == item.fromPriestId) return AppStrings.transferLeave;
    return AppStrings.transferJoin;
  }
}

class _TransferActions extends ConsumerStatefulWidget {
  const _TransferActions({required this.transfer});

  final FatherTransfer transfer;

  @override
  ConsumerState<_TransferActions> createState() => _TransferActionsState();
}

class _TransferActionsState extends ConsumerState<_TransferActions> {
  bool _busy = false;

  Future<void> _respond(bool approve) async {
    final user = ref.read(authControllerProvider);
    setState(() => _busy = true);
    try {
      await ref
          .read(fatherTransferRepositoryProvider)
          .respond(
            transferId: widget.transfer.id,
            actorPriestId: user?.priestId ?? '',
            approve: approve,
            asAdmin: user?.isAdmin ?? false,
          );
      await ref.read(authControllerProvider.notifier).refresh();
      ref.invalidate(fatherTransfersProvider);
      ref.invalidate(flockProvider);
      ref.invalidate(appointmentsStreamProvider);
      ref.invalidate(userNotificationsProvider);
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

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider);
    final waiting = !widget.transfer.needsActionFrom(user?.priestId) &&
        !(user?.isAdmin ?? false);
    if (_busy) {
      return const SizedBox(
        height: 44,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }
    if (waiting) {
      return const Text(
        AppStrings.transferWaitingOther,
        style: TextStyle(color: AppColors.textSecondary),
      );
    }
    return Row(
      children: [
        Expanded(
          child: TonalButton(
            label: AppStrings.transferApprove,
            onPressed: () => _respond(true),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: TonalButton(
            danger: true,
            label: AppStrings.transferReject,
            onPressed: () => _respond(false),
          ),
        ),
      ],
    );
  }
}
