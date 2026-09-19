import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/motion/enter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_nav.dart';
import '../../../core/utils/date_formatters.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/empty_state.dart';
import '../../auth/presentation/auth_controller.dart';
import '../data/care_repository.dart';

class SpiritualRuleScreen extends ConsumerWidget {
  const SpiritualRuleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canon = ref.watch(myCanonProvider).value;
    final user = ref.watch(authControllerProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: AppStrings.backLabel,
          onPressed: () => goBack(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
        ),
        title: const Text(AppStrings.spiritualRule),
      ),
      body: canon == null
          ? const Center(
              child: EmptyState(
                title: AppStrings.emptyRule,
                body: AppStrings.emptyRuleHint,
                icon: Icons.auto_stories_outlined,
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
              children: [
                Text(
                  AppStrings.spiritualRuleHint,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                AppCard(
                  color: AppColors.gold100,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStrings.spiritualRule,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(canon.rule, style: const TextStyle(height: 1.7, fontSize: 16)),
                      const SizedBox(height: 16),
                      Text(
                        '${AppStrings.givenBy} · ${DateFormatters.longDate(canon.createdAt)}',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ).enter(context),
                if (user != null && !user.isPriest) ...[
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => context.push('/priests'),
                    child: const Text(AppStrings.bookNewAppointment),
                  ),
                ],
              ],
            ),
    );
  }
}
