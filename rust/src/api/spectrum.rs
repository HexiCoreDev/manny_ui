//! Audio spectrum analyzer modeled on the Web Audio API's AnalyserNode.
//!
//! Two-step approach matching WaveForge's instant response:
//! 1. `AudioBuffer::decode()` — decodes MP3/WAV/etc to PCM (~0.5s). No FFT.
//! 2. `SpectrumAnalyzer::analyze_at()` — runs ONE FFT at a given position (<1ms).
//!
//! Live streaming (mic/AI voice) uses `push_samples()` + `get_bands()` directly.

use rustfft::{num_complex::Complex, FftPlanner};
use std::f32::consts::PI;
use std::io::Cursor;
use symphonia::core::{
    audio::SampleBuffer,
    codecs::DecoderOptions,
    formats::FormatOptions,
    io::MediaSourceStream,
    meta::MetadataOptions,
    probe::Hint,
};

#[flutter_rust_bridge::frb(init)]
pub fn init_app() {
    flutter_rust_bridge::setup_default_user_utils();
}

const BAND_RANGES: [(f64, f64); 4] = [
    (60.0, 250.0),
    (250.0, 800.0),
    (800.0, 3000.0),
    (3000.0, 8000.0),
];

// ─── AudioBuffer: decoded PCM stored in Rust memory ──────────────────────────

/// Decoded audio stored in Rust memory. Decoding is fast (~0.5s for a 7min MP3).
/// No FFT is run during decode — that happens on-demand per frame.
#[flutter_rust_bridge::frb(opaque)]
pub struct AudioBuffer {
    samples: Vec<f32>,
    sample_rate: u32,
    duration_ms: f32,
}

impl AudioBuffer {
    /// Decode audio file bytes to PCM. Fast — no FFT.
    /// Supports MP3, WAV, OGG, FLAC, AAC.
    pub fn decode(file_bytes: Vec<u8>, file_extension: String) -> AudioBuffer {
        let cursor = Cursor::new(file_bytes);
        let mss = MediaSourceStream::new(Box::new(cursor), Default::default());
        let mut hint = Hint::new();
        hint.with_extension(&file_extension);

        let probed = match symphonia::default::get_probe().format(
            &hint, mss, &FormatOptions::default(), &MetadataOptions::default(),
        ) {
            Ok(p) => p,
            Err(_) => return AudioBuffer { samples: vec![], sample_rate: 44100, duration_ms: 0.0 },
        };

        let mut format = probed.format;
        let track = match format.default_track() {
            Some(t) => t,
            None => return AudioBuffer { samples: vec![], sample_rate: 44100, duration_ms: 0.0 },
        };

        let sample_rate = track.codec_params.sample_rate.unwrap_or(44100);
        let channels = track.codec_params.channels.map(|c| c.count()).unwrap_or(1);
        let track_id = track.id;

        let mut decoder = match symphonia::default::get_codecs()
            .make(&track.codec_params, &DecoderOptions::default())
        {
            Ok(d) => d,
            Err(_) => return AudioBuffer { samples: vec![], sample_rate, duration_ms: 0.0 },
        };

        let mut all_samples: Vec<f32> = Vec::new();
        loop {
            let packet = match format.next_packet() {
                Ok(p) => p,
                Err(_) => break,
            };
            if packet.track_id() != track_id { continue; }
            let decoded = match decoder.decode(&packet) {
                Ok(d) => d,
                Err(_) => continue,
            };

            let spec = *decoded.spec();
            let mut sample_buf = SampleBuffer::<f32>::new(decoded.capacity() as u64, spec);
            sample_buf.copy_interleaved_ref(decoded);

            if channels > 1 {
                for chunk in sample_buf.samples().chunks(channels) {
                    all_samples.push(chunk.iter().sum::<f32>() / channels as f32);
                }
            } else {
                all_samples.extend_from_slice(sample_buf.samples());
            }
        }

        let duration_ms = (all_samples.len() as f64 / sample_rate as f64 * 1000.0) as f32;
        AudioBuffer { samples: all_samples, sample_rate, duration_ms }
    }

    /// Get the duration in milliseconds.
    #[flutter_rust_bridge::frb(sync)]
    pub fn duration_ms(&self) -> f32 {
        self.duration_ms
    }

    /// Get the sample rate.
    #[flutter_rust_bridge::frb(sync)]
    pub fn sample_rate(&self) -> u32 {
        self.sample_rate
    }

    /// Whether the buffer has audio data.
    #[flutter_rust_bridge::frb(sync)]
    pub fn has_data(&self) -> bool {
        !self.samples.is_empty()
    }
}

// ─── SpectrumAnalyzer ────────────────────────────────────────────────────────

/// Real-time spectrum analyzer matching Web Audio AnalyserNode behavior.
///
/// For file playback: use `analyze_at(buffer, position_ms)` — instant, one FFT.
/// For live streams: use `push_samples()` + `get_bands()` — sync, <1ms.
#[flutter_rust_bridge::frb(opaque)]
pub struct SpectrumAnalyzer {
    fft_size: usize,
    hann_window: Vec<f32>,
    sample_buffer: Vec<f32>,
    freq_resolution: f64,
    smoothed_magnitudes: Vec<f32>,
    smoothing: f32,
    min_decibels: f32,
    max_decibels: f32,
    sensitivity: f32,
}

