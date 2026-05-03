import 'dart:ui' show lerpDouble;

import 'package:flutter/animation.dart';
import 'package:flutter/foundation.dart';

/// Curve that stays linear until [startingPoint], then applies [curve].
///
/// Used by [FrostedBottomSheet] to settle the sheet animation after a
/// drag-gesture ends — the suspended region preserves the drag's endpoint
/// as the curve's starting point so the snap-to-open or snap-to-close
/// animation continues smoothly from wherever the user released.
///
/// Behavior matches the upstream `BottomSheetSuspendedCurve` from the
/// modal_bottom_sheet package by Jaime Blasco (MIT licensed), used as the
/// reference for this clean-room port.
class SheetSuspendedCurve extends Curve {
  /// Creates a suspended curve.
  const SheetSuspendedCurve(
    this.startingPoint, {
    this.curve = Curves.easeOutCubic,
  });

  /// The progress value at which [curve] should begin.
  ///
  /// This defaults to [Curves.easeOutCubic].
  final double startingPoint;

  /// The curve to use when [startingPoint] is reached.
  final Curve curve;

  @override
  double transform(double t) {
    assert(t >= 0.0 && t <= 1.0);
    assert(startingPoint >= 0.0 && startingPoint <= 1.0);

    if (t < startingPoint) {
      return t;
    }

    if (t == 1.0) {
      return t;
    }

    final double curveProgress = (t - startingPoint) / (1 - startingPoint);
    final double transformed = curve.transform(curveProgress);
    return lerpDouble(startingPoint, 1, transformed)!;
  }

  @override
  String toString() {
    return '${describeIdentity(this)}($startingPoint, $curve)';
  }
}
