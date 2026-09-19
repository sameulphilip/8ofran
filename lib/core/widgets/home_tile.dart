import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import 'pressable.dart';

class HomeTile extends StatelessWidget {
  const HomeTile({
    super.key,
    required this.title,
    required this.icon,
    required this.background,
    required this.foreground,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final Color background;
  final Color foreground;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      semanticLabel: title,
      child: Container(
        height: 112,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 32, color: foreground),
            const Spacer(),
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: foreground,
                fontWeight: FontWeight.w700,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
