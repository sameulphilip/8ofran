import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/app_strings.dart';
import '../theme/app_colors.dart';

class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 72});

  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: Size.square(size), painter: const _SeedPainter());
  }
}

class BrandWordmark extends StatelessWidget {
  const BrandWordmark({super.key, this.size = 44, this.color});

  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Text(
      AppStrings.appName,
      style: GoogleFonts.cairo(
        fontSize: size,
        fontWeight: FontWeight.w700,
        color: color ?? AppColors.textPrimary,
        height: 1,
      ),
    );
  }
}

class _SeedPainter extends CustomPainter {
  const _SeedPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final ink = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    final fill = Paint()..color = AppColors.accent.withValues(alpha: 0.18);
    final copper = Paint()
      ..color = AppColors.accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height * 0.58);
    canvas.drawOval(
      Rect.fromCenter(
        center: center,
        width: size.width * 0.42,
        height: size.height * 0.34,
      ),
      fill,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: center,
        width: size.width * 0.42,
        height: size.height * 0.34,
      ),
      ink,
    );

    final stem = Path()
      ..moveTo(size.width / 2, size.height * 0.78)
      ..quadraticBezierTo(
        size.width * 0.62,
        size.height * 0.42,
        size.width * 0.54,
        size.height * 0.18,
      );
    canvas.drawPath(stem, copper);

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.62, size.height * 0.28),
        width: size.width * 0.22,
        height: size.height * 0.14,
      ),
      copper,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
