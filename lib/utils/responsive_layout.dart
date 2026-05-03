import 'package:flutter/material.dart';

/// Breakpoint definitions for responsive design.
class Breakpoints {
  Breakpoints._();

  /// Mobile: < 600px
  static const double mobile = 600;

  /// Tablet: 600px - 1200px
  static const double tablet = 1200;

  /// Large desktop: > 1600px
  static const double largeDesktop = 1600;
}

/// Screen size categories.
enum ScreenSize { mobile, tablet, desktop, largeDesktop }

/// Responsive layout utilities and builder widget.
class ResponsiveLayout extends StatelessWidget {
  final Widget mobileView;
  final Widget? tabletView;
  final Widget? desktopView;

  const ResponsiveLayout({
    super.key,
    required this.mobileView,
    this.tabletView,
    this.desktopView,
  });

  /// Check if current screen is mobile.
  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < Breakpoints.mobile;

  /// Check if current screen is tablet.
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= Breakpoints.mobile && width < Breakpoints.tablet;
  }

  /// Check if current screen is desktop.
  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= Breakpoints.tablet;

  /// Check if current screen is large desktop.
  static bool isLargeDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= Breakpoints.largeDesktop;

  /// Get current screen size category.
  static ScreenSize getScreenSize(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width >= Breakpoints.largeDesktop) return ScreenSize.largeDesktop;
    if (width >= Breakpoints.tablet) return ScreenSize.desktop;
    if (width >= Breakpoints.mobile) return ScreenSize.tablet;
    return ScreenSize.mobile;
  }

  /// Get screen width.
  static double screenWidth(BuildContext context) =>
      MediaQuery.of(context).size.width;

  /// Get screen height.
  static double screenHeight(BuildContext context) =>
      MediaQuery.of(context).size.height;

  /// Get responsive value based on screen size.
  static T value<T>(
    BuildContext context, {
    required T mobile,
    T? tablet,
    T? desktop,
    T? largeDesktop,
  }) {
    final size = getScreenSize(context);
    switch (size) {
      case ScreenSize.largeDesktop:
        return largeDesktop ?? desktop ?? tablet ?? mobile;
      case ScreenSize.desktop:
        return desktop ?? tablet ?? mobile;
      case ScreenSize.tablet:
        return tablet ?? mobile;
      case ScreenSize.mobile:
        return mobile;
    }
  }

  /// Get responsive padding based on screen size.
  static EdgeInsets padding(BuildContext context) {
    return value(
      context,
      mobile: const EdgeInsets.all(16),
      tablet: const EdgeInsets.all(24),
      desktop: const EdgeInsets.all(32),
      largeDesktop: const EdgeInsets.all(40),
    );
  }

  /// Get responsive horizontal padding.
  static double horizontalPadding(BuildContext context) {
    return value(
      context,
      mobile: 16.0,
      tablet: 24.0,
      desktop: 32.0,
      largeDesktop: 48.0,
    );
  }

  /// Get responsive grid column count.
  static int gridColumns(BuildContext context) {
    return value(context, mobile: 2, tablet: 3, desktop: 4, largeDesktop: 5);
  }

  /// Get max content width for centered layouts.
  static double maxContentWidth(BuildContext context) {
    return value(
      context,
      mobile: double.infinity,
      tablet: 800.0,
      desktop: 1200.0,
      largeDesktop: 1400.0,
    );
  }

  /// Get responsive modal max width (compact).
  static double modalMaxWidth(BuildContext context) {
    return value(
      context,
      mobile: double.infinity,
      tablet: 400.0,
      desktop: 450.0,
    );
  }

  /// Get responsive large modal max width (for content-heavy modals).
  static double largeModalMaxWidth(BuildContext context) {
    return value(
      context,
      mobile: double.infinity,
      tablet: 800.0,
      desktop: 900.0,
    );
  }

  /// Get responsive bottom sheet max width.
  static double bottomSheetMaxWidth(BuildContext context) {
    return value(
      context,
      mobile: double.infinity,
      tablet: 400.0,
      desktop: 450.0,
    );
  }

  /// Get responsive page content max width.
  static double pageContentMaxWidth(BuildContext context) {
    return value(
      context,
      mobile: double.infinity,
      tablet: 700.0,
      desktop: 800.0,
    );
  }

  /// Get responsive grid cross axis count.
  static int responsiveGridCount(
    BuildContext context, {
    int mobile = 1,
    int tablet = 2,
    int desktop = 3,
    int? largeDesktop,
  }) {
    return value(
      context,
      mobile: mobile,
      tablet: tablet,
      desktop: desktop,
      largeDesktop: largeDesktop ?? desktop + 1,
    );
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (_, constraints) {
      if (constraints.maxWidth >= Breakpoints.tablet) {
        return desktopView ?? tabletView ?? mobileView;
      } else if (constraints.maxWidth >= Breakpoints.mobile) {
        return tabletView ?? mobileView;
      }
      return mobileView;
    },
  );
}

/// A builder widget that provides screen size information.
class ResponsiveBuilder extends StatelessWidget {
  final Widget Function(
    BuildContext context,
    ScreenSize screenSize,
    BoxConstraints constraints,
  )
  builder;

  const ResponsiveBuilder({super.key, required this.builder});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenSize = ResponsiveLayout.getScreenSize(context);
        return builder(context, screenSize, constraints);
      },
    );
  }
}

/// Extension for easy responsive value access.
extension ResponsiveContext on BuildContext {
  bool get isMobile => ResponsiveLayout.isMobile(this);
  bool get isTablet => ResponsiveLayout.isTablet(this);
  bool get isDesktop => ResponsiveLayout.isDesktop(this);
  bool get isLargeDesktop => ResponsiveLayout.isLargeDesktop(this);
  ScreenSize get screenSize => ResponsiveLayout.getScreenSize(this);
  double get screenWidth => ResponsiveLayout.screenWidth(this);
  double get screenHeight => ResponsiveLayout.screenHeight(this);

  /// Get responsive value.
  T responsive<T>({required T mobile, T? tablet, T? desktop, T? largeDesktop}) {
    return ResponsiveLayout.value(
      this,
      mobile: mobile,
      tablet: tablet,
      desktop: desktop,
      largeDesktop: largeDesktop,
    );
  }
}
