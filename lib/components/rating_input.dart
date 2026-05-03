import 'package:flutter/material.dart';

/// Interactive Rating Input Widget.
///
/// Allows users to tap stars to set a rating with animation
/// and hover effects.
///
/// Example usage:
/// ```dart
/// RatingInput(
///   initialRating: 3.0,
///   label: 'Rate this item',
///   onRatingChanged: (rating) {
///     print('Rating: $rating');
///   },
/// )
/// ```
class RatingInput extends StatefulWidget {
  final double initialRating;
  final ValueChanged<double> onRatingChanged;
  final double starSize;
  final Color? activeColor;
  final Color? inactiveColor;
  final bool allowHalfRating;
  final String? label;
  final Map<double, String>? ratingLabels;

  const RatingInput({
    super.key,
    this.initialRating = 0.0,
    required this.onRatingChanged,
    this.starSize = 40.0,
    this.activeColor,
    this.inactiveColor,
    this.allowHalfRating = false,
    this.label,
    this.ratingLabels,
  });

  @override
  State<RatingInput> createState() => _RatingInputState();
}

class _RatingInputState extends State<RatingInput>
    with SingleTickerProviderStateMixin {
  late double _currentRating;
  late AnimationController _animationController;
  int _hoveredIndex = -1;

  @override
  void initState() {
    super.initState();
    _currentRating = widget.initialRating;
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleTap(int index) {
    setState(() {
      _currentRating = (index + 1).toDouble();
    });
    _animationController.forward(from: 0.0);
    widget.onRatingChanged(_currentRating);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final defaultActiveColor = widget.activeColor ?? Colors.amber;
    final defaultInactiveColor =
        widget.inactiveColor ??
        theme.colorScheme.onSurface.withValues(alpha: 0.2);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
        ],
        Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(5, (index) {
            final isFilled = (index + 1) <= _currentRating;
            final isHovered = index <= _hoveredIndex;

            return GestureDetector(
              onTap: () => _handleTap(index),
              child: MouseRegion(
                onEnter: (_) => setState(() => _hoveredIndex = index),
                onExit: (_) => setState(() => _hoveredIndex = -1),
                child: ScaleTransition(
                  scale: Tween<double>(begin: 1.0, end: 1.2).animate(
                    CurvedAnimation(
                      parent: _animationController,
                      curve: Curves.easeOutBack,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: Icon(
                      isFilled || isHovered ? Icons.star : Icons.star_border,
                      size: widget.starSize,
                      color: isFilled || isHovered
                          ? defaultActiveColor
                          : defaultInactiveColor,
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
        if (_currentRating > 0) ...[
          const SizedBox(height: 8),
          Text(
            _getRatingLabel(_currentRating),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }

  String _getRatingLabel(double rating) {
    if (widget.ratingLabels != null) {
      // Find the closest label
      final sortedKeys = widget.ratingLabels!.keys.toList()..sort();
      for (final key in sortedKeys.reversed) {
        if (rating >= key) return widget.ratingLabels![key]!;
      }
    }

    if (rating >= 4.5) return 'Excellent!';
    if (rating >= 3.5) return 'Good';
    if (rating >= 2.5) return 'Average';
    if (rating >= 1.5) return 'Poor';
    return 'Very Poor';
  }
}

/// Compact Rating Input (for inline use).
class CompactRatingInput extends StatefulWidget {
  final double initialRating;
  final ValueChanged<double> onRatingChanged;
  final double starSize;

  const CompactRatingInput({
    super.key,
    this.initialRating = 0.0,
    required this.onRatingChanged,
    this.starSize = 24.0,
  });

  @override
  State<CompactRatingInput> createState() => _CompactRatingInputState();
}

class _CompactRatingInputState extends State<CompactRatingInput> {
  late double _currentRating;

  @override
  void initState() {
    super.initState();
    _currentRating = widget.initialRating;
  }

  void _handleTap(int index) {
    setState(() {
      _currentRating = (index + 1).toDouble();
    });
    widget.onRatingChanged(_currentRating);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final isFilled = (index + 1) <= _currentRating;

        return GestureDetector(
          onTap: () => _handleTap(index),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2.0),
            child: Icon(
              isFilled ? Icons.star : Icons.star_border,
              size: widget.starSize,
              color: isFilled ? Colors.amber : Colors.grey,
            ),
          ),
        );
      }),
    );
  }
}
