import 'package:flutter/widgets.dart';

/// Provides a [ScrollController] to descendants that need to drive a
/// [Scrollable] inside a frosted modal sheet.
///
/// Wraps [PrimaryScrollController]-style hand-off: callers attach this
/// controller to their inner scroll view (e.g. `SingleChildScrollView`) so
/// the sheet's drag engine can take over the gesture once the inner scroll
/// reaches offset 0.
///
/// Behavior contract mirrors the upstream `ModalScrollController` from the
/// modal_bottom_sheet package by Jaime Blasco (MIT licensed).
///
/// ```dart
/// final scroll = SheetScrollController.of(context);
/// return SingleChildScrollView(controller: scroll, child: ...);
/// ```
class SheetScrollController extends InheritedWidget {
  const SheetScrollController({
    super.key,
    required this.controller,
    required super.child,
  });

  final ScrollController controller;

  static ScrollController? of(BuildContext context) {
    final widget =
        context.dependOnInheritedWidgetOfExactType<SheetScrollController>();
    return widget?.controller;
  }

  @override
  bool updateShouldNotify(SheetScrollController oldWidget) =>
      controller != oldWidget.controller;
}
