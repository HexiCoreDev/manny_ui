// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
//
// This file is a clean-room port of the gesture/animation engine from
// modal_bottom_sheet's bottom_sheet.dart, by Jaime Blasco (MIT licensed).
// The visual surface is handled separately by FrostedSheetSurface (Phase 1),
// wired through the containerBuilder callback.

import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'sheet_animation_curve.dart';

const Curve _decelerateEasing = Cubic(0.0, 0.0, 0.2, 1.0);

const double _minFlingVelocity = 500.0;
const double _closeProgressThreshold = 0.6;
const Duration _bottomSheetDuration = Duration(milliseconds: 400);

/// A builder that wraps the sheet's child in a surface container.
///
/// The [animation] parameter is the sheet's [AnimationController], so the
/// surface can respond to open/close progress if needed (e.g., for
/// previous-route transitions during Cupertino-style modals).
typedef SheetContainerBuilder = Widget Function(
  BuildContext context,
  Animation<double> animation,
  Widget child,
);

/// Core stateful widget that handles drag-to-dismiss, fling-to-close,
/// scroll-handoff, and bounce overshoot for a modal bottom sheet.
///
/// Does NOT render its own surface decoration — pass a [containerBuilder]
/// (typically wrapping the child in [FrostedSheetSurface]) to apply the
/// frosted-glass aesthetic.
///
/// Behavior contract mirrors the upstream `ModalBottomSheet` widget from
/// the modal_bottom_sheet package by Jaime Blasco (MIT licensed). This
/// is a clean-room port that preserves drag physics, scroll sync, bounce,
/// and the [shouldClose] async callback flow.
class FrostedBottomSheet extends StatefulWidget {
  /// Creates a frosted bottom sheet.
  ///
  /// The [animationController] drives the sheet's position (0 = closed,
  /// 1 = fully open). The [scrollController] must be shared with any
  /// inner [ScrollView] so that drag-to-close can hand off correctly.
  const FrostedBottomSheet({
    super.key,
    required this.animationController,
    required this.scrollController,
    required this.expanded,
    required this.onClosing,
    required this.child,
    this.animationCurve,
    this.enableDrag = true,
    this.containerBuilder,
    this.bounce = true,
    this.shouldClose,
    this.minFlingVelocity = _minFlingVelocity,
    this.closeProgressThreshold = _closeProgressThreshold,
    this.preventPopThreshold = 0.0,
  });

  /// The animation controller that drives the sheet's entrance and exit.
  ///
  /// [FrostedBottomSheet] manipulates this controller's value during drag
  /// and fling gestures — it is not a passive observer.
  final AnimationController animationController;

  /// The curve used when settling the animation after a drag ends.
  ///
  /// Falls back to a decelerate easing cubic when not provided.
  final Curve? animationCurve;

  /// If `true`, the sheet can be dragged vertically and dismissed by
  /// swiping downwards.
  ///
  /// Defaults to `true`.
  final bool enableDrag;

  /// Optional builder that wraps [child] in a surface container.
  ///
  /// The animation is the same [animationController] so the container can
  /// react to open/close progress. Typically wraps the child in
  /// [FrostedSheetSurface].
  final SheetContainerBuilder? containerBuilder;

  /// Whether the sheet overshoots its open position when dragged upward
  /// past the top. When `true`, the sheet snaps back with a bounce.
  ///
  /// Defaults to `true`.
  final bool bounce;

  /// Optional async callback invoked before the sheet commits to closing.
  ///
  /// If it returns `false`, the close is cancelled and the sheet animates
  /// back to its open position. If `null`, the sheet closes unconditionally.
  final Future<bool> Function()? shouldClose;

  /// The [ScrollController] shared by the sheet's drag engine and any
  /// inner scroll view. When the scroll position is at offset 0 and the
  /// user drags downward, the sheet drags instead of the content scrolling.
  final ScrollController scrollController;

  /// If `true`, the sheet fills the maximum available height. Otherwise it
  /// sizes to its child's intrinsic height.
  final bool expanded;

  /// Called when the sheet has committed to closing.
  ///
  /// The sheet may be prevented from closing even after this is called
  /// (e.g., by [shouldClose] returning `false`), so this can fire multiple
  /// times for a single sheet instance.
  final VoidCallback onClosing;

  /// The sheet's content. Passed through to [containerBuilder] when
  /// provided, or rendered directly as the sheet body.
  final Widget child;

  /// Minimum fling velocity (in logical pixels / second) required to
  /// close the sheet on drag release, regardless of position.
  ///
  /// Defaults to `500.0`.
  final double minFlingVelocity;

