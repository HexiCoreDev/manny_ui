import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import 'package:manny_ui/config/ui_constants.dart';
import 'package:manny_ui/src/sheets/frosted_sheet_surface.dart';
import 'package:manny_ui/utils/responsive_layout.dart';

/// A scaffold with a built-in frosted glass app bar.
///
/// Handles body-behind-appbar layout internally — the developer just
/// provides a title, actions, and body. Content scrolls behind the
/// frosted glass automatically with correct padding.
///
/// ```dart
/// FrostedScaffold(
///   title: 'Dashboard',
///   actions: [IconButton(...)],
///   body: ListView(children: [...]),
/// )
/// ```
///
/// Set `extendBehindAppBar: false` to place body below the appbar
/// (no scroll-behind effect).
class FrostedScaffold extends StatelessWidget {
  const FrostedScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions,
    this.leading,
    this.centerTitle = true,
    this.automaticallyImplyLeading = true,
    this.extendBehindAppBar = true,
    this.toolbarHeight = kToolbarHeight,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.backgroundColor,
    this.extendBody = false,
    this.bodyPadding,
  });

  /// Horizontal padding applied around the body.
  /// If null, uses responsive padding (16 mobile, 24 tablet, 32 desktop).
  /// The top padding for the appbar is handled automatically.
  final EdgeInsetsGeometry? bodyPadding;

  final dynamic title;
  final Widget body;
  final List<Widget>? actions;
  final Widget? leading;
  final bool centerTitle;
  final bool automaticallyImplyLeading;
  final double toolbarHeight;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final Color? backgroundColor;

  /// Whether the body scrolls behind the frosted appbar.
  /// Defaults to true for the glass blur effect.
  final bool extendBehindAppBar;

  /// Whether the body extends behind the bottom navigation bar.
  final bool extendBody;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final statusBarHeight = MediaQuery.of(context).padding.top;
    final appBarTotalHeight = statusBarHeight + toolbarHeight;

    // When this scaffold is rendered INSIDE a frosted modal sheet, default
    // its background to transparent so the sheet's frost shows through.
    // Callers can still override by passing an explicit [backgroundColor].
    final effectiveBackgroundColor = backgroundColor ??
        (FrostedSheetScope.isInside(context) ? Colors.transparent : null);

    // Build title widget
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

    // Build the frosted app bar
    final frostedBar = ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: UIConstants.glassBlurSigma,
          sigmaY: UIConstants.glassBlurSigma,
        ),
        child: Container(
          height: appBarTotalHeight,
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
          child: Padding(
            padding: EdgeInsets.only(top: statusBarHeight),
            child: Material(
              type: MaterialType.transparency,
              // Force circular hover/press/splash highlight on every
              // IconButton placed in the leading or trailing slots so
              // they match the iOS/M3 expected look (no rectangular
              // ripple bounds). Overlay color matches the
              // FrostedSheetSurface recipe for uniform feel across
              // modal and non-modal contexts.
              child: IconButtonTheme(
                data: IconButtonThemeData(
                  style: IconButton.styleFrom(
                    shape: const CircleBorder(),
                    overlayColor: theme.colorScheme.onSurface
                        .withValues(alpha: 0.10),
                  ),
                ),
                child: NavigationToolbar(
                  leading: leading ??
                      (automaticallyImplyLeading &&
                              Navigator.of(context).canPop()
                          ? IconButton(
                              icon: const Icon(IconlyBroken.arrow_left_2),
                              onPressed: () => Navigator.of(context).pop(),
                            )
                          : null),
                  middle: titleWidget,
                  centerMiddle: centerTitle,
                  middleSpacing: NavigationToolbar.kMiddleSpacing,
                  trailing: actions != null
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: actions!,
                        )
                      : null,
                ),
              ),
            ),
          ),
        ),
      ),
    );

    if (!extendBehindAppBar) {
      return Scaffold(
        backgroundColor: effectiveBackgroundColor,
        extendBody: extendBody,
        bottomNavigationBar: bottomNavigationBar,
        floatingActionButton: floatingActionButton,
        body: Column(
          children: [
            frostedBar,
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: ResponsiveLayout.maxContentWidth(context),
                  ),
                  child: Padding(
                    padding: bodyPadding ?? EdgeInsets.symmetric(
                      horizontal: ResponsiveLayout.horizontalPadding(context),
                    ),
                    child: body,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Body scrolls behind the frosted appbar.
    // We inject appBarTotalHeight into MediaQuery.padding.top so that
    // ListView (with padding: null) auto-adds the right top padding.
    // Content starts below the appbar but scrolls up behind the glass.
    final existingPadding = MediaQuery.of(context).padding;
    return Scaffold(
      backgroundColor: effectiveBackgroundColor,
      extendBody: extendBody,
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
      body: Stack(
        children: [
          // Body — MediaQuery tells scrollables to pad for the appbar
          Positioned.fill(
            child: MediaQuery(
              data: MediaQuery.of(context).copyWith(
                padding: existingPadding.copyWith(
                  top: appBarTotalHeight + 8,
                ),
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: ResponsiveLayout.maxContentWidth(context),
                  ),
                  child: Padding(
                    padding: bodyPadding ?? EdgeInsets.symmetric(
                      horizontal: ResponsiveLayout.horizontalPadding(context),
                    ),
                    child: body,
                  ),
                ),
              ),
            ),
          ),
          // Frosted appbar on top
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: frostedBar,
          ),
        ],
      ),
    );
  }
}
