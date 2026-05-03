import 'package:flutter/rendering.dart';
import 'package:flutter/material.dart';

/// Wraps a [NavigationView] and hides it when the user scrolls down.
/// Shows it again when scrolling up.
///
/// Attach the [controller] to your scrollable (ListView, CustomScrollView, etc).
///
/// ```dart
/// final scrollController = ScrollController();
///
/// HideOnScrollNavbar(
///   controller: scrollController,
///   child: NavigationView(floating: true, visible: ???, ...),
/// )
///
/// // In your body:
/// ListView(controller: scrollController, ...)
/// ```
///
/// Or use the [visible] ValueNotifier directly with NavigationView:
/// ```dart
/// final navVisible = HideOnScrollController(scrollController);
/// NavigationView(visible: navVisible.value, ...)
/// ```
class HideOnScrollController extends ChangeNotifier {
  HideOnScrollController(this.scrollController, {this.threshold = 5.0}) {
    scrollController.addListener(_onScroll);
  }

  final ScrollController scrollController;

  /// Minimum scroll delta to trigger hide/show.
  final double threshold;

  bool _visible = true;
  bool get visible => _visible;

  bool _locked = false;

  void _onScroll() {
    if (_locked) return;
    final direction = scrollController.position.userScrollDirection;
    if (direction == ScrollDirection.reverse && _visible) {
      _visible = false;
      notifyListeners();
    } else if (direction == ScrollDirection.forward && !_visible) {
      _visible = true;
      notifyListeners();
    }
  }

  /// Temporarily show the navbar for [duration], then hide again.
  /// Used by the toast system to show navbar when hidden.
  void showTemporarily(Duration duration) {
    if (_visible) return;
    _locked = true;
    _visible = true;
    notifyListeners();
    Future.delayed(duration, () {
      _locked = false;
      _visible = false;
      notifyListeners();
    });
  }

  /// Force show (e.g. when user taps).
  void show() {
    _visible = true;
    notifyListeners();
  }

  /// Force hide.
  void hide() {
    _visible = false;
    notifyListeners();
  }

  @override
  void dispose() {
    scrollController.removeListener(_onScroll);
    super.dispose();
  }
}
