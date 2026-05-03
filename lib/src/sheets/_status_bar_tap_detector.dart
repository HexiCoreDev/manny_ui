import 'package:flutter/widgets.dart';

/// Renders an invisible 44pt-tall tap target at the top of the screen.
/// On iOS, tapping the status bar here invokes [onTap] (typically used to
/// scroll a modal's primary scroll controller to top).
///
/// On Android the overlay is harmless: the system status bar is not a
/// touch target there, so this detector simply never fires.
///
/// Internal to the manny_ui sheet primitives; not exported.
///
/// Behavior contract mirrors `StatusBarGestureDetector` from the
/// modal_bottom_sheet package by Jaime Blasco (MIT licensed).
class StatusBarTapDetector extends StatefulWidget {
  const StatusBarTapDetector({
    super.key,
    required this.child,
    required this.onTap,
  });

  final Widget child;
  final VoidCallback onTap;

  @override
  State<StatusBarTapDetector> createState() => _StatusBarTapDetectorState();
}

class _StatusBarTapDetectorState extends State<StatusBarTapDetector> {
  final OverlayPortalController _portalController = OverlayPortalController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _portalController.show();
    });
  }

  @override
  Widget build(BuildContext context) {
    return OverlayPortal(
      controller: _portalController,
      overlayChildBuilder: (BuildContext overlayContext) {
        return Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: 44, // standard iOS status bar height
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: widget.onTap,
            child: const SizedBox.expand(),
          ),
        );
      },
      child: widget.child,
    );
  }
}
