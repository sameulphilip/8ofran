import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';

import '../../../core/motion/motion.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/brand_logo.dart';
import 'splash_end.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  static const videoAsset = 'assets/brand/ghofran_splash.mp4';

  VideoPlayerController? _controller;
  bool _started = false;
  bool _leaving = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (context.reduceMotion) {
      removeHtmlSplash();
      Future<void>.delayed(const Duration(milliseconds: 400), _goNext);
      return;
    }
    if (kIsWeb) {
      bindHtmlSplashEnd(_goNext);
      return;
    }
    _playNative();
  }

  Future<void> _playNative() async {
    final controller = VideoPlayerController.asset(videoAsset);
    _controller = controller;
    try {
      await controller.setLooping(false);
      await controller.setVolume(0);
      await controller.initialize();
      if (!mounted) return;
      controller.addListener(_onVideoTick);
      await controller.play();
      if (mounted) setState(() {});
    } catch (_) {
      _goNext();
    }
  }

  void _onVideoTick() {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    final duration = controller.value.duration;
    final position = controller.value.position;
    if (duration == Duration.zero) return;
    if (position >= duration - const Duration(milliseconds: 80)) {
      _goNext();
    }
  }

  void _goNext() {
    if (_leaving || !mounted) return;
    _leaving = true;
    removeHtmlSplash();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.go('/login');
    });
  }

  @override
  void dispose() {
    _controller?.removeListener(_onVideoTick);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    return Scaffold(
      backgroundColor: AppColors.splash,
      body: context.reduceMotion
          ? const Center(child: BrandLogo(height: 240))
          : controller != null && controller.value.isInitialized
          ? SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: controller.value.size.width,
                  height: controller.value.size.height,
                  child: VideoPlayer(controller),
                ),
              ),
            )
          : const SizedBox.expand(),
    );
  }
}
