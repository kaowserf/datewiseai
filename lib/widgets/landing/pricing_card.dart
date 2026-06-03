import 'package:flutter/material.dart';

import '../../models/tier.dart';
import '../../theme/app_theme.dart';

/// A single tier card in the pricing section. Emits [onSelect] when the user
/// chooses this plan. Background, text, and accents adapt per tier — Spark on
/// white, Flame on a soft blush, Magnet on a deep plum — matching the design.
class PricingCard extends StatefulWidget {
  const PricingCard({
    super.key,
    required this.info,
    required this.onSelect,
    this.selected = false,
  });

  final TierInfo info;
  final VoidCallback onSelect;
  final bool selected;

  @override
  State<PricingCard> createState() => _PricingCardState();
}

class _PricingCardState extends State<PricingCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final info = widget.info;
    final dark = info.dark;
    final emphasised = info.highlight;

    // Adaptive palette per card surface.
    final bg = dark
        ? AppColors.magnetDark
        : emphasised
            ? AppColors.flameTint
            : Colors.white;
    final textColor = dark ? Colors.white : AppColors.text;
    final mutedColor =
        dark ? Colors.white.withValues(alpha: 0.65) : AppColors.textMuted;
    final checkColor = dark ? AppColors.accent : AppColors.primary;
    final borderColor = dark
        ? AppColors.magnetDarkBorder
        : (emphasised || _hover)
            ? AppColors.primary
            : AppColors.cardBorder;

    final card = AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      width: 340,
      transform: Matrix4.translationValues(0, _hover ? -8 : 0, 0),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: borderColor, width: emphasised ? 2 : 1),
        boxShadow: (emphasised || _hover || dark)
            ? [
                BoxShadow(
                  color: (dark ? AppColors.magnetDark : AppColors.primary)
                      .withValues(alpha: _hover ? 0.30 : 0.18),
                  blurRadius: _hover ? 44 : 30,
                  offset: const Offset(0, 16),
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            info.name,
            style: theme.textTheme.headlineSmall
                ?.copyWith(color: textColor, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(info.tagline,
              style: theme.textTheme.bodyLarge?.copyWith(color: mutedColor)),
          const SizedBox(height: AppSpacing.lg),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                info.priceLabel,
                style: theme.textTheme.displayMedium?.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(' / week',
                  style: theme.textTheme.bodyLarge?.copyWith(color: mutedColor)),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(info.description,
              style: theme.textTheme.bodyMedium?.copyWith(color: mutedColor)),
          const SizedBox(height: AppSpacing.lg),
          ...info.highlights.map(
            (h) => _featureRow(h, checkColor, textColor),
          ),
          const SizedBox(height: AppSpacing.xl),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: _buildButton(theme, info, dark, emphasised),
          ),
        ],
      ),
    );

    // Top badge (e.g. "MOST POPULAR" / "PHOTO COACH") overlaps the card edge.
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.topCenter,
          children: [
            card,
            if (emphasised || info.topBadge != null)
              Positioned(top: -12, child: _badge(info, emphasised)),
          ],
        ),
      ),
    );
  }

  Widget _badge(TierInfo info, bool emphasised) {
    final label = emphasised ? 'MOST POPULAR' : (info.topBadge ?? '');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        gradient: AppColors.romanticGradient,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.4),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!emphasised) ...[
            const Icon(Icons.camera_alt_rounded, size: 13, color: Colors.white),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _featureRow(String text, Color checkColor, Color textColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_rounded, size: 18, color: checkColor),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: textColor, fontSize: 14, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButton(
      ThemeData theme, TierInfo info, bool dark, bool emphasised) {
    final label = widget.selected ? 'Continue' : 'Choose ${info.name}';

    if (emphasised) {
      // Gradient filled button for the popular tier.
      return DecoratedBox(
        decoration: BoxDecoration(
          gradient: AppColors.romanticGradient,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.35),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: widget.onSelect,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
          ),
          child: Text(label),
        ),
      );
    }

    if (dark) {
      // Outlined-on-dark for the premium tier.
      return OutlinedButton(
        onPressed: widget.onSelect,
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          side: BorderSide(color: Colors.white.withValues(alpha: 0.5)),
        ),
        child: Text(label),
      );
    }

    return OutlinedButton(
      onPressed: widget.onSelect,
      child: Text(label),
    );
  }
}
