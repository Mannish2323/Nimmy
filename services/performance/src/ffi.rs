/// 🟣 NIMMY Performance — C-Compatible FFI Interface (Rust)
/// ========================================================
/// Provides low-overhead C ABI entrypoints for Flutter (Dart FFI) and Python (ctypes).

use std::ffi::CStr;
use std::os::raw::c_char;
use crate::dsp;
use crate::vector;

static VERSION_STRING: &[u8] = b"1.0.0-rust-native\0";

/// Health check verification.
#[no_mangle]
pub extern "C" fn nimmy_health() -> i32 {
    1 // Healthy
}

/// Version string pointer.
#[no_mangle]
pub extern "C" fn nimmy_version() -> *const c_char {
    VERSION_STRING.as_ptr() as *const c_char
}

/// Calculate Root-Mean-Square (RMS) energy via FFI.
/// Returns 0.0 if `samples` pointer is null or `len` is 0.
#[no_mangle]
pub extern "C" fn nimmy_audio_calculate_rms(samples: *const i16, len: usize) -> f64 {
    if samples.is_null() || len == 0 {
        return 0.0;
    }
    let slice = unsafe { std::slice::from_raw_parts(samples, len) };
    dsp::calculate_rms(slice)
}

/// Find peak absolute amplitude via FFI.
#[no_mangle]
pub extern "C" fn nimmy_audio_find_peak(samples: *const i16, len: usize) -> i16 {
    if samples.is_null() || len == 0 {
        return 0;
    }
    let slice = unsafe { std::slice::from_raw_parts(samples, len) };
    dsp::find_peak(slice)
}

/// Apply in-place noise gate via FFI.
/// Returns number of zeroed samples.
#[no_mangle]
pub extern "C" fn nimmy_audio_apply_noise_gate(samples: *mut i16, len: usize, threshold: i16) -> usize {
    if samples.is_null() || len == 0 {
        return 0;
    }
    let slice = unsafe { std::slice::from_raw_parts_mut(samples, len) };
    dsp::apply_noise_gate(slice, threshold)
}

/// Compute cosine similarity between two float vectors via FFI.
#[no_mangle]
pub extern "C" fn nimmy_vector_cosine_similarity(a: *const f32, b: *const f32, len: usize) -> f32 {
    if a.is_null() || b.is_null() || len == 0 {
        return 0.0;
    }
    let slice_a = unsafe { std::slice::from_raw_parts(a, len) };
    let slice_b = unsafe { std::slice::from_raw_parts(b, len) };
    vector::cosine_similarity(slice_a, slice_b)
}

/// Compute dot product between two float vectors via FFI.
#[no_mangle]
pub extern "C" fn nimmy_vector_dot_product(a: *const f32, b: *const f32, len: usize) -> f32 {
    if a.is_null() || b.is_null() || len == 0 {
        return 0.0;
    }
    let slice_a = unsafe { std::slice::from_raw_parts(a, len) };
    let slice_b = unsafe { std::slice::from_raw_parts(b, len) };
    vector::dot_product(slice_a, slice_b)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_ffi_health_and_version() {
        assert_eq!(nimmy_health(), 1);

        let v_ptr = nimmy_version();
        let c_str = unsafe { CStr::from_ptr(v_ptr) };
        assert_eq!(c_str.to_str().unwrap(), "1.0.0-rust-native");
    }

    #[test]
    fn test_ffi_audio_rms() {
        let samples = [1000i16, -1000i16];
        let rms = nimmy_audio_calculate_rms(samples.as_ptr(), samples.len());
        assert!((rms - 1000.0).abs() < 1e-6);

        // Null pointer safety
        assert_eq!(nimmy_audio_calculate_rms(std::ptr::null(), 10), 0.0);
    }

    #[test]
    fn test_ffi_vector_similarity() {
        let v1 = [1.0f32, 0.0f32];
        let v2 = [1.0f32, 0.0f32];
        let sim = nimmy_vector_cosine_similarity(v1.as_ptr(), v2.as_ptr(), 2);
        assert!((sim - 1.0).abs() < 1e-6);

        // Null pointer safety
        assert_eq!(nimmy_vector_cosine_similarity(std::ptr::null(), v2.as_ptr(), 2), 0.0);
    }
}
