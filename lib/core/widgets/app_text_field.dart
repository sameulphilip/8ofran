import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    required this.hint,
    this.label,
    this.controller,
    this.icon,
    this.obscureText = false,
    this.keyboardType,
    this.validator,
    this.textInputAction,
    this.onSubmitted,
    this.autovalidateMode,
    this.autofillHints,
    this.maxLength,
    this.maxLines = 1,
  });

  final String hint;
  final String? label;
  final TextEditingController? controller;
  final IconData? icon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final AutovalidateMode? autovalidateMode;
  final Iterable<String>? autofillHints;
  final int? maxLength;
  final int maxLines;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late bool _obscured = widget.obscureText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final input = theme.inputDecorationTheme;
    final muted = input.hintStyle?.color ?? AppColors.text500;

    return Semantics(
      label: widget.label ?? widget.hint,
      child: TextFormField(
        controller: widget.controller,
        obscureText: _obscured,
        keyboardType: widget.keyboardType,
        validator: widget.validator,
        autovalidateMode: widget.autovalidateMode,
        textInputAction: widget.textInputAction,
        onFieldSubmitted: widget.onSubmitted,
        autofillHints: widget.autofillHints,
        maxLength: widget.maxLength,
        maxLines: widget.maxLines,
        style: theme.textTheme.bodyLarge,
        decoration: InputDecoration(
          labelText: widget.label ?? widget.hint,
          hintText: widget.hint,
          floatingLabelBehavior: FloatingLabelBehavior.auto,
          hintStyle:
              input.hintStyle ??
              theme.textTheme.bodyLarge?.copyWith(color: muted),
          labelStyle:
              input.labelStyle ??
              theme.textTheme.bodyMedium?.copyWith(color: muted),
          filled: true,
          fillColor: input.fillColor ?? AppColors.surface,
          prefixIcon: widget.icon == null
              ? null
              : Icon(widget.icon, color: muted, size: 22),
          suffixIcon: widget.obscureText
              ? IconButton(
                  tooltip: _obscured
                      ? 'إظهار كلمة المرور'
                      : 'إخفاء كلمة المرور',
                  onPressed: () => setState(() => _obscured = !_obscured),
                  icon: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    child: Icon(
                      _obscured
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      key: ValueKey(_obscured),
                      color: muted,
                    ),
                  ),
                )
              : null,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
          enabledBorder:
              input.enabledBorder as OutlineInputBorder? ??
              OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
                borderSide: const BorderSide(color: AppColors.border),
              ),
          focusedBorder:
              input.focusedBorder as OutlineInputBorder? ??
              OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
                borderSide: const BorderSide(color: AppColors.primary, width: 1.6),
              ),
          errorBorder:
              input.errorBorder as OutlineInputBorder? ??
              OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
                borderSide: const BorderSide(color: AppColors.danger500),
              ),
          focusedErrorBorder:
              input.focusedErrorBorder as OutlineInputBorder? ??
              OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
                borderSide: const BorderSide(
                  color: AppColors.danger500,
                  width: 1.5,
                ),
              ),
        ),
      ),
    );
  }
}
