import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../domain/priest.dart';

class FatherPickerField extends StatelessWidget {
  const FatherPickerField({
    super.key,
    required this.value,
    required this.priests,
    required this.onChanged,
  });

  final String? value;
  final List<Priest> priests;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final selected = priests.any((priest) => priest.id == value) ? value : null;
    return DropdownButtonFormField<String>(
      key: ValueKey('father-$selected-${priests.length}'),
      initialValue: selected,
      decoration: const InputDecoration(
        labelText: AppStrings.chooseFather,
        prefixIcon: Icon(Icons.church_outlined),
      ),
      hint: const Text(AppStrings.chooseFather),
      items: [
        for (final priest in priests)
          DropdownMenuItem(
            value: priest.id,
            child: Text(
              priest.churchName.isEmpty
                  ? priest.name
                  : '${priest.name} · ${priest.churchName}',
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
      validator: (value) =>
          value == null || value.isEmpty ? AppStrings.chooseFatherError : null,
      onChanged: (value) {
        if (value != null) onChanged(value);
      },
    );
  }
}
