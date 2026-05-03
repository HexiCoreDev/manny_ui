import 'package:flutter/material.dart';

import 'frosted_bottom_sheet.dart';
import 'sheet_scroll_controller.dart';
import '_status_bar_tap_detector.dart';

export 'frosted_bottom_sheet.dart' show SheetContainerBuilder;

/// PageRoute for a frosted modal bottom sheet.
///
/// Owns the [AnimationController] lifecycle, wraps the body in
/// [SheetScrollController] for scroll/drag coordination, and adds an
/// invisible iOS status-bar tap target for scroll-to-top.
///
/// Behavior contract mirrors `ModalSheetRoute` from the modal_bottom_sheet
/// package by Jaime Blasco (MIT licensed).
class FrostedModalRoute<T> extends PageRoute<T> {
  FrostedModalRoute({
    required this.builder,
    required this.expanded,
    this.containerBuilder,
    this.scrollController,
    this.barrierLabel,
    this.modalBarrierColor,
    this.secondAnimationController,
    this.closeProgressThreshold,
    this.preventPopThreshold,
    this.isDismissible = true,
    this.enableDrag = true,
    this.bounce = false,
    this.animationCurve,
    Duration? duration,
    super.settings,
  }) : _duration = duration ?? const Duration(milliseconds: 400);

  final WidgetBuilder builder;
  final bool expanded;
  final SheetContainerBuilder? containerBuilder;
  final ScrollController? scrollController;

  @override
  final String? barrierLabel;

  final Color? modalBarrierColor;
  final AnimationController? secondAnimationController;
  final double? closeProgressThreshold;
  final double? preventPopThreshold;
  final bool isDismissible;
  final bool enableDrag;
  final bool bounce;
  final Curve? animationCurve;
  final Duration _duration;

  AnimationController? _animationController;
  ScrollController? _internalScrollController;

  @override
  Duration get transitionDuration => _duration;

  @override
  bool get barrierDismissible => isDismissible;

  @override
  bool get maintainState => true;

  @override
  bool get opaque => false;

  @override
  Color get barrierColor =>
      modalBarrierColor ?? Colors.black.withValues(alpha: 0.35);

  @override
  AnimationController createAnimationController() {
    assert(_animationController == null);
    _animationController = FrostedBottomSheet.createAnimationController(
      navigator!,
      duration: _duration,
    );
    _animationController!.addListener(_syncSecondAnimationController);
    return _animationController!;
  }

  void _syncSecondAnimationController() {
    final animationController = _animationController;
    if (animationController == null) return;

    secondAnimationController?.value = animationController.value;
  }

  // ignore: deprecated_member_use
  bool get _hasScopedWillPopCallback => hasScopedWillPopCallback;

  Future<bool> _shouldClose() async {
    // ignore: deprecated_member_use
    final willPopDisposition = await willPop();
    final currentPopDisposition = popDisposition;
    final shouldClose = !(willPopDisposition == RoutePopDisposition.doNotPop ||
        currentPopDisposition == RoutePopDisposition.doNotPop);

    if (!shouldClose) {
      // ignore: deprecated_member_use
      onPopInvoked(false);
    }

    return shouldClose;
  }

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    assert(debugCheckHasMediaQuery(context));
    assert(_animationController != null);

    final body = MediaQuery.removePadding(
      context: context,
      removeTop: true,
      child: Builder(builder: builder),
    );

    final scroll = scrollController ??
        (_internalScrollController ??= ScrollController());
    final sheet = FrostedBottomSheet(
      animationController: _animationController!,
      scrollController: scroll,
      expanded: expanded,
      onClosing: () {
        if (isCurrent) {
          Navigator.of(context).pop();
        }
      },
      enableDrag: enableDrag,
      bounce: bounce,
      animationCurve: animationCurve,
      containerBuilder: containerBuilder,
      closeProgressThreshold: closeProgressThreshold ?? 0.6,
      preventPopThreshold: preventPopThreshold ?? 0.0,
      shouldClose:
          popDisposition == RoutePopDisposition.doNotPop ||
                  _hasScopedWillPopCallback
              ? _shouldClose
              : null,
      child: body,
    );

    return SheetScrollController(
      controller: scroll,
      child: StatusBarTapDetector(
        onTap: () {
          if (scroll.hasClients) {
            scroll.animateTo(
              0,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
            );
          }
        },
        child: sheet,
      ),
    );
  }

  /// Hook for Phase 9 (FrostedCompatiblePageRoute) to call when this route
  /// is the next route.
  Widget getPreviousRouteTransition(
    BuildContext context,
    Animation<double> secondAnimation,
    Widget child,
  ) {
    return child;
  }

  @override
  bool canTransitionTo(TransitionRoute<dynamic> nextRoute) => false;

  @override
  bool canTransitionFrom(TransitionRoute<dynamic> previousRoute) => true;

  @override
  void dispose() {
    _animationController?.removeListener(_syncSecondAnimationController);
    _internalScrollController?.dispose();
    super.dispose();
  }
}

/// Generic frosted modal bottom sheet. Most callers should use the
/// variant-specific helpers ([showFrostedCupertinoSheet],
/// [showFrostedMaterialSheet], [showFrostedBarSheet]) which provide
/// pre-configured [SheetContainerBuilder]s.
Future<T?> showFrostedSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  required SheetContainerBuilder containerBuilder,
  Color? barrierColor,
  bool bounce = false,
  bool expand = false,
  AnimationController? secondAnimation,
  Curve? animationCurve,
  bool useRootNavigator = false,
  bool isDismissible = true,
  bool enableDrag = true,
  Duration? duration,
  RouteSettings? settings,
  double? closeProgressThreshold,
}) {
  assert(debugCheckHasMediaQuery(context));
  assert(debugCheckHasMaterialLocalizations(context));

  final hasMaterialLocalizations = Localizations.of<MaterialLocalizations>(
        context,
        MaterialLocalizations,
      ) !=
      null;
  final barrierLabel = hasMaterialLocalizations
      ? MaterialLocalizations.of(context).modalBarrierDismissLabel
      : '';

  return Navigator.of(context, rootNavigator: useRootNavigator).push(
    FrostedModalRoute<T>(
      builder: builder,
      containerBuilder: containerBuilder,
      expanded: expand,
      modalBarrierColor: barrierColor,
      secondAnimationController: secondAnimation,
      bounce: bounce,
      animationCurve: animationCurve,
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      duration: duration,
      settings: settings,
      closeProgressThreshold: closeProgressThreshold,
      barrierLabel: barrierLabel,
    ),
  );
}
