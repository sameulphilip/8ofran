import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_nav.dart';
import '../../../core/widgets/primary_button.dart';
import '../data/prepare_local_store.dart';

class PrepareChecklistScreen extends ConsumerStatefulWidget {
  const PrepareChecklistScreen({super.key});

  @override
  ConsumerState<PrepareChecklistScreen> createState() =>
      _PrepareChecklistScreenState();
}

class _PrepareChecklistScreenState
    extends ConsumerState<PrepareChecklistScreen> {
  late Map<String, bool> _checks;

  @override
  void initState() {
    super.initState();
    _checks = Map<String, bool>.from(
      ref.read(prepareLocalStoreProvider).load(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = ref.watch(prepareLocalStoreProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => goBack(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
        ),
        title: const Text(AppStrings.prepareChecklist),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F1DE),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              AppStrings.prepareChecklistHint,
              style: TextStyle(height: 1.5),
            ),
          ),
          const SizedBox(height: 16),
          for (final step in PrepareLocalStore.steps)
            CheckboxListTile(
              key: ValueKey(step.id),
              value: _checks[step.id] ?? false,
              onChanged: (value) {
                setState(() => _checks[step.id] = value ?? false);
              },
              title: Text(step.text),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
          const SizedBox(height: 16),
          PrimaryButton(
            label: AppStrings.saveLocally,
            onPressed: () async {
              await store.save(_checks);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text(AppStrings.prepareSaved)),
                );
              }
            },
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () async {
              await store.clear();
              setState(() => _checks.clear());
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text(AppStrings.clearedLocal)),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text(AppStrings.clearLocal),
          ),
        ],
      ),
    );
  }
}
