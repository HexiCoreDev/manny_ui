import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:manny_ui/config/ui_constants.dart';
import 'package:manny_ui/utils/neumorphic_painter.dart';

/// A frosted glass app bar matching the floating navbar's aesthetic.
///
/// Handles status bar padding internally via [SafeArea] — just like
/// Flutter's built-in [AppBar]. Works correctly with
/// `extendBodyBehindAppBar: true` without any manual padding on the body.
///
/// ```dart
/// Scaffold(
///   extendBodyBehindAppBar: true,
///   appBar: FrostedAppBar(title: 'Dashboard'),
///   body: ListView(...), // padding handled automatically
/// )
/// ```
class FrostedAppBar extends StatelessWidget implements PreferredSizeWidget {
  const FrostedAppBar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.centerTitle = true,
    this.automaticallyImplyLeading = true,
    this.bottom,
    this.titleSpacing,
    this.toolbarHeight,
    this.primary = true,
  });

  final dynamic title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool centerTitle;
  final bool automaticallyImplyLeading;
  final PreferredSizeWidget? bottom;
  final double? titleSpacing;
  final double? toolbarHeight;

  /// Whether this appbar accounts for the system status bar.
  /// Same as [AppBar.primary].
  final bool primary;

  @override
  Size get preferredSize {
    final h = toolbarHeight ?? kToolbarHeight;
    return Size.fromHeight(h + (bottom?.preferredSize.height ?? 0));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final tbHeight = toolbarHeight ?? kToolbarHeight;

    Widget titleWidget;
    if (title is String) {
      titleWidget = Text(
        title as String,
        style: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      );
    } else if (title is Widget) {
      titleWidget = title as Widget;
    } else {
      titleWidget = const SizedBox.shrink();
    }

    // The toolbar content — same layout as AppBar's internal structure
    Widget toolbar = SizedBox(
      height: tbHeight,
      child: NavigationToolbar(
        leading: leading ??
            (automaticallyImplyLeading && Navigator.of(context).canPop()
                ? const BackButton()
                : null),
        middle: titleWidget,
        centerMiddle: centerTitle,
        middleSpacing: titleSpacing ?? NavigationToolbar.kMiddleSpacing,
        trailing: actions != null
            ? Row(mainAxisSize: MainAxisSize.min, children: actions!)
            : null,
      ),
    );

    // SafeArea adds status bar padding — matching AppBar's primary behavior
    if (primary) {
      toolbar = SafeArea(bottom: false, child: toolbar);
    }

    if (bottom != null) {
      toolbar = Column(
        mainAxisSize: MainAxisSize.min,
        children: [toolbar, bottom!],
      );
    }

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: UIConstants.glassBlurSigma,
          sigmaY: UIConstants.glassBlurSigma,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface.withValues(
              alpha: UIConstants.glassOpacity,
            ),
            border: Border(
              bottom: BorderSide(
                color: isDark
                    ? Colors.white.withValues(
                        alpha: UIConstants.glassBorderOpacityDark)
                    : Colors.white.withValues(
                        alpha: UIConstants.glassBorderOpacityLight),
                width: 0.5,
              ),
            ),
          ),
          child: Material(
            type: MaterialType.transparency,
            child: toolbar,
          ),
        ),
      ),
    );
  }
}
