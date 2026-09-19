import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/brand_mark.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../booking/presentation/booking_controller.dart';

class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(unreadCountProvider);

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.page,
            20,
            AppSpacing.page,
            AppSpacing.navClearance,
          ),
          children: [
            const BrandWordmark(size: 36),
            const SizedBox(height: 6),
            Text(
              AppStrings.brandLine,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 22),
            _row(
              context,
              Icons.notifications_none_rounded,
              AppStrings.notifications,
              () => context.push('/notifications'),
              badge: unread,
            ),
            _row(
              context,
              Icons.auto_stories_outlined,
              AppStrings.infoAndGuides,
              () => context.push('/info'),
            ),
            _row(
              context,
              Icons.spa_outlined,
              AppStrings.aboutPage,
              () => context.push('/about'),
            ),
            _row(
              context,
              Icons.chat_bubble_outline_rounded,
              AppStrings.contactUs,
              () => context.push('/contact'),
            ),
            _row(
              context,
              Icons.tune_rounded,
              AppStrings.settings,
              () => context.push('/settings'),
            ),
            const SizedBox(height: 12),
            AppCard(
              onTap: () => _logout(context, ref),
              child: const Text(
                AppStrings.logout,
                style: TextStyle(
                  color: AppColors.danger,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback onTap, {
    int badge = 0,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        onTap: onTap,
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.accentSoft,
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(icon, color: AppColors.accent, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            if (badge > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.accentSoft,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$badge',
                  style: const TextStyle(
                    color: AppColors.accent,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              )
            else
              const Icon(Icons.chevron_left, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppStrings.logoutConfirm),
        content: const Text(AppStrings.logoutBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(AppStrings.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(AppStrings.logout),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(authControllerProvider.notifier).logout();
    }
  }
}
