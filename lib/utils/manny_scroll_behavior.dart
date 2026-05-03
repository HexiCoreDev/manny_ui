import 'package:flutter/material.dart';

/// Custom scroll behavior that hides scrollbar indicators globally.
///
/// Apply via [MaterialApp.scrollBehavior] or wrap with [ScrollConfiguration].
///
/// ```dart
/// MaterialApp(
///   scrollBehavior: MannyScrollBehavior(),
///   ...
/// )
/// ```
class MannyScrollBehavior extends MaterialScrollBehavior {
  @override
  Widget buildScrollbar(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    // Return the child directly — no scrollbar wrapper.
    return child;
  }
}
