import 'dart:math';
import 'package:flutter/material.dart';

/// A frosted glass ripple effect that replaces the default Material splash.
///
/// Renders a semi-transparent glass-tinted circle with a radial gradient
/// and a subtle highlight ring, mimicking a frosted glass distortion.
///
/// Apply globally via theme:
/// ```dart
/// ThemeData(splashFactory: FrostedInkSplash.splashFactory)
/// ```
class FrostedInkSplash extends InteractiveInkFeature {
  FrostedInkSplash({
    required super.controller,
    required super.referenceBox,
    required super.color,
    super.onRemoved,
    Offset? position,
    bool containedInkWell = false,
    BorderRadius? borderRadius,
    double? radius,
  })  : _position = position ?? referenceBox.size.center(Offset.zero),
        _borderRadius = borderRadius ?? BorderRadius.zero,
        _targetRadius = radius ??
            _getTargetRadius(
              referenceBox.size,
              position ?? referenceBox.size.center(Offset.zero),
            ) {
    _radiusController = AnimationController(
      vsync: controller.vsync,
      duration: const Duration(milliseconds: 350),
    )
      ..addListener(controller.markNeedsPaint)
      ..forward();

    _fadeController = AnimationController(
      vsync: controller.vsync,
      duration: const Duration(milliseconds: 200),
    )..addListener(controller.markNeedsPaint);

    _radius = _radiusController.drive(
      Tween<double>(begin: 0, end: _targetRadius),
    );
    _alpha = _fadeController.drive(
      Tween<double>(begin: 1, end: 0),
    );
  }

  final Offset _position;
  final BorderRadius _borderRadius;
  final double _targetRadius;
  late AnimationController _radiusController;
  late AnimationController _fadeController;
  late Animation<double> _radius;
  late Animation<double> _alpha;

  static double _getTargetRadius(Size size, Offset position) {
    final d1 = (position - Offset.zero).distance;
    final d2 = (position - Offset(size.width, 0)).distance;
    final d3 = (position - Offset(0, size.height)).distance;
    final d4 = (position - Offset(size.width, size.height)).distance;
    return max(max(d1, d2), max(d3, d4)) * 1.1;
  }

  @override
  void confirm() {
    _radiusController.forward();
    _fadeController.forward().then((_) => dispose());
  }

  @override
  void cancel() {
    _fadeController.forward().then((_) => dispose());
  }

  @override
  void dispose() {
    _radiusController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  void paintFeature(Canvas canvas, Matrix4 transform) {
    final r = _radius.value;
    final a = _alpha.value;
    if (r <= 0 || a <= 0) return;

    final paint = Paint()
      ..color = color.withValues(alpha: 0.12 * a)
      ..style = PaintingStyle.fill;

    final highlightPaint = Paint()
      ..color = color.withValues(alpha: 0.2 * a)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.save();
    if (_borderRadius != BorderRadius.zero) {
      canvas.clipRRect(
        _borderRadius.toRRect(Offset.zero & referenceBox.size),
      );
    }

    // Frosted fill
    final gradient = RadialGradient(
      colors: [
        color.withValues(alpha: 0.15 * a),
        color.withValues(alpha: 0.04 * a),
      ],
    );
    final rect = Rect.fromCircle(center: _position, radius: r);
    canvas.drawCircle(
      _position,
      r,
      paint..shader = gradient.createShader(rect),
    );

    // Glass highlight ring
    canvas.drawCircle(_position, r * 0.8, highlightPaint);

    canvas.restore();
  }

  /// Factory to use in ThemeData.splashFactory.
  static InteractiveInkFeatureFactory get splashFactory =>
      _FrostedInkSplashFactory();
}

class _FrostedInkSplashFactory extends InteractiveInkFeatureFactory {
  @override
  InteractiveInkFeature create({
    required MaterialInkController controller,
    required RenderBox referenceBox,
    required Offset position,
    required Color color,
    required TextDirection textDirection,
    bool containedInkWell = false,
    RectCallback? rectCallback,
    BorderRadius? borderRadius,
    ShapeBorder? customBorder,
    double? radius,
    VoidCallback? onRemoved,
  }) {
    return FrostedInkSplash(
      controller: controller,
      referenceBox: referenceBox,
      color: color,
      position: position,
      containedInkWell: containedInkWell,
      borderRadius: borderRadius,
      radius: radius,
      onRemoved: onRemoved,
    );
  }
}