  /// Fraction of "down" progress required for drag-release to commit to
  /// close. When [animationController.value] is below this threshold at
  /// drag-release, the sheet snaps closed. Otherwise it snaps back open.
  ///
  /// Defaults to `0.6`.
  final double closeProgressThreshold;

  /// When the sheet has been dragged below this value and [shouldClose]
  /// is provided, the close-confirmation callback fires during the drag
  /// (not just at drag-end). For [PopScope] integration, set to a value
  /// like `0.8` so the system back button is blocked until the sheet has
  /// been dragged most of the way down.
  ///
  /// Defaults to `0.0` (disabled — confirmation only fires at drag-end).
  final double preventPopThreshold;

  @override
  FrostedBottomSheetState createState() => FrostedBottomSheetState();

  /// Creates an [AnimationController] suitable for a
  /// [FrostedBottomSheet.animationController].
  ///
  /// Convenience factory so callers (typically routes) don't need to
  /// remember the default duration or debug label.
  static AnimationController createAnimationController(
    TickerProvider vsync, {
    Duration? duration,
  }) {
    return AnimationController(
      duration: duration ?? _bottomSheetDuration,
      debugLabel: 'FrostedBottomSheet',
      vsync: vsync,
    );
  }
}

/// State for [FrostedBottomSheet] that owns all drag/gesture logic.
///
/// Public so that widget tests can access the state directly for
/// programmatic drag simulation and status inspection.
class FrostedBottomSheetState extends State<FrostedBottomSheet>
    with TickerProviderStateMixin {
  final GlobalKey _childKey =
      GlobalKey(debugLabel: 'FrostedBottomSheet child');

  ScrollController get _scrollController => widget.scrollController;

  late AnimationController _bounceDragController;

  /// The measured height of the sheet's child, derived from the layout
  /// render box. Used to convert drag delta to progress fraction.
  double? get _childHeight {
    final childContext = _childKey.currentContext;
    final renderBox = childContext?.findRenderObject() as RenderBox;
    return renderBox.size.height;
  }

  bool get _dismissUnderway =>
      widget.animationController.status == AnimationStatus.reverse;

  /// Whether the user is currently in a drag gesture.
  ///
  /// Set to `true` in [_handleDragUpdate], cleared in [_handleDragEnd]
  /// and [_close].
  bool isDragging = false;

  bool get _hasReachedPreventPopThreshold =>
      widget.animationController.value < widget.preventPopThreshold;

  bool get _hasReachedCloseThreshold =>
      widget.animationController.value < widget.closeProgressThreshold;

  void _close() {
    isDragging = false;
    widget.onClosing();
  }

  void _cancelClose() {
    widget.animationController.forward().then((value) {
      // When using pop-prevention, animation doesn't always end at 1.
      if (!widget.animationController.isCompleted) {
        widget.animationController.value = 1;
      }
    });
    _bounceDragController.reverse();
  }

  bool _isCheckingShouldClose = false;

  FutureOr<bool> _shouldClose() async {
    if (_isCheckingShouldClose) return false;
    if (widget.shouldClose == null) return false;
    _isCheckingShouldClose = true;
    final result = await widget.shouldClose?.call();
    _isCheckingShouldClose = false;
    return result ?? false;
  }

  /// The active animation curve. Set to [Curves.linear] during live drag
  /// so the sheet follows the user's finger precisely, then swapped to a
  /// [SheetSuspendedCurve] at drag-end for a smooth settle.
  ParametricCurve<double> animationCurve = Curves.linear;

  /// Responds to vertical drag updates by moving the sheet.
  ///
  /// The [primaryDelta] is the change in the vertical axis since the last
  /// update. Positive values move the sheet downward (toward close);
  /// negative values move it upward (toward open/bounce).
  void _handleDragUpdate(double primaryDelta) async {
    animationCurve = Curves.linear;
    assert(widget.enableDrag, 'Dragging is disabled');

    if (_dismissUnderway) return;
    isDragging = true;

    final progress = primaryDelta / (_childHeight ?? primaryDelta);

    // During-drag shouldClose check: when the user drags past the
    // preventPopThreshold and a shouldClose callback is set, attempt
    // to close immediately rather than waiting for drag-end.
    if (widget.shouldClose != null && _hasReachedPreventPopThreshold) {
      _cancelClose();
      final canClose = await _shouldClose();
      if (canClose) {
        _close();
        return;
      } else {
        _cancelClose();
      }
    }

    // Bounce at the top: when bounce is enabled and the sheet is at or
    // beyond its open position, route the drag delta through the bounce
    // controller instead so the sheet visually overshoots.
    final bounce = widget.bounce;
    final shouldBounce = _bounceDragController.value > 0;
    final isBouncing = (widget.animationController.value - progress) > 1;
    if (bounce && (shouldBounce || isBouncing)) {
      _bounceDragController.value -= progress * 10;
      return;
    }

    widget.animationController.value -= progress;
  }

  /// Handles the end of a vertical drag gesture for the sheet itself
  /// (not the scroll content — see [_handleScrollUpdate] for handoff).
  ///
  /// Decides whether to fling-to-close, snap-to-close, or snap-back-open
  /// based on [velocity], [closeProgressThreshold], and [shouldClose].
  void _handleDragEnd(double velocity) async {
    assert(widget.enableDrag, 'Dragging is disabled');

    animationCurve = SheetSuspendedCurve(
      widget.animationController.value,
      curve: _defaultCurve,
    );

    if (_dismissUnderway || !isDragging) return;
    isDragging = false;
    _bounceDragController.reverse();

    Future<void> tryClose() async {
      if (widget.shouldClose != null) {
        _cancelClose();
        bool canClose = await _shouldClose();
        if (canClose) {
          _close();
        }
      } else {
        _close();
      }
    }

    // Strong fling downward → close regardless of position.
    if (velocity > widget.minFlingVelocity) {
      tryClose();
    } else if (_hasReachedCloseThreshold) {
      // Dragged past close threshold → commit to close.
      if (widget.animationController.value > 0.0) {
        widget.animationController.fling(velocity: -1.0);
      }
      tryClose();
    } else {
      // Not far enough → snap back open.
      _cancelClose();
    }
  }

  // Velocity tracking for scroll-driven drag. Since we cannot access the
  // inner scroll view's drag gesture detector directly, we use a
  // [VelocityTracker] to compute the end velocity from scroll
  // notifications when the user drags the modal by pulling on the content.
  VelocityTracker? _velocityTracker;
  DateTime? _startTime;

  /// Callback for [NotificationListener<ScrollNotification>] that implements
  /// scroll-to-drag handoff.
  ///
  /// When the inner scroll view is at offset 0 and the user drags downward,
  /// scroll updates are interpreted as sheet drags instead. A
  /// [VelocityTracker] computes the end velocity for the fling decision.
  void _handleScrollUpdate(ScrollNotification notification) {
    assert(notification.context != null);
    if (!_scrollController.hasClients) return;

    ScrollPosition scrollPosition;
    if (_scrollController.positions.length > 1) {
      scrollPosition = _scrollController.positions.firstWhere(
        (p) => p.isScrollingNotifier.value,
        orElse: () => _scrollController.positions.first,
      );
    } else {
      scrollPosition = _scrollController.position;
    }

    if (scrollPosition.axis == Axis.horizontal) return;

    final isScrollReversed =
        scrollPosition.axisDirection == AxisDirection.down;
    final offset = isScrollReversed
        ? scrollPosition.pixels
        : scrollPosition.maxScrollExtent - scrollPosition.pixels;

    if (offset <= 0) {
      // Clamping scroll physics return a ScrollEndNotification with
      // DragEndDetails that include primary velocity. Use them directly.
      if (notification is ScrollEndNotification) {
        final dragDetails = notification.dragDetails;
        if (dragDetails != null) {
          _handleDragEnd(dragDetails.primaryVelocity ?? 0);
          _velocityTracker = null;
          _startTime = null;
          return;
        }
      }

      // Bouncing or overflow physics don't include DragEndDetails, so
      // compute velocity manually with a VelocityTracker.
      if (_velocityTracker == null) {
        final pointerKind = defaultPointerDeviceKind(context);
        _velocityTracker = VelocityTracker.withKind(pointerKind);
        _startTime = DateTime.now();
      }

      DragUpdateDetails? dragDetails;
      if (notification is ScrollUpdateNotification) {
        dragDetails = notification.dragDetails;
      }
      if (notification is OverscrollNotification) {
        dragDetails = notification.dragDetails;
      }
      assert(_velocityTracker != null);
      assert(_startTime != null);
      final startTime = _startTime!;
      final velocityTracker = _velocityTracker!;
      if (dragDetails != null) {
        final duration = startTime.difference(DateTime.now());
        velocityTracker.addPosition(duration, Offset(0, offset));
        _handleDragUpdate(dragDetails.delta.dy);
      } else if (isDragging) {
        final velocity = velocityTracker.getVelocity().pixelsPerSecond.dy;
        _velocityTracker = null;
        _startTime = null;
        _handleDragEnd(velocity);
      }
    }
  }

  Curve get _defaultCurve => widget.animationCurve ?? _decelerateEasing;

  @override
  void initState() {
    animationCurve = _defaultCurve;
    _bounceDragController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    super.initState();
  }

  @override
  void dispose() {
    _bounceDragController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bounceAnimation = CurvedAnimation(
      parent: _bounceDragController,
      curve: Curves.easeOutSine,
    );

    var child = widget.child;
    if (widget.containerBuilder != null) {
      child = widget.containerBuilder!(
        context,
        widget.animationController,
        child,
      );
    }

    child = AnimatedBuilder(
      animation: widget.animationController,
      builder: (context, Widget? child) {
        assert(child != null);
        final animationValue = animationCurve.transform(
          widget.animationController.value,
        );

        final draggableChild = !widget.enableDrag
            ? child
            : KeyedSubtree(
                key: _childKey,
                child: AnimatedBuilder(
                  animation: bounceAnimation,
                  builder: (context, _) => CustomSingleChildLayout(
                    delegate:
                        _FrostedBottomSheetBounceLayout(bounceAnimation.value),
                    child: GestureDetector(
                      onVerticalDragUpdate: (details) {
                        _handleDragUpdate(details.delta.dy);
                      },
                      onVerticalDragEnd: (details) {
                        _handleDragEnd(details.primaryVelocity ?? 0);
                      },
                      child: NotificationListener<ScrollNotification>(
                        onNotification: (ScrollNotification notification) {
                          _handleScrollUpdate(notification);
                          return false;
                        },
                        child: child!,
                      ),
                    ),
                  ),
                ),
              );
        return ClipRect(
          child: CustomSingleChildLayout(
            delegate: _FrostedBottomSheetLayout(
              animationValue,
              widget.expanded,
            ),
            child: draggableChild,
          ),
        );
      },
      child: RepaintBoundary(child: child),
    );

    return child;
  }
}

