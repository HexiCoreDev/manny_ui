import 'package:flutter/material.dart';

/// Global runtime configuration for the Manny UI component set.
///
/// Wrap your app in [MannyConfig] to control features like neumorphic shadows:
///
/// ```dart
/// MannyConfig(
///   neumorphic: true,  // toggle neumorphic shadows
///   child: MaterialApp(...),
/// )
/// ```
///
/// Components read the config via:
/// ```dart
/// final config = MannyConfig.of(context);
/// if (config.neumorphic) { /* draw shadows */ }
/// ```
class MannyConfig extends InheritedWidget {
  const MannyConfig({
    super.key,
    required super.child,
    this.neumorphic = true,
  });

  /// Whether neumorphic shadows are enabled globally.
  /// Frosted glass (blur + translucency) remains always active.
  final bool neumorphic;

  /// Get the nearest [MannyConfig] or a default with neumorphic enabled.
  static MannyConfig of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<MannyConfig>() ??
        const MannyConfig(child: SizedBox.shrink());
  }

  /// Check if neumorphic is enabled without requiring the widget.
  static bool isNeumorphic(BuildContext context) {
    return context
            .dependOnInheritedWidgetOfExactType<MannyConfig>()
            ?.neumorphic ??
        true;
  }

  @override
  bool updateShouldNotify(MannyConfig oldWidget) =>
      neumorphic != oldWidget.neumorphic;
}