impl SpectrumAnalyzer {
    /// Create a new analyzer.
    /// - `sample_rate`: 44100 for music, 16000/24000 for AI voice
    /// - `fft_size`: 2048 recommended
    /// - `smoothing`: 0.85 matches WaveForge
    pub fn new(sample_rate: u32, fft_size: u32, smoothing: f32) -> Self {
        let fft_size = (fft_size as usize).next_power_of_two();
        let bin_count = fft_size / 2;
        let hann: Vec<f32> = (0..fft_size)
            .map(|i| 0.5 * (1.0 - (2.0 * PI * i as f32 / (fft_size - 1) as f32).cos()))
            .collect();

        Self {
            fft_size,
            hann_window: hann,
            sample_buffer: Vec::with_capacity(fft_size * 2),
            freq_resolution: sample_rate as f64 / fft_size as f64,
            smoothed_magnitudes: vec![0.0; bin_count],
            smoothing: smoothing.clamp(0.0, 1.0),
            min_decibels: -90.0,
            max_decibels: -10.0,
            sensitivity: 1.5,
        }
    }

    /// Analyze at a specific position in an AudioBuffer. ONE FFT — instant.
    /// Call this every frame during playback.
    #[flutter_rust_bridge::frb(sync)]
    pub fn analyze_at(&mut self, buffer: &AudioBuffer, position_ms: u32) -> Vec<f32> {
        if buffer.samples.is_empty() { return vec![0.0; 4]; }

        let start = ((position_ms as u64 * buffer.sample_rate as u64) / 1000) as usize;
        let end = (start + self.fft_size).min(buffer.samples.len());
        if end - start < self.fft_size / 2 { return vec![0.0; 4]; }

        // Feed the window at this position
        let chunk = &buffer.samples[start..end];
        self.run_fft(chunk);
        self.compute_bands()
    }

    /// Push raw PCM f32 mono samples for live streaming (mic/AI).
    #[flutter_rust_bridge::frb(sync)]
    pub fn push_samples(&mut self, samples: Vec<f32>) {
        self.sample_buffer.extend_from_slice(&samples);
        while self.sample_buffer.len() >= self.fft_size {
            let window: Vec<f32> = self.sample_buffer[..self.fft_size].to_vec();
            self.run_fft(&window);
            let hop = self.fft_size / 2;
            self.sample_buffer.drain(..hop);
        }
    }

    /// Push interleaved multi-channel samples.
    #[flutter_rust_bridge::frb(sync)]
    pub fn push_interleaved(&mut self, samples: Vec<f32>, channels: u32) {
        if channels <= 1 {
            self.push_samples(samples);
            return;
        }
        let ch = channels as usize;
        let mono: Vec<f32> = samples.chunks(ch)
            .map(|c| c.iter().sum::<f32>() / ch as f32)
            .collect();
        self.push_samples(mono);
    }

    /// Get frequency data as 0–255 bytes (like getByteFrequencyData).
    #[flutter_rust_bridge::frb(sync)]
    pub fn get_frequency_data(&self) -> Vec<u8> {
        let db_range = self.max_decibels - self.min_decibels;
        self.smoothed_magnitudes.iter()
            .map(|&mag| {
                let db = if mag > 1e-10 { 20.0 * mag.log10() } else { self.min_decibels };
                ((db - self.min_decibels) / db_range).clamp(0.0, 1.0) as u8 * 255
            })
            .collect()
    }

    /// Get 4 frequency bands (0.0–1.0).
    #[flutter_rust_bridge::frb(sync)]
    pub fn get_bands(&self) -> Vec<f32> {
        self.compute_bands()
    }

    /// Get overall amplitude (0.0–1.0).
    #[flutter_rust_bridge::frb(sync)]
    pub fn get_amplitude(&self) -> f32 {
        let bands = self.compute_bands();
        let sum: f32 = bands.iter().sum();
        (sum / 4.0).clamp(0.0, 1.0)
    }

    /// Reset state.
    #[flutter_rust_bridge::frb(sync)]
    pub fn reset(&mut self) {
        self.sample_buffer.clear();
        self.smoothed_magnitudes.fill(0.0);
    }

    // ── Internal ──

    fn run_fft(&mut self, samples: &[f32]) {
        let mut planner = FftPlanner::<f32>::new();
        let fft = planner.plan_fft_forward(self.fft_size);

        let len = samples.len().min(self.fft_size);
        let mut buffer: Vec<Complex<f32>> = (0..self.fft_size)
            .map(|i| {
                let s = if i < len { samples[i] } else { 0.0 };
                Complex::new(s * self.hann_window[i], 0.0)
            })
            .collect();

        fft.process(&mut buffer);

        // Per-bin smoothing (exactly like AnalyserNode)
        let bin_count = self.fft_size / 2;
        for i in 0..bin_count {
            let mag = buffer[i].norm() / (self.fft_size as f32);
            self.smoothed_magnitudes[i] =
                self.smoothing * self.smoothed_magnitudes[i] + (1.0 - self.smoothing) * mag;
        }
    }

    fn compute_bands(&self) -> Vec<f32> {
        let db_range = self.max_decibels - self.min_decibels;
        let mut bands = [0.0f32; 4];
        let mut counts = [0u32; 4];

        for (bin, &mag) in self.smoothed_magnitudes.iter().enumerate() {
            let freq = (bin + 1) as f64 * self.freq_resolution;
            // Convert to byte value (0-255) like getByteFrequencyData
            let db = if mag > 1e-10 { 20.0 * mag.log10() } else { self.min_decibels };
            let byte_val = ((db - self.min_decibels) / db_range).clamp(0.0, 1.0) * 255.0;

            for (idx, &(lo, hi)) in BAND_RANGES.iter().enumerate() {
                if freq >= lo && freq < hi {
                    bands[idx] += byte_val;
                    counts[idx] += 1;
                    break;
                }
            }
        }

        for b in 0..4 {
            bands[b] = if counts[b] > 0 {
                (bands[b] / counts[b] as f32 / 255.0 * self.sensitivity).clamp(0.0, 1.0)
            } else {
                0.0
            };
        }

        bands.to_vec()
    }
}
