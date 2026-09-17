/// 🟣 NIMMY Performance — Native Vector Math & Similarity Module (Rust)
/// ====================================================================
/// Cache-efficient vector operations for embedded semantic memory.

/// Compute standard dot product between two f32 vectors.
pub fn dot_product(a: &[f32], b: &[f32]) -> f32 {
    let len = a.len().min(b.len());
    let mut sum: f32 = 0.0;
    for i in 0..len {
        sum += a[i] * b[i];
    }
    sum
}

/// Compute cosine similarity between two vectors. Range: [-1.0, 1.0].
pub fn cosine_similarity(a: &[f32], b: &[f32]) -> f32 {
    if a.is_empty() || b.is_empty() || a.len() != b.len() {
        return 0.0;
    }

    let mut dot: f32 = 0.0;
    let mut norm_a: f32 = 0.0;
    let mut norm_b: f32 = 0.0;

    for i in 0..a.len() {
        dot += a[i] * b[i];
        norm_a += a[i] * a[i];
        norm_b += b[i] * b[i];
    }

    let denominator = (norm_a.sqrt()) * (norm_b.sqrt());
    if denominator < 1e-9 {
        return 0.0;
    }

    dot / denominator
}

/// Compute L2 Euclidean distance between two vectors.
pub fn euclidean_distance(a: &[f32], b: &[f32]) -> f32 {
    if a.is_empty() || b.is_empty() || a.len() != b.len() {
        return f32::MAX;
    }

    let mut sum_diff_sq: f32 = 0.0;
    for i in 0..a.len() {
        let diff = a[i] - b[i];
        sum_diff_sq += diff * diff;
    }

    sum_diff_sq.sqrt()
}

/// Item with rank score for top-K extraction.
#[derive(Debug, Clone, PartialEq)]
pub struct ScoredIndex {
    pub index: usize,
    pub score: f32,
}

/// Search top-K closest vectors from a pool given a query vector using cosine similarity.
pub fn find_top_k(query: &[f32], pool: &[Vec<f32>], k: usize) -> Vec<ScoredIndex> {
    if query.is_empty() || pool.is_empty() || k == 0 {
        return Vec::new();
    }

    let mut scored: Vec<ScoredIndex> = pool
        .iter()
        .enumerate()
        .map(|(index, candidate)| {
            let score = cosine_similarity(query, candidate);
            ScoredIndex { index, score }
        })
        .collect();

    // Sort descending by score
    scored.sort_by(|a, b| b.score.partial_cmp(&a.score).unwrap_or(std::cmp::Ordering::Equal));

    scored.truncate(k);
    scored
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_cosine_similarity() {
        let v1 = vec![1.0, 0.0, 0.0];
        let v2 = vec![1.0, 0.0, 0.0];
        assert!((cosine_similarity(&v1, &v2) - 1.0).abs() < 1e-6);

        let v3 = vec![0.0, 1.0, 0.0];
        assert!((cosine_similarity(&v1, &v3) - 0.0).abs() < 1e-6);

        let v4 = vec![-1.0, 0.0, 0.0];
        assert!((cosine_similarity(&v1, &v4) - (-1.0)).abs() < 1e-6);
    }

    #[test]
    fn test_euclidean_distance() {
        let a = vec![0.0, 0.0];
        let b = vec![3.0, 4.0];
        assert!((euclidean_distance(&a, &b) - 5.0).abs() < 1e-6);
    }

    #[test]
    fn test_top_k_search() {
        let query = vec![1.0, 0.0, 0.0];
        let pool = vec![
            vec![0.0, 1.0, 0.0],  // Orthogonal (score ~0.0)
            vec![0.9, 0.1, 0.0],  // Very close (score ~0.99)
            vec![-1.0, 0.0, 0.0], // Opposite (score ~-1.0)
            vec![0.7, 0.7, 0.0],  // Angle 45 deg (score ~0.707)
        ];

        let top = find_top_k(&query, &pool, 2);
        assert_eq!(top.len(), 2);
        assert_eq!(top[0].index, 1); // [0.9, 0.1, 0.0]
        assert_eq!(top[1].index, 3); // [0.7, 0.7, 0.0]
    }
}
