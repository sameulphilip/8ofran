import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/app_nav.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/form_error_banner.dart';
import '../../../core/widgets/primary_button.dart';
import '../data/admin_repository.dart';
import '../domain/church.dart';

class ChurchFormScreen extends ConsumerStatefulWidget {
  const ChurchFormScreen({super.key, this.churchId});

  final String? churchId;

  @override
  ConsumerState<ChurchFormScreen> createState() => _ChurchFormScreenState();
}

class _ChurchFormScreenState extends ConsumerState<ChurchFormScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _city = TextEditingController();
  var _busy = false;
  var _hydrated = false;
  String? _error;

  bool get _isNew => widget.churchId == null || widget.churchId == 'new';

  @override
  void dispose() {
    _name.dispose();
    _city.dispose();
    super.dispose();
  }

  void _hydrate(List<Church> churches) {
    if (_hydrated || _isNew) return;
    final church = churches.cast<Church?>().firstWhere(
      (item) => item!.id == widget.churchId,
      orElse: () => null,
    );
    if (church == null) return;
    _name.text = church.name;
    _city.text = church.city;
    _hydrated = true;
  }

  Future<void> _save() async {
    setState(() => _error = null);
    if (!(_form.currentState?.validate() ?? false)) return;
    setState(() => _busy = true);
    try {
      final church = Church(
        id: _isNew ? newCatalogId('ch') : widget.churchId!,
        name: _name.text.trim(),
        city: _city.text.trim(),
      );
      await ref.read(adminRepositoryProvider).saveChurch(church);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text(AppStrings.churchSaved)));
      goBack(context);
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final churches = ref.watch(churchesProvider);
    _hydrate(churches);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: AppStrings.backLabel,
          onPressed: () => goBack(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
        ),
        title: Text(_isNew ? AppStrings.addChurch : AppStrings.editChurch),
      ),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.page,
            AppSpacing.md,
            AppSpacing.page,
            AppSpacing.xxxl,
          ),
          children: [
            if (_error != null) FormErrorBanner(messages: [_error!]),
            AppTextField(
              controller: _name,
              label: AppStrings.churchName,
              hint: AppStrings.churchName,
              icon: Icons.church_outlined,
              validator: (value) => (value == null || value.trim().isEmpty)
                  ? AppStrings.requiredField
                  : null,
            ),
            const SizedBox(height: 12),
            AppTextField(
              controller: _city,
              label: AppStrings.cityLabel,
              hint: AppStrings.cityLabel,
              icon: Icons.location_city_outlined,
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              label: AppStrings.saveChurch,
              busy: _busy,
              onPressed: _busy ? null : _save,
            ),
          ],
        ),
      ),
    );
  }
}
