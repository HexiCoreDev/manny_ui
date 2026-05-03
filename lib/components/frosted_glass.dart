import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:manny_ui/config/manny_config.dart';
import 'package:manny_ui/config/ui_constants.dart';
import 'package:manny_ui/utils/neumorphic_painter.dart';

/// A reusable frosted glass container with backdrop blur and angular
/// neumorphic shadows. The light source wraps around the shape so each
/// edge gets a different intensity — no two edges share the same color.
///
/// Example usage:
/// ```dart
/// FrostedGlass(
///   child: Padding(
///     padding: EdgeInsets.all(16),
///     child: Text('Hello from the glass'),
///   ),
/// )
/// ```
class FrostedGlass extends StatelessWidget {
  const FrostedGlass({
    super.key,
    required this.child,
    this.borderRadius,
    this.blurSigma = UIConstants.glassBlurSigma,
    this.opacity = UIConstants.glassOpacity,
    this.border = true,
    this.shadow = true,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.tintColor,
    this.neumorphicStyle = const NeumorphicStyle(),
  });

  final Widget child;
  final BorderRadiusGeometry? borderRadius;
  final double blurSigma;
  final double opacity;
  final bool border;
  final bool shadow;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final Color? tintColor;

  /// Neumorphic configuration (light angle, depth, intensity).
  final NeumorphicStyle neumorphicStyle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final effectiveRadius =
        (borderRadius ?? BorderRadius.circular(20)) as BorderRadius;
    final surfaceColor = tintColor ?? theme.colorScheme.surface;

    final lightColor = isDark
        ? Colors.white.withValues(alpha: 0.05 * neumorphicStyle.lightIntensity)
        : Colors.white.withValues(alpha: 0.7 * neumorphicStyle.lightIntensity);
    final darkColor = isDark
        ? Colors.black.withValues(alpha: 0.6 * neumorphicStyle.darkIntensity)
        : Colors.black.withValues(alpha: 0.15 * neumorphicStyle.darkIntensity);

    final neuEnabled = shadow && MannyConfig.isNeumorphic(context);

    return Container(
      width: width,
      height: height,
      margin: margin,
      child: CustomPaint(
        painter: neuEnabled
            ? NeumorphicPainter(
                style: neumorphicStyle,
                borderRadius: effectiveRadius,
                surfaceColor: Colors.transparent,
                lightColor: lightColor,
                darkColor: darkColor,
                isDark: isDark,
              )
            : null,
        child: ClipRRect(
          borderRadius: effectiveRadius,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
            child: CustomPaint(
              painter: border
                  ? NeumorphicPainter(
                      style: neumorphicStyle,
                      borderRadius: effectiveRadius,
                      surfaceColor: surfaceColor.withValues(alpha: opacity),
                      lightColor: Colors.transparent,
                      darkColor: Colors.transparent,
                      isDark: isDark,
                    )
                  : null,
              child: Container(
                padding: padding,
                decoration: BoxDecoration(
                  color: surfaceColor.withValues(alpha: opacity),
                  borderRadius: effectiveRadius,
                ),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Convenience for a frosted glass with only top corners rounded (for sheets).
  static Widget sheet({
    required Widget child,
    double blurSigma = UIConstants.glassBlurSigma,
    double opacity = UIConstants.glassOpacity,
    double topRadius = UIConstants.glassSheetTopRadius,
    EdgeInsetsGeometry? padding,
  }) {
    return Builder(
      builder: (context) {
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;
        final surfaceColor = theme.colorScheme.surface;
        final radius = BorderRadius.vertical(top: Radius.circular(topRadius));

        return ClipRRect(
          borderRadius: radius,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
            child: CustomPaint(
              painter: NeumorphicPainter(
                style: const NeumorphicStyle(),
                borderRadius: radius,
                surfaceColor: surfaceColor.withValues(alpha: opacity),
                lightColor: Colors.transparent,
                darkColor: Colors.transparent,
                isDark: isDark,
              ),
              child: Container(
                padding: padding,
                decoration: BoxDecoration(
                  color: surfaceColor.withValues(alpha: opacity),
                  borderRadius: radius,
                ),
                child: child,
              ),
            ),
          ),
        );
      },
    );
  }
}
