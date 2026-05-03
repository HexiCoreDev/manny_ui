import 'dart:math';
import 'package:flutter/material.dart';

/// Visual style for the sound wave.
enum SoundWaveStyle {
  /// Horizontal bars that bounce to audio levels.
  horizontal,

  /// Circular ring that pulses and ripples to audio levels.
  circular,
}

/// A real-time sound wave visualizer that animates to audio levels.
///
/// Feed it amplitude data (0.0–1.0) from a microphone or audio player,
/// and it renders either horizontal bouncing bars or a circular pulsing ring.
///
/// Example usage:
/// ```dart
/// // Horizontal bars
/// SoundWave(
///   levels: audioLevels, // List<double> from 0.0 to 1.0
///   style: SoundWaveStyle.horizontal,
///   color: Colors.blue,
/// )
///
/// // Circular pulse
/// SoundWave(
///   levels: audioLevels,
///   style: SoundWaveStyle.circular,
///   color: Colors.purple,
///   size: 200,
/// )
/// ```
///
/// For demo/preview without real audio, use [SoundWave.demo] which
/// auto-animates with synthetic wave data.
class SoundWave extends StatelessWidget {
  const SoundWave({
    super.key,
    required this.levels,
    this.style = SoundWaveStyle.horizontal,
    this.color,
    this.secondaryColor,
    this.barCount = 40,
    this.barWidth = 3.0,
    this.barSpacing = 2.0,
    this.barRadius = 2.0,
    this.size,
    this.minBarHeight = 0.04,
    this.mirror = true,
  });

  /// Amplitude levels, each between 0.0 and 1.0.
  /// For horizontal: each value maps to one bar's height.
  /// For circular: values map to radial displacement around the ring.
  final List<double> levels;

  /// Visual style. Defaults to horizontal bars.
  final SoundWaveStyle style;

  /// Primary wave color. Defaults to theme primary.
  final Color? color;

  /// Secondary gradient color. Defaults to primary at 0.3 alpha.
  final Color? secondaryColor;

  /// Number of bars (horizontal) or segments (circular).
  final int barCount;

  /// Bar width in pixels.
  final double barWidth;

  /// Gap between bars.
  final double barSpacing;

  /// Bar corner radius.
  final double barRadius;

  /// Size constraint (width for horizontal, diameter for circular).
  final double? size;

  /// Minimum bar height as fraction of max. Prevents fully flat bars.
  final double minBarHeight;

  /// Whether to mirror bars (center-out). Horizontal only.
  final bool mirror;

  /// Create a self-animating demo wave for preview purposes.
  static Widget demo({
    Key? key,
    SoundWaveStyle style = SoundWaveStyle.horizontal,
    Color? color,
    Color? secondaryColor,
    int barCount = 40,
    double barWidth = 3.0,
    double barSpacing = 2.0,
    double? size,
    Duration speed = const Duration(milliseconds: 50),
  }) {
    return _SoundWaveDemo(
      key: key,
      style: style,
      color: color,
      secondaryColor: secondaryColor,
      barCount: barCount,
      barWidth: barWidth,
      barSpacing: barSpacing,
      size: size,
      speed: speed,
    );
  }

  List<double> get _normalizedLevels {
    if (levels.isEmpty) return List.filled(barCount, minBarHeight);
    if (levels.length == barCount) return levels;

    // Resample levels to match barCount
    final result = <double>[];
    for (int i = 0; i < barCount; i++) {
      final srcIndex = (i / barCount * levels.length).floor();
      result.add(levels[srcIndex.clamp(0, levels.length - 1)]);
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveColor = color ?? theme.colorScheme.primary;
    final effectiveSecondary =
        secondaryColor ?? effectiveColor.withValues(alpha: 0.3);

    if (style == SoundWaveStyle.circular) {
      final diameter = size ?? 200.0;
      return SizedBox(
        width: diameter,
        height: diameter,
        child: CustomPaint(
          painter: _CircularWavePainter(
            levels: _normalizedLevels,
            color: effectiveColor,
            secondaryColor: effectiveSecondary,
            minLevel: minBarHeight,
          ),
        ),
      );
    }

    // Horizontal
    return SizedBox(
      width: size,
      child: CustomPaint(
        size: Size(
          size ?? (barCount * (barWidth + barSpacing)),
          double.infinity,
        ),
        painter: _HorizontalWavePainter(
          levels: _normalizedLevels,
          color: effectiveColor,
          secondaryColor: effectiveSecondary,
          barWidth: barWidth,
          barSpacing: barSpacing,
          barRadius: barRadius,
          minLevel: minBarHeight,
          mirror: mirror,
        ),
      ),
    );
  }
}

// ─── Horizontal Bars Painter ─────────────────────────────────────────────────

class _HorizontalWavePainter extends CustomPainter {
  final List<double> levels;
  final Color color;
  final Color secondaryColor;
  final double barWidth;
  final double barSpacing;
  final double barRadius;
  final double minLevel;
  final bool mirror;

