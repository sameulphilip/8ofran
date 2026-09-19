import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/primary_button.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../booking/presentation/booking_controller.dart';
import '../data/care_repository.dart';
import '../domain/pastoral_care.dart';

class AssignCareScreen extends ConsumerStatefulWidget {
  const AssignCareScreen({super.key, required this.userId});

  final String userId;

  @override
  ConsumerState<AssignCareScreen> createState() => _AssignCareScreenState();
}

class _AssignCareScreenState extends ConsumerState<AssignCareScreen> {
  final _rule = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _rule.dispose();
    super.dispose();
  }

  Future<void> _saveRule() async {
    final priest = ref.read(authControllerProvider);
    if (priest?.priestId == null) return;
    setState(() => _busy = true);
    try {
      await ref
          .read(careRepositoryProvider)
          .assignCanon(
            userId: widget.userId,
            priestId: priest!.priestId!,
            priestUid: priest.id,
            rule: _rule.text,
          );
      if (mounted) {
        _rule.clear();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text(AppStrings.ruleSaved)));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _saveCadence(int days) async {
    final priest = ref.read(authControllerProvider);
    if (priest?.priestId == null) return;
    await ref
        .read(careRepositoryProvider)
        .setInterval(
          userId: widget.userId,
          priestId: priest!.priestId!,
          priestUid: priest.id,
          intervalDays: days,
        );
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text(AppStrings.cadenceSaved)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final people = ref.watch(directoryProvider).value ?? const {};
    final person = people[widget.userId];
    final flock = ref.watch(flockProvider).value ?? const [];
    final care = flock.cast<PastoralCare?>().firstWhere(
      (item) => item!.userId == widget.userId,
      orElse: () => null,
    );
    final appointments = ref.watch(allAppointmentsProvider);
    final last = lastVisitFor(
      userId: widget.userId,
      priestId: ref.watch(authControllerProvider)?.priestId ?? '',
      appointments: appointments,
    );

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
        ),
        title: Text(person?.fullName ?? AppStrings.choosePerson),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${AppStrings.lastVisitLabel}: ${AppStrings.daysSinceVisit(care?.daysSince(DateTime.now(), last) ?? -1)}',
                ),
                if (care != null) ...[
                  const SizedBox(height: 6),
                  Text(AppStrings.everyNDays(care.intervalDays)),
                ],
              ],
            ),
          ),
          const SizedBox(height: 18),
          Text(
            AppStrings.confessionCadence,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          const Text(
            AppStrings.cadenceHint,
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final days in AppConstants.cadenceOptions)
                ChoiceChip(
                  label: Text(AppStrings.everyNDays(days)),
                  selected: care?.intervalDays == days,
                  onSelected: (_) => _saveCadence(days),
                ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            AppStrings.assignRule,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          const Text(
            AppStrings.ruleFieldHint,
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          AppTextField(
            hint: AppStrings.ruleFieldHint,
            controller: _rule,
            maxLines: 6,
            icon: Icons.auto_stories_outlined,
          ),
          const SizedBox(height: 16),
          PrimaryButton(
            label: AppStrings.saveRule,
            busy: _busy,
            onPressed: _busy ? null : _saveRule,
          ),
        ],
      ),
    );
  }
}
