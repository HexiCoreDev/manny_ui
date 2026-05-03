import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:manny_ui/config/ui_constants.dart';

/// A reusable blurred AppBar component with consistent styling.
///
/// Features:
/// - Blur effect via BackdropFilter
/// - Matches scaffold background when at top
/// - Consistent left-aligned title
/// - Smooth transition effects
///
/// Example usage:
/// ```dart
/// Scaffold(
///   appBar: BlurredAppBar(
///     title: 'Dashboard',
///     actions: [
///       IconButton(icon: Icon(Icons.settings), onPressed: () {}),
///     ],
///   ),
///   body: ...,
/// )
/// ```
class BlurredAppBar extends StatelessWidget implements PreferredSizeWidget {
  const BlurredAppBar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.automaticallyImplyLeading = true,
    this.bottom,
    this.centerTitle = false,
    this.titleSpacing,
    this.scrolledUnderElevation = 0,
    this.blurSigma = 10.0,
    this.backgroundOpacity = 0.85,
    this.frosted = false,
  });

  /// The title widget or string to display.
  final dynamic title;

  /// Action widgets to display in the app bar.
  final List<Widget>? actions;

  /// Leading widget (back button, menu, etc.).
  final Widget? leading;

  /// Whether to show back button automatically.
  final bool automaticallyImplyLeading;

  /// Bottom widget (e.g., TabBar).
  final PreferredSizeWidget? bottom;

  /// Whether to center the title (default: false - left aligned).
  final bool centerTitle;

  /// Spacing around the title.
  final double? titleSpacing;

  /// Elevation when scrolled under.
  final double scrolledUnderElevation;

  /// Blur intensity. Defaults to 10.0.
  final double blurSigma;

  /// Background opacity. Defaults to 0.85.
  final double backgroundOpacity;

  /// Use frosted glass + neumorphic styling instead of plain blur.
  final bool frosted;

  @override
  Size get preferredSize =>
      Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0));

  Widget _buildTitle() {
    if (title is String) {
      return Text(
        title as String,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
      );
    } else if (title is Widget) {
      return title as Widget;
    }
    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final titleWidget = _buildTitle();

    final appBar = AppBar(
      title: titleWidget,
      centerTitle: centerTitle,
      titleSpacing: titleSpacing,
      leading: leading,
      automaticallyImplyLeading: automaticallyImplyLeading,
      actions: actions,
      bottom: bottom,
      elevation: 0,
      scrolledUnderElevation: scrolledUnderElevation,
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
    );

    if (frosted) {
      final isDark = theme.brightness == Brightness.dark;
      return ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface.withValues(
                alpha: UIConstants.glassOpacity,
              ),
              border: Border(
                bottom: BorderSide(
                  color: isDark
                      ? Colors.white.withValues(alpha: UIConstants.glassBorderOpacityDark)
                      : Colors.white.withValues(alpha: UIConstants.glassBorderOpacityLight),
                  width: 0.5,
                ),
              ),
            ),
            child: appBar,
          ),
        ),
      );
    }

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: Container(
          color: theme.scaffoldBackgroundColor.withValues(alpha: backgroundOpacity),
          child: appBar,
        ),
      ),
    );
  }
}

/// A SliverAppBar variant with blur effect for CustomScrollView usage.
class BlurredSliverAppBar extends StatelessWidget {
  const BlurredSliverAppBar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.automaticallyImplyLeading = true,
    this.pinned = true,
    this.floating = false,
    this.snap = false,
    this.centerTitle = false,
    this.titleSpacing,
    this.expandedHeight,
    this.customFlexibleSpace,
    this.blurSigma = 10.0,
    this.backgroundOpacity = 0.85,
  });

  /// The title widget or string to display.
  final dynamic title;

  /// Action widgets to display in the app bar.
  final List<Widget>? actions;

  /// Leading widget (back button, menu, etc.).
  final Widget? leading;

  /// Whether to show back button automatically.
  final bool automaticallyImplyLeading;

  /// Whether the app bar should remain visible at the top.
  final bool pinned;

  /// Whether the app bar should become visible as soon as user scrolls up.
  final bool floating;

  /// If floating, whether it should snap into view.
  final bool snap;

  /// Whether to center the title (default: false - left aligned).
  final bool centerTitle;

  /// Spacing around the title.
  final double? titleSpacing;

  /// The height of the app bar when fully expanded.
  final double? expandedHeight;

  /// Widget to display behind the app bar (e.g., image).
  final Widget? customFlexibleSpace;

  /// Blur intensity. Defaults to 10.0.
  final double blurSigma;

  /// Background opacity. Defaults to 0.85.
  final double backgroundOpacity;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Build the title widget.
    Widget titleWidget;
    if (title is String) {
      titleWidget = Text(
        title as String,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
      );
    } else if (title is Widget) {
      titleWidget = title as Widget;
    } else {
      titleWidget = const SizedBox.shrink();
    }

    // Build flexible space with blur effect.
    Widget? effectiveFlexibleSpace;
    if (customFlexibleSpace != null) {
      effectiveFlexibleSpace = FlexibleSpaceBar(
        background: customFlexibleSpace,
      );
    } else {
      effectiveFlexibleSpace = ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
          child: Container(color: Colors.transparent),
        ),
      );
    }

    return SliverAppBar(
      title: titleWidget,
      centerTitle: centerTitle,
      titleSpacing: titleSpacing,
      leading: leading,
      automaticallyImplyLeading: automaticallyImplyLeading,
      actions: actions,
      pinned: pinned,
      floating: floating,
      snap: snap,
      expandedHeight: expandedHeight,
      flexibleSpace: effectiveFlexibleSpace,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: theme.scaffoldBackgroundColor.withValues(
        alpha: backgroundOpacity,
      ),
      surfaceTintColor: Colors.transparent,
    );
  }
}
