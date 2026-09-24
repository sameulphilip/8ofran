import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_nav.dart';
import '../../../core/widgets/primary_button.dart';
import '../data/conscience_local_store.dart';
import '../domain/church_calendar.dart';

class ConscienceExamScreen extends ConsumerStatefulWidget {
  const ConscienceExamScreen({super.key});

  @override
  ConsumerState<ConscienceExamScreen> createState() =>
      _ConscienceExamScreenState();
}

class _ConscienceExamScreenState extends ConsumerState<ConscienceExamScreen> {
  late Map<String, bool> _answers;
  late final TextEditingController _notes;

  @override
  void initState() {
    super.initState();
    final snapshot = ref.read(conscienceLocalStoreProvider).load();
    _answers = Map<String, bool>.from(snapshot.answers);
    _notes = TextEditingController(text: snapshot.notes);
  }

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = ref.watch(conscienceLocalStoreProvider);
    final season = ChurchCalendar.seasonFor(DateTime.now());
    final questions = ConscienceLocalStore.questionsFor();

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
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${AppStrings.seasonToday}: ${season.title}',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                Text(
                  season.body,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          for (final question in questions)
            CheckboxListTile(
              key: ValueKey(question.id),
              value: _answers[question.id] ?? false,
              onChanged: (value) {
                setState(() => _answers[question.id] = value ?? false);
              },
              title: Text(question.text),
              subtitle: question.seasonal
                  ? const Text(
                      AppStrings.seasonalQuestion,
                      style: TextStyle(fontSize: 12),
                    )
                  : null,
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
          const SizedBox(height: 8),
          TextField(
            controller: _notes,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: AppStrings.conscienceNotes,
              hintText: AppStrings.conscienceNotesHint,
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 16),
          PrimaryButton(
            label: AppStrings.saveLocally,
            onPressed: () async {
              await store.save(
                ConscienceSnapshot(
                  answers: _answers,
                  notes: _notes.text.trim(),
                ),
              );
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text(AppStrings.savedLocally)),
                );
              }
            },
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () async {
              await Clipboard.setData(
                ClipboardData(text: store.exportText()),
              );
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text(AppStrings.exportedLocal)),
                );
              }
            },
            child: const Text(AppStrings.exportLocal),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () async {
              await store.clear();
              setState(() {
                _answers.clear();
                _notes.clear();
              });
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
