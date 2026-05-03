import 'package:flutter/material.dart';

/// A reusable wrapper widget that applies SafeArea with customizable options.
///
/// This widget provides consistent safe area handling across the app while
/// allowing per-page customization when needed.
///
/// Example usage:
/// ```dart
/// SafeAreaWrapper(
///   child: MyPageContent(),
/// )
///
/// // Disable top safe area (useful when AppBar handles it)
/// SafeAreaWrapper(
///   top: false,
///   child: MyPageContent(),
/// )
///
/// // Completely disable safe area
/// SafeAreaWrapper(
///   enabled: false,
///   child: MyPageContent(),
/// )
/// ```
class SafeAreaWrapper extends StatelessWidget {
  /// The child widget to wrap with SafeArea.
  final Widget child;

  /// Whether to apply SafeArea at all. Defaults to true.
  final bool enabled;

  /// Whether to apply safe area padding on top. Defaults to true.
  final bool top;

  /// Whether to apply safe area padding on bottom. Defaults to true.
  final bool bottom;

  /// Whether to apply safe area padding on left. Defaults to true.
  final bool left;

  /// Whether to apply safe area padding on right. Defaults to true.
  final bool right;

  /// Minimum padding to maintain even when SafeArea would be zero.
  final EdgeInsets? minimum;

  const SafeAreaWrapper({
    super.key,
    required this.child,
    this.enabled = true,
    this.top = true,
    this.bottom = true,
    this.left = true,
    this.right = true,
    this.minimum,
  });

  @override
  Widget build(BuildContext context) {
    if (!enabled) {
      return child;
    }

    return SafeArea(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      minimum: minimum ?? EdgeInsets.zero,
      child: child,
    );
  }
}
