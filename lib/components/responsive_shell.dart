import 'package:flutter/material.dart';

/// Page transition switcher with fade + subtle slide animation.
///
/// A reusable animated page switcher for use in navigation shells.
/// Provides smooth fade and slide transitions between indexed pages.
///
/// Example usage:
/// ```dart
/// PageTransitionSwitcher(
///   currentIndex: _selectedIndex,
///   children: [
///     HomePage(),
///     SettingsPage(),
///     ProfilePage(),
///   ],
/// )
/// ```
class PageTransitionSwitcher extends StatelessWidget {
  const PageTransitionSwitcher({
    super.key,
    required this.currentIndex,
    required this.children,
    this.duration = const Duration(milliseconds: 300),
    this.switchInCurve = Curves.easeOutCubic,
    this.switchOutCurve = Curves.easeInCubic,
    this.slideOffset = const Offset(0.02, 0),
  });

  /// The index of the currently visible child.
  final int currentIndex;

  /// The list of child widgets to switch between.
  final List<Widget> children;

  /// Duration of the transition animation.
  final Duration duration;

  /// Curve for the incoming widget animation.
  final Curve switchInCurve;

  /// Curve for the outgoing widget animation.
  final Curve switchOutCurve;

  /// The starting offset for the slide-in animation.
  final Offset slideOffset;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: duration,
      switchInCurve: switchInCurve,
      switchOutCurve: switchOutCurve,
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: slideOffset,
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        );
      },
      child: KeyedSubtree(
        key: ValueKey<int>(currentIndex),
        child: children[currentIndex],
      ),
    );
  }
}
