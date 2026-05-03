import 'package:flutter/material.dart';

import 'frosted_cupertino_sheet.dart';

/// A [MaterialPageRoute] subclass that animates the previous-route transition
/// when a [FrostedCupertinoModalRoute] is pushed on top.
///
/// Use this in place of [MaterialPageRoute] for any route that may push a
/// frosted Cupertino-style sheet, so the underlying page scales, translates,
/// and rounds its corners during the modal's open animation. Pages routed
/// via plain [MaterialPageRoute] still work — the sheet just won't animate
/// the previous route.
///
/// Behavior contract mirrors `MaterialWithModalsPageRoute` from the
/// modal_bottom_sheet package by Jaime Blasco (MIT licensed).
class FrostedCompatiblePageRoute<T> extends MaterialPageRoute<T> {
  FrostedCompatiblePageRoute({
    required super.builder,
    super.settings,
    super.maintainState,
    super.fullscreenDialog,
  });

  // Track the next modal route while it's transitioning over us
  FrostedCupertinoModalRoute<dynamic>? _nextModalRoute;

  @override
  bool canTransitionTo(TransitionRoute<dynamic> nextRoute) {
    if (nextRoute is FrostedCupertinoModalRoute) {
      _nextModalRoute = nextRoute;
      return true;
    }
    return super.canTransitionTo(nextRoute);
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (_nextModalRoute != null) {
      // Delegate to the modal's previous-route transition
      final modal = _nextModalRoute!;
      if (!secondaryAnimation.isDismissed) {
        return modal.getPreviousRouteTransition(
          context,
          secondaryAnimation,
          child,
        );
      }
      _nextModalRoute = null; // clear when dismissed
    }
    return super.buildTransitions(context, animation, secondaryAnimation, child);
  }
}
