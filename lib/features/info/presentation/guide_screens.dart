import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_nav.dart';
import '../../../core/widgets/app_card.dart';
import '../domain/guide_content.dart';

class ConfessionGuideScreen extends StatelessWidget {
  const ConfessionGuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _SectionsScaffold(
      title: AppStrings.confessionGuide,
      sections: GuideContent.confessionSteps,
    );
  }
}

class PsalmScreen extends StatelessWidget {
  const PsalmScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => goBack(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
        ),
        title: const Text(AppStrings.reflectionText),
      ),
      body: ListView(
        padding: const EdgeInsets.all(22),
        children: [
          Text(
            GuideContent.psalm50,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              height: 1.9,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class FastsScreen extends StatelessWidget {
  const FastsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _SectionsScaffold(
      title: AppStrings.quietPrompts,
      sections: GuideContent.fasts,
    );
  }
}

class _SectionsScaffold extends StatelessWidget {
  const _SectionsScaffold({required this.title, required this.sections});

  final String title;
  final List<GuideSection> sections;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => goBack(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
        ),
        title: Text(title),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        itemCount: sections.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final section = sections[index];
          return AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  section.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  section.body,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    height: 1.6,
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
