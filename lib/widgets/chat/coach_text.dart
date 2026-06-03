import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// Minimal markdown renderer for coach messages. Supports the subset DateWise AI
/// actually emits (PRD voice guidelines): **bold**, bullet lists (`• `/`- `),
/// numbered lists (`1. `), and blockquotes (`> `). Avoids a heavy markdown
/// dependency for what is a small, well-known grammar.
class CoachText extends StatelessWidget {
  const CoachText(this.text, {super.key, this.color});

  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).textTheme.bodyLarge!.copyWith(
          color: color ?? AppColors.text,
          height: 1.5,
        );
    final lines = text.split('\n');
    final blocks = <Widget>[];

    for (final line in lines) {
      final trimmed = line.trimRight();
      if (trimmed.isEmpty) {
        blocks.add(const SizedBox(height: 8));
        continue;
      }
      if (trimmed.startsWith('> ')) {
        blocks.add(_quote(trimmed.substring(2), base));
      } else if (trimmed.startsWith('• ') || trimmed.startsWith('- ')) {
        blocks.add(_bullet(trimmed.substring(2), base));
      } else if (RegExp(r'^\d+\.\s').hasMatch(trimmed)) {
        final idx = trimmed.indexOf('. ');
        blocks.add(_numbered(trimmed.substring(0, idx), trimmed.substring(idx + 2), base));
      } else {
        blocks.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: RichText(text: _inline(trimmed, base)),
          ),
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: blocks,
    );
  }

  Widget _quote(String content, TextStyle base) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: const Border(
          left: BorderSide(color: AppColors.accent, width: 3),
        ),
      ),
      child: RichText(
        text: _inline(content, base.copyWith(fontStyle: FontStyle.italic)),
      ),
    );
  }

  Widget _bullet(String content, TextStyle base) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, top: 2, bottom: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 6, right: 8),
            child: Icon(Icons.circle, size: 6, color: AppColors.primary),
          ),
          Expanded(child: RichText(text: _inline(content, base))),
        ],
      ),
    );
  }

  Widget _numbered(String number, String content, TextStyle base) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, top: 2, bottom: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Text('$number.',
                style: base.copyWith(
                    fontWeight: FontWeight.w700, color: AppColors.primary)),
          ),
          Expanded(child: RichText(text: _inline(content, base))),
        ],
      ),
    );
  }

  /// Parses **bold** spans within a line.
  TextSpan _inline(String content, TextStyle base) {
    final spans = <TextSpan>[];
    final pattern = RegExp(r'\*\*(.+?)\*\*');
    var last = 0;
    for (final match in pattern.allMatches(content)) {
      if (match.start > last) {
        spans.add(TextSpan(text: content.substring(last, match.start)));
      }
      spans.add(TextSpan(
        text: match.group(1),
        style: const TextStyle(fontWeight: FontWeight.w700),
      ));
      last = match.end;
    }
    if (last < content.length) {
      spans.add(TextSpan(text: content.substring(last)));
    }
    return TextSpan(style: base, children: spans);
  }
}
