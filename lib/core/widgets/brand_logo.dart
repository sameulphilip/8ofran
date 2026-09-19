import 'package:flutter/material.dart';

class BrandLogo extends StatelessWidget {
  const BrandLogo({super.key, this.height = 220});

  final double height;

  static const assetPath = 'assets/brand/ghofran_logo.png';

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      assetPath,
      height: height,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
    );
  }
}
