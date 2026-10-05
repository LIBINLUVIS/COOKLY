import 'package:flutter/material.dart';

import '../theme/cookly_text_styles.dart';
import '../theme/cookly_theme.dart';

/// Pill-shaped badge used for tags, status labels and dietary chips.
class CooklyChip extends StatelessWidget {
  const CooklyChip({
    super.key,
    required this.label,
    required this.background,
    required this.foreground,
    this.leading,
    this.textStyle,
    this.padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
  });

  final String label;
  final Color background;
  final Color foreground;
  final Widget? leading;
  final TextStyle? textStyle;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(CooklyRadius.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (leading != null) ...[leading!, const SizedBox(width: 4)],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: (textStyle ?? CooklyTextStyles.labelSm).copyWith(color: foreground),
            ),
          ),
        ],
      ),
    );
  }
}

/// Small filled dot used as a leading status indicator inside a [CooklyChip].
class CooklyStatusDot extends StatelessWidget {
  const CooklyStatusDot({super.key, required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
