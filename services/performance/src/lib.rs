/// 🟣 NIMMY Performance — Native Rust Core
/// ========================================
/// High-performance audio DSP, vector mathematics, and cross-language FFI.

pub mod dsp;
pub mod vector;
pub mod ffi;

// Re-export key functions
pub use dsp::{calculate_rms, find_peak, apply_noise_gate, is_silence, apply_pre_emphasis};
pub use vector::{cosine_similarity, dot_product, euclidean_distance, find_top_k};
pub use ffi::*;

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_core_pipeline() {
        // Generate simulated voice buffer with noise
        let mut audio_buffer = vec![15i16, 20, -10, 4500, -3200, 18, -12];

        // 1. Check if quiet
        assert!(!is_silence(&audio_buffer, 100.0));

        // 2. Apply noise gate at 50 amplitude
        let zeroed = apply_noise_gate(&mut audio_buffer, 50);
        assert_eq!(zeroed, 5); // All low ambient noise samples zeroed

        // 3. Calculate filtered RMS
        let rms = calculate_rms(&audio_buffer);
        assert!(rms > 1000.0);

        // 4. Vector similarity test
        let query = vec![0.5, 0.5, 0.0];
        let document = vec![0.5, 0.5, 0.0];
        assert!((cosine_similarity(&query, &document) - 1.0).abs() < 1e-6);
    }
}
