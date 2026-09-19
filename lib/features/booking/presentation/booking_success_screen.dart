import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/motion/enter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/date_formatters.dart';
import '../../../core/utils/url_actions.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/success_check.dart';
import 'booking_controller.dart';

class BookingSuccessScreen extends ConsumerWidget {
  const BookingSuccessScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(bookingControllerProvider);
    final summary = [
      if (draft.startsAt != null) DateFormatters.longDate(draft.startsAt!),
      if (draft.startsAt != null) DateFormatters.time(draft.startsAt!),
      if (draft.priest != null) draft.priest!.name,
    ].join(' · ');

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) context.go('/home');
      },
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.page,
              AppSpacing.xl,
              AppSpacing.page,
              AppSpacing.md,
            ),
            child: Column(
              children: [
                const Spacer(),
                const SuccessCheck(),
                Text(
                  AppStrings.bookingSuccessTitle,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cairo(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.text900,
                  ),
                ).enter(context),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  AppStrings.bookingSuccessBody,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.7,
                  ),
                ).enter(context, index: 1),
                if (summary.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.lg),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary50,
                      borderRadius: BorderRadius.circular(AppRadius.full),
                    ),
                    child: Text(
                      summary,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ).enter(context, index: 2),
                ],
                const Spacer(),
                PrimaryButton(
                  label: AppStrings.backHome,
                  onPressed: () => context.go('/home'),
                ).enter(context, index: 3),
                const SizedBox(height: AppSpacing.sm),
                SecondaryButton(
                  label: AppStrings.showAppointments,
                  onPressed: () => context.go('/appointments'),
                ).enter(context, index: 4),
                if (draft.startsAt != null && draft.priest != null)
                  TextButton.icon(
                    onPressed: () => UrlActions.addToCalendar(
                      startsAt: draft.startsAt!,
                      priestName: draft.priest!.name,
                    ),
                    icon: const Icon(Icons.calendar_month_outlined),
                    label: const Text(AppStrings.addToCalendar),
                  ).enter(context, index: 5),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
