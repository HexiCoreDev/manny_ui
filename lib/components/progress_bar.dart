import 'package:flutter/material.dart';

/// A simple linear progress bar with rounded ends.
///
/// Uses pure Flutter (no external dependencies) for a clean progress indicator.
///
/// Example usage:
/// ```dart
/// ProgressBar(
///   progress: 0.65,
///   height: 12,
/// )
/// ```
class ProgressBar extends StatelessWidget {
  /// Progress value between 0.0 and 1.0.
  final double progress;

  /// Height of the progress bar.
  final double height;

  /// Color of the filled portion. Defaults to theme primary color.
  final Color? progressColor;

  /// Background color of the unfilled portion.
  final Color? backgroundColor;

  /// Border radius of the progress bar.
  final double borderRadius;

  /// Duration of the progress animation.
  final Duration animationDuration;

  const ProgressBar({
    super.key,
    required this.progress,
    this.height = 15.0,
    this.progressColor,
    this.backgroundColor,
    this.borderRadius = 20.0,
    this.animationDuration = const Duration(milliseconds: 300),
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveProgressColor = progressColor ?? theme.colorScheme.primary;
    final effectiveBackgroundColor =
        backgroundColor ?? theme.colorScheme.primary.withValues(alpha: 0.15);

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: SizedBox(
        height: height,
        child: Stack(
          children: [
            // Background
            Container(
              decoration: BoxDecoration(color: effectiveBackgroundColor),
            ),
            // Filled portion
            AnimatedFractionallySizedBox(
              duration: animationDuration,
              curve: Curves.easeInOut,
              alignment: Alignment.centerLeft,
              widthFactor: progress.clamp(0.0, 1.0),
              child: Container(
                decoration: BoxDecoration(color: effectiveProgressColor),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
