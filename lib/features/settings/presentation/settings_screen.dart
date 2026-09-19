import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_nav.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../../core/data/local_database.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider);

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
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text(AppStrings.notifyReminders),
            value: ref.watch(localDatabaseProvider).remindersEnabled(),
            onChanged: (value) {
              ref.read(localDatabaseProvider).setRemindersEnabled(value);
              setState(() {});
            },
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text(AppStrings.biometricSoon),
            subtitle: const Text(AppStrings.biometricHint),
            value: false,
            onChanged: null,
          ),
          const Divider(),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text(AppStrings.privacyPolicy),
            trailing: const Icon(Icons.chevron_left),
            onTap: () {
              showDialog<void>(
                context: context,
                builder: (context) => const AlertDialog(
                  title: Text(AppStrings.privacyPolicy),
                  content: Text(AppStrings.privacyBody),
                ),
              );
            },
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text(AppStrings.aboutApp),
            subtitle: Text(
              AppStrings.appName,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}
