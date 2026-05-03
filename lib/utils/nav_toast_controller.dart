import 'dart:async';
import 'package:flutter/material.dart';
import 'package:manny_ui/utils/hide_on_scroll.dart';

/// Toast notification type for the navbar.
enum NavToastType { success, error, warning, info }

/// State of a navbar toast notification.
class NavToastState {
  final String message;
  final NavToastType type;
  final Duration duration;
  final bool isActive;

  const NavToastState({
    this.message = '',
    this.type = NavToastType.info,
    this.duration = const Duration(seconds: 3),
    this.isActive = false,
  });

  Color get color {
    switch (type) {
      case NavToastType.success:
        return Colors.green;
      case NavToastType.error:
        return Colors.red;
      case NavToastType.warning:
        return Colors.orange;
      case NavToastType.info:
        return Colors.blue;
    }
  }
}

/// Controls toast notifications displayed through the navbar.
///
/// The NavigationView listens to this controller. When a toast activates:
/// - The indicator wraps fully around the pill border in the toast's color
/// - The navbar slides up if hidden
/// - After duration, the indicator shrinks back
///
/// ```dart
/// final navToast = NavToastController();
///
/// // In your NavigationView:
/// NavigationView(toastController: navToast, ...)
///
/// // To trigger a toast via the navbar:
/// navToast.show('Node connected!', type: NavToastType.success);
/// ```
class NavToastController extends ChangeNotifier {
  NavToastState _state = const NavToastState();
  Timer? _dismissTimer;
  HideOnScrollController? scrollController;

  NavToastState get state => _state;

  /// Show a toast through the navbar.
  void show(
    String message, {
    NavToastType type = NavToastType.info,
    Duration duration = const Duration(seconds: 3),
  }) {
    _dismissTimer?.cancel();

    // If navbar is hidden, show it temporarily
    scrollController?.showTemporarily(duration + const Duration(seconds: 1));

    _state = NavToastState(
      message: message,
      type: type,
      duration: duration,
      isActive: true,
    );
    notifyListeners();

    _dismissTimer = Timer(duration, dismiss);
  }

  /// Dismiss the current toast.
  void dismiss() {
    _dismissTimer?.cancel();
    _state = const NavToastState();
    notifyListeners();
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    super.dispose();
  }
}
