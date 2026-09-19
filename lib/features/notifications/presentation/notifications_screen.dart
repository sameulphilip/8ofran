import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_nav.dart';
import '../../../core/utils/date_formatters.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/empty_state.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../booking/presentation/booking_controller.dart';
import '../data/notification_repository.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items =
        ref.watch(userNotificationsProvider).value ?? const [];
    final user = ref.watch(authControllerProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => goBack(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
        ),
        title: const Text(AppStrings.notifications),
        actions: [
          if (items.any((n) => !n.read))
            TextButton(
              onPressed: user == null
                  ? null
                  : () async {
                      await ref
                          .read(notificationRepositoryProvider)
                          .markAllRead(user.id);
                      ref.invalidate(userNotificationsProvider);
                    },
              child: const Text(AppStrings.markAllRead),
            ),
        ],
      ),
      body: items.isEmpty
          ? const Center(
              child: EmptyState(
                title: AppStrings.noNotifications,
                body: AppStrings.emptyNotificationsHint,
                icon: Icons.notifications_none_rounded,
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final item = items[index];
                return AppCard(
                  key: ValueKey(item.id),
                  color: item.read ? AppColors.card : AppColors.primary50,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item.body,
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        DateFormatters.longDate(item.createdAt),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
