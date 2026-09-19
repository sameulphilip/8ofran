import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class PriestAvatar extends StatelessWidget {
  const PriestAvatar({
    super.key,
    required this.name,
    this.size = 56,
    this.seed,
    this.heroTag,
  });

  final String name;
  final double size;
  final int? seed;
  final String? heroTag;

  @override
  Widget build(BuildContext context) {
    final tones = <Color>[
      const Color(0xFF0F3D63),
      const Color(0xFF1F62A8),
      const Color(0xFF3E5340),
      const Color(0xFF5B4A32),
      const Color(0xFF2C4A6E),
    ];
    final color = tones[(seed ?? name.hashCode).abs() % tones.length];
    final trimmed = name.trim();
    final initial = trimmed.isEmpty
        ? 'ب'
        : String.fromCharCode(trimmed.runes.first);

    final avatar = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.gold100, width: 2),
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: TextStyle(
          color: AppColors.card,
          fontSize: size * 0.34,
          fontWeight: FontWeight.w600,
        ),
      ),
    );

    if (heroTag == null) return avatar;
    return Hero(
      tag: heroTag!,
      child: Material(color: Colors.transparent, child: avatar),
    );
  }
}