  _HorizontalWavePainter({
    required this.levels,
    required this.color,
    required this.secondaryColor,
    required this.barWidth,
    required this.barSpacing,
    required this.barRadius,
    required this.minLevel,
    required this.mirror,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final totalBarWidth = barWidth + barSpacing;
    final centerY = size.height / 2;
    final maxBarHeight = size.height * 0.9;

    for (int i = 0; i < levels.length; i++) {
      final level = levels[i].clamp(minLevel, 1.0);
      final barHeight = maxBarHeight * level;
      final x = i * totalBarWidth;

      if (x + barWidth > size.width) break;

      final gradient = LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [secondaryColor, color],
      );

      final paint = Paint()
        ..shader = gradient.createShader(
          Rect.fromLTWH(x, centerY - barHeight / 2, barWidth, barHeight),
        );

      final rect = mirror
          ? RRect.fromRectAndRadius(
              Rect.fromCenter(
                center: Offset(x + barWidth / 2, centerY),
                width: barWidth,
                height: barHeight,
              ),
              Radius.circular(barRadius),
            )
          : RRect.fromRectAndRadius(
              Rect.fromLTWH(x, size.height - barHeight, barWidth, barHeight),
              Radius.circular(barRadius),
            );

      canvas.drawRRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _HorizontalWavePainter old) =>
      old.levels != levels;
}

// ─── Circular Wave Painter ───────────────────────────────────────────────────

class _CircularWavePainter extends CustomPainter {
  final List<double> levels;
  final Color color;
  final Color secondaryColor;
  final double minLevel;

  _CircularWavePainter({
    required this.levels,
    required this.color,
    required this.secondaryColor,
    required this.minLevel,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final baseRadius = min(size.width, size.height) / 2 * 0.55;
    final maxDisplacement = min(size.width, size.height) / 2 * 0.35;
    final segmentCount = levels.length;

    // Inner glow ring
    final glowPaint = Paint()
      ..color = color.withValues(alpha: 0.08)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, baseRadius * 1.1, glowPaint);

    // Base circle
    final basePaint = Paint()
      ..color = color.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(center, baseRadius, basePaint);

    // Wave path
    final wavePath = Path();
    final wavePoints = <Offset>[];

    for (int i = 0; i <= segmentCount; i++) {
      final idx = i % segmentCount;
      final level = levels[idx].clamp(minLevel, 1.0);
      final angle = (2 * pi / segmentCount) * i - pi / 2;
      final radius = baseRadius + maxDisplacement * level;
      final x = center.dx + radius * cos(angle);
      final y = center.dy + radius * sin(angle);
      wavePoints.add(Offset(x, y));
    }

    // Smooth the wave with cubic bezier
    if (wavePoints.length >= 2) {
      wavePath.moveTo(wavePoints[0].dx, wavePoints[0].dy);
      for (int i = 0; i < wavePoints.length - 1; i++) {
        final p0 = wavePoints[i];
        final p1 = wavePoints[(i + 1) % wavePoints.length];
        final midX = (p0.dx + p1.dx) / 2;
        final midY = (p0.dy + p1.dy) / 2;
        wavePath.quadraticBezierTo(p0.dx, p0.dy, midX, midY);
      }
      wavePath.close();
    }

    // Fill with gradient
    final fillPaint = Paint()
      ..shader =
          RadialGradient(
            colors: [
              color.withValues(alpha: 0.12),
              secondaryColor.withValues(alpha: 0.04),
            ],
          ).createShader(
            Rect.fromCircle(
              center: center,
              radius: baseRadius + maxDisplacement,
            ),
          )
      ..style = PaintingStyle.fill;
    canvas.drawPath(wavePath, fillPaint);

    // Stroke outline
    final strokePaint = Paint()
      ..shader =
          SweepGradient(
            colors: [color, secondaryColor, color],
            startAngle: 0,
            endAngle: 2 * pi,
          ).createShader(
            Rect.fromCircle(
              center: center,
              radius: baseRadius + maxDisplacement,
            ),
          )
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(wavePath, strokePaint);
  }

  @override
  bool shouldRepaint(covariant _CircularWavePainter old) =>
      old.levels != levels;
}

// ─── Self-Animating Demo ─────────────────────────────────────────────────────

class _SoundWaveDemo extends StatefulWidget {
  final SoundWaveStyle style;
  final Color? color;
  final Color? secondaryColor;
  final int barCount;
  final double barWidth;
  final double barSpacing;
  final double? size;
  final Duration speed;

  const _SoundWaveDemo({
    super.key,
    required this.style,
    this.color,
    this.secondaryColor,
    required this.barCount,
    required this.barWidth,
    required this.barSpacing,
    this.size,
    required this.speed,
  });

  @override
  State<_SoundWaveDemo> createState() => _SoundWaveDemoState();
}

class _SoundWaveDemoState extends State<_SoundWaveDemo>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final _random = Random();
  late List<double> _levels;
  late List<double> _targets;

  @override
  void initState() {
    super.initState();
    _levels = List.generate(widget.barCount, (_) => 0.05);
    _targets = List.generate(widget.barCount, (_) => _random.nextDouble());

    _controller = AnimationController(vsync: this, duration: widget.speed)
      ..addListener(_tick);

    _controller.repeat();
  }

  void _tick() {
    setState(() {
      for (int i = 0; i < _levels.length; i++) {
        // Ease toward target
        _levels[i] += (_targets[i] - _levels[i]) * 0.15;

        // Pick new target when close enough
        if ((_levels[i] - _targets[i]).abs() < 0.05) {
          _targets[i] = _random.nextDouble() * 0.8 + 0.05;
        }
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SoundWave(
      levels: _levels,
      style: widget.style,
      color: widget.color,
      secondaryColor: widget.secondaryColor,
      barCount: widget.barCount,
      barWidth: widget.barWidth,
      barSpacing: widget.barSpacing,
      size: widget.size,
    );
  }
}
