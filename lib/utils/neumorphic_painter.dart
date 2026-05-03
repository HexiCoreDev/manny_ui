import 'dart:math';
import 'package:flutter/material.dart';

/// Shape type for neumorphic rendering.
enum NeumorphicShape {
  /// Raised surface — light on lit side, dark on shadow side.
  convex,

  /// Pressed-in surface — shadows swap (inner shadow effect).
  concave,

  /// Flat surface with outer shadows only (no surface gradient).
  flat,
}

/// Light source angle and depth config for neumorphic rendering.
/// 0° = top, 90° = right, 180° = bottom, 270° = left.
class NeumorphicStyle {
  /// Light source angle in degrees (0-360). Default 315 (top-left).
  final double lightAngle;

  /// Depth of extrusion. Higher = more pronounced shadows. Range 0–12.
  final double depth;

  /// Blur spread multiplier. Default 1.0.
  final double spread;

  /// Intensity of the light highlight (0.0–1.0).
  final double lightIntensity;

  /// Intensity of the dark shadow (0.0–1.0).
  final double darkIntensity;

  /// Surface shape: convex (raised), concave (pressed), flat.
  final NeumorphicShape shape;

  /// Surface gradient intensity (0.0–1.0). Controls how
  /// pronounced the 3D shading on the surface is.
  final double surfaceIntensity;

  const NeumorphicStyle({
    this.lightAngle = 315,
    this.depth = 6.0,
    this.spread = 1.0,
    this.lightIntensity = 0.7,
    this.darkIntensity = 0.5,
    this.shape = NeumorphicShape.convex,
    this.surfaceIntensity = 0.3,
  });

  /// Convenience for a concave (pressed) version of this style.
  NeumorphicStyle get pressed => NeumorphicStyle(
        lightAngle: lightAngle,
        depth: depth * 0.5,
        spread: spread,
        lightIntensity: lightIntensity,
        darkIntensity: darkIntensity,
        shape: NeumorphicShape.concave,
        surfaceIntensity: surfaceIntensity,
      );

  /// Offset for the light (highlight) shadow.
  Offset get lightOffset {
    final rad = lightAngle * pi / 180;
    return Offset(-cos(rad) * depth, -sin(rad) * depth);
  }

  /// Offset for the dark shadow.
  Offset get darkOffset {
    final rad = lightAngle * pi / 180;
    return Offset(cos(rad) * depth, sin(rad) * depth);
  }

  double get blurRadius => depth * 2 * spread;
}

/// Paints a neumorphic container with:
/// - Dual offset outer shadows (convex) or inner shadows (concave)
/// - Multi-layer shadows (light + dark + ambient)
/// - Linear gradient border (lit corner → shadow corner)
/// - Convex/concave surface shading
/// - Emboss masking via BlendMode.dstOut for concave shapes
class NeumorphicPainter extends CustomPainter {
  final NeumorphicStyle style;
  final BorderRadius borderRadius;
  final Color surfaceColor;
  final Color lightColor;
  final Color darkColor;
  final bool isDark;
  final double borderWidth;

  NeumorphicPainter({
    required this.style,
    required this.borderRadius,
    required this.surfaceColor,
    required this.lightColor,
    required this.darkColor,
    required this.isDark,
    this.borderWidth = 1.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = borderRadius.toRRect(rect);

    if (style.shape == NeumorphicShape.concave) {
      // Concave: surface first, then inner shadows on top
      _drawSurface(canvas, rrect);
      _drawInnerShadows(canvas, rrect);
    } else {
      // Convex/flat: outer shadows first, then surface
      _drawOuterShadows(canvas, rrect);
      _drawSurface(canvas, rrect);
    }

    // Border gradient
    _drawLinearBorder(canvas, size, rrect);

    // Surface shading (convex/concave)
    if (style.shape != NeumorphicShape.flat) {
      _drawSurfaceShading(canvas, rrect.deflate(borderWidth));
    }
  }

  void _drawSurface(Canvas canvas, RRect rrect) {
    if (surfaceColor.a > 0) {
      canvas.drawRRect(rrect, Paint()..color = surfaceColor);
    }
  }

  void _drawOuterShadows(Canvas canvas, RRect rrect) {
    if (style.depth < 0.5) return;

    // Ambient shadow (subtle, centered, larger blur)
    final ambientAlpha = isDark ? 0.15 : 0.04;
    final ambientPaint = Paint()
      ..color = Colors.black.withValues(alpha: ambientAlpha)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, style.blurRadius * 1.5);
    canvas.drawRRect(rrect, ambientPaint);

    // Light shadow
    if (lightColor.a > 0) {
      final paint = Paint()
        ..color = lightColor
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, style.blurRadius);
      canvas.save();
      canvas.translate(style.lightOffset.dx, style.lightOffset.dy);
      canvas.drawRRect(rrect, paint);
      canvas.restore();
    }

