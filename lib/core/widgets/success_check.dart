import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../motion/motion.dart';
import '../theme/app_colors.dart';

class SuccessCheck extends StatefulWidget {
  const SuccessCheck({super.key, this.size = 120});

  final double size;

  @override
  State<SuccessCheck> createState() => _SuccessCheckState();
}

class _SuccessCheckState extends State<SuccessCheck>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );

  late final Animation<double> _circle = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.0, 0.45, curve: Curves.elasticOut),
  );
  late final Animation<double> _check = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.30, 0.70, curve: Curves.easeOutCubic),
  );
  late final Animation<double> _ring = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.45, 1.0, curve: Curves.easeOut),
  );

  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (context.reduceMotion) {
      _controller.value = 1;
    } else {
      _controller.forward();
      Future<void>.delayed(
        const Duration(milliseconds: 500),
        HapticFeedback.mediumImpact,
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;
    return Semantics(
      label: 'تم بنجاح',
      child: SizedBox(
        width: size * 1.7,
        height: size * 1.7,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (_, _) => Stack(
            alignment: Alignment.center,
            children: [
              Opacity(
                opacity: (1 - _ring.value) * 0.35,
                child: Container(
                  width: size * (1 + 0.6 * _ring.value),
                  height: size * (1 + 0.6 * _ring.value),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.success500, width: 3),
                  ),
                ),
              ),
              Transform.scale(
                scale: _circle.value,
                child: Container(
                  width: size,
                  height: size,
                  decoration: const BoxDecoration(
                    color: AppColors.success500,
                    shape: BoxShape.circle,
                  ),
                  child: CustomPaint(
                    painter: _CheckPainter(_check.value, AppColors.card),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CheckPainter extends CustomPainter {
  _CheckPainter(this.progress, this.color);

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width * 0.28, size.height * 0.52)
      ..lineTo(size.width * 0.44, size.height * 0.68)
      ..lineTo(size.width * 0.72, size.height * 0.36);
    final metric = path.computeMetrics().first;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.09
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(metric.extractPath(0, metric.length * progress), paint);
  }

  @override
  bool shouldRepaint(_CheckPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
