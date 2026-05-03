import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import 'package:manny_ui/config/ui_constants.dart';
import 'package:manny_ui/utils/nav_toast_controller.dart';

/// Toast position options.
enum ToastPosition {
  topLeft,
  topCenter,
  topRight,
  bottomLeft,
  bottomCenter,
  bottomRight,
}

/// Notification type enum.
enum NotificationType { success, error, info, warning }

/// Notification Toast Component.
/// Beautiful slide-in/slide-out notifications with configurable position.
///
/// Usage:
/// ```dart
/// NotificationToast.show(
///   context: context,
///   message: 'Node joined cluster successfully!',
///   type: NotificationType.success,
///   position: ToastPosition.topCenter,
/// );
/// ```
class NotificationToast {
  /// Optional [NavToastController] for navbar-based toasts.
  static NavToastController? navToastController;

  /// Show a notification toast.
  /// If [useNav] is true and [navToastController] is set, shows via the navbar.
  static void show({
    required BuildContext context,
    required String message,
    NotificationType type = NotificationType.info,
    Duration duration = const Duration(seconds: 3),
    String? actionLabel,
    VoidCallback? onActionPressed,
    ToastPosition position = ToastPosition.topCenter,
    bool useNav = false,
  }) {
    // Route to navbar if requested
    if (useNav && navToastController != null) {
      final navType = switch (type) {
        NotificationType.success => NavToastType.success,
        NotificationType.error => NavToastType.error,
        NotificationType.warning => NavToastType.warning,
        NotificationType.info => NavToastType.info,
      };
      navToastController!.show(message, type: navType, duration: duration);
      return;
    }

    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => _NotificationToastWidget(
        message: message,
        type: type,
        duration: duration,
        actionLabel: actionLabel,
        onActionPressed: onActionPressed,
        position: position,
      ),
    );

    overlay.insert(overlayEntry);

    // Auto-dismiss after duration + exit animation time.
    Future.delayed(duration + const Duration(milliseconds: 300), () {
      if (overlayEntry.mounted) {
        overlayEntry.remove();
      }
    });
  }

  /// Show success notification.
  static void success(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
    ToastPosition position = ToastPosition.topCenter,
  }) {
    show(
      context: context,
      message: message,
      type: NotificationType.success,
      duration: duration,
      position: position,
    );
  }

  /// Show error notification.
  static void error(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
    ToastPosition position = ToastPosition.topCenter,
  }) {
    show(
      context: context,
      message: message,
      type: NotificationType.error,
      duration: duration,
      position: position,
    );
  }

  /// Show info notification.
  static void info(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
    ToastPosition position = ToastPosition.topCenter,
  }) {
    show(
      context: context,
      message: message,
      type: NotificationType.info,
      duration: duration,
      position: position,
    );
  }

  /// Show warning notification.
  static void warning(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
    ToastPosition position = ToastPosition.topCenter,
  }) {
    show(
      context: context,
      message: message,
      type: NotificationType.warning,
      duration: duration,
      position: position,
    );
  }
}

/// Internal notification widget.
class _NotificationToastWidget extends StatefulWidget {
  final String message;
  final NotificationType type;
  final Duration duration;
  final String? actionLabel;
  final VoidCallback? onActionPressed;
  final ToastPosition position;

  const _NotificationToastWidget({
    required this.message,
    required this.type,
    required this.duration,
    this.actionLabel,
    this.onActionPressed,
    required this.position,
  });

  @override
  State<_NotificationToastWidget> createState() =>
      _NotificationToastWidgetState();
}

