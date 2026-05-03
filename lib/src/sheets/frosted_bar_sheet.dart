import 'package:flutter/material.dart';

import 'package:manny_ui/config/ui_constants.dart';
import 'frosted_modal_route.dart';
import 'frosted_sheet_surface.dart';

/// A convenience widget that delegates to [FrostedSheetSurface] with a default
/// frosted-context drag handle.
///
/// Callers who want the bar-sheet surface without going through the
/// [showFrostedBarSheet] function can construct this widget directly.
class FrostedBarSheet extends StatelessWidget {
  const FrostedBarSheet({
    super.key,
    required this.child,
    this.dragHandle,
    this.topRadius = const Radius.circular(UIConstants.glassSheetTopRadius),
  });

  final Widget child;
  final Widget? dragHandle;
  final Radius topRadius;

  @override
  Widget build(BuildContext context) {
    final handle = dragHandle ?? _defaultBarDragHandle(context);
    return FrostedSheetSurface(
      topRadius: topRadius,
      dragHandle: handle,
      child: child,
    );
  }
}

/// Shows a frosted bar-style modal bottom sheet with a drag handle pill.
///
/// The bar variant has [bounce] enabled by default and uses a darker scrim
/// ([Colors.black54]) than other variants, matching the behavior contract
/// of `showBarModalBottomSheet` from the modal_bottom_sheet package
/// by Jaime Blasco (MIT licensed).
///
/// The default drag handle is a 6x40 translucent pill that blends with the
/// frosted glass background.
Future<T?> showFrostedBarSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  Color barrierColor = Colors.black54,
  bool bounce = true,
  bool expand = false,
  AnimationController? secondAnimation,
  Curve? animationCurve,
  bool useRootNavigator = false,
  bool isDismissible = true,
  bool enableDrag = true,
  Widget? dragHandle,
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
      containerBuilder: (ctx, anim, child) {
        final handle = dragHandle ?? _defaultBarDragHandle(ctx);
        return FrostedSheetSurface(
          topRadius: topRadius,
          dragHandle: handle,
          child: child,
        );
      },
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

Widget _defaultBarDragHandle(BuildContext context) {
  final theme = Theme.of(context);
  return Container(
    width: 40,
    height: 6,
    decoration: BoxDecoration(
      color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
      borderRadius: BorderRadius.circular(3),
    ),
  );
}