/// Layout delegate that positions the sheet based on animation progress.
///
/// When [expand] is `true`, the child fills the viewport height. Otherwise
/// it sizes to its intrinsic height. The vertical offset slides the sheet
/// up from the bottom as [progress] increases from 0 to 1.
class _FrostedBottomSheetLayout extends SingleChildLayoutDelegate {
  _FrostedBottomSheetLayout(this.progress, this.expand);

  final double progress;
  final bool expand;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    return BoxConstraints(
      minWidth: constraints.maxWidth,
      maxWidth: constraints.maxWidth,
      minHeight: expand ? constraints.maxHeight : 0,
      maxHeight: expand ? constraints.maxHeight : constraints.minHeight,
    );
  }

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    return Offset(0.0, size.height - childSize.height * progress);
  }

  @override
  bool shouldRelayout(_FrostedBottomSheetLayout oldDelegate) {
    return progress != oldDelegate.progress;
  }
}

/// Layout delegate that allows the sheet to temporarily exceed its normal
/// bounds during bounce overshoot.
///
/// The [progress] value comes from the bounce animation controller, which
/// is driven by upward drag velocity routed through [Curves.easeOutSine].
class _FrostedBottomSheetBounceLayout extends SingleChildLayoutDelegate {
  _FrostedBottomSheetBounceLayout(this.progress);

