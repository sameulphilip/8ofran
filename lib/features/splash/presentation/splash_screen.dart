import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/motion/motion.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/brand_logo.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  static const gifAsset = 'assets/brand/ghofran_splash.gif';
  static const _gifDuration = Duration(milliseconds: 10200);

  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );
    precacheImage(const AssetImage(gifAsset), context);
    final wait = context.reduceMotion
        ? const Duration(milliseconds: 500)
        : _gifDuration;
    Future<void>.delayed(wait, _goNext);
  }

  void _goNext() {
    if (!mounted) return;
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.splash,
      body: context.reduceMotion
          ? const Center(child: BrandLogo(height: 240))
          : SizedBox.expand(
              child: Image.asset(
                gifAsset,
                fit: BoxFit.cover,
                gaplessPlayback: true,
                filterQuality: FilterQuality.high,
              ),
            ),
    );
  }
}
