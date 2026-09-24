import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/primary_button.dart';

Future<String?> pickRejectReason(BuildContext context) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => const _RejectReasonSheet(),
  );
}

class _RejectReasonSheet extends StatefulWidget {
  const _RejectReasonSheet();

  @override
  State<_RejectReasonSheet> createState() => _RejectReasonSheetState();
}

class _RejectReasonSheetState extends State<_RejectReasonSheet> {
  String? _selected;
  final _other = TextEditingController();

  @override
  void dispose() {
    _other.dispose();
    super.dispose();
  }

  void _submit() {
    if (_selected == null) return;
    final reason = _selected == AppStrings.rejectReasonOther
        ? _other.text.trim()
        : _selected!;
    if (reason.isEmpty) return;
    Navigator.pop(context, reason);
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.page,
        0,
        AppSpacing.page,
        20 + bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.rejectReasonTitle,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          const Text(
            AppStrings.rejectReasonHint,
            style: TextStyle(height: 1.45),
          ),
          const SizedBox(height: 12),
          for (final reason in [
            ...AppStrings.rejectReasons,
            AppStrings.rejectReasonOther,
          ])
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(reason),
              leading: Icon(
                _selected == reason
                    ? Icons.radio_button_checked
                    : Icons.radio_button_off,
                color: Theme.of(context).colorScheme.primary,
              ),
              onTap: () => setState(() => _selected = reason),
            ),
          if (_selected == AppStrings.rejectReasonOther) ...[
            AppTextField(
              controller: _other,
              hint: AppStrings.rejectReasonHint,
              maxLength: 80,
              maxLines: 2,
            ),
            const SizedBox(height: 12),
          ],
          PrimaryButton(
            label: AppStrings.rejectRequest,
            onPressed: _selected == null ? null : _submit,
          ),
        ],
      ),
    );
  }
}