    // Dark shadow
    if (darkColor.a > 0) {
      final paint = Paint()
        ..color = darkColor
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, style.blurRadius);
      canvas.save();
      canvas.translate(style.darkOffset.dx, style.darkOffset.dy);
      canvas.drawRRect(rrect, paint);
      canvas.restore();
    }
  }

  void _drawInnerShadows(Canvas canvas, RRect rrect) {
    if (style.depth < 0.5) return;
    final blur = style.blurRadius * 0.7;

    // Save layer for emboss masking
    canvas.saveLayer(rrect.outerRect.inflate(20), Paint());

    // Dark inner shadow (top-left for 315° light → shadow comes from bottom-right)
    final darkInner = Paint()
      ..color = isDark
          ? Colors.black.withValues(alpha: 0.5 * style.darkIntensity)
          : Colors.black.withValues(alpha: 0.12 * style.darkIntensity)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, blur);
    canvas.save();
    canvas.translate(style.darkOffset.dx * 0.5, style.darkOffset.dy * 0.5);
    canvas.drawRRect(rrect, darkInner);
    canvas.restore();

    // Light inner shadow
    final lightInner = Paint()
      ..color = isDark
          ? Colors.white.withValues(alpha: 0.06 * style.lightIntensity)
          : Colors.white.withValues(alpha: 0.5 * style.lightIntensity)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, blur);
    canvas.save();
    canvas.translate(style.lightOffset.dx * 0.5, style.lightOffset.dy * 0.5);
    canvas.drawRRect(rrect, lightInner);
    canvas.restore();

    // Mask: cut out the shape interior so shadows only show at edges
    canvas.drawRRect(rrect, Paint()..blendMode = BlendMode.dstOut);

    canvas.restore();
  }

  void _drawLinearBorder(Canvas canvas, Size size, RRect rrect) {
    if (borderWidth <= 0) return;

    final rad = style.lightAngle * pi / 180;
    final fromAlign = Alignment(-cos(rad), -sin(rad));
    final toAlign = Alignment(cos(rad), sin(rad));

    final highlightColor = isDark
        ? Colors.white.withValues(alpha: 0.14 * style.lightIntensity)
        : Colors.white.withValues(alpha: 0.9 * style.lightIntensity);
    final shadowColor = isDark
        ? Colors.black.withValues(alpha: 0.35 * style.darkIntensity)
        : Colors.black.withValues(alpha: 0.1 * style.darkIntensity);

    final gradient = LinearGradient(
      begin: fromAlign,
      end: toAlign,
      colors: [highlightColor, shadowColor],
    );

    final paint = Paint()
      ..shader = gradient.createShader(rrect.outerRect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;

    canvas.drawRRect(rrect.deflate(borderWidth / 2), paint);
  }

  void _drawSurfaceShading(Canvas canvas, RRect innerRRect) {
    if (style.surfaceIntensity < 0.01) return;

    // For concave: light comes from the angle → lit side is darker (indented)
    // For convex: invert → lit side is brighter (raised)
    final effectiveAngle = style.shape == NeumorphicShape.concave
        ? style.lightAngle
        : style.lightAngle + 180;
    final rad = effectiveAngle * pi / 180;
    final si = style.surfaceIntensity;

    final gradient = LinearGradient(
      begin: Alignment(cos(rad), sin(rad)),
      end: Alignment(-cos(rad), -sin(rad)),
      colors: [
        Colors.white.withValues(alpha: isDark ? 0.03 * si : 0.12 * si),
        Colors.black.withValues(alpha: isDark ? 0.06 * si : 0.05 * si),
      ],
    );

    canvas.drawRRect(
      innerRRect,
      Paint()..shader = gradient.createShader(innerRRect.outerRect),
    );
  }

  @override
  bool shouldRepaint(covariant NeumorphicPainter old) =>
      old.style.lightAngle != style.lightAngle ||
      old.style.depth != style.depth ||
      old.style.shape != style.shape ||
      old.style.surfaceIntensity != style.surfaceIntensity ||
      old.isDark != isDark ||
      old.surfaceColor != surfaceColor;
}

