import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/motion/enter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/app_nav.dart';
import '../../../core/utils/date_formatters.dart';
import '../../../core/utils/url_actions.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/booking_stepper.dart';
import '../../../core/widgets/priest_avatar.dart';
import '../../../core/widgets/primary_button.dart';
import '../../appointments/domain/appointment.dart';
import 'booking_controller.dart';

class ConfirmBookingScreen extends ConsumerStatefulWidget {
  const ConfirmBookingScreen({super.key});

  @override
  ConsumerState<ConfirmBookingScreen> createState() =>
      _ConfirmBookingScreenState();
}

class _ConfirmBookingScreenState extends ConsumerState<ConfirmBookingScreen> {
  final _notes = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    setState(() => _busy = true);
    try {
      await ref
          .read(bookingControllerProvider.notifier)
          .confirm(notes: _notes.text.trim());
      if (mounted) context.go('/booking/success');
    } on SlotTakenException {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text(AppStrings.slotTaken)));
        context.go('/booking/slot');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(bookingControllerProvider);
    final priest = draft.priest;
    final startsAt = draft.startsAt;
    if (priest == null || startsAt == null) {
      return const Scaffold(body: SizedBox.shrink());
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: AppStrings.backLabel,
          onPressed: () => goBack(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
        ),
        title: const Text(AppStrings.confirmBooking),
        actions: const [
          Padding(
            padding: EdgeInsetsDirectional.only(end: AppSpacing.md),
            child: BookingStepper(step: 3),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.page,
          AppSpacing.sm,
          AppSpacing.page,
          AppSpacing.md,
        ),
        child: Column(
          children: [
            Expanded(
              child: ListView(
                children: [
                  Container(
                    width: 96,
                    height: 96,
                    decoration: const BoxDecoration(
                      color: AppColors.primary50,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.calendar_month_outlined,
                      size: 44,
                      color: AppColors.primary700,
                    ),
                  ).enter(context),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    AppStrings.reviewDetails,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ).enter(context, index: 1),
                  const SizedBox(height: AppSpacing.lg),
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            PriestAvatar(
                              name: priest.name,
                              seed: priest.id.hashCode,
                              heroTag: 'priest-${priest.id}',
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                priest.name,
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _row(
                          Icons.event_outlined,
                          DateFormatters.longDate(startsAt),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        _row(
                          Icons.schedule_outlined,
                          DateFormatters.time(startsAt),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        _row(Icons.location_on_outlined, priest.churchName),
                        const SizedBox(height: AppSpacing.sm),
                        TextButton.icon(
                          onPressed: UrlActions.openMap,
                          icon: const Icon(Icons.map_outlined, size: 18),
                          label: const Text(AppStrings.openMaps),
                        ),
                      ],
                    ),
                  ).enter(context, index: 2),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    hint: AppStrings.optionalNote,
                    controller: _notes,
                    icon: Icons.notes_outlined,
                    maxLength: 140,
                    maxLines: 2,
                    keyboardType: TextInputType.multiline,
                  ).enter(context, index: 3),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.lock_outline,
                        size: 18,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          AppStrings.privacyNote,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: AppColors.textSecondary,
                                height: 1.5,
                              ),
                        ),
                      ),
                    ],
                  ).enter(context, index: 4),
                ],
              ),
            ),
            PrimaryButton(
              label: AppStrings.sendBookingRequest,
              busy: _busy,
              onPressed: _busy ? null : _confirm,
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary600, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}
