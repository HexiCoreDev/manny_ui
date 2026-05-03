import 'package:flutter/material.dart';

/// Reusable Rating Display Widget.
///
/// Shows star ratings with optional count and size customization.
/// Supports full, half, and empty star states.
///
/// Example usage:
/// ```dart
/// RatingDisplay(
///   rating: 4.5,
///   reviewCount: 128,
/// )
/// ```
class RatingDisplay extends StatelessWidget {
  final double rating;
  final int? reviewCount;
  final double starSize;
  final Color? activeColor;
  final Color? inactiveColor;
  final bool showCount;
  final TextStyle? countStyle;
  final MainAxisAlignment alignment;

  const RatingDisplay({
    super.key,
    required this.rating,
    this.reviewCount,
    this.starSize = 20.0,
    this.activeColor,
    this.inactiveColor,
    this.showCount = true,
    this.countStyle,
    this.alignment = MainAxisAlignment.start,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final defaultActiveColor = activeColor ?? Colors.amber;
    final defaultInactiveColor =
        inactiveColor ?? theme.colorScheme.onSurface.withValues(alpha: 0.3);

    return Row(
      mainAxisAlignment: alignment,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Star icons
        Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(5, (index) {
            return Icon(
              _getStarIcon(index),
              size: starSize,
              color: _getStarColor(
                index,
                defaultActiveColor,
                defaultInactiveColor,
              ),
            );
          }),
        ),

        // Rating number and review count
        if (showCount && (rating > 0 || reviewCount != null)) ...[
          const SizedBox(width: 8),
          Text(
            _buildCountText(),
            style:
                countStyle ??
                theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
          ),
        ],
      ],
    );
  }

  /// Get appropriate star icon for position.
  IconData _getStarIcon(int index) {
    final difference = rating - index;

    if (difference >= 1.0) {
      return Icons.star;
    } else if (difference >= 0.5) {
      return Icons.star_half;
    } else {
      return Icons.star_border;
    }
  }

  /// Get color for star at position.
  Color _getStarColor(int index, Color active, Color inactive) {
    return (rating - index) > 0 ? active : inactive;
  }

  /// Build count text.
  String _buildCountText() {
    if (reviewCount != null && reviewCount! > 0) {
      return '$rating ($reviewCount)';
    } else {
      return rating.toStringAsFixed(1);
    }
  }
}

/// Compact Rating Display (just star icon and number).
class CompactRatingDisplay extends StatelessWidget {
  final double rating;
  final double starSize;
  final Color? starColor;

  const CompactRatingDisplay({
    super.key,
    required this.rating,
    this.starSize = 16.0,
    this.starColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.star, size: starSize, color: starColor ?? Colors.amber),
        const SizedBox(width: 4),
        Text(
          rating.toStringAsFixed(1),
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