/// Convenience widget that wraps a child in a neumorphic container.
///
/// Supports convex (raised), concave (pressed), and flat shapes.
/// Use [Neumorphic.pressable] for interactive elements that animate
/// between convex and concave on tap.
class Neumorphic extends StatelessWidget {
  const Neumorphic({
    super.key,
    required this.child,
    this.style = const NeumorphicStyle(),
    this.borderRadius,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.surfaceColor,
  });

  final Widget child;
  final NeumorphicStyle style;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final Color? surfaceColor;

  /// Creates a neumorphic button that animates between convex and concave on press.
  static Widget pressable({
    Key? key,
    required Widget child,
    required VoidCallback onTap,
    NeumorphicStyle style = const NeumorphicStyle(),
    BorderRadius? borderRadius,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    double? width,
    double? height,
    Color? surfaceColor,
    Duration duration = const Duration(milliseconds: 150),
  }) {
    return _NeumorphicPressable(
      key: key,
      onTap: onTap,
      style: style,
      borderRadius: borderRadius,
      padding: padding,
      margin: margin,
      width: width,
      height: height,
      surfaceColor: surfaceColor,
      duration: duration,
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final effectiveRadius = borderRadius ?? BorderRadius.circular(20);
    final effectiveSurface = surfaceColor ?? theme.colorScheme.surface;

    final lightColor = isDark
        ? Colors.white.withValues(alpha: 0.05 * style.lightIntensity)
        : Colors.white.withValues(alpha: 0.7 * style.lightIntensity);
    final darkColor = isDark
        ? Colors.black.withValues(alpha: 0.6 * style.darkIntensity)
        : Colors.black.withValues(alpha: 0.15 * style.darkIntensity);

    return Container(
      width: width,
      height: height,
      margin: margin,
      child: CustomPaint(
        painter: NeumorphicPainter(
          style: style,
          borderRadius: effectiveRadius,
          surfaceColor: effectiveSurface.withValues(
            alpha: isDark ? 0.15 : 0.85,
          ),
          lightColor: lightColor,
          darkColor: darkColor,
          isDark: isDark,
        ),
        child: Padding(padding: padding ?? EdgeInsets.zero, child: child),
      ),
    );
  }
}

/// Internal: animates between convex and concave on press.
class _NeumorphicPressable extends StatefulWidget {
  const _NeumorphicPressable({
    super.key,
    required this.child,
    required this.onTap,
    required this.style,
    required this.duration,
    this.borderRadius,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.surfaceColor,
  });

  final Widget child;
  final VoidCallback onTap;
  final NeumorphicStyle style;
  final Duration duration;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final Color? surfaceColor;

  @override
  State<_NeumorphicPressable> createState() => _NeumorphicPressableState();
}

class _NeumorphicPressableState extends State<_NeumorphicPressable> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final currentStyle = _pressed ? widget.style.pressed : widget.style;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: widget.duration,
        curve: Curves.easeOutCubic,
        child: Neumorphic(
          style: currentStyle,
          borderRadius: widget.borderRadius,
          padding: widget.padding,
          margin: widget.margin,
          width: widget.width,
          height: widget.height,
          surfaceColor: widget.surfaceColor,
          child: widget.child,
        ),
      ),
    );
  }
}
