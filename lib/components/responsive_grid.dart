import 'package:flutter/material.dart';
import 'package:manny_ui/utils/responsive_layout.dart';

/// A responsive grid that adapts column count based on screen size.
///
/// ```dart
/// ResponsiveGrid(
///   children: items.map((item) => CardWidget(item)).toList(),
/// )
/// ```
///
/// Or with custom column counts:
/// ```dart
/// ResponsiveGrid(
///   mobileCols: 1,
///   tabletCols: 2,
///   desktopCols: 3,
///   spacing: 16,
///   children: [...],
/// )
/// ```
class ResponsiveGrid extends StatelessWidget {
  const ResponsiveGrid({
    super.key,
    required this.children,
    this.mobileCols = 1,
    this.tabletCols = 2,
    this.desktopCols = 3,
    this.largeDesktopCols,
    this.spacing = 16,
    this.runSpacing,
    this.childAspectRatio = 1.0,
    this.shrinkWrap = false,
    this.physics,
    this.padding,
  });

  final List<Widget> children;
  final int mobileCols;
  final int tabletCols;
  final int desktopCols;
  final int? largeDesktopCols;
  final double spacing;
  final double? runSpacing;
  final double childAspectRatio;
  final bool shrinkWrap;
  final ScrollPhysics? physics;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final cols = ResponsiveLayout.value(
      context,
      mobile: mobileCols,
      tablet: tabletCols,
      desktop: desktopCols,
      largeDesktop: largeDesktopCols ?? desktopCols + 1,
    );

    return GridView.builder(
      shrinkWrap: shrinkWrap,
      physics: physics ?? const NeverScrollableScrollPhysics(),
      padding: padding,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: cols,
        mainAxisSpacing: runSpacing ?? spacing,
        crossAxisSpacing: spacing,
        childAspectRatio: childAspectRatio,
      ),
      itemCount: children.length,
      itemBuilder: (_, i) => children[i],
    );
  }
}

/// A responsive wrap that stacks vertically on mobile and wraps on larger screens.
///
/// ```dart
/// ResponsiveWrap(
///   children: [Button('A'), Button('B'), Button('C')],
/// )
/// ```
class ResponsiveWrap extends StatelessWidget {
  const ResponsiveWrap({
    super.key,
    required this.children,
    this.spacing = 12,
    this.runSpacing = 12,
    this.alignment = WrapAlignment.start,
    this.mobileDirection = Axis.vertical,
  });

  final List<Widget> children;
  final double spacing;
  final double runSpacing;
  final WrapAlignment alignment;

  /// On mobile, stack children in this direction.
  /// On tablet+, always uses Wrap.
  final Axis mobileDirection;

  @override
  Widget build(BuildContext context) {
    if (context.isMobile && mobileDirection == Axis.vertical) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (int i = 0; i < children.length; i++) ...[
            children[i],
            if (i < children.length - 1) SizedBox(height: runSpacing),
          ],
        ],
      );
    }

    return Wrap(
      spacing: spacing,
      runSpacing: runSpacing,
      alignment: alignment,
      children: children,
    );
  }
}

/// A container that limits max width based on screen size for centered content.
///
/// ```dart
/// ContentContainer(
///   child: Column(children: [...]),
/// )
/// ```
class ContentContainer extends StatelessWidget {
  const ContentContainer({
    super.key,
    required this.child,
    this.maxWidth,
    this.padding,
  });

  final Widget child;
  final double? maxWidth;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final effectiveMaxWidth =
        maxWidth ?? ResponsiveLayout.maxContentWidth(context);
    final effectivePadding =
        padding ?? EdgeInsets.symmetric(
          horizontal: ResponsiveLayout.horizontalPadding(context),
        );

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: effectiveMaxWidth),
        child: Padding(
          padding: effectivePadding,
          child: child,
        ),
      ),
    );
  }
}
