import 'package:flutter/material.dart';

/// Navigation item model for [NavigationView].
///
/// Each item has a before (inactive) and after (active) widget,
/// typically icons with different styles.
class ItemNavigationView {
  final Widget iconBefore;
  final Widget iconAfter;
  final String? tooltip;

  ItemNavigationView({
    required this.iconBefore,
    required this.iconAfter,
    this.tooltip,
  });
}
