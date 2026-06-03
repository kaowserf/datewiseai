import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// A starter prompt suggestion.
class Suggestion {
  const Suggestion(this.emoji, this.label, {this.requiresPhoto = false});
  final String emoji;
  final String label;

  /// True for the photo-review prompt, which is gated to the Magnet tier.
  final bool requiresPhoto;
}

/// Quick-start prompt chips shown above the composer while a conversation is
/// fresh, mirroring the PRD's tier-appropriate coaching entry points.
class SuggestionChips extends StatelessWidget {
  const SuggestionChips({
    super.key,
    required this.onSelect,
    required this.canSendPhoto,
    required this.onPhotoBlocked,
  });

  /// Sends the chosen prompt text into the chat.
  final ValueChanged<String> onSelect;
  final bool canSendPhoto;
  final VoidCallback onPhotoBlocked;

  static const _suggestions = [
    Suggestion('✍️', 'Rewrite my Hinge bio'),
    Suggestion('🔥', 'Give me a killer opener'),
    Suggestion('💬', 'She stopped replying — what now?'),
    Suggestion('📸', 'Review my dating photos', requiresPhoto: true),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.md, 0, AppSpacing.md, AppSpacing.sm),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: _suggestions.map((s) {
            final locked = s.requiresPhoto && !canSendPhoto;
            return _Chip(
              suggestion: s,
              locked: locked,
              onTap: () {
                if (locked) {
                  onPhotoBlocked();
                } else {
                  onSelect(s.label);
                }
              },
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _Chip extends StatefulWidget {
  const _Chip({
    required this.suggestion,
    required this.locked,
    required this.onTap,
  });

  final Suggestion suggestion;
  final bool locked;
  final VoidCallback onTap;

  @override
  State<_Chip> createState() => _ChipState();
}

class _ChipState extends State<_Chip> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md, vertical: 10),
          decoration: BoxDecoration(
            color: _hover ? AppColors.surface : Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(
              color: _hover ? AppColors.primary : AppColors.cardBorder,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(widget.suggestion.emoji, style: const TextStyle(fontSize: 15)),
              const SizedBox(width: 8),
              Text(
                widget.suggestion.label,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w500),
              ),
              if (widget.locked) ...[
                const SizedBox(width: 6),
                const Icon(Icons.lock_outline, size: 14, color: AppColors.textMuted),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
