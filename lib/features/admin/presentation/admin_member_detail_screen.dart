import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/app_nav.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/primary_button.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/domain/app_user.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../care/data/care_repository.dart';
import '../../priests/data/priest_repository.dart';
import '../../priests/domain/priest.dart';
import '../data/admin_repository.dart';
import '../domain/admin_scope.dart';
import '../domain/church.dart';

class AdminMemberDetailScreen extends ConsumerStatefulWidget {
  const AdminMemberDetailScreen({super.key, required this.userId});

  final String userId;

  @override
  ConsumerState<AdminMemberDetailScreen> createState() =>
      _AdminMemberDetailScreenState();
}

class _AdminMemberDetailScreenState
    extends ConsumerState<AdminMemberDetailScreen> {
  bool _busy = false;

  AppUser? _member(List<AppUser> members) {
    for (final user in members) {
      if (user.id == widget.userId) return user;
    }
    return null;
  }

  Future<void> _assignFather(List<Priest> priests, String? currentId) async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          children: [
            Text(
              AppStrings.chooseFather,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            for (final priest in priests)
              if (priest.isBookable(
                findChurch(ref.read(churchesProvider), priest.churchId),
              ))
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(priest.name),
                  subtitle: Text(priest.churchName),
                  trailing: priest.id == currentId
                      ? const Icon(Icons.check, color: AppColors.primary600)
                      : null,
                  onTap: () => Navigator.pop(context, priest.id),
                ),
          ],
        );
      },
    );
    if (selected == null || !mounted) return;
    setState(() => _busy = true);
    try {
      final priest = ref.read(priestRepositoryProvider).byId(selected);
      await ref
          .read(adminRepositoryProvider)
          .assignMemberFather(
            userId: widget.userId,
            fatherId: selected,
            priestUid: priest?.uid,
          );
      ref.invalidate(directoryProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.fatherAssigned)),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _unlinkFather() async {
    setState(() => _busy = true);
    try {
      await ref.read(adminRepositoryProvider).unlinkMemberFather(widget.userId);
      ref.invalidate(directoryProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.fatherUnlinked)),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _toggleSuspend(AppUser member) async {
    setState(() => _busy = true);
    try {
      await ref
          .read(adminRepositoryProvider)
          .setMemberSuspended(member.id, !member.isSuspended);
      ref.invalidate(directoryProvider);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _deleteAccount(AppUser member) async {
    final actor = ref.read(authControllerProvider);
    if (actor?.isSuperAdmin != true) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppStrings.deleteAccountConfirm),
        content: const Text(AppStrings.deleteAccountBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(AppStrings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text(AppStrings.deleteAccount),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _busy = true);
    try {
      await ref
          .read(adminRepositoryProvider)
          .deleteAccount(
            userId: member.id,
            actorId: actor!.id,
            email: member.email,
          );
      ref.invalidate(directoryProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text(AppStrings.accountDeleted)));
      goBack(context);
    } on AuthException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final actor = ref.watch(authControllerProvider);
    final member = _member(ref.watch(scopedMembersProvider));
    final priests = ref.watch(scopedPriestsProvider);
    if (member == null) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            onPressed: () => goBack(context),
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          ),
          title: Text(
            actor?.isSuperAdmin == true
                ? AppStrings.accountDetails
                : AppStrings.memberDetails,
          ),
        ),
        body: const Center(child: Text(AppStrings.emptyMembers)),
      );
    }
    final father = member.hasFather
        ? ref.watch(priestRepositoryProvider).byId(member.fatherId!)
        : null;
    final isMember = member.role == UserRole.member;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: AppStrings.backLabel,
          onPressed: () => goBack(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
        ),
        title: Text(
          actor?.isSuperAdmin == true
              ? AppStrings.accountDetails
              : AppStrings.memberDetails,
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.page,
          AppSpacing.sm,
          AppSpacing.page,
          AppSpacing.xxl,
        ),
        children: [
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.fullName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  member.email,
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 6),
                Text(
                  roleLabelFor(member),
                  style: const TextStyle(
                    color: AppColors.primary700,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  member.isSuspended
                      ? AppStrings.memberSuspended
                      : AppStrings.memberActive,
                  style: TextStyle(
                    color: member.isSuspended
                        ? AppColors.danger700
                        : AppColors.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          if (isMember) ...[
            const SizedBox(height: 12),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    AppStrings.chooseFather,
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    father?.name ?? AppStrings.noFatherAssigned,
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 12),
                  PrimaryButton(
                    label: AppStrings.chooseFather,
                    busy: _busy,
                    onPressed: _busy
                        ? null
                        : () => _assignFather(priests, member.fatherId),
                  ),
                  if (member.hasFather) ...[
                    const SizedBox(height: 8),
                    TonalButton(
                      danger: true,
                      label: AppStrings.unlinkFather,
                      onPressed: _busy ? null : _unlinkFather,
                    ),
                  ],
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          TonalButton(
            danger: !member.isSuspended,
            label: member.isSuspended
                ? AppStrings.unsuspendMember
                : AppStrings.suspendMember,
            onPressed: _busy ? null : () => _toggleSuspend(member),
          ),
          if (actor?.isSuperAdmin == true) ...[
            const SizedBox(height: 12),
            TonalButton(
              danger: true,
              label: AppStrings.deleteAccount,
              onPressed: _busy ? null : () => _deleteAccount(member),
            ),
          ],
        ],
      ),
    );
  }
}
