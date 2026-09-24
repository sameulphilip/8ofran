import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_nav.dart';
import '../../../core/widgets/app_card.dart';

class InfoScreen extends StatelessWidget {
  const InfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => goBack(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
        ),
        title: const Text(AppStrings.infoTitle),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          _tile(
            context,
            Icons.checklist_outlined,
            AppStrings.prepareChecklist,
            '/info/prepare',
          ),
          _tile(
            context,
            Icons.menu_book_outlined,
            AppStrings.confessionGuide,
            '/info/guide',
          ),
          _tile(
            context,
            Icons.favorite_outline,
            AppStrings.conscienceExam,
            '/info/conscience',
          ),
          _tile(
            context,
            Icons.auto_stories_outlined,
            AppStrings.reflectionText,
            '/info/psalm',
          ),
          _tile(
            context,
            Icons.calendar_month_outlined,
            AppStrings.churchCalendar,
            '/info/calendar',
          ),
          _tile(
            context,
            Icons.calendar_today_outlined,
            AppStrings.quietPrompts,
            '/info/fasts',
          ),
        ],
      ),
    );
  }

  Widget _tile(
    BuildContext context,
    IconData icon,
    String title,
    String route,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        onTap: () => context.push(route),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            const Icon(Icons.chevron_left, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}
