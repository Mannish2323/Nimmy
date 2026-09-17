/// 🟣 NIMMY Performance — Native Audio DSP Module (Rust)
/// =======================================================
/// Zero-allocation, SIMD-friendly digital signal processing for 16-bit PCM audio.

/// Calculate Root-Mean-Square (RMS) energy of a 16-bit PCM sample buffer.
pub fn calculate_rms(samples: &[i16]) -> f64 {
    if samples.is_empty() {
        return 0.0;
    }

    let mut sum_squares: f64 = 0.0;
    for &sample in samples {
        let val = sample as f64;
        sum_squares += val * val;
    }

    (sum_squares / samples.len() as f64).sqrt()
}

/// Find peak absolute amplitude in sample buffer.
pub fn find_peak(samples: &[i16]) -> i16 {
    let mut peak: i16 = 0;
    for &sample in samples {
        let abs_val = sample.abs();
        if abs_val > peak {
            peak = abs_val;
        }
    }
    peak
}

/// Apply a hard noise gate in-place to suppress background room noise.
/// Any sample whose absolute amplitude is below `threshold` is zeroed.
/// Returns the count of zeroed samples.
pub fn apply_noise_gate(samples: &mut [i16], threshold: i16) -> usize {
    let mut zeroed_count = 0;
    for sample in samples.iter_mut() {
        if sample.abs() < threshold {
            *sample = 0;
            zeroed_count += 1;
        }
    }
    zeroed_count
}

/// Determine whether a buffer represents ambient silence based on RMS threshold.
pub fn is_silence(samples: &[i16], silence_rms_threshold: f64) -> bool {
    calculate_rms(samples) < silence_rms_threshold
}

/// Apply first-order pre-emphasis filter: y[n] = x[n] - alpha * x[n-1]
/// Commonly used in speech processing to boost high-frequency speech clarity.
pub fn apply_pre_emphasis(samples: &[i16], alpha: f32) -> Vec<i16> {
    if samples.is_empty() {
        return Vec::new();
    }

    let mut output = Vec::with_capacity(samples.len());
    output.push(samples[0]);

    for i in 1..samples.len() {
        let filtered = samples[i] as f32 - alpha * (samples[i - 1] as f32);
        let clamped = filtered.clamp(i16::MIN as f32, i16::MAX as f32);
        output.push(clamped as i16);
    }

    output
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_rms_calculation() {
        let samples = vec![1000, -1000, 1000, -1000];
        let rms = calculate_rms(&samples);
        assert!((rms - 1000.0).abs() < 1e-6);

        assert_eq!(calculate_rms(&[]), 0.0);
    }

    #[test]
    fn test_peak_detection() {
        let samples = vec![10, -500, 250, -32000, 100];
        assert_eq!(find_peak(&samples), 32000);
    }

    #[test]
    fn test_noise_gate() {
        let mut samples = vec![50, 1500, -80, -2000, 20];
        let zeroed = apply_noise_gate(&mut samples, 100);
        assert_eq!(zeroed, 3);
        assert_eq!(samples, vec![0, 1500, 0, -2000, 0]);
    }

    #[test]
    fn test_silence_detection() {
        let quiet_samples = vec![10, -10, 15, -15];
        assert!(is_silence(&quiet_samples, 50.0));

        let loud_samples = vec![5000, -5000];
        assert!(!is_silence(&loud_samples, 100.0));
    }
}
