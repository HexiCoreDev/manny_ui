import 'package:flutter/material.dart';

/// A fade gradient effect overlay that appears conditionally.
///
/// Useful for indicating scrollable content at the bottom of a list.
/// The gradient fades from a configurable color to transparent.
///
/// Example usage:
/// ```dart
/// Stack(
///   children: [
///     ListView(...),
///     Positioned(
///       bottom: 0,
///       left: 0,
///       right: 0,
///       child: AppFaderEffect(
///         visible: !isAtBottom,
///         color: Theme.of(context).colorScheme.primary,
///       ),
///     ),
///   ],
/// )
/// ```
class AppFaderEffect extends StatelessWidget {
  const AppFaderEffect({
    super.key,
    required this.visible,
    this.color,
    this.height = 100,
    this.fadeDuration = const Duration(milliseconds: 400),
  });

  /// Whether the fader effect is visible.
  final bool visible;

  /// Base color for the gradient. Defaults to the scaffold background color.
  final Color? color;

  /// Height of the fade gradient.
  final double height;

  /// Duration of the fade animation.
  final Duration fadeDuration;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final baseColor = color ?? theme.scaffoldBackgroundColor;

    return IgnorePointer(
      child: AnimatedOpacity(
        opacity: visible ? 1 : 0,
        duration: fadeDuration,
        child: Container(
          height: height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              end: Alignment.topCenter,
              begin: Alignment.bottomCenter,
              colors: [
                baseColor.withValues(alpha: 0.8),
                baseColor.withValues(alpha: 0.6),
                baseColor.withValues(alpha: 0.4),
                baseColor.withValues(alpha: 0.2),
                Colors.transparent,
              ],
              stops: const [0.1, 0.3, 0.5, 0.7, 1.0],
            ),
          ),
        ),
      ),
    );
  }
}
