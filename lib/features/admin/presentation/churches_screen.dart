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
import '../data/admin_repository.dart';

class ChurchesScreen extends ConsumerWidget {
  const ChurchesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final churchesAsync = ref.watch(churchesStreamProvider);
    final churches = churchesAsync.value ?? const [];
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: AppStrings.backLabel,
          onPressed: () => goBack(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
        ),
        title: const Text(AppStrings.churches),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/admin/churches/new'),
        icon: const Icon(Icons.add),
        label: const Text(AppStrings.addChurch),
      ),
      body: churchesAsync.isLoading && churches.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : churches.isEmpty
          ? const Center(
              child: EmptyState(
                title: AppStrings.emptyChurches,
                body: AppStrings.emptyChurchesHint,
                icon: Icons.church_outlined,
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.page,
                AppSpacing.xs,
                AppSpacing.page,
                100,
              ),
              itemCount: churches.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final church = churches[index];
                return AppCard(
                  onTap: () => context.push('/admin/churches/${church.id}'),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.church_outlined,
                        color: AppColors.primary700,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              church.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                            if (church.subtitle.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                church.subtitle,
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 13,
                                ),
                              ),
                            ],
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
