import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_nav.dart';
import '../../../core/widgets/primary_button.dart';
import '../data/conscience_local_store.dart';

class ConscienceExamScreen extends ConsumerStatefulWidget {
  const ConscienceExamScreen({super.key});

  @override
  ConsumerState<ConscienceExamScreen> createState() =>
      _ConscienceExamScreenState();
}

class _ConscienceExamScreenState extends ConsumerState<ConscienceExamScreen> {
  late Map<String, bool> _answers;

  @override
  void initState() {
    super.initState();
    _answers = Map<String, bool>.from(
      ref.read(conscienceLocalStoreProvider).load(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = ref.watch(conscienceLocalStoreProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => goBack(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
        ),
        title: const Text(AppStrings.conscienceExam),
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
              AppStrings.privacyLocalOnly,
              style: TextStyle(height: 1.5),
            ),
          ),
          const SizedBox(height: 16),
          for (final question in ConscienceLocalStore.questions)
            CheckboxListTile(
              key: ValueKey(question.id),
              value: _answers[question.id] ?? false,
              onChanged: (value) {
                setState(() => _answers[question.id] = value ?? false);
              },
              title: Text(question.text),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
          const SizedBox(height: 16),
          PrimaryButton(
            label: AppStrings.saveLocally,
            onPressed: () async {
              await store.save(_answers);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text(AppStrings.savedLocally)),
                );
              }
            },
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () async {
              await store.clear();
              setState(() => _answers.clear());
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
