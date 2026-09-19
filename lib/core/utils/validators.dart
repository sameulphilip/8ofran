import '../constants/app_strings.dart';

class Validators {
  Validators._();

  static String? required(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppStrings.requiredField;
    }
    return null;
  }

  static String? email(String? value) {
    final empty = required(value);
    if (empty != null) return empty;
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRegex.hasMatch(value!.trim())) {
      return AppStrings.invalidEmail;
    }
    return null;
  }

  static String? password(String? value) {
    final empty = required(value);
    if (empty != null) return empty;
    if (value!.length < 8) return AppStrings.shortPassword;
    return null;
  }

  static String? confirmPassword(String? value, String original) {
    final empty = password(value);
    if (empty != null) return empty;
    if (value != original) return AppStrings.passwordMismatch;
    return null;
  }
}
