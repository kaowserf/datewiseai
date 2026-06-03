import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// The DateWise AI wordmark — a blush heart-spark glyph + name.
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.compact = false, this.onLight = false});

  final bool compact;
  final bool onLight;

  @override
  Widget build(BuildContext context) {
    final color = onLight ? Colors.white : AppColors.text;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: const BoxDecoration(
            gradient: AppColors.romanticGradient,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.favorite_rounded, color: Colors.white, size: 18),
        ),
        if (!compact) ...[
          const SizedBox(width: AppSpacing.sm),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: 'DateWise',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                    color: color,
                    letterSpacing: -0.3,
                  ),
                ),
                TextSpan(
                  text: ' AI',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                    color: AppColors.primary,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
