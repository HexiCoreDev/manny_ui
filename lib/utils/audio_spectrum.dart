import 'dart:typed_data';
import 'package:manny_ui/src/rust/api/spectrum.dart' as rust;

/// Lightweight wrapper around the Rust AudioBuffer + SpectrumAnalyzer.
///
/// Two-step instant playback:
/// 1. `await AudioSpectrum.decode(bytes, 'mp3')` — decodes PCM (~0.5s), no FFT
/// 2. `spectrum.getBandsAt(positionMs)` — ONE FFT per call (<1ms), sync
///
/// For live mic/AI streams, use `SpectrumAnalyzer` directly.
class AudioSpectrum {
  final rust.AudioBuffer _buffer;
  final rust.SpectrumAnalyzer _analyzer;

  AudioSpectrum._(this._buffer, this._analyzer);

  /// Decode audio file to PCM (fast, no FFT).
  static Future<AudioSpectrum> decode(Uint8List fileBytes, String ext) async {
    final buffer = await rust.AudioBuffer.decode(
      fileBytes: fileBytes,
      fileExtension: ext,
    );
    final analyzer = await rust.SpectrumAnalyzer.newInstance(
      sampleRate: buffer.sampleRate(),
      fftSize: 2048,
      smoothing: 0.85,
    );
    return AudioSpectrum._(buffer, analyzer);
  }

  /// Get 4 frequency bands at a playback position. ONE FFT — instant.
  List<double> getBandsAt(int positionMs) {
    final bands = _analyzer.analyzeAt(
      buffer: _buffer,
      positionMs: positionMs,
    );
    return [
      bands[0].toDouble(),
      bands[1].toDouble(),
      bands[2].toDouble(),
      bands[3].toDouble(),
    ];
  }

  double get durationMs => _buffer.durationMs();
  bool get hasData => _buffer.hasData();
}
