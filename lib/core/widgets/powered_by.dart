import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/app_strings.dart';
import '../theme/app_colors.dart';
import '../utils/url_actions.dart';

class PoweredByMark extends StatelessWidget {
  const PoweredByMark({super.key, this.onDark = true});

  final bool onDark;

  static const assetPath = 'assets/brand/cowdlly_logo.png';

  @override
  Widget build(BuildContext context) {
    final credit = Semantics(
      button: true,
      label: '${AppStrings.poweredBy} ${AppStrings.studioName}',
      child: InkWell(
        onTap: UrlActions.openStudio,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  AppStrings.poweredBy,
                  style: GoogleFonts.cairo(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: onDark
                        ? Colors.white.withValues(alpha: 0.72)
                        : AppColors.text600,
                  ),
                ),
                const SizedBox(width: 8),
                Image.asset(
                  assetPath,
                  height: 88,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (onDark) return credit;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.splash,
        borderRadius: BorderRadius.circular(14),
      ),
      child: PoweredByMark(onDark: true),
    );
  }
}
