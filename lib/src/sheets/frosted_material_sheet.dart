import 'package:flutter/material.dart';

import 'package:manny_ui/config/ui_constants.dart';
import 'frosted_modal_route.dart';
import 'frosted_sheet_surface.dart';

/// Shows a frosted material-style modal bottom sheet.
///
/// Unlike [showFrostedCupertinoSheet], this variant does not animate the
/// previous route. [bounce] defaults to `false` to match the Material Design
/// convention.
Future<T?> showFrostedMaterialSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
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
  Radius topRadius = const Radius.circular(UIConstants.glassSheetTopRadius),
}) {
  assert(debugCheckHasMediaQuery(context));
  assert(debugCheckHasMaterialLocalizations(context));

  return Navigator.of(context, rootNavigator: useRootNavigator).push<T>(
    FrostedModalRoute<T>(
      builder: builder,
      expanded: expand,
      containerBuilder: (ctx, anim, child) => FrostedSheetSurface(
        topRadius: topRadius,
        child: child,
      ),
      modalBarrierColor: barrierColor,
      bounce: bounce,
      animationCurve: animationCurve,
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      duration: duration,
      settings: settings,
      closeProgressThreshold: closeProgressThreshold,
      secondAnimationController: secondAnimation,
    ),
  );
}
