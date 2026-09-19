import 'package:flutter/material.dart';

import '../constants/app_strings.dart';
import '../theme/app_colors.dart';

class FormErrorBanner extends StatelessWidget {
  const FormErrorBanner({super.key, required this.messages});

  final List<String> messages;

  @override
  Widget build(BuildContext context) {
    if (messages.isEmpty) return const SizedBox.shrink();
    return Semantics(
      liveRegion: true,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.dangerSoft,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppStrings.formErrorTitle,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: AppColors.danger,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            for (final message in messages)
              Text(
                '• $message',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.danger),
              ),
          ],
        ),
      ),
    );
  }
}
