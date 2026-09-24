import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/motion/enter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/priest_avatar.dart';
import '../../admin/data/admin_repository.dart';
import '../../admin/domain/admin_scope.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../care/data/care_repository.dart';
import '../data/priest_repository.dart';

class ChooseFatherScreen extends ConsumerStatefulWidget {
  const ChooseFatherScreen({super.key});

  @override
  ConsumerState<ChooseFatherScreen> createState() => _ChooseFatherScreenState();
}

class _ChooseFatherScreenState extends ConsumerState<ChooseFatherScreen> {
  bool _busy = false;

  Future<void> _save(String fatherId) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await ref.read(authControllerProvider.notifier).setFather(fatherId);
      final user = ref.read(authControllerProvider);
      final priest = ref.read(priestRepositoryProvider).byId(fatherId);
      if (user != null) {
        await ref
            .read(careRepositoryProvider)
            .ensureLink(
              userId: user.id,
              priestId: fatherId,
              priestUid: priest?.uid,
            );
      }
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text(AppStrings.fatherSaved)));
        context.go('/home');
      }
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
    final priestsAsync = ref.watch(priestsStreamProvider);
    final priests = bookablePriests(
      priestsAsync.value ?? const [],
      ref.watch(churchesProvider),
    );

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.chooseFather)),
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
                    child: Text(
                      AppStrings.chooseFatherHint,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                    ),
                  );
                }
                final priest = priests[index - 1];
                return AppCard(
                  onTap: _busy ? null : () => _save(priest.id),
                  child: Row(
                    children: [
                      PriestAvatar(name: priest.name, seed: priest.id.hashCode),
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
                      if (_busy)
                        const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      else
                        const Icon(
                          Icons.chevron_left,
                          color: AppColors.textSecondary,
                        ),
                    ],
                  ),
                ).enter(context, index: index);
              },
            ),
    );
  }
}
