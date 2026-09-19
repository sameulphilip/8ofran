import 'package:flutter/material.dart';

import '../motion/motion.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'app_buttons.dart';

class EmptyState extends StatefulWidget {
  const EmptyState({
    super.key,
    required this.title,
    required this.body,
    this.actionLabel,
    this.onAction,
    this.icon = Icons.event_available_outlined,
  });

  final String title;
  final String body;
  final String? actionLabel;
  final VoidCallback? onAction;
  final IconData icon;

  @override
  State<EmptyState> createState() => _EmptyStateState();
}

class _EmptyStateState extends State<EmptyState>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 3),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (context.reduceMotion) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final offset = context.reduceMotion
                  ? 0.0
                  : (Curves.easeInOut.transform(_controller.value) * 8) - 4;
              return Transform.translate(
                offset: Offset(0, offset),
                child: child,
              );
            },
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.primary50,
                shape: BoxShape.circle,
              ),
              child: Icon(widget.icon, color: AppColors.primary, size: 32),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            widget.title,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            widget.body,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
              height: 1.6,
            ),
          ),
          if (widget.actionLabel != null && widget.onAction != null) ...[
            const SizedBox(height: AppSpacing.lg),
            TonalButton(label: widget.actionLabel!, onPressed: widget.onAction),
          ],
        ],
      ),
    );
  }
}
