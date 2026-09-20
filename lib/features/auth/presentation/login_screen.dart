import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/brand_logo.dart';
import '../../../core/widgets/form_error_banner.dart';
import '../../../core/widgets/google_sign_in_button.dart';
import '../../../core/widgets/or_divider.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/powered_by.dart';
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

  ThemeData _navyTheme(BuildContext context) {
    const onNavy = Color(0xFFF6F8FB);
    const muted = Color(0xFFB8C4D4);
    final outline = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
      borderSide: BorderSide(color: onNavy.withValues(alpha: 0.28)),
    );
    return Theme.of(context).copyWith(
      scaffoldBackgroundColor: AppColors.splash,
      colorScheme: Theme.of(context).colorScheme.copyWith(
        surface: AppColors.splash,
        onSurface: onNavy,
        outline: onNavy.withValues(alpha: 0.35),
        primary: AppColors.gold500,
      ),
      hintColor: muted,
      dividerColor: onNavy.withValues(alpha: 0.2),
      textTheme: GoogleFonts.cairoTextTheme(
        ThemeData.dark().textTheme,
      ).apply(bodyColor: onNavy, displayColor: onNavy),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.gold500;
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(AppColors.splash),
        side: BorderSide(color: onNavy.withValues(alpha: 0.45), width: 1.4),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: AppColors.gold500),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.splash,
        titleTextStyle: GoogleFonts.cairo(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.bg,
        ),
        contentTextStyle: GoogleFonts.cairo(color: AppColors.bg, height: 1.5),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.splash,
        hintStyle: const TextStyle(color: muted),
        labelStyle: const TextStyle(color: muted),
        enabledBorder: outline,
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.gold500, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.danger500),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.danger500, width: 1.5),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: AppColors.splash,
      ),
      child: Theme(
        data: _navyTheme(context),
        child: Scaffold(
          backgroundColor: AppColors.splash,
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
              children: [
                const SizedBox(height: 12),
                const BrandLogo(height: 168),
                const SizedBox(height: 28),
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
                        const SizedBox(height: 8),
                        PrimaryButton(
                          label: AppStrings.login,
                          busy: _busy,
                          backgroundColor: AppColors.gold500,
                          foregroundColor: AppColors.splash,
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
                              style: const TextStyle(color: AppColors.disabled),
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
                          style: const TextStyle(color: AppColors.disabled),
                        ),
                        const SizedBox(height: 22),
                        const Center(child: PoweredByMark()),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
