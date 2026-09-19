import 'package:flutter/material.dart';

import '../constants/app_strings.dart';

class OrDivider extends StatelessWidget {
  const OrDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            AppStrings.or,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).hintColor,
            ),
          ),
        ),
        const Expanded(child: Divider()),
      ],
    );
  }
}
