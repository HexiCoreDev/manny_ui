import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:manny_ui/config/ui_constants.dart';
import 'package:manny_ui/utils/nav_toast_controller.dart';
import 'package:manny_ui/utils/neumorphic_painter.dart';
import 'item_navigation_view.dart';

/// Animated bottom navigation bar with gradient indicator and glassmorphism.
///
/// Supports two modes:
/// - **Docked** (default): Full-width bar at the bottom edge.
/// - **Floating**: Telegram-style pill floating above the bottom edge with
///   neumorphic shadow, backdrop blur, and hide-on-scroll support.
///
/// Example usage:
/// ```dart
/// // Docked mode (default)
/// NavigationView(
///   onChangePage: (index) => setState(() => _currentPage = index),
///   items: [...],
///   selectedIndex: _currentPage,
///   color: Colors.blue,
/// )
///
/// // Floating mode (Telegram-style)
/// NavigationView(
///   floating: true,
///   onChangePage: (index) => setState(() => _currentPage = index),
///   items: [...],
///   selectedIndex: _currentPage,
///   color: Colors.blue,
/// )
/// ```
class NavigationView extends StatefulWidget {
  final Function(int) onChangePage;
  final Color? backgroundColor;
  final Color? borderTopColor;
  final Curve? curve;
  final Color? color;
  final BorderRadiusGeometry? borderRadius;
  final Gradient? gradient;
  final Duration? durationAnimation;
  final List<ItemNavigationView> items;
  final int defaultSelectedIndex;
  final int? selectedIndex;
  final bool useTooltip;
  final bool topIndicator;
  final Radius indicatorRadius;
  final double indicatorGradientCover;
  final bool enableGlassmorphism;
  final double blurSigma;

  /// Enable floating pill mode (Telegram-style).
  final bool floating;

  /// Vertical orientation — renders as a tall pill on the left side.
  final bool vertical;

  /// Width as fraction of screen width when floating horizontal. Defaults to 0.75.
  final double floatingWidthFactor;

  /// Bottom margin when floating horizontal. Defaults to 4.
  final double floatingMarginBottom;

  /// Left margin when floating vertical. Defaults to 12.
  final double floatingMarginLeft;

  /// Whether the floating bar is currently visible.
  /// Useful for hide-on-scroll. Defaults to true.
  final bool visible;

  /// Indicator stroke thickness on a 1–5 scale.
  /// 1 = thin (1.5px), 3 = default (3.0px), 5 = thick (5.0px).
  final int indicatorThickness;

  /// Optional toast controller. When a toast is active, the indicator
  /// wraps fully around the pill border in the toast's color.
  final NavToastController? toastController;

  const NavigationView({
    super.key,
    required this.onChangePage,
    required this.items,
    this.defaultSelectedIndex = 0,
    this.selectedIndex,
    this.durationAnimation,
    this.backgroundColor,
    this.borderRadius,
    this.gradient,
    this.color,
    this.curve,
    this.borderTopColor,
    this.useTooltip = false,
    this.topIndicator = false,
    this.indicatorRadius = const Radius.circular(25),
    this.indicatorGradientCover = 0.5,
    this.enableGlassmorphism = true,
    this.blurSigma = 15.0,
    this.floating = false,
    this.vertical = false,
    this.floatingWidthFactor = 0.75,
    this.floatingMarginBottom = 4.0,
    this.floatingMarginLeft = 12.0,
    this.visible = true,
    this.indicatorThickness = 3,
    this.toastController,
  });

  @override
  State<StatefulWidget> createState() => _NavigationViewState();
}

