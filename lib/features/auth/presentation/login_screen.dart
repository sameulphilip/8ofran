import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/form_error_banner.dart';
import '../../../core/widgets/google_sign_in_button.dart';
import '../../../core/widgets/login_hero.dart';
import '../../../core/widgets/or_divider.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/shake.dart';
import '../data/auth_repository.dart';
import 'auth_controller.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _userController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _remember = false;
  bool _busy = false;
  bool _submitted = false;
  int _shake = 0;
  final List<String> _errors = [];

  AutovalidateMode get _mode => _submitted
      ? AutovalidateMode.onUserInteraction
      : AutovalidateMode.disabled;

  @override
  void dispose() {
    _userController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _submitted = true;
      _errors.clear();
    });
    if (!_formKey.currentState!.validate()) {
      setState(() {
        final userError = Validators.required(_userController.text);
        final passError = Validators.password(_passwordController.text);
        if (userError != null) _errors.add(userError);
        if (passError != null) _errors.add(passError);
        _shake++;
      });
      HapticFeedback.lightImpact();
      return;
    }
    setState(() => _busy = true);
    try {
      await ref
          .read(authControllerProvider.notifier)
          .login(
            identifier: _userController.text,
            password: _passwordController.text,
            remember: _remember,
          );
    } on AuthException catch (error) {
      if (mounted) {
        setState(() {
          _errors.add(error.message);
          _shake++;
        });
        HapticFeedback.lightImpact();
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _forgot() async {
    final emailController = TextEditingController();
    final sent = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppStrings.resetTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(AppStrings.resetHint),
            const SizedBox(height: 12),
            AppTextField(
              hint: AppStrings.email,
              controller: emailController,
              icon: Icons.mail_outline,
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(AppStrings.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(AppStrings.sendReset),
          ),
        ],
      ),
    );
    final email = emailController.text;
    emailController.dispose();
    if (sent == true && mounted) {
      if (email.trim().isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text(AppStrings.requiredField)));
        return;
      }
      try {
        await ref
            .read(authControllerProvider.notifier)
            .sendPasswordReset(email);
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text(AppStrings.resetSent)));
        }
      } on AuthException catch (error) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(error.message)));
        }
      }
    }
  }

  Future<void> _google() async {
    setState(() => _busy = true);
    try {
      await ref.read(authControllerProvider.notifier).loginWithGoogle();
    } on AuthException catch (error) {
      if (mounted) {
        setState(() {
          _errors
            ..clear()
            ..add(error.message);
          _shake++;
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Column(
        children: [
          SizedBox(height: height * 0.38, child: const LoginHero()),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x140F2238),
                    blurRadius: 16,
                    offset: Offset(0, -4),
                  ),
                ],
              ),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
                children: [
                  Shake(
                    trigger: _shake,
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          FormErrorBanner(messages: _errors),
                          AppTextField(
                            hint: AppStrings.emailOrUsername,
                            controller: _userController,
                            icon: Icons.person_outline,
                            validator: Validators.required,
                            autovalidateMode: _mode,
                            textInputAction: TextInputAction.next,
                          ),
                          const SizedBox(height: 12),
                          AppTextField(
                            hint: AppStrings.password,
                            controller: _passwordController,
                            icon: Icons.lock_outline,
                            obscureText: true,
                            validator: Validators.password,
                            autovalidateMode: _mode,
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) => _submit(),
                          ),
                          Row(
                            children: [
                              Checkbox(
                                value: _remember,
                                onChanged: (value) {
                                  setState(() => _remember = value ?? false);
                                },
                              ),
                              const Text(AppStrings.rememberMe),
                              const Spacer(),
                              TextButton(
                                onPressed: _forgot,
                                child: const Text(AppStrings.forgotPassword),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          PrimaryButton(
                            label: AppStrings.login,
                            busy: _busy,
                            onPressed: _busy ? null : _submit,
                          ),
                          const SizedBox(height: 16),
                          const OrDivider(),
                          const SizedBox(height: 16),
                          GoogleSignInButton(onPressed: _busy ? null : _google),
                          const SizedBox(height: 16),
                          Wrap(
                            alignment: WrapAlignment.center,
                            children: [
                              Text(
                                AppStrings.noAccount,
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(color: AppColors.text600),
                              ),
                              TextButton(
                                onPressed: () => context.go('/signup'),
                                child: const Text(AppStrings.createNewAccount),
                              ),
                            ],
                          ),
                          Text(
                            AppStrings.demoHint,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: AppColors.text500),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
