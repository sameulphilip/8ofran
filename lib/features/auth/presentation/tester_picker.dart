import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/firebase/tester_catalog.dart';
import '../../../core/theme/app_colors.dart';

class TesterPicker extends StatelessWidget {
  const TesterPicker({super.key, required this.onSelect});

  final void Function(TesterAccount tester) onSelect;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          AppStrings.testersTitle,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: AppColors.gold500,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          AppStrings.testersPasswordHint,
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: const Color(0xFFB8C4D4)),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: [
            for (final tester in TesterCatalog.logins)
              ActionChip(
                label: Text(tester.label),
                onPressed: () => onSelect(tester),
                backgroundColor: AppColors.splash,
                side: const BorderSide(color: AppColors.gold500),
                labelStyle: const TextStyle(
                  color: AppColors.gold500,
                  fontWeight: FontWeight.w700,
                ),
              ),
          ],
        ),
      ],
    );
  }
}
