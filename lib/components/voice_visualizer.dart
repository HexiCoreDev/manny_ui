import 'dart:math';
import 'package:flutter/material.dart';

/// Visual style for the AI voice visualizer.
enum VoiceVisualizerStyle {
  /// Siri-style: multiple flowing sine waves stacked, gradient colored,
  /// with edge attenuation and organic breathing.
  siriWave,

  /// iOS 9 Siri-style: three additive-blended waveform layers with
  /// independent curve spawning, despawning, and color mixing.
  /// The authentic Siri look.
  siriIos9,

  /// Gemini-style: horizontal flowing bands of light, aurora-like,
  /// with phase-offset layers and amplitude modulation.
  geminiBand,

  /// Fluid blob: a morphing organic blob that pulses and deforms
  /// with audio, like water disturbed by sound.
  fluidBlob,
}

/// AI voice visualizer that reacts to audio amplitude.
///
/// Feed it a single `amplitude` (0.0–1.0) and it renders a beautiful
/// animated waveform. Idle state shows gentle breathing animation.
///
/// ```dart
/// VoiceVisualizer(
///   amplitude: currentAmplitude,
///   style: VoiceVisualizerStyle.siriWave,
///   colors: [Colors.purple, Colors.blue, Colors.cyan],
/// )
/// ```
///
/// For self-animating demo:
/// ```dart
/// VoiceVisualizer.demo(
///   style: VoiceVisualizerStyle.siriWave,
///   speaking: true,
/// )
/// ```
class VoiceVisualizer extends StatefulWidget {
  const VoiceVisualizer({
    super.key,
    this.amplitude = 0,
    this.bands,
    this.style = VoiceVisualizerStyle.siriWave,
    this.colors,
    this.height = 120,
    this.width,
    this.speed = 1.0,
    this.waveCount = 4,
  });

  /// Overall amplitude (0.0–1.0). Used when [bands] is null.
  final double amplitude;

  /// 4 frequency band energies from the spectrum analyzer:
  /// [low, lowMid, midHigh, high]. Each 0.0–1.0.
  /// When provided, each wave layer reacts to its own frequency range.
  final List<double>? bands;

  /// Visual style.
  final VoiceVisualizerStyle style;

  /// Gradient colors for the wave. Defaults to purple → blue → cyan.
  final List<Color>? colors;

  /// Height of the visualizer.
  final double height;

  /// Width. Null = fill parent.
  final double? width;

  /// Animation speed multiplier.
  final double speed;

  /// Number of wave layers.
  final int waveCount;

  /// Self-animating demo with simulated voice patterns.
  static Widget demo({
    Key? key,
    VoiceVisualizerStyle style = VoiceVisualizerStyle.siriWave,
    List<Color>? colors,
    double height = 120,
    double? width,
    bool speaking = true,
  }) {
    return _VoiceVisualizerDemo(
      key: key,
      style: style,
      colors: colors,
      height: height,
      width: width,
      speaking: speaking,
    );
  }

  @override
  State<VoiceVisualizer> createState() => _VoiceVisualizerState();
}

class _VoiceVisualizerState extends State<VoiceVisualizer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final _smoothBands = [0.0, 0.0, 0.0, 0.0];
  final _stopwatch = Stopwatch();

  @override
  void initState() {
    super.initState();
    _stopwatch.start();
    // Controller only drives repaints — we use _stopwatch for continuous time
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<double> get _effectiveBands {
    final raw = widget.bands ??
        List.filled(4, widget.amplitude);
    // Rust analyzer already applies 0.85 smoothing (matching WaveForge).
    // Dart side just does a light lerp for 60fps visual interpolation.
    for (int i = 0; i < 4; i++) {
      final target = i < raw.length ? raw[i] : 0.0;
      _smoothBands[i] += (target - _smoothBands[i]) * 0.35;
    }
    return _smoothBands;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final defaultColors = [
      theme.colorScheme.primary,
      theme.colorScheme.secondary,
      theme.colorScheme.tertiary,
      theme.colorScheme.primary.withValues(alpha: 0.7),
    ];
    final colors = widget.colors ?? defaultColors;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final bands = _effectiveBands;
        final avgAmp = bands.reduce((a, b) => a + b) / bands.length;
        // Continuous time from stopwatch — never loops
        final time = _stopwatch.elapsedMilliseconds / 1000.0 *
            widget.speed;

        return SizedBox(
          width: widget.width,
          height: widget.height,
          child: CustomPaint(
            painter: switch (widget.style) {
              VoiceVisualizerStyle.siriWave => _SiriWavePainter(
                time: time,
                bands: bands,
                colors: colors,
                waveCount: widget.waveCount,
              ),
              VoiceVisualizerStyle.siriIos9 => _SiriIos9Painter(
                amplitude: avgAmp,
                speed: 0.2 * widget.speed,
                colors: colors,
              ),
              VoiceVisualizerStyle.geminiBand => _GeminiBandPainter(
                time: time,
                bands: bands,
                colors: colors,
                waveCount: widget.waveCount,
              ),
              VoiceVisualizerStyle.fluidBlob => _FluidBlobPainter(
                time: time,
                bands: bands,
                colors: colors,
              ),
            },
            size: Size.infinite,
          ),
        );
      },
    );
  }
}

