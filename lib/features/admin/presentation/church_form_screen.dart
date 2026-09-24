import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/app_nav.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/form_error_banner.dart';
import '../../../core/widgets/primary_button.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/presentation/auth_controller.dart';
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
  final _address = TextEditingController();
  final _mapsQuery = TextEditingController();
  final _phone = TextEditingController();
  final _stewardName = TextEditingController();
  final _stewardEmail = TextEditingController();
  final _stewardPassword = TextEditingController();
  var _active = true;
  var _busy = false;
  var _hydrated = false;
  String? _error;

  bool get _isNew => widget.churchId == null || widget.churchId == 'new';

  @override
  void dispose() {
    _name.dispose();
    _city.dispose();
    _address.dispose();
    _mapsQuery.dispose();
    _phone.dispose();
    _stewardName.dispose();
    _stewardEmail.dispose();
    _stewardPassword.dispose();
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
    _address.text = church.address;
    _mapsQuery.text = church.mapsQuery;
    _phone.text = church.phone;
    _active = church.isActive;
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
        address: _address.text.trim(),
        mapsQuery: _mapsQuery.text.trim(),
        phone: _phone.text.trim(),
        isActive: _active,
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

  Future<void> _createSteward() async {
    final actor = ref.read(authControllerProvider);
    if (actor?.isSuperAdmin != true || _isNew) {
      setState(() => _error = AppStrings.stewardOnlySuper);
      return;
    }
    if (_stewardName.text.trim().isEmpty ||
        _stewardEmail.text.trim().isEmpty ||
        _stewardPassword.text.length < 8) {
      setState(() => _error = AppStrings.requiredField);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(adminRepositoryProvider)
          .createSteward(
            fullName: _stewardName.text.trim(),
            email: _stewardEmail.text.trim(),
            password: _stewardPassword.text,
            churchId: widget.churchId!,
          );
      _stewardName.clear();
      _stewardEmail.clear();
      _stewardPassword.clear();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text(AppStrings.stewardCreated)));
    } on AuthException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final actor = ref.watch(authControllerProvider);
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
            const SizedBox(height: 12),
            AppTextField(
              controller: _address,
              label: AppStrings.churchAddress,
              hint: AppStrings.churchAddress,
              icon: Icons.place_outlined,
            ),
            const SizedBox(height: 12),
            AppTextField(
              controller: _mapsQuery,
              label: AppStrings.churchMapsQuery,
              hint: AppStrings.churchMapsHint,
              icon: Icons.map_outlined,
            ),
            const SizedBox(height: 12),
            AppTextField(
              controller: _phone,
              label: AppStrings.churchPhone,
              hint: AppStrings.churchPhone,
              icon: Icons.call_outlined,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                _active ? AppStrings.churchActive : AppStrings.churchPaused,
              ),
              value: _active,
              onChanged: (value) => setState(() => _active = value),
            ),
            const SizedBox(height: 16),
            PrimaryButton(
              label: AppStrings.saveChurch,
              busy: _busy,
              onPressed: _busy ? null : _save,
            ),
            if (!_isNew && (actor?.isSuperAdmin ?? false)) ...[
              const SizedBox(height: 12),
              TonalButton(
                danger: true,
                label: AppStrings.deleteChurch,
                onPressed: _busy ? null : _deleteChurch,
              ),
              const SizedBox(height: 28),
              const Divider(),
              const SizedBox(height: 12),
              Text(
                AppStrings.stewardTitle,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              const Text(
                AppStrings.stewardHint,
                style: TextStyle(color: AppColors.textSecondary, height: 1.45),
              ),
              const SizedBox(height: 12),
              AppTextField(
                controller: _stewardName,
                label: AppStrings.fullName,
                hint: AppStrings.fullName,
                icon: Icons.person_outline,
              ),
              const SizedBox(height: 12),
              AppTextField(
                controller: _stewardEmail,
                label: AppStrings.email,
                hint: AppStrings.email,
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              AppTextField(
                controller: _stewardPassword,
                label: AppStrings.password,
                hint: AppStrings.password,
                icon: Icons.lock_outline,
                obscureText: true,
              ),
              const SizedBox(height: 16),
              PrimaryButton(
                label: AppStrings.createSteward,
                busy: _busy,
                onPressed: _busy ? null : _createSteward,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _deleteChurch() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppStrings.deleteChurchConfirm),
        content: const Text(AppStrings.deleteChurchBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(AppStrings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text(AppStrings.deleteChurch),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _busy = true);
    try {
      await ref.read(adminRepositoryProvider).deleteChurch(widget.churchId!);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text(AppStrings.churchDeleted)));
      goBack(context);
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}
