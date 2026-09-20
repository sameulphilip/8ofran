import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/google_sign_in_button.dart';
import '../../../core/widgets/or_divider.dart';
import '../../../core/widgets/powered_by.dart';
import '../../../core/widgets/primary_button.dart';
import '../data/auth_repository.dart';
import '../../care/data/care_repository.dart';
import '../../priests/data/priest_repository.dart';
import '../../priests/presentation/father_picker_field.dart';
import 'auth_controller.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _username = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _accepted = false;
  bool _busy = false;
  String? _fatherId;

  @override
  void dispose() {
    _name.dispose();
    _username.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_accepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.acceptTermsError)),
      );
      return;
    }
    setState(() => _busy = true);
    try {
      await ref
          .read(authControllerProvider.notifier)
          .signup(
            fullName: _name.text,
            username: _username.text,
            email: _email.text,
            password: _password.text,
            fatherId: _fatherId,
          );
      final user = ref.read(authControllerProvider);
      if (user?.hasFather == true) {
        final priest = ref.read(priestRepositoryProvider).byId(user!.fatherId!);
        await ref
            .read(careRepositoryProvider)
            .ensureLink(
              userId: user.id,
              priestId: user.fatherId!,
              priestUid: priest?.uid,
            );
      }
    } on AuthException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _google() async {
    setState(() => _busy = true);
    try {
      await ref.read(authControllerProvider.notifier).loginWithGoogle();
    } on AuthException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.go('/login'),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
        ),
        title: const Text(AppStrings.signupTitle),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(22, 8, 22, 32),
        children: [
          Text(
            AppStrings.signupSubtitle,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 18),
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              color: AppColors.primary100,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person_outline,
              color: AppColors.primary700,
            ),
          ),
          const SizedBox(height: 22),
          Form(
            key: _formKey,
            child: Column(
              children: [
                AppTextField(
                  hint: AppStrings.fullName,
                  controller: _name,
                  icon: Icons.badge_outlined,
                  validator: Validators.required,
                ),
                const SizedBox(height: 12),
                AppTextField(
                  hint: AppStrings.username,
                  controller: _username,
                  icon: Icons.person_outline,
                  validator: Validators.required,
                ),
                const SizedBox(height: 12),
                AppTextField(
                  hint: AppStrings.email,
                  controller: _email,
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: Validators.email,
                ),
                const SizedBox(height: 12),
                AppTextField(
                  hint: AppStrings.password,
                  controller: _password,
                  icon: Icons.lock_outline,
                  obscureText: true,
                  validator: Validators.password,
                ),
                const SizedBox(height: 12),
                AppTextField(
                  hint: AppStrings.confirmPassword,
                  controller: _confirm,
                  icon: Icons.lock_outline,
                  obscureText: true,
                  validator: (value) =>
                      Validators.confirmPassword(value, _password.text),
                ),
                const SizedBox(height: 12),
                FatherPickerField(
                  value: _fatherId,
                  priests: (ref.watch(priestsStreamProvider).value ?? const [])
                      .where((priest) => priest.isAvailable)
                      .toList(),
                  onChanged: (value) => setState(() => _fatherId = value),
                ),
                const SizedBox(height: 8),
                Text(
                  AppStrings.chooseFatherHint,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Checkbox(
                      value: _accepted,
                      onChanged: (value) {
                        setState(() => _accepted = value ?? false);
                      },
                    ),
                    const Expanded(child: Text(AppStrings.acceptTerms)),
                  ],
                ),
                const SizedBox(height: 8),
                PrimaryButton(
                  label: AppStrings.signup,
                  busy: _busy,
                  onPressed: _busy ? null : _submit,
                ),
                const SizedBox(height: 18),
                const OrDivider(),
                const SizedBox(height: 18),
                GoogleSignInButton(
                  label: AppStrings.signupWithGoogle,
                  onPressed: _busy ? null : _google,
                ),
                const SizedBox(height: 16),
                Wrap(
                  alignment: WrapAlignment.center,
                  children: [
                    Text(
                      AppStrings.haveAccount,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.go('/login'),
                      child: const Text(AppStrings.goToLogin),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Center(child: PoweredByMark(onDark: false)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