class _NavigationViewState extends State<NavigationView>
    with SingleTickerProviderStateMixin {
  late int _currentPage;
  final Color colorDefault = Colors.blue;
  late Duration durationAnimation;
  late AnimationController _indicatorController;

  // Single indicator that always moves clockwise around the pill perimeter.
  double _pathDist = 0;
  // Glow intensity per tab (0.0 = no glow, 1.0 = full glow).
  // Only the resting tab glows; fades in when indicator arrives.
  late List<double> _glowIntensity;

  @override
  void initState() {
    super.initState();

    durationAnimation =
        widget.durationAnimation ?? const Duration(milliseconds: 250);

    _indicatorController =
        AnimationController(
            vsync: this,
            duration: Duration(
              milliseconds: durationAnimation.inMilliseconds * 2,
            ),
          )
          ..addListener(_onTick)
          ..addStatusListener((status) {
            if (status == AnimationStatus.completed) {
              // Indicator arrived — fade in glow on the current tab
              _startGlow(_currentPage);
            }
          });

    final initialIndex = widget.selectedIndex ?? widget.defaultSelectedIndex;
    _currentPage = (initialIndex >= 0 && initialIndex < widget.items.length)
        ? initialIndex
        : 0;

    _glowIntensity = List.filled(widget.items.length, 0.0);
    _glowIntensity[_currentPage] = 1.0;

    widget.toastController?.addListener(_onToastChanged);

    if (widget.selectedIndex == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onChangePage.call(_currentPage);
      });
    }
  }

  // Toast state
  double _toastIndicatorFraction = 0.0; // 0 = normal, 1 = full perimeter
  double _toastTargetFraction = 0.0;
  Color? _toastColor;
  String? _toastMessage;
  Timer? _toastAnimTimer;

  void _onToastChanged() {
    final toast = widget.toastController?.state;
    if (toast != null && toast.isActive) {
      _toastColor = toast.color;
      _toastMessage = toast.message;
      _toastTargetFraction = 1.0;
      _startToastAnim();
    } else {
      _toastTargetFraction = 0.0;
      _startToastAnim();
    }
  }

  void _startToastAnim() {
    _toastAnimTimer?.cancel();
    _toastAnimTimer = Timer.periodic(const Duration(milliseconds: 16), (_) {
      if (!mounted) { _toastAnimTimer?.cancel(); return; }
      setState(() {
        // Slow grow (0.03 per frame ≈ 500ms to full), fast shrink
        final speed = _toastTargetFraction > _toastIndicatorFraction ? 0.03 : 0.08;
        _toastIndicatorFraction +=
            (_toastTargetFraction - _toastIndicatorFraction) * speed;

        // Snap when close enough
        if ((_toastIndicatorFraction - _toastTargetFraction).abs() < 0.01) {
          _toastIndicatorFraction = _toastTargetFraction;
          if (_toastTargetFraction == 0.0) {
            _toastColor = null;
            _toastMessage = null;
          }
          _toastAnimTimer?.cancel();
        }
      });
    });
  }

  @override
  void dispose() {
    _toastAnimTimer?.cancel();
    widget.toastController?.removeListener(_onToastChanged);
    _indicatorController.dispose();
    super.dispose();
  }

  // ── Path distance helpers ──

  double _tabToTopDist(int tab, double w, double r) {
    final tabW = w / widget.items.length;
    final cx = tabW * tab + tabW / 2;
    if (cx <= r) {
      final total = _perimeter(w, r);
      return total - (r * pi / 2) * ((r - cx) / r);
    } else if (cx >= w - r) {
      return (w - 2 * r) + (r * pi / 2) * ((cx - (w - r)) / r);
    }
    return cx - r;
  }

  double _tabToBottomDist(int tab, double w, double r) {
    final tabW = w / widget.items.length;
    final cx = tabW * tab + tabW / 2;
    // Bottom edge starts after: topEdge + topRightArc + rightEdge(0 for pill) + bottomRightArc
    final bottomStart = (w - 2 * r) + (r * pi / 2) + 0 + (r * pi / 2);
    // Bottom goes right-to-left: x=(w-r) maps to dist=0 along bottom, x=r maps to dist=(w-2r)
    final distAlongBottom = (w - r - cx).clamp(0.0, w - 2 * r);
    return bottomStart + distAlongBottom;
  }

  double _perimeter(double w, double r) =>
      2 * (w - 2 * r) +
      2 * pi * r; // pill: h = 2r so straight vertical edges = 0

  // ── Animation ──

  double _animFrom = 0;
  double _animTo = 0;

  void _onTick() {
    final t = Curves.easeInOutCubic
        .transform(_indicatorController.value)
        .clamp(0.0, 1.0);
    setState(() {
      _pathDist = _animFrom + (_animTo - _animFrom) * t;
    });
  }

  void _startGlow(int tab) {
    // Animate glow fade-in over a few frames
    Future.delayed(Duration.zero, () {
      if (!mounted) return;
      setState(() {
        for (int i = 0; i < _glowIntensity.length; i++) {
          _glowIntensity[i] = i == tab ? 1.0 : 0.0;
        }
      });
    });
  }

  void _animateIndicatorTo(int newPage, double navWidth, double r) {
    final oldPage = _currentPage;
    _currentPage = newPage;

    // Kill glow on departure
    for (int i = 0; i < _glowIntensity.length; i++) {
      _glowIntensity[i] = 0.0;
    }

    final totalLen = _perimeter(navWidth, r);
    final oldTopDist = _tabToTopDist(oldPage, navWidth, r);
    final newTopDist = _tabToTopDist(newPage, navWidth, r);

    _animFrom = _pathDist;

    final newBottomDist = _tabToBottomDist(newPage, navWidth, r);

    // Always clockwise (forward). Never reverse.
    // Right → land on TOP. Left → land on BOTTOM.
    final targetDist = newPage > oldPage ? newTopDist : newBottomDist;
    final currentOnPath = _animFrom % totalLen;
    var travel = targetDist - currentOnPath;
    if (travel <= 0) travel += totalLen; // always forward (clockwise)
    _animTo = _animFrom + travel;

    // Duration proportional to travel distance — slow and smooth
    final travelFrac = (_animTo - _animFrom).abs() / totalLen;
    _indicatorController.duration = Duration(
      milliseconds:
          (durationAnimation.inMilliseconds * 6 * travelFrac.clamp(0.4, 1.0))
              .round(),
    );
    _indicatorController.forward(from: 0);
  }

  double _lastNavWidth = 0;

  @override
  void didUpdateWidget(NavigationView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedIndex != null &&
        widget.selectedIndex != oldWidget.selectedIndex &&
        widget.selectedIndex != _currentPage) {
      final newIndex = widget.selectedIndex!;
      if (newIndex >= 0 && newIndex < widget.items.length) {
        _animateIndicatorTo(newIndex, _lastNavWidth, 28.0);
      }
    }
  }

  /// Vertical floating = rotated horizontal (no vertical-specific indicator math).
  bool get _isRotatedVertical => widget.vertical && widget.floating;

  /// Floating mode always uses top indicator.
  bool get _effectiveTopIndicator =>
      widget.floating ? true : widget.topIndicator;

  /// Map 1–5 scale to pixel strokeWidth.
  double get _indicatorStrokeWidth =>
      1.5 + (widget.indicatorThickness.clamp(1, 5) - 1) * 0.875;

  BorderRadiusGeometry get _effectiveContainerBorderRadius =>
      widget.borderRadius ?? BorderRadius.circular(11.0);

  BorderRadius get _effectiveIndicatorLineBorderRadius {
    return _effectiveTopIndicator
        ? BorderRadius.only(
            bottomLeft: widget.indicatorRadius,
            bottomRight: widget.indicatorRadius,
          )
        : BorderRadius.only(
            topLeft: widget.indicatorRadius,
            topRight: widget.indicatorRadius,
          );
  }

  Widget _buildGradientIndicator() {
    final double cover = widget.indicatorGradientCover.clamp(0.0, 1.0);
    final LinearGradient defaultGradient = _effectiveTopIndicator
        ? LinearGradient(
            colors: [
              widget.color?.withValues(alpha: 0.2) ??
                  colorDefault.withValues(alpha: 0.2),
              Colors.white.withValues(alpha: 0),
            ],
            stops: [1.0 - cover, 1.0],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          )
        : LinearGradient(
            colors: [
              Colors.white.withValues(alpha: 0),
              widget.color?.withValues(alpha: 0.2) ??
                  colorDefault.withValues(alpha: 0.2),
            ],
            stops: [0.0, cover],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          );
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5),
        child: AnimatedContainer(
          duration: Duration(
            microseconds: durationAnimation.inMilliseconds ~/ 2.1,
          ),
          decoration: BoxDecoration(
            gradient: widget.gradient ?? defaultGradient,
          ),
        ),
      ),
    );
  }

  Widget _buildIndicatorLine() {
    final indicatorColor = widget.color ?? colorDefault;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: AnimatedContainer(
        duration: Duration(milliseconds: durationAnimation.inMilliseconds ~/ 2),
        width: double.maxFinite,
        height: 4,
        decoration: BoxDecoration(
          color: indicatorColor.withValues(alpha: 0.8),
          borderRadius: _effectiveIndicatorLineBorderRadius,
          boxShadow: [
            BoxShadow(
              color: indicatorColor.withValues(alpha: 0.5),
              blurRadius: 8,
              spreadRadius: 1,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedIcon(
    ItemNavigationView item,
    bool isSelected,
    int index,
  ) {
    final double yOffset = widget.floating
        ? 0.0
        : isSelected
        ? (widget.topIndicator ? 5.0 : -5.0)
        : 0.0;

    final glow = widget.floating && index < _glowIntensity.length
        ? _glowIntensity[index]
        : 0.0;
    final glowColor = widget.color ?? colorDefault;

    Widget iconWidget = AnimatedCrossFade(
      firstChild: item.iconBefore,
      secondChild: item.iconAfter,
      crossFadeState: isSelected
          ? CrossFadeState.showSecond
          : CrossFadeState.showFirst,
      duration: Duration(milliseconds: durationAnimation.inMilliseconds ~/ 2),
    );

    if (glow > 0) {
      iconWidget = AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: glowColor.withValues(alpha: 0.5 * glow),
              blurRadius: 18 * glow,
              spreadRadius: 2 * glow,
            ),
          ],
        ),
        child: iconWidget,
      );
    }

    Widget result = AnimatedContainer(
      duration: Duration(milliseconds: durationAnimation.inMilliseconds ~/ 2),
      transform: Matrix4.translationValues(0, yOffset, 0),
      child: iconWidget,
    );

    // Counter-transform for rotated vertical: undo the outer CW + flipX
    if (_isRotatedVertical) {
      result = RotatedBox(
        quarterTurns: 3,
        child: Transform.flip(flipX: true, child: result),
      );
    }

    return result;
  }

  Widget _buildNavContent() {
    final isFloating = widget.floating;
    final height = isFloating ? 56.0 : 55.0;
    final borderRadius = isFloating
        ? BorderRadius.circular(height / 2)
        : (_effectiveContainerBorderRadius as BorderRadius?) ??
              BorderRadius.circular(11.0);

    final bgColor = widget.enableGlassmorphism
        ? (widget.backgroundColor ?? Colors.white).withValues(
            alpha: UIConstants.glassOpacity,
          )
        : widget.backgroundColor ?? Colors.white;

    return Container(
      width: double.maxFinite,
      height: height,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: isFloating ? borderRadius : null,
      ),
      child: Column(
        children: [
          if (!isFloating)
            Container(
              width: double.maxFinite,
              height: 1,
              color: widget.borderTopColor ?? Colors.transparent,
            ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                _lastNavWidth = constraints.maxWidth;
                if (_pathDist == 0 && isFloating) {
                  _pathDist = _tabToTopDist(
                    _currentPage,
                    constraints.maxWidth,
                    28.0,
                  );
                }
                return Stack(
                  children: [
                    if (isFloating)
                      CustomPaint(
                        size: Size(constraints.maxWidth, constraints.maxHeight),
                        painter: _FloatingIndicatorPainter(
                          pathDistance: _pathDist,
                          itemCount: widget.items.length,
                          color: _toastColor ?? widget.color ?? colorDefault,
                          navWidth: constraints.maxWidth,
                          navHeight: constraints.maxHeight,
                          pillRadius: 28,
                          strokeWidth: _indicatorStrokeWidth,
                          toastFraction: _toastIndicatorFraction,
                        ),
                      )
                    else
                      AnimatedPositioned(
                        curve: widget.curve ?? Curves.easeInOutQuint,
                        left:
                            (constraints.maxWidth / widget.items.length) *
                            _currentPage,
                        width: constraints.maxWidth / widget.items.length,
                        height: constraints.maxHeight,
                        duration: Duration(
                          milliseconds: durationAnimation.inMilliseconds,
                        ),
                        child: Padding(
                          padding: EdgeInsets.only(
                            top: _effectiveTopIndicator ? 0 : 5,
                            bottom: _effectiveTopIndicator ? 5 : 0,
                            left: (45 / widget.items.length),
                            right: (45 / widget.items.length),
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              borderRadius: _effectiveContainerBorderRadius,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: _effectiveTopIndicator
                                  ? [
                                      _buildIndicatorLine(),
                                      _buildGradientIndicator(),
                                    ]
                                  : [
                                      _buildGradientIndicator(),
                                      _buildIndicatorLine(),
                                    ],
                            ),
                          ),
                        ),
                      ),

                    // Tab icons — hidden during toast
                    AnimatedOpacity(
                      duration: const Duration(milliseconds: 300),
                      opacity: _toastMessage != null ? 0.0 : 1.0,
                      child: SizedBox(
                      width: double.maxFinite,
                      height: double.maxFinite,
                      child: Row(
                        textDirection: TextDirection.ltr,
                        children: widget.items.map((item) {
                          int index = widget.items.indexOf(item);
                          bool isSelected = (_currentPage == index);
                          Widget itemWidget = InkWell(
                            onTap: () {
                              if (index != _currentPage) {
                                if (widget.floating) {
                                  _animateIndicatorTo(
                                    index,
                                    _lastNavWidth,
                                    28.0,
                                  );
                                } else {
                                  setState(() => _currentPage = index);
                                }
                                widget.onChangePage.call(index);
                              }
                            },
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                return Center(
                                  child: _buildAnimatedIcon(
                                    item,
                                    isSelected,
                                    index,
                                  ),
                                );
                              },
                            ),
                          );
                          if (widget.useTooltip &&
                              item.tooltip != null &&
                              item.tooltip!.isNotEmpty) {
                            return Flexible(
                              flex: 1,
                              child: Tooltip(
                                message: item.tooltip!,
                                child: itemWidget,
                              ),
                            );
                          } else {
                            return Flexible(flex: 1, child: itemWidget);
                          }
                        }).toList(),
                      ),
                    ),
                    ),

                    // Toast message overlay
                    if (_toastMessage != null)
                      AnimatedOpacity(
                        duration: const Duration(milliseconds: 300),
                        opacity: _toastIndicatorFraction > 0.5 ? 1.0 : 0.0,
                        child: Container(
                          width: double.maxFinite,
                          height: double.maxFinite,
                          alignment: Alignment.center,
                          child: _isRotatedVertical
                            ? RotatedBox(
                                quarterTurns: 2,
                                child: Transform.flip(
                                  flipX: true,
                                  child: Text(
                                    _toastMessage!,
                                    style: TextStyle(
                                      color: _toastColor,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 11,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              )
                            : Text(
                            _toastMessage!,
                            style: TextStyle(
                              color: _toastColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final navContent = _buildNavContent();

    Widget result;

    if (widget.floating && widget.vertical) {
      // Vertical floating pill — rotated horizontal pill.
      final pillRadius = BorderRadius.circular(28);
      final totalHeight = widget.items.length * 56.0 + 56;

      const neuStyle = NeumorphicStyle(lightAngle: 315, depth: 6);
      final lightColor = isDark
          ? Colors.white.withValues(alpha: 0.05 * neuStyle.lightIntensity)
          : Colors.white.withValues(alpha: 0.7 * neuStyle.lightIntensity);
      final darkColor = isDark
          ? Colors.black.withValues(alpha: 0.6 * neuStyle.darkIntensity)
          : Colors.black.withValues(alpha: 0.15 * neuStyle.darkIntensity);

      result = Align(
        alignment: Alignment.centerLeft,
        child: Padding(
          padding: EdgeInsets.only(left: widget.floatingMarginLeft),
          child: Transform.flip(
            flipX: true,
            child: SizedBox(
              width: 56,
              height: totalHeight,
              child: RotatedBox(
                quarterTurns: 1,
                child: CustomPaint(
                  painter: NeumorphicPainter(
                    style: neuStyle,
                    borderRadius: pillRadius,
                    surfaceColor: Colors.transparent,
                    lightColor: lightColor,
                    darkColor: darkColor,
                    isDark: isDark,
                  ),
                  child: ClipRRect(
                    borderRadius: pillRadius,
                    child: BackdropFilter(
                      filter: ImageFilter.blur(
                        sigmaX: widget.blurSigma,
                        sigmaY: widget.blurSigma,
                      ),
                      child: CustomPaint(
                        painter: NeumorphicPainter(
                          style: neuStyle,
                          borderRadius: pillRadius,
                          surfaceColor: (widget.backgroundColor ?? Colors.white)
                              .withValues(alpha: UIConstants.glassOpacity),
                          lightColor: Colors.transparent,
                          darkColor: Colors.transparent,
                          isDark: isDark,
                        ),
                        child: navContent,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    } else if (widget.floating) {
      // Horizontal floating pill mode with angular neumorphic shadow
      final pillRadius = BorderRadius.circular(28);
      final screenWidth = MediaQuery.of(context).size.width;
      final navWidth = screenWidth * widget.floatingWidthFactor;
      final bottomPad = MediaQuery.of(context).padding.bottom;

      const neuStyle = NeumorphicStyle(lightAngle: 315, depth: 6);

      final lightColor = isDark
          ? Colors.white.withValues(alpha: 0.05 * neuStyle.lightIntensity)
          : Colors.white.withValues(alpha: 0.7 * neuStyle.lightIntensity);
      final darkColor = isDark
          ? Colors.black.withValues(alpha: 0.6 * neuStyle.darkIntensity)
          : Colors.black.withValues(alpha: 0.15 * neuStyle.darkIntensity);

      // Use a SizedBox + AnimatedPositioned so the slide-out
      // isn't clipped by the bottomNavigationBar slot.
      final totalHeight = 56.0 + widget.floatingMarginBottom + bottomPad + 20;
      result = SizedBox(
        height: totalHeight,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            AnimatedPositioned(
              duration: const Duration(milliseconds: 380),
              curve: Curves.easeOutQuint,
              bottom: widget.visible ? 0 : -totalHeight,
              left: 0,
              right: 0,
              child: Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: navWidth,
              margin: EdgeInsets.only(
                bottom: widget.floatingMarginBottom + bottomPad,
              ),
              child: CustomPaint(
                painter: NeumorphicPainter(
                  style: neuStyle,
                  borderRadius: pillRadius,
                  surfaceColor: Colors.transparent,
                  lightColor: lightColor,
                  darkColor: darkColor,
                  isDark: isDark,
                ),
                child: ClipRRect(
                  borderRadius: pillRadius,
                  child: BackdropFilter(
                    filter: ImageFilter.blur(
                      sigmaX: widget.blurSigma,
                      sigmaY: widget.blurSigma,
                    ),
                    child: CustomPaint(
                      painter: NeumorphicPainter(
                        style: neuStyle,
                        borderRadius: pillRadius,
                        surfaceColor: (widget.backgroundColor ?? Colors.white)
                            .withValues(alpha: UIConstants.glassOpacity),
                        lightColor: Colors.transparent,
                        darkColor: Colors.transparent,
                        isDark: isDark,
                      ),
                      child: navContent,
                    ),
                  ),
                ),
              ),
            ),
          ),
            ),
          ],
        ),
      );
    } else if (widget.enableGlassmorphism) {
      // Docked glassmorphism mode
      result = ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: widget.blurSigma,
            sigmaY: widget.blurSigma,
          ),
          child: navContent,
        ),
      );
    } else {
      result = navContent;
    }

    return result;
  }
}

/// Edge-lighting indicator that orbits the pill border.
///
/// [pathDistance] is a cumulative distance along the pill perimeter.
/// The painter modulos it by the total length, then extracts a glowing
/// segment. The indicator naturally follows curves at the pill's edges.
///
/// Moving right → slides clockwise along the top.
/// Moving left  → slides clockwise the long way around the bottom.
class _FloatingIndicatorPainter extends CustomPainter {
  final double pathDistance;
  final int itemCount;
  final Color color;
  final double navWidth;
  final double navHeight;
  final double pillRadius;
  final double strokeWidth;

  /// 0.0 = normal segment, 1.0 = full perimeter (toast mode).
  final double toastFraction;

  _FloatingIndicatorPainter({
    required this.pathDistance,
    required this.itemCount,
    required this.color,
    required this.navWidth,
    required this.navHeight,
    this.pillRadius = 28,
    this.strokeWidth = 3.0,
    this.toastFraction = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = navWidth;
    final h = navHeight;
    final r = pillRadius.clamp(0.0, h / 2);

    // Build the pill border as a closed clockwise path starting after
    // the top-left arc: (r, 0) → top → top-right arc → right → ... → top-left arc → (r, 0)
    final borderPath = Path();
    borderPath.moveTo(r, 0);
    borderPath.lineTo(w - r, 0);
    borderPath.arcToPoint(Offset(w, r), radius: Radius.circular(r));
    borderPath.lineTo(w, h - r);
    borderPath.arcToPoint(Offset(w - r, h), radius: Radius.circular(r));
    borderPath.lineTo(r, h);
    borderPath.arcToPoint(Offset(0, h - r), radius: Radius.circular(r));
    borderPath.lineTo(0, r);
    borderPath.arcToPoint(Offset(r, 0), radius: Radius.circular(r));

    final metrics = borderPath.computeMetrics().first;
    final totalLength = metrics.length;

    // Wrap the cumulative distance into [0, totalLength)
    double dist = pathDistance % totalLength;
    if (dist < 0) dist += totalLength;

    // Segment length ~ one tab width
    final tabW = w / itemCount;
    // Interpolate segment length: normal → full perimeter when toast is active
    final normalSegLen = tabW * 0.75;
    final segLen = normalSegLen + (totalLength - normalSegLen) * toastFraction.clamp(0.0, 1.0);
    final halfSeg = segLen / 2;

    var startDist = dist - halfSeg;
    var endDist = dist + halfSeg;

    // Draw — handle wrapping at the loop seam
    final glowPaint = Paint()
      ..color = color.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth + 4
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    final paint = Paint()
      ..color = color.withValues(alpha: 0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    if (startDist < 0) {
      // Wraps around the seam — draw two segments
      final seg1 = metrics.extractPath(totalLength + startDist, totalLength);
      final seg2 = metrics.extractPath(0, endDist.clamp(0, totalLength));
      canvas.drawPath(seg1, glowPaint);
      canvas.drawPath(seg2, glowPaint);
      canvas.drawPath(seg1, paint);
      canvas.drawPath(seg2, paint);
    } else if (endDist > totalLength) {
      // Wraps the other way
      final seg1 = metrics.extractPath(startDist, totalLength);
      final seg2 = metrics.extractPath(0, endDist - totalLength);
      canvas.drawPath(seg1, glowPaint);
      canvas.drawPath(seg2, glowPaint);
      canvas.drawPath(seg1, paint);
      canvas.drawPath(seg2, paint);
    } else {
      final seg = metrics.extractPath(startDist, endDist);
      canvas.drawPath(seg, glowPaint);
      canvas.drawPath(seg, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _FloatingIndicatorPainter old) =>
      old.pathDistance != pathDistance || old.color != color ||
      old.strokeWidth != strokeWidth;
}