  final double progress;
  double? childHeight;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    return BoxConstraints(
      minWidth: constraints.maxWidth,
      maxWidth: constraints.maxWidth,
      minHeight: constraints.minHeight,
      maxHeight: constraints.maxHeight + progress * 8,
    );
  }

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    childHeight ??= childSize.height;
    return Offset(0.0, size.height - childSize.height);
  }

  @override
  bool shouldRelayout(_FrostedBottomSheetBounceLayout oldDelegate) {
    if (progress != oldDelegate.progress) {
      childHeight = oldDelegate.childHeight;
      return true;
    }
    return false;
  }
}

/// Determines the pointer device kind from the platform brightness theme.
///
/// Mobile platforms return [PointerDeviceKind.touch] so [VelocityTracker]
/// uses touch-appropriate velocity scaling; desktop platforms return
/// [PointerDeviceKind.mouse].
///
/// Copied from the upstream modal_bottom_sheet package; referenced in
/// https://github.com/flutter/flutter/pull/64267#issuecomment-694196304.
PointerDeviceKind defaultPointerDeviceKind(BuildContext context) {
  final platform = Theme.of(context).platform;
  switch (platform) {
    case TargetPlatform.iOS:
    case TargetPlatform.android:
      return PointerDeviceKind.touch;
    case TargetPlatform.linux:
    case TargetPlatform.macOS:
    case TargetPlatform.windows:
      return PointerDeviceKind.mouse;
    case TargetPlatform.fuchsia:
      return PointerDeviceKind.unknown;
  }
}
