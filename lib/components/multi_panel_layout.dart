import 'package:flutter/material.dart';
import 'package:manny_ui/utils/responsive_layout.dart';

/// Multi-panel layout for tablet and desktop views.
///
/// Supports:
/// - Single panel (mobile)
/// - Two panels (tablet: list + detail)
/// - Three panels (desktop: nav + list + detail)
class MultiPanelLayout extends StatelessWidget {
  const MultiPanelLayout({
    super.key,
    required this.primaryPanel,
    this.secondaryPanel,
    this.tertiaryPanel,
    this.primaryPanelWidth,
    this.secondaryPanelWidth,
    this.showSecondaryOnMobile = false,
  });

  /// Main content panel (always visible).
  final Widget primaryPanel;

  /// Secondary panel (visible on tablet+).
  final Widget? secondaryPanel;

  /// Tertiary panel (visible on desktop+).
  final Widget? tertiaryPanel;

  /// Fixed width for primary panel (null = flexible).
  final double? primaryPanelWidth;

  /// Fixed width for secondary panel (null = flexible).
  final double? secondaryPanelWidth;

  /// Whether to show secondary panel on mobile as overlay.
  final bool showSecondaryOnMobile;

  @override
  Widget build(BuildContext context) {
    final screenSize = context.screenSize;

    switch (screenSize) {
      case ScreenSize.mobile:
        return primaryPanel;

      case ScreenSize.tablet:
        if (secondaryPanel == null) {
          return primaryPanel;
        }
        return Row(
          children: [
            SizedBox(width: primaryPanelWidth ?? 350, child: primaryPanel),
            const VerticalDivider(width: 1),
            Expanded(child: secondaryPanel!),
          ],
        );

      case ScreenSize.desktop:
      case ScreenSize.largeDesktop:
        if (secondaryPanel == null) {
          return primaryPanel;
        }
        return Row(
          children: [
            SizedBox(width: primaryPanelWidth ?? 350, child: primaryPanel),
            const VerticalDivider(width: 1),
            Expanded(
              child: tertiaryPanel != null
                  ? Row(
                      children: [
                        Expanded(child: secondaryPanel!),
                        const VerticalDivider(width: 1),
                        SizedBox(
                          width: secondaryPanelWidth ?? 400,
                          child: tertiaryPanel!,
                        ),
                      ],
                    )
                  : secondaryPanel!,
            ),
          ],
        );
    }
  }
}

/// A master-detail layout commonly used for list + detail views.
class MasterDetailLayout extends StatefulWidget {
  const MasterDetailLayout({
    super.key,
    required this.masterBuilder,
    required this.detailBuilder,
    this.emptyDetailBuilder,
    this.masterWidth = 350,
    this.breakpoint = Breakpoints.mobile,
    this.emptyDetailMessage = 'Select an item to view details',
    this.emptyDetailIcon = Icons.touch_app_outlined,
  });

  /// Builder for the master (list) panel.
  final Widget Function(BuildContext context, bool isExpanded) masterBuilder;

  /// Builder for the detail panel, receives selected item.
  final Widget Function(BuildContext context)? detailBuilder;

  /// Builder for empty detail state.
  final Widget Function(BuildContext context)? emptyDetailBuilder;

  /// Width of master panel on larger screens.
  final double masterWidth;

  /// Breakpoint at which to show side-by-side layout.
  final double breakpoint;

  /// Message shown in default empty detail state.
  final String emptyDetailMessage;

  /// Icon shown in default empty detail state.
  final IconData emptyDetailIcon;

  @override
  State<MasterDetailLayout> createState() => _MasterDetailLayoutState();
}

class _MasterDetailLayoutState extends State<MasterDetailLayout> {
  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final showSideBySide = width >= widget.breakpoint;

    if (showSideBySide) {
      return Row(
        children: [
          SizedBox(
            width: widget.masterWidth,
            child: widget.masterBuilder(context, false),
          ),
          const VerticalDivider(width: 1),
          Expanded(
            child:
                widget.detailBuilder?.call(context) ??
                widget.emptyDetailBuilder?.call(context) ??
                _buildEmptyState(context),
          ),
        ],
      );
    }

    // Mobile: Just show master, detail opens as new page.
    return widget.masterBuilder(context, true);
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            widget.emptyDetailIcon,
            size: 64,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            widget.emptyDetailMessage,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}

/// Adaptive grid that changes columns based on screen size.
class AdaptiveGrid extends StatelessWidget {
  const AdaptiveGrid({
    super.key,
    required this.children,
    this.mobileColumns = 2,
    this.tabletColumns = 3,
    this.desktopColumns = 4,
    this.largeDesktopColumns = 5,
    this.spacing = 16,
    this.runSpacing = 16,
    this.childAspectRatio = 1.0,
    this.padding,
    this.shrinkWrap = false,
    this.physics,
  });

  final List<Widget> children;
  final int mobileColumns;
  final int tabletColumns;
  final int desktopColumns;
  final int largeDesktopColumns;
  final double spacing;
  final double runSpacing;
  final double childAspectRatio;
  final EdgeInsetsGeometry? padding;
  final bool shrinkWrap;
  final ScrollPhysics? physics;

  @override
  Widget build(BuildContext context) {
    final columns = context.responsive(
      mobile: mobileColumns,
      tablet: tabletColumns,
      desktop: desktopColumns,
      largeDesktop: largeDesktopColumns,
    );

    return GridView.builder(
      padding: padding,
      shrinkWrap: shrinkWrap,
      physics: physics,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: spacing,
        mainAxisSpacing: runSpacing,
        childAspectRatio: childAspectRatio,
      ),
      itemCount: children.length,
      itemBuilder: (context, index) => children[index],
    );
  }
}

/// Sliver version of AdaptiveGrid for CustomScrollView.
class SliverAdaptiveGrid extends StatelessWidget {
  const SliverAdaptiveGrid({
    super.key,
    required this.children,
    this.mobileColumns = 2,
    this.tabletColumns = 3,
    this.desktopColumns = 4,
    this.largeDesktopColumns = 5,
    this.spacing = 16,
    this.runSpacing = 16,
    this.childAspectRatio = 1.0,
  });

  final List<Widget> children;
  final int mobileColumns;
  final int tabletColumns;
  final int desktopColumns;
  final int largeDesktopColumns;
  final double spacing;
  final double runSpacing;
  final double childAspectRatio;

  @override
  Widget build(BuildContext context) {
    final columns = context.responsive(
      mobile: mobileColumns,
      tablet: tabletColumns,
      desktop: desktopColumns,
      largeDesktop: largeDesktopColumns,
    );

    return SliverGrid(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: spacing,
        mainAxisSpacing: runSpacing,
        childAspectRatio: childAspectRatio,
      ),
      delegate: SliverChildBuilderDelegate(
        (context, index) => children[index],
        childCount: children.length,
      ),
    );
  }
}

/// Responsive container that constrains content width on larger screens.
class ResponsiveContainer extends StatelessWidget {
  const ResponsiveContainer({
    super.key,
    required this.child,
    this.maxWidth,
    this.padding,
    this.alignment = Alignment.topCenter,
  });

  final Widget child;
  final double? maxWidth;
  final EdgeInsetsGeometry? padding;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    final effectiveMaxWidth =
        maxWidth ?? ResponsiveLayout.maxContentWidth(context);
    final effectivePadding =
        padding ??
        EdgeInsets.symmetric(
          horizontal: ResponsiveLayout.horizontalPadding(context),
        );

    return Align(
      alignment: alignment,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: effectiveMaxWidth),
        child: Padding(padding: effectivePadding, child: child),
      ),
    );
  }
}
