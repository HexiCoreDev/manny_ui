import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:manny_ui/config/ui_constants.dart';

/// Navigation item configuration.
///
/// Defines the appearance and label for a single navigation item.
class NavItemConfig {
  final String tooltip;
  final IconData activeIcon;
  final IconData inactiveIcon;

  const NavItemConfig({
    required this.tooltip,
    required this.activeIcon,
    required this.inactiveIcon,
  });
}

/// A generic mobile bottom navigation bar with animated indicator.
///
/// Features:
/// - Configurable navigation items via [NavItemConfig]
/// - Animated sliding indicator
/// - Active/inactive icon states
/// - iOS-style rounded design
///
/// Example usage:
/// ```dart
/// MobileNavBar(
///   items: const [
///     NavItemConfig(
///       tooltip: 'Home',
///       activeIcon: Icons.home,
///       inactiveIcon: Icons.home_outlined,
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
class MobileNavBar extends StatelessWidget {
  const MobileNavBar({
    super.key,
    required this.items,
    required this.onChangePage,
    this.selectedIndex = 0,
    this.activeIconSize = 28,
    this.inactiveIconSize = 24,
    this.height = 65,
    this.borderRadius = const BorderRadius.all(Radius.circular(25)),
    this.animationDuration = const Duration(milliseconds: 300),
    this.animationCurve = Curves.easeInOut,
  });

  /// Navigation items to display.
  final List<NavItemConfig> items;

  /// Callback when a navigation item is tapped.
  final ValueChanged<int> onChangePage;

  /// Currently selected index.
  final int selectedIndex;

  /// Size of the active icon.
  final double activeIconSize;

  /// Size of the inactive icon.
  final double inactiveIconSize;

  /// Height of the navigation bar.
  final double height;

  /// Border radius of the navigation bar.
  final BorderRadius borderRadius;

  /// Duration of the indicator animation.
  final Duration animationDuration;

  /// Curve of the indicator animation.
  final Curve animationCurve;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final isDark = theme.brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: UIConstants.glassBlurSigma,
          sigmaY: UIConstants.glassBlurSigma,
        ),
        child: Container(
          height: height,
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor.withValues(
              alpha: UIConstants.glassOpacity,
            ),
            borderRadius: borderRadius,
            border: Border(
              top: BorderSide(
                color: isDark
                    ? Colors.white.withValues(
                        alpha: UIConstants.glassBorderOpacityDark,
                      )
                    : Colors.white.withValues(
                        alpha: UIConstants.glassBorderOpacityLight,
                      ),
                width: 1,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withValues(
                        alpha: UIConstants.glassShadowOpacityDark,
                      )
                    : Colors.black.withValues(
                        alpha: UIConstants.glassShadowOpacityLight,
                      ),
                blurRadius: 24,
                offset: const Offset(0, -8),
                spreadRadius: -4,
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (index) {
              final item = items[index];
              final isSelected = index == selectedIndex;

              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onChangePage(index),
                  child: Tooltip(
                    message: item.tooltip,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedSwitcher(
                          duration: animationDuration,
                          child: Icon(
                            isSelected ? item.activeIcon : item.inactiveIcon,
                            key: ValueKey('${item.tooltip}_$isSelected'),
                            size: isSelected
                                ? activeIconSize
                                : inactiveIconSize,
                            color: isSelected
                                ? primaryColor
                                : theme.colorScheme.onSurface.withValues(
                                    alpha: 0.5,
                                  ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        AnimatedContainer(
                          duration: animationDuration,
                          curve: animationCurve,
                          width: isSelected ? 20 : 0,
                          height: 3,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? primaryColor
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