class _NotificationToastWidgetState extends State<_NotificationToastWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  bool _isDismissing = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    // Determine slide direction based on position.
    final slideBegin = _getSlideBeginOffset();

    _slideAnimation = Tween<Offset>(
      begin: slideBegin,
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    // Start slide-in animation.
    _controller.forward();

    // Start auto-dismiss countdown.
    Future.delayed(widget.duration, () {
      if (mounted && !_isDismissing) {
        _dismiss();
      }
    });
  }

  Offset _getSlideBeginOffset() {
    switch (widget.position) {
      case ToastPosition.topLeft:
      case ToastPosition.topCenter:
      case ToastPosition.topRight:
        return const Offset(0, -1);
      case ToastPosition.bottomLeft:
      case ToastPosition.bottomCenter:
      case ToastPosition.bottomRight:
        return const Offset(0, 1);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _dismiss() {
    if (_isDismissing) return;
    _isDismissing = true;
    _controller.reverse();
  }

  _NotificationConfig _getConfig() {
    switch (widget.type) {
      case NotificationType.success:
        return _NotificationConfig(
          icon: IconlyBroken.shield_done,
          color: Colors.green,
          backgroundColor: Colors.green.withValues(alpha: 0.1),
        );
      case NotificationType.error:
        return _NotificationConfig(
          icon: IconlyBroken.danger,
          color: Colors.red,
          backgroundColor: Colors.red.withValues(alpha: 0.1),
        );
      case NotificationType.warning:
        return _NotificationConfig(
          icon: IconlyBroken.info_square,
          color: Colors.orange,
          backgroundColor: Colors.orange.withValues(alpha: 0.1),
        );
      case NotificationType.info:
        return _NotificationConfig(
          icon: IconlyBroken.info_circle,
          color: Colors.blue,
          backgroundColor: Colors.blue.withValues(alpha: 0.1),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final config = _getConfig();
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;

    // Simple responsive: mobile if width < 600.
    final isMobile = screenWidth < 600;
    const horizontalPadding = 16.0;
    final maxToastWidth = isMobile ? screenWidth : 400.0;
    final toastWidth = isMobile
        ? screenWidth - (horizontalPadding * 2)
        : maxToastWidth.clamp(0.0, screenWidth - (horizontalPadding * 2));

    final positioning = _calculatePositioning(
      mediaQuery: mediaQuery,
      toastWidth: toastWidth,
      horizontalPadding: horizontalPadding,
      isMobile: isMobile,
    );

    return Positioned(
      top: positioning.top,
      bottom: positioning.bottom,
      left: positioning.left,
      right: positioning.right,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: GestureDetector(
            onVerticalDragUpdate: (details) {
              // Swipe to dismiss based on position.
              final isTopPosition =
                  widget.position == ToastPosition.topLeft ||
                  widget.position == ToastPosition.topCenter ||
                  widget.position == ToastPosition.topRight;

              if (isTopPosition && details.primaryDelta! < -10) {
                _dismiss();
              } else if (!isTopPosition && details.primaryDelta! > 10) {
                _dismiss();
              }
            },
            child: Material(
              color: Colors.transparent,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: UIConstants.glassBlurSigma,
                    sigmaY: UIConstants.glassBlurSigma,
                  ),
                  child: Container(
                    width: isMobile ? null : toastWidth,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface.withValues(
                        alpha: UIConstants.glassOpacity,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: config.color.withValues(alpha: 0.2),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color:
                              (theme.brightness == Brightness.dark
                                      ? Colors.black
                                      : config.color)
                                  .withValues(alpha: 0.3),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                          spreadRadius: -4,
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        // Icon
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: config.backgroundColor,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            config.icon,
                            color: config.color,
                            size: 22,
                          ),
                        ),

                        const SizedBox(width: 12),

                        // Message
                        Expanded(
                          child: Text(
                            widget.message,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              height: 1.4,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),

                        const SizedBox(width: 8),

                        // Action button (if provided)
                        if (widget.actionLabel != null &&
                            widget.onActionPressed != null) ...[
                          TextButton(
                            onPressed: () {
                              widget.onActionPressed?.call();
                              _dismiss();
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: config.color,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                            ),
                            child: Text(
                              widget.actionLabel!,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],

                        // Close button
                        IconButton(
                          icon: Icon(
                            Icons.close,
                            size: 20,
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.5,
                            ),
                          ),
                          onPressed: _dismiss,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 32,
                            minHeight: 32,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  _ToastPositioning _calculatePositioning({
    required MediaQueryData mediaQuery,
    required double toastWidth,
    required double horizontalPadding,
    required bool isMobile,
  }) {
    final screenWidth = mediaQuery.size.width;
    final safeAreaTop = mediaQuery.padding.top;
    final safeAreaBottom = mediaQuery.padding.bottom;

    // On large displays, auto-map center positions to a corner so
    // toasts don't obscure the middle of the screen.
    var pos = widget.position;
    if (!isMobile) {
      if (pos == ToastPosition.topCenter) pos = ToastPosition.topRight;
      if (pos == ToastPosition.bottomCenter) pos = ToastPosition.bottomRight;
    }

    double? top;
    double? bottom;
    double? left;
    double? right;

    // Vertical positioning.
    switch (pos) {
      case ToastPosition.topLeft:
      case ToastPosition.topCenter:
      case ToastPosition.topRight:
        top = safeAreaTop + 16;
      case ToastPosition.bottomLeft:
      case ToastPosition.bottomCenter:
      case ToastPosition.bottomRight:
        bottom = safeAreaBottom + 16;
    }

    // Horizontal positioning.
    if (isMobile) {
      // On mobile, always stretch full width with padding.
      left = horizontalPadding;
      right = horizontalPadding;
    } else {
      // On larger screens, position based on anchor.
      switch (pos) {
        case ToastPosition.topLeft:
        case ToastPosition.bottomLeft:
          left = horizontalPadding;
        case ToastPosition.topCenter:
        case ToastPosition.bottomCenter:
          left = (screenWidth - toastWidth) / 2;
        case ToastPosition.topRight:
        case ToastPosition.bottomRight:
          right = horizontalPadding;
      }
    }

    return _ToastPositioning(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
    );
  }
}

/// Helper class for toast positioning.
class _ToastPositioning {
  final double? top;
  final double? bottom;
  final double? left;
  final double? right;

  _ToastPositioning({this.top, this.bottom, this.left, this.right});
}

/// Notification configuration.
class _NotificationConfig {
  final IconData icon;
  final Color color;
  final Color backgroundColor;

  _NotificationConfig({
    required this.icon,
    required this.color,
    required this.backgroundColor,
  });
}
