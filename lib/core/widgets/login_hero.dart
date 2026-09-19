import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'brand_logo.dart';

class LoginHero extends StatelessWidget {
  const LoginHero({super.key});

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: AppColors.splash,
      child: SafeArea(
        bottom: false,
        child: Center(child: BrandLogo(height: 220)),
      ),
    );
  }
}
