import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/data/local_database.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_nav.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../booking/presentation/booking_controller.dart';
import '../../care/data/local_reminder_service.dart';
import '../../priests/data/priest_repository.dart';
import '../data/app_lock_store.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider);
    final lockStore = ref.watch(appLockStoreProvider);
    final lockEnabled = lockStore.isEnabled;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => goBack(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
        ),
        title: const Text(AppStrings.settingsTitle),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(user?.fullName ?? ''),
            subtitle: Text(user?.email ?? ''),
          ),
          if (user?.hasFather ?? false)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(AppStrings.currentFather),
              subtitle: Text(
                ref
                        .watch(priestRepositoryProvider)
                        .byId(user!.fatherId!)
                        ?.name ??
                    user.fatherId!,
              ),
              trailing: const Icon(Icons.chevron_left),
              onTap: () => context.push('/change-father'),
            ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text(AppStrings.notifyReminders),
            value: ref.watch(localDatabaseProvider).remindersEnabled(),
            onChanged: (value) async {
              await ref.read(localDatabaseProvider).setRemindersEnabled(value);
              if (!value) await localReminderService.cancelAll();
              ref.invalidate(reminderSyncProvider);
              if (mounted) setState(() {});
            },
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text(AppStrings.appLock),
            subtitle: Text(
              lockEnabled
                  ? AppStrings.appLockEnabled
                  : AppStrings.appLockHint,
            ),
            value: lockEnabled,
            onChanged: (value) async {
              if (value) {
                await _enableLock();
              } else {
                await _disableLock();
              }
            },
          ),
          if (lockEnabled)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(AppStrings.changeAppPin),
              trailing: const Icon(Icons.chevron_left),
              onTap: _enableLock,
            ),
          const Divider(),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text(AppStrings.privacyPolicy),
            trailing: const Icon(Icons.chevron_left),
            onTap: () => context.push('/privacy'),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text(AppStrings.termsTitle),
            trailing: const Icon(Icons.chevron_left),
            onTap: () => context.push('/terms'),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text(AppStrings.aboutApp),
            subtitle: Text(
              AppStrings.appName,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            trailing: const Icon(Icons.chevron_left),
            onTap: () => context.push('/about'),
          ),
        ],
      ),
    );
  }

  Future<void> _enableLock() async {
    final pin = await _askPin(
      title: AppStrings.setAppPin,
      confirmTitle: AppStrings.confirmAppPin,
    );
    if (pin == null) return;
    await ref.read(appLockStoreProvider).enableWithPin(pin);
    ref.read(appLockUnlockedProvider.notifier).unlock();
    if (mounted) setState(() {});
  }

  Future<void> _disableLock() async {
    final pin = await _askSinglePin(title: AppStrings.enterAppPin);
    if (pin == null) return;
    final store = ref.read(appLockStoreProvider);
    if (!store.verifyPin(pin)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.wrongPin)),
        );
      }
      return;
    }
    await store.disable();
    ref.read(appLockUnlockedProvider.notifier).refreshGate();
    if (mounted) setState(() {});
  }

  Future<String?> _askPin({
    required String title,
    required String confirmTitle,
  }) async {
    final first = TextEditingController();
    final second = TextEditingController();
    String? error;

    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(title),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: first,
                    obscureText: true,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(labelText: title),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: second,
                    obscureText: true,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(labelText: confirmTitle),
                  ),
                  if (error != null) ...[
                    const SizedBox(height: 8),
                    Text(error!, style: const TextStyle(color: AppColors.danger)),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(AppStrings.cancel),
                ),
                FilledButton(
                  onPressed: () {
                    if (first.text.trim().length < 4) {
                      setDialogState(() => error = AppStrings.pinTooShort);
                      return;
                    }
                    if (first.text != second.text) {
                      setDialogState(() => error = AppStrings.pinMismatch);
                      return;
                    }
                    Navigator.pop(context, first.text.trim());
                  },
                  child: const Text(AppStrings.save),
                ),
              ],
            );
          },
        );
      },
    );
    first.dispose();
    second.dispose();
    return result;
  }

  Future<String?> _askSinglePin({required String title}) async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          obscureText: true,
          autofocus: true,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(labelText: title),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(AppStrings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text(AppStrings.ok),
          ),
        ],
      ),
    );
    controller.dispose();
    return result;
  }
}
