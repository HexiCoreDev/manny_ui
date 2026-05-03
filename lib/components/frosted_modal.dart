import 'package:flutter/material.dart';
import 'package:manny_ui/src/sheets/frosted_bar_sheet.dart';
import 'package:manny_ui/src/sheets/frosted_cupertino_sheet.dart';

/// Frosted glass modal bottom sheets.
///
/// Provides Cupertino-style and bar-style modals with backdrop blur,
/// translucent surfaces, and neumorphic soft shadows.
///
/// Example usage:
/// ```dart
/// FrostedModal.showCupertino(
///   context: context,
///   builder: (context) => MySheetContent(),
/// );
///
/// FrostedModal.showBar(
///   context: context,
///   builder: (context) => MySheetContent(),
/// );
/// ```
class FrostedModal {
  FrostedModal._();

  /// Show a Cupertino-style frosted modal bottom sheet (full-screen capable).
  static Future<T?> showCupertino<T>({
    required BuildContext context,
    required WidgetBuilder builder,
    bool expand = false,
    bool enableDrag = true,
    double blurSigma = 20.0, // kept for API compat, ignored
    double opacity = 0.12, // kept for API compat, ignored
    double topRadius = 12.0,
    Duration? duration,
  }) {
    return showFrostedCupertinoSheet<T>(
      context: context,
      useRootNavigator: true,
      expand: expand,
      enableDrag: enableDrag,
      duration: duration,
      topRadius: Radius.circular(topRadius),
      builder: builder,
    );
  }

  /// Show a bar-style frosted modal bottom sheet (Material-ish with top bar).
  static Future<T?> showBar<T>({
    required BuildContext context,
    required WidgetBuilder builder,
    bool expand = false,
    bool enableDrag = true,
    double blurSigma = 20.0, // kept for API compat, ignored
    double opacity = 0.12, // kept for API compat, ignored
    double topRadius = 25.0,
    Duration? duration,
  }) {
    return showFrostedBarSheet<T>(
      context: context,
      useRootNavigator: true,
      expand: expand,
      enableDrag: enableDrag,
      duration: duration,
      topRadius: Radius.circular(topRadius),
      builder: builder,
    );
  }
}
