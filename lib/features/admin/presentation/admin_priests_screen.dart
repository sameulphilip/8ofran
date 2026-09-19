import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/motion/enter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/app_nav.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/priest_avatar.dart';
import '../../priests/data/priest_repository.dart';

class AdminPriestsScreen extends ConsumerWidget {
  const AdminPriestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final priestsAsync = ref.watch(priestsStreamProvider);
    final priests = priestsAsync.value ?? const [];
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: AppStrings.backLabel,
          onPressed: () => goBack(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
        ),
        title: const Text(AppStrings.managePriests),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/admin/priests/new'),
        icon: const Icon(Icons.add),
        label: const Text(AppStrings.addPriest),
      ),
      body: priestsAsync.isLoading && priests.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : priests.isEmpty
          ? const Center(
              child: EmptyState(
                title: AppStrings.emptyAdminPriests,
                body: AppStrings.emptyAdminPriestsHint,
                icon: Icons.groups_outlined,
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.page,
                AppSpacing.xs,
                AppSpacing.page,
                100,
              ),
              itemCount: priests.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final priest = priests[index];
                final status = !priest.isAvailable
                    ? AppStrings.hiddenFromBooking
                    : priest.hasAccount
                    ? AppStrings.accountLinked
                    : AppStrings.noAccountYet;
                return AppCard(
                  onTap: () => context.push('/admin/priests/${priest.id}'),
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
                              [
                                if (priest.churchName.isNotEmpty)
                                  priest.churchName,
                                status,
                              ].join(' · '),
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
                ).enter(context, index: index);
              },
            ),
    );
  }
}