// ─── Siri Wave Painter ───────────────────────────────────────────────────────

class _SiriWavePainter extends CustomPainter {
  final double time;
  final List<double> bands;
  final List<Color> colors;
  final int waveCount;

  _SiriWavePainter({
    required this.time,
    required this.bands,
    required this.colors,
    required this.waveCount,
  });

  // Edge attenuation — organic falloff at left/right edges
  double _attenuation(double x, double width) {
    final normalized = (x / width) * 2 - 1; // -1 to 1
    final factor = 4.0;
    return pow(factor / (factor + normalized * normalized), factor).toDouble();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final midY = size.height / 2;
    for (int w = 0; w < waveCount; w++) {
      // Each wave layer uses its own frequency band
      final bandAmp = w < bands.length ? bands[w] : bands.last;
      final effectiveAmp = 0.03 + bandAmp * 0.45;
      final wavePhase = w * 0.8;
      final waveFreq = 1.5 + w * 0.4;
      final waveAmpFactor = 1.0 - (w * 0.15);
      final opacity = (0.6 - w * 0.1).clamp(0.15, 0.6);

      final colorIndex = w % colors.length;
      final nextColorIndex = (w + 1) % colors.length;
      final waveColor = Color.lerp(
        colors[colorIndex],
        colors[nextColorIndex],
        0.5,
      )!;

      final path = Path();
      path.moveTo(0, midY);

      for (double x = 0; x <= size.width; x += 1.5) {
        final att = _attenuation(x, size.width);
        final normalX = x / size.width;

        // Multiple harmonics for organic movement
        final y1 = sin(normalX * waveFreq * pi * 2 - time * 1.2 + wavePhase);
        final y2 =
            sin(normalX * waveFreq * pi * 3.3 - time * 0.8 + wavePhase * 1.5) *
            0.5;
        final y3 =
            sin(normalX * waveFreq * pi * 5.1 - time * 1.6 + wavePhase * 0.7) *
            0.25;

        final y =
            (y1 + y2 + y3) * effectiveAmp * waveAmpFactor * att * size.height;
        path.lineTo(x, midY + y);
      }

      // Glow layer
      final glowPaint = Paint()
        ..color = waveColor.withValues(alpha: opacity * 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6.0
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawPath(path, glowPaint);

      // Main stroke
      final paint = Paint()
        ..color = waveColor.withValues(alpha: opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round;
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SiriWavePainter old) => true;
}

// ─── Gemini Band Painter ─────────────────────────────────────────────────────

class _GeminiBandPainter extends CustomPainter {
  final double time;
  final List<double> bands;
  final List<Color> colors;
  final int waveCount;

  _GeminiBandPainter({
    required this.time,
    required this.bands,
    required this.colors,
    required this.waveCount,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final midY = size.height / 2;

    for (int w = 0; w < waveCount; w++) {
      final bandAmp = w < bands.length ? bands[w] : bands.last;
      final effectiveAmp = 0.02 + bandAmp * 0.35;
      final bandOffset = (w - waveCount / 2) * (size.height / (waveCount + 2));
      final phase = w * 1.2;
      final freq = 0.8 + w * 0.2;

      final colorT = w / (waveCount - 1).clamp(1, waveCount);
      final bandColor = _lerpColors(colors, colorT);

      final path = Path();
      final topPath = Path();
      final bottomPath = Path();

      for (double x = 0; x <= size.width; x += 2) {
        final normalX = x / size.width;
        final edgeFade = sin(normalX * pi); // 0 at edges, 1 at center

        final wave =
            sin(normalX * freq * pi * 2 - time * 1.3 + phase) +
            sin(normalX * freq * pi * 3.7 - time * 0.7 + phase * 1.3) * 0.4;

        final displacement = wave * effectiveAmp * edgeFade * size.height * 0.5;
        final y = midY + bandOffset + displacement;
        final bandHeight = (4 + effectiveAmp * 12) * edgeFade;

        if (x == 0) {
          topPath.moveTo(x, y - bandHeight / 2);
          bottomPath.moveTo(x, y + bandHeight / 2);
        } else {
          topPath.lineTo(x, y - bandHeight / 2);
          bottomPath.lineTo(x, y + bandHeight / 2);
        }
      }

      // Combine into a filled shape
      path.addPath(topPath, Offset.zero);
      // Reverse bottom path
      final bottomPoints = <Offset>[];
      for (double x = size.width; x >= 0; x -= 2) {
        final normalX = x / size.width;
        final edgeFade = sin(normalX * pi);
        final wave =
            sin(normalX * freq * pi * 2 - time * 1.3 + phase) +
            sin(normalX * freq * pi * 3.7 - time * 0.7 + phase * 1.3) * 0.4;
        final displacement = wave * effectiveAmp * edgeFade * size.height * 0.5;
        final y = midY + bandOffset + displacement;
        final bandHeight = (4 + effectiveAmp * 12) * edgeFade;
        bottomPoints.add(Offset(x, y + bandHeight / 2));
      }
      for (final p in bottomPoints) {
        path.lineTo(p.dx, p.dy);
      }
      path.close();

      // Glow
      canvas.drawPath(
        path,
        Paint()
          ..color = bandColor.withValues(alpha: 0.25 + bandAmp * 0.15)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
      );

      // Vertical gradient fill — color flows downward through the band
      final nextColor = _lerpColors(colors, ((w + 1) / waveCount).clamp(0, 1));
      final fillGradient = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          bandColor.withValues(alpha: 0.5 + bandAmp * 0.3),
          Color.lerp(bandColor, nextColor, 0.5)!.withValues(alpha: 0.15),
        ],
      );
      canvas.drawPath(
        path,
        Paint()
          ..shader = fillGradient.createShader(
            Rect.fromLTWH(
              0,
              midY + bandOffset - size.height * 0.3,
              size.width,
              size.height * 0.6,
            ),
          ),
      );

      // Bright top edge stroke
      canvas.drawPath(
        topPath,
        Paint()
          ..color = bandColor.withValues(alpha: 0.6 + bandAmp * 0.3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  Color _lerpColors(List<Color> colors, double t) {
    if (colors.length == 1) return colors[0];
    final scaled = t * (colors.length - 1);
    final i = scaled.floor().clamp(0, colors.length - 2);
    return Color.lerp(colors[i], colors[i + 1], scaled - i)!;
  }

  @override
  bool shouldRepaint(covariant _GeminiBandPainter old) => true;
}

// ─── Fluid Blob Painter ──────────────────────────────────────────────────────

class _FluidBlobPainter extends CustomPainter {
  final double time;
  final List<double> bands;
  final List<Color> colors;

  _FluidBlobPainter({
    required this.time,
    required this.bands,
    required this.colors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final baseRadius = min(size.width, size.height) / 2 * 0.4;
    final segments = 128;

    // Draw 4 layered blobs — each driven by its frequency band
    for (int layer = 3; layer >= 0; layer--) {
      final bandAmp = layer < bands.length ? bands[layer] : bands.last;
      final effectiveAmp = 0.05 + bandAmp * 0.5;
      final layerScale = 1.0 + layer * 0.12;
      final layerPhase = layer * 0.8;
      final layerSpeed = 1.0 - layer * 0.15;
      final color = colors[layer % colors.length];

      final path = Path();
      final points = <Offset>[];

      for (int i = 0; i <= segments; i++) {
        final angle = (2 * pi / segments) * i;
        final t = time * layerSpeed + layerPhase;

        // Organic deformation: multiple sine frequencies
        final deform =
            sin(angle * 3 + t) * 0.3 +
            sin(angle * 5 - t * 1.3) * 0.2 +
            sin(angle * 7 + t * 0.7) * 0.15 +
            sin(angle * 2 - t * 2.1) * effectiveAmp * 0.8;

        final r = baseRadius * layerScale * (1 + deform * effectiveAmp);
        points.add(
          Offset(center.dx + r * cos(angle), center.dy + r * sin(angle)),
        );
      }

      // Smooth bezier
      path.moveTo(points[0].dx, points[0].dy);
      for (int i = 0; i < points.length - 1; i++) {
        final midX = (points[i].dx + points[i + 1].dx) / 2;
        final midY = (points[i].dy + points[i + 1].dy) / 2;
        path.quadraticBezierTo(points[i].dx, points[i].dy, midX, midY);
      }
      path.close();

      // Glow
      canvas.drawPath(
        path,
        Paint()
          ..color = color.withValues(alpha: 0.15)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
      );

      // Fill with radial gradient
      canvas.drawPath(
        path,
        Paint()
          ..shader =
              RadialGradient(
                colors: [
                  color.withValues(alpha: 0.3 + bandAmp * 0.2),
                  color.withValues(alpha: 0.05),
                ],
              ).createShader(
                Rect.fromCircle(
                  center: center,
                  radius: baseRadius * layerScale * 1.5,
                ),
              ),
      );

      // Stroke
      canvas.drawPath(
        path,
        Paint()
          ..color = color.withValues(alpha: 0.5 + bandAmp * 0.3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _FluidBlobPainter old) => true;
}

// ─── iOS 9 Siri Painter (integrated from siri_wave) ─────────────────────────

class _SiriIos9Painter extends CustomPainter {
  _SiriIos9Painter({
    required this.amplitude,
    required this.speed,
    required this.colors,
  });

  final double amplitude;
  final double speed;
  final List<Color> colors;

  // Each wave layer has independent spawning curves
  static final _waves = List.generate(3, (_) => _Ios9WaveState());
  static final _rand = Random();

  static const _amplitudeFactor = 2.0;
  static const _attenuationFactor = 4;
  static const _deadPixel = 2;
  static const _despawnFactor = .02;
  static const _graphX = 25.0;
  static const _pixelDepth = .1;
  static const _speedFactor = 1.0;

  double _getRandomRange(List<double> e) =>
      e[0] + _rand.nextDouble() * (e[1] - e[0]);

  void _spawnSingle(int ci, _Ios9WaveState wave) {
    wave.phases[ci] = 0;
    wave.amplitudes[ci] = 0;
    wave.despawnTimeouts[ci] = _getRandomRange([500, 2000]);
    wave.offsets[ci] = _getRandomRange([-3, 3]);
    wave.speeds[ci] = _getRandomRange([.5, 1]);
    wave.finalAmplitudes[ci] = _getRandomRange([.3, 1]);
    wave.widths[ci] = _getRandomRange([1, 3]);
    wave.verses[ci] = _getRandomRange([-1, 1]);
  }

  void _spawn(_Ios9WaveState wave) {
    final count = 2 + _rand.nextInt(4); // 2–5 curves
    wave
      ..spawnAt = DateTime.now().millisecondsSinceEpoch
      ..noOfCurves = count
      ..amplitudes = List.filled(count, 0)
      ..despawnTimeouts = List.filled(count, 0)
      ..finalAmplitudes = List.filled(count, 0)
      ..offsets = List.filled(count, 0)
      ..phases = List.filled(count, 0)
      ..speeds = List.filled(count, 0)
      ..verses = List.filled(count, 0)
      ..widths = List.filled(count, 0);
    for (var ci = 0; ci < count; ci++) {
      _spawnSingle(ci, wave);
    }
  }

  double _globalAtt(double x) => pow(
    _attenuationFactor / (_attenuationFactor + x * x),
    _attenuationFactor,
  ).toDouble();

  double _yRelativePos(double i, _Ios9WaveState wave) {
    var y = 0.0;
    for (var ci = 0; ci < wave.noOfCurves; ci++) {
      var t = 4 * (-1 + (ci / (wave.noOfCurves - 1).clamp(1, 99)) * 2);
      t += wave.offsets[ci];
      final k = 1 / wave.widths[ci];
      final x = i * k - t;
      y +=
          (wave.amplitudes[ci] *
                  sin(wave.verses[ci] * x - wave.phases[ci]) *
                  _globalAtt(x))
              .abs();
    }
    return y / wave.noOfCurves.clamp(1, 99);
  }

  double _yPos(double i, _Ios9WaveState wave, double maxH) =>
      _amplitudeFactor *
      maxH *
      amplitude *
      _yRelativePos(i, wave) *
      _globalAtt((i / _graphX) * 2);

  double _xPos(double i, double w) => w * ((i + _graphX) / (_graphX * 2));

  @override
  void paint(Canvas canvas, Size size) {
    final maxH = size.height / 2;

    canvas.saveLayer(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = Colors.white,
    );

    for (var idx = 0; idx < _waves.length; idx++) {
      final wave = _waves[idx];
      if (wave.spawnAt == 0) _spawn(wave);

      for (var ci = 0; ci < wave.noOfCurves; ci++) {
        if (wave.spawnAt + wave.despawnTimeouts[ci] <=
            DateTime.now().millisecondsSinceEpoch) {
          wave.amplitudes[ci] -= _despawnFactor;
        } else {
          wave.amplitudes[ci] += _despawnFactor;
        }
        wave.amplitudes[ci] = wave.amplitudes[ci].clamp(
          0,
          wave.finalAmplitudes[ci],
        );
        wave.phases[ci] =
            (wave.phases[ci] + speed * wave.speeds[ci] * _speedFactor) %
            (2 * pi);
      }

      var maxY = double.negativeInfinity;
      final color = colors[idx % colors.length];

      for (final sign in [1, -1]) {
        final path = Path()..moveTo(0, maxH);
        for (var i = -_graphX; i <= _graphX; i += _pixelDepth) {
          final x = _xPos(i, size.width);
          final y = _yPos(i, wave, maxH);
          path.lineTo(x, maxH - sign * y);
          maxY = max(maxY, y);
        }
        path.close();
        canvas.drawPath(
          path,
          Paint()
            ..blendMode = BlendMode.plus
            ..color = color,
        );
      }

      if (maxY < _deadPixel && wave.prevMaxY >= maxY) {
        wave.spawnAt = 0;
      }
      wave.prevMaxY = maxY;
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _SiriIos9Painter old) => true;
}

class _Ios9WaveState {
  var amplitudes = <double>[];
  var despawnTimeouts = <double>[];
  var finalAmplitudes = <double>[];
  var noOfCurves = 0;
  var offsets = <double>[];
  var phases = <double>[];
  double prevMaxY = 0;
  var spawnAt = 0;
  var speeds = <double>[];
  var verses = <double>[];
  var widths = <double>[];
}

// ─── Demo Widget ─────────────────────────────────────────────────────────────

class _VoiceVisualizerDemo extends StatefulWidget {
  final VoiceVisualizerStyle style;
  final List<Color>? colors;
  final double height;
  final double? width;
  final bool speaking;

  const _VoiceVisualizerDemo({
    super.key,
    required this.style,
    this.colors,
    required this.height,
    this.width,
    required this.speaking,
  });

  @override
  State<_VoiceVisualizerDemo> createState() => _VoiceVisualizerDemoState();
}

class _VoiceVisualizerDemoState extends State<_VoiceVisualizerDemo>
    with SingleTickerProviderStateMixin {
  late AnimationController _simController;
  final _random = Random(42);
  // 4 independent band simulations
  final _bands = [0.0, 0.0, 0.0, 0.0];
  final _targets = [0.0, 0.0, 0.0, 0.0];

  int _frameCount = 0;
  int _nextBurstFrame = 10;
  int _burstLength = 0;
  bool _inBurst = false;

  @override
  void initState() {
    super.initState();
    _simController =
        AnimationController(
            vsync: this,
            duration: const Duration(milliseconds: 33),
          )
          ..addListener(_tick)
          ..repeat();
  }

  void _tick() {
    _frameCount++;
    setState(() {
      if (widget.speaking) {
        if (_inBurst) {
          // Each band gets its own random target — voice has different
          // energy distribution across frequencies
          _targets[0] = 0.4 + _random.nextDouble() * 0.5;  // low: strong
          _targets[1] = 0.3 + _random.nextDouble() * 0.6;  // low-mid: speech body
          _targets[2] = 0.15 + _random.nextDouble() * 0.5;  // mid-high: less
          _targets[3] = 0.05 + _random.nextDouble() * 0.3;  // high: sibilance, sparse
          _burstLength--;
          if (_burstLength <= 0) {
            _inBurst = false;
            _nextBurstFrame = _frameCount + 5 + _random.nextInt(12);
          }
        } else {
          for (int i = 0; i < 4; i++) {
            _targets[i] = 0.01 + _random.nextDouble() * 0.04;
          }
          if (_frameCount >= _nextBurstFrame) {
            _inBurst = true;
            _burstLength = 8 + _random.nextInt(20);
          }
        }
      } else {
        for (int i = 0; i < 4; i++) {
          _targets[i] = 0.01;
        }
      }

      for (int i = 0; i < 4; i++) {
        _bands[i] += (_targets[i] - _bands[i]) * 0.18;
      }
    });
  }

  @override
  void dispose() {
    _simController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return VoiceVisualizer(
      bands: List.from(_bands),
      style: widget.style,
      colors: widget.colors,
      height: widget.height,
      width: widget.width,
    );
  }
}
