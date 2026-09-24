import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
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
import '../../priests/data/priest_repository.dart';
import '../../priests/domain/priest.dart';
import '../data/admin_repository.dart';
import 'hours_editor.dart';
import 'off_days_picker.dart';

class PriestFormScreen extends ConsumerStatefulWidget {
  const PriestFormScreen({super.key, this.priestId});

  final String? priestId;

  @override
  ConsumerState<PriestFormScreen> createState() => _PriestFormScreenState();
}

class _PriestFormScreenState extends ConsumerState<PriestFormScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  var _churchId = '';
  var _available = true;
  var _firstHour = AppConstants.firstSlotHour;
  var _lastHour = AppConstants.lastSlotHour;
  var _slotMinutes = AppConstants.slotMinutes;
  var _offDays = <int>{};
  var _uid = '';
  var _busy = false;
  var _hydrated = false;
  final _errors = <String>[];
  late final String _recordId;

  bool get _isNew => widget.priestId == null || widget.priestId == 'new';

  @override
  void initState() {
    super.initState();
    _recordId = _isNew ? newCatalogId('p') : widget.priestId!;
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _hydrate(List<Priest> priests) {
    if (_hydrated || _isNew) {
      _hydrated = true;
      return;
    }
    final priest = priests.cast<Priest?>().firstWhere(
      (item) => item!.id == widget.priestId,
      orElse: () => null,
    );
    if (priest == null) return;
    _name.text = priest.name;
    _email.text = priest.email;
    _churchId = priest.churchId;
    _available = priest.isAvailable;
    _firstHour = priest.firstSlotHour;
    _lastHour = priest.lastSlotHour;
    _slotMinutes = priest.slotMinutes;
    _offDays = {...priest.offWeekdays};
    _uid = priest.uid ?? '';
    _hydrated = true;
  }

  Priest _draft() {
    final churches = ref.read(scopedChurchesProvider);
    final match = churches.where((item) => item.id == _churchId);
    final churchName = match.isEmpty ? '' : match.first.name;
    return Priest(
      id: _recordId,
      name: _name.text.trim(),
      email: _email.text.trim().toLowerCase(),
      churchId: _churchId,
      churchName: churchName,
      uid: _uid.isEmpty ? null : _uid,
      isAvailable: _available,
      firstSlotHour: _firstHour,
      lastSlotHour: _lastHour,
      slotMinutes: _slotMinutes,
      offWeekdays: _offDays,
    );
  }

  bool _validate() {
    _errors.clear();
    final formOk = _form.currentState?.validate() ?? false;
    if (_churchId.isEmpty) _errors.add(AppStrings.chooseChurchError);
    if (_firstHour > _lastHour) _errors.add(AppStrings.hoursInvalid);
    setState(() {});
    return formOk && _errors.isEmpty;
  }

  Future<void> _save({bool createAccount = false}) async {
    if (!_validate()) return;
    if (createAccount && _password.text.length < 8) {
      setState(() => _errors.add(AppStrings.shortPassword));
      return;
    }
    setState(() => _busy = true);
    try {
      var priest = _draft();
      await ref.read(adminRepositoryProvider).savePriest(priest);
      if (createAccount && !priest.hasAccount) {
        priest = await ref
            .read(adminRepositoryProvider)
            .createPriestAccount(priest: priest, password: _password.text);
        _uid = priest.uid ?? '';
        _password.clear();
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            createAccount ? AppStrings.accountCreated : AppStrings.priestSaved,
          ),
        ),
      );
      if (!createAccount) goBack(context);
    } on AuthException catch (error) {
      if (mounted) setState(() => _errors.add(error.message));
    } catch (error) {
      if (mounted) setState(() => _errors.add(error.toString()));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _unlinkAccount() async {
    setState(() => _busy = true);
    try {
      await ref.read(adminRepositoryProvider).unlinkPriestAccount(_draft());
      _uid = '';
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.priestAccountUnlinked)),
      );
      setState(() {});
    } catch (error) {
      if (mounted) setState(() => _errors.add(error.toString()));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _sendReset() async {
    setState(() => _busy = true);
    try {
      await ref.read(adminRepositoryProvider).sendPriestReset(_email.text);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text(AppStrings.resetLinkSent)));
    } on AuthException catch (error) {
      if (mounted) setState(() => _errors.add(error.message));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final priests = ref.watch(priestsProvider);
    final churches = ref.watch(scopedChurchesProvider);
    final actor = ref.watch(authControllerProvider);
    _hydrate(priests);
    if (_churchId.isEmpty &&
        actor?.isSteward == true &&
        churches.length == 1) {
      _churchId = churches.first.id;
    }
    final churchIds = {for (final church in churches) church.id};
    final churchValue = churchIds.contains(_churchId) ? _churchId : null;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: AppStrings.backLabel,
          onPressed: () => goBack(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
        ),
        title: Text(_isNew ? AppStrings.addPriest : AppStrings.editPriest),
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
            FormErrorBanner(messages: _errors),
            AppTextField(
              controller: _name,
              label: AppStrings.fullName,
              hint: AppStrings.fullName,
              icon: Icons.person_outline,
              validator: (value) => (value == null || value.trim().isEmpty)
                  ? AppStrings.requiredField
                  : null,
            ),
            const SizedBox(height: 12),
            AppTextField(
              controller: _email,
              label: AppStrings.email,
              hint: AppStrings.email,
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                final mail = value?.trim() ?? '';
                if (mail.isEmpty) return AppStrings.requiredField;
                if (!mail.contains('@')) return AppStrings.invalidEmail;
                return null;
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              key: ValueKey('church-$churchValue-${churches.length}'),
              initialValue: churchValue,
              decoration: const InputDecoration(
                labelText: AppStrings.chooseChurch,
              ),
              items: [
                for (final church in churches)
                  DropdownMenuItem(value: church.id, child: Text(church.name)),
              ],
              onChanged: (value) => setState(() => _churchId = value ?? ''),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(AppStrings.priestAvailable),
              value: _available,
              onChanged: (value) => setState(() => _available = value),
            ),
            const SizedBox(height: 8),
            Text(
              AppStrings.priestHours,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            HoursEditor(
              firstHour: _firstHour,
              lastHour: _lastHour,
              slotMinutes: _slotMinutes,
              onFirstHour: (value) => setState(() => _firstHour = value),
              onLastHour: (value) => setState(() => _lastHour = value),
              onSlotMinutes: (value) => setState(() => _slotMinutes = value),
            ),
            const SizedBox(height: 16),
            Text(
              AppStrings.offDays,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            OffDaysPicker(
              selected: _offDays,
              onChanged: (value) => setState(() => _offDays = value),
            ),
            const SizedBox(height: 20),
            if (_uid.isEmpty) ...[
              AppTextField(
                controller: _password,
                label: AppStrings.password,
                hint: AppStrings.password,
                icon: Icons.lock_outline,
                obscureText: true,
              ),
              const SizedBox(height: 12),
              PrimaryButton(
                label: AppStrings.createPriestAccount,
                busy: _busy,
                onPressed: _busy ? null : () => _save(createAccount: true),
              ),
              const SizedBox(height: 12),
            ] else ...[
              Text(
                AppStrings.accountLinked,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.success700,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              PrimaryButton(
                label: AppStrings.sendResetLink,
                busy: _busy,
                onPressed: _busy ? null : _sendReset,
              ),
              const SizedBox(height: 12),
              TonalButton(
                danger: true,
                label: AppStrings.unlinkPriestAccount,
                onPressed: _busy ? null : _unlinkAccount,
              ),
              const SizedBox(height: 12),
            ],
            PrimaryButton(
              label: AppStrings.savePriest,
              busy: _busy,
              backgroundColor: AppColors.gold500,
              foregroundColor: AppColors.splash,
              onPressed: _busy ? null : _save,
            ),
            if (!_isNew &&
                (ref.watch(authControllerProvider)?.isSuperAdmin ?? false)) ...[
              const SizedBox(height: 12),
              TonalButton(
                danger: true,
                label: AppStrings.deletePriest,
                onPressed: _busy ? null : _deletePriest,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _deletePriest() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppStrings.deletePriestConfirm),
        content: const Text(AppStrings.deletePriestBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(AppStrings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text(AppStrings.deletePriest),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _busy = true);
    try {
      await ref.read(adminRepositoryProvider).deletePriest(_recordId);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text(AppStrings.priestDeleted)));
      goBack(context);
    } on AuthException catch (error) {
      if (mounted) {
        setState(() {
          _errors
            ..clear()
            ..add(error.message);
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}
