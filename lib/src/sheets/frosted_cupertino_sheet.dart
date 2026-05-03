import 'package:flutter/material.dart';
// ignore: unnecessary_import
import 'package:flutter/widgets.dart';

import 'package:manny_ui/config/ui_constants.dart';
import 'frosted_modal_route.dart';
import 'frosted_sheet_surface.dart';

/// PageRoute for a frosted Cupertino-style modal bottom sheet.
class FrostedCupertinoModalRoute<T> extends FrostedModalRoute<T> {
  FrostedCupertinoModalRoute({
    required super.builder,
    required super.expanded,
    super.containerBuilder,
    super.scrollController,
    super.barrierLabel,
    super.modalBarrierColor,
    super.secondAnimationController,
    super.closeProgressThreshold,
    super.preventPopThreshold,
    super.isDismissible,
    super.enableDrag = true,
    super.bounce = true,
    super.animationCurve,
    super.duration,
    super.settings,
    this.topRadius = const Radius.circular(UIConstants.glassSheetTopRadius),
    this.previousRouteAnimationCurve,
    this.transitionBackgroundColor,
  });

  final Radius topRadius;
  final Curve? previousRouteAnimationCurve;
  final Color? transitionBackgroundColor;

  @override
  bool canTransitionTo(TransitionRoute<dynamic> nextRoute) => false;

  @override
  Widget getPreviousRouteTransition(
    BuildContext context,
    Animation<double> secondAnimation,
    Widget child,
  ) {
    final curve = previousRouteAnimationCurve ?? Curves.linearToEaseOut;
    // Default to transparent so the previous route remains visible behind the
    // sheet. The frosted BackdropFilter on the modal needs real content to
    // blur — covering the previous route with an opaque ColoredBox (the
    // upstream Cupertino default) collapses the modal into a flat dark
    // surface for fullscreen (expand:true) sheets. Callers who want the
    // upstream "blacked-out previous route" aesthetic can pass an explicit
    // opaque [transitionBackgroundColor].
    final backgroundColor = transitionBackgroundColor ?? Colors.transparent;

    return Stack(
      children: [
        if (backgroundColor.a > 0)
          Positioned.fill(child: ColoredBox(color: backgroundColor)),
        AnimatedBuilder(
          animation: secondAnimation,
          child: child,
          builder: (context, child) {
            final value = secondAnimation.value.clamp(0.0, 1.0).toDouble();
            final progress = curve.transform(value);
            const minScale = 0.92;
            const maxYOffset = 10.0;
            final scale = 1.0 - ((1.0 - minScale) * progress);
            final radius = Radius.lerp(
              Radius.zero,
              topRadius,
              progress,
            )!;

            return Transform.translate(
              offset: Offset(0, maxYOffset * progress),
              child: Transform.scale(
                scale: scale,
                alignment: Alignment.topCenter,
                child: ClipRRect(
                  borderRadius: BorderRadius.all(radius),
                  child: child!,
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

/// Shows a frosted Cupertino-style modal bottom sheet.
Future<T?> showFrostedCupertinoSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  Color? barrierColor,
  bool expand = false,
  AnimationController? secondAnimation,
  Curve? animationCurve,
  Curve? previousRouteAnimationCurve,
  bool useRootNavigator = false,
  bool bounce = true,
  bool? isDismissible,
  bool enableDrag = true,
  Radius topRadius = const Radius.circular(UIConstants.glassSheetTopRadius),
  Duration? duration,
  RouteSettings? settings,
  Color? transitionBackgroundColor,
  double? closeProgressThreshold,
}) {
  assert(debugCheckHasMediaQuery(context));

  final hasMaterialLocalizations = Localizations.of<MaterialLocalizations>(
        context,
        MaterialLocalizations,
      ) !=
      null;
  final barrierLabel = hasMaterialLocalizations
      ? MaterialLocalizations.of(context).modalBarrierDismissLabel
      : '';

  final route = FrostedCupertinoModalRoute<T>(
    builder: builder,
    expanded: expand,
    containerBuilder: (ctx, anim, child) {
      // iOS-native Cupertino sheets leave a status-bar-height strip above
      // the sheet so the previous route peeks through. The route's
      // [buildPage] strips the top safe area via [MediaQuery.removePadding];
      // we re-add it here as a Padding so the sheet starts below the notch
      // / status bar.
      final topPadding = MediaQuery.of(ctx).viewPadding.top;
      return Padding(
        padding: EdgeInsets.only(top: topPadding),
        child: FrostedSheetSurface(
          topRadius: topRadius,
          child: child,
        ),
      );
    },
    modalBarrierColor: barrierColor,
    secondAnimationController: secondAnimation,
    closeProgressThreshold: closeProgressThreshold,
    barrierLabel: barrierLabel,
    bounce: bounce,
    isDismissible: isDismissible ?? enableDrag,
    enableDrag: enableDrag,
    animationCurve: animationCurve,
    duration: duration,
    settings: settings,
    topRadius: topRadius,
    previousRouteAnimationCurve: previousRouteAnimationCurve,
    transitionBackgroundColor: transitionBackgroundColor,
  );

  return Navigator.of(context, rootNavigator: useRootNavigator).push<T>(route);
}
