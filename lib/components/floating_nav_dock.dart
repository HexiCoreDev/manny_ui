import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:manny_ui/components/mobile_nav_bar.dart';

/// Floating navigation dock for tablet and desktop layouts.
///
/// Features:
/// - Positioned on LEFT side, vertically centered
/// - Flat left edge (against screen wall), rounded right edge
/// - Icons only, no text labels
/// - Glass morphism backdrop with blur effect
/// - Hover animations: scale up + background highlight
/// - Active/inactive icon states
///
/// Example usage:
/// ```dart
/// FloatingNavDock(
///   items: [
///     NavItemConfig(
///       tooltip: 'Dashboard',
///       activeIcon: Icons.dashboard,
///       inactiveIcon: Icons.dashboard_outlined,
///     ),
///     NavItemConfig(
///       tooltip: 'Settings',
///       activeIcon: Icons.settings,
///       inactiveIcon: Icons.settings_outlined,
///     ),
///   ],
///   selectedIndex: _currentIndex,
///   onChangePage: (index) => setState(() => _currentIndex = index),
/// )
/// ```
class FloatingNavDock extends StatefulWidget {
  const FloatingNavDock({
    super.key,
    required this.items,
    required this.onChangePage,
    required this.selectedIndex,
    this.trailingItems,
    this.blurSigma = 15.0,
    this.backgroundOpacity = 0.85,
    this.width = 60,
  });

  /// Navigation items to display.
  final List<NavItemConfig> items;

  /// Callback when a navigation item is tapped.
  final ValueChanged<int> onChangePage;

  /// Currently selected index.
  final int selectedIndex;

  /// Optional trailing items shown after a divider (e.g., settings).
  /// These items do not affect the [selectedIndex].
  final List<NavDockAction>? trailingItems;

  /// Blur intensity. Defaults to 15.0.
  final double blurSigma;

  /// Background opacity. Defaults to 0.85.
  final double backgroundOpacity;

  /// Width of the dock. Defaults to 60.
  final double width;

  @override
  State<FloatingNavDock> createState() => _FloatingNavDockState();
}

class _FloatingNavDockState extends State<FloatingNavDock> {
  int? _hoveredIndex;
  final Map<int, bool> _trailingHovered = {};

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return Align(
      alignment: Alignment.centerLeft,
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: widget.blurSigma,
            sigmaY: widget.blurSigma,
          ),
          child: Container(
            width: widget.width,
            margin: const EdgeInsets.only(left: 0, top: 16, bottom: 16),
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor.withValues(
                alpha: widget.backgroundOpacity,
              ),
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
              border: Border.all(
                color: theme.colorScheme.outline.withValues(alpha: 0.1),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(4, 0),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Navigation items
                ...widget.items.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  final isSelected = widget.selectedIndex == index;
                  final isHovered = _hoveredIndex == index;

                  return _NavDockItem(
                    item: item,
                    isSelected: isSelected,
                    isHovered: isHovered,
                    primaryColor: primaryColor,
                    onTap: () => widget.onChangePage(index),
                    onHover: (hovered) {
                      setState(() {
                        _hoveredIndex = hovered ? index : null;
                      });
                    },
                  );
                }),

                // Trailing items (e.g., settings)
                if (widget.trailingItems != null &&
                    widget.trailingItems!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Divider(
                      color: theme.colorScheme.outline.withValues(alpha: 0.2),
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...widget.trailingItems!.asMap().entries.map((entry) {
                    final index = entry.key;
                    final action = entry.value;
                    return _NavDockItem(
                      item: NavItemConfig(
                        tooltip: action.tooltip,
                        activeIcon: action.icon,
                        inactiveIcon: action.icon,
                      ),
                      isSelected: false,
                      isHovered: _trailingHovered[index] ?? false,
                      primaryColor: primaryColor,
                      onTap: action.onTap,
                      onHover: (hovered) {
                        setState(() {
                          _trailingHovered[index] = hovered;
                        });
                      },
                    );
                  }),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Configuration for trailing dock actions (e.g., settings button).
class NavDockAction {
  final String tooltip;
  final IconData icon;
  final VoidCallback onTap;

  const NavDockAction({
    required this.tooltip,
    required this.icon,
    required this.onTap,
  });
}

/// Individual navigation dock item with hover and selection states.
class _NavDockItem extends StatelessWidget {
  const _NavDockItem({
    required this.item,
    required this.isSelected,
    required this.isHovered,
    required this.primaryColor,
    required this.onTap,
    required this.onHover,
  });

  final NavItemConfig item;
  final bool isSelected;
  final bool isHovered;
  final Color primaryColor;
  final VoidCallback onTap;
  final ValueChanged<bool> onHover;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Determine icon and color based on state.
    final icon = isSelected ? item.activeIcon : item.inactiveIcon;
    final iconColor = isSelected
        ? primaryColor
        : theme.colorScheme.onSurface.withValues(alpha: 0.6);

    // Scale factor for hover effect.
    final scale = isHovered ? 1.15 : 1.0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: MouseRegion(
        onEnter: (_) => onHover(true),
        onExit: (_) => onHover(false),
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedScale(
            scale: scale,
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOutCubic,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isSelected
                    ? primaryColor.withValues(alpha: 0.15)
                    : isHovered
                    ? theme.colorScheme.onSurface.withValues(alpha: 0.08)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    icon,
                    key: ValueKey('${item.tooltip}_$isSelected'),
                    color: iconColor,
                    size: 24,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
