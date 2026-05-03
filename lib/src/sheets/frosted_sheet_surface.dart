import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:manny_ui/config/ui_constants.dart';
import 'package:manny_ui/utils/neumorphic_painter.dart';

/// Canonical frosted visual surface for manny_ui modal bottom sheets.
///
/// This widget owns the sheet surface itself: one clipped blur layer, an
/// optional neumorphic painter, and a translucent tinted container. Sheet route
/// and drag behavior should render their content into this surface instead of
/// wrapping an external bottom-sheet widget.
///
/// Example usage:
/// ```dart
/// FrostedSheetSurface(
///   dragHandle: SizedBox(width: 36, height: 4),
///   padding: EdgeInsets.all(16),
///   child: Text('Sheet content'),
/// )
/// ```
class FrostedSheetSurface extends StatelessWidget {
  const FrostedSheetSurface({
    super.key,
    required this.child,
    this.topRadius,
    this.bottomRadius = Radius.zero,
    this.blurSigma,
    this.opacity,
    this.tintColor,
    this.dragHandle,
    this.dragHandleSpacing = 8.0,
    this.useNeumorphicPainter = true,
    this.useBorder = true,
    this.padding,
  });

  final Widget child;
  final Radius? topRadius;
  final Radius bottomRadius;
  final double? blurSigma;
  final double? opacity;
  final Color? tintColor;
  final Widget? dragHandle;
  final double dragHandleSpacing;
  final bool useNeumorphicPainter;
  final bool useBorder;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    // In dark mode, theme.colorScheme.surface is near-black. At 12% alpha on a
    // dark backdrop, the frosted tint becomes invisible. Lift the tint base
    // toward white in dark mode so the surface stays legibly frosted even
    // when the backdrop is fully dark (e.g. expand:true Cupertino sheets).
    final tintBase = tintColor ??
        (isDark
            ? Color.lerp(theme.colorScheme.surface, Colors.white, 0.18)!
            : theme.colorScheme.surface);

    final effectiveBlurSigma = blurSigma ?? UIConstants.glassBlurSigma;
    final effectiveOpacity = opacity ?? UIConstants.glassOpacity;
    final effectiveTopRadius =
        topRadius ?? const Radius.circular(UIConstants.glassSheetTopRadius);
    final effectiveRadius = BorderRadius.only(
      topLeft: effectiveTopRadius,
      topRight: effectiveTopRadius,
      bottomLeft: bottomRadius,
      bottomRight: bottomRadius,
    );
    // In dark mode, also bump opacity a touch so the lifted tint actually
    // shows through; this preserves the frosted-but-translucent look without
    // collapsing into "flat dark surface".
    final effectiveSurfaceColor = tintBase.withValues(
      alpha: isDark ? (effectiveOpacity * 1.6).clamp(0.0, 1.0) : effectiveOpacity,
    );

    final sheetChild = dragHandle == null
        ? child
        : Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: EdgeInsets.only(top: dragHandleSpacing),
                child: Center(child: dragHandle),
              ),
              child,
            ],
          );

    return FrostedSheetScope(
      child: ClipRRect(
        borderRadius: effectiveRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: effectiveBlurSigma,
            sigmaY: effectiveBlurSigma,
          ),
          child: CustomPaint(
            painter: useNeumorphicPainter
                ? NeumorphicPainter(
                    style: const NeumorphicStyle(),
                    borderRadius: effectiveRadius,
                    surfaceColor: effectiveSurfaceColor,
                    lightColor: Colors.transparent,
                    darkColor: Colors.transparent,
                    isDark: isDark,
                  )
                : null,
            child: Container(
              padding: padding,
              decoration: BoxDecoration(
                color: effectiveSurfaceColor,
                borderRadius: effectiveRadius,
                border: useBorder
                    ? Border.all(
                        color: isDark
                            ? Colors.white.withValues(
                                alpha: UIConstants.glassBorderOpacityDark,
                              )
                            : Colors.white.withValues(
                                alpha: UIConstants.glassBorderOpacityLight,
                              ),
                        width: 0.5,
                      )
                    : null,
              ),
              // Material(transparency) gives nested TextField / FilterChip /
              // IconButton / etc. a Material ancestor so InkResponse and
              // ripples render correctly. Does not paint anything itself.
              //
              // IconButtonTheme enforces a circular highlight shape and a
              // uniform overlay color so every IconButton placed inside any
              // frosted sheet (close X, back, custom actions in
              // FrostedScaffold leading/trailing, sheet-internal close
              // buttons, etc.) gets the same look without per-caller styling.
              child: Material(
                type: MaterialType.transparency,
                child: IconButtonTheme(
                  data: IconButtonThemeData(
                    style: IconButton.styleFrom(
                      shape: const CircleBorder(),
                      overlayColor: theme.colorScheme.onSurface
                          .withValues(alpha: 0.10),
                    ),
                  ),
                  child: sheetChild,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Marker [InheritedWidget] indicating the descendant tree is rendered
/// inside a frosted modal sheet surface.
///
/// Ambient widgets like [FrostedScaffold] use this to switch to transparent
/// backgrounds automatically, so callers don't need to pass
/// `backgroundColor: Colors.transparent` themselves when nesting a scaffold
/// inside a frosted sheet.
class FrostedSheetScope extends InheritedWidget {
  const FrostedSheetScope({super.key, required super.child});

  /// Returns true if the current build context is inside a
  /// [FrostedSheetSurface].
  static bool isInside(BuildContext context) {
    return context
            .dependOnInheritedWidgetOfExactType<FrostedSheetScope>() !=
        null;
  }

  @override
  bool updateShouldNotify(FrostedSheetScope oldWidget) => false;
}
