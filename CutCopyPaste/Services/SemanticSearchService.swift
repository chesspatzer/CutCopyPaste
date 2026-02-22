import Foundation
import NaturalLanguage

final class SemanticSearchService {
    static let shared = SemanticSearchService()

    private let sentenceEmbedding: NLEmbedding?
    private let wordEmbedding: NLEmbedding?

    /// Cached query vector to avoid recomputing per-item during a search pass
    private var cachedQueryVector: (query: String, vector: [Double])?

    var isAvailable: Bool { sentenceEmbedding != nil }

    private init() {
        sentenceEmbedding = NLEmbedding.sentenceEmbedding(for: .english)
        wordEmbedding = NLEmbedding.wordEmbedding(for: .english)
    }

    // MARK: - Embedding Computation (capture time)

    /// Compute sentence embedding vector for a text string.
    /// Truncates to first 500 chars for performance and signal quality.
    func computeEmbedding(for text: String) -> [Double]? {
        guard !text.isEmpty else { return nil }
        let truncated = String(text.prefix(500))
        return sentenceEmbedding?.vector(for: truncated)
    }

    // MARK: - Semantic Scoring (search time)

    /// Cosine similarity between a query string and a pre-computed item vector.
    /// Returns 0.0 (unrelated) to 1.0 (identical).
    func semanticScore(query: String, itemVector: [Double]) -> Double {
        let queryVector: [Double]
        if let cached = cachedQueryVector, cached.query == query {
            queryVector = cached.vector
        } else if let vec = sentenceEmbedding?.vector(for: query) {
            queryVector = vec
            cachedQueryVector = (query, vec)
        } else {
            return 0.0
        }
        return cosineSimilarity(queryVector, itemVector)
    }

    /// Word-level semantic similarity for short single-word queries.
    /// Returns 0.0 to 1.0 (1.0 = most similar).
    func wordSemanticScore(queryWord: String, targetWord: String) -> Double {
        guard let embedding = wordEmbedding else { return 0.0 }
        // NLEmbedding.distance returns cosine distance: 0 = identical, 2 = opposite
        let distance = embedding.distance(between: queryWord.lowercased(),
                                           and: targetWord.lowercased())
        return max(0, 1.0 - (distance / 2.0))
    }

    /// Clear cached query vector (call when search text is cleared)
    func clearCache() {
        cachedQueryVector = nil
    }

    // MARK: - Vector Serialization

    static func vectorToData(_ vector: [Double]) -> Data {
        vector.withUnsafeBufferPointer { buffer in
            Data(buffer: buffer)
        }
    }

    static func dataToVector(_ data: Data) -> [Double] {
        data.withUnsafeBytes { raw in
            let buffer = raw.bindMemory(to: Double.self)
            return Array(buffer)
        }
    }

    // MARK: - Math

    private func cosineSimilarity(_ a: [Double], _ b: [Double]) -> Double {
        guard a.count == b.count, !a.isEmpty else { return 0.0 }
        var dot = 0.0
        var normA = 0.0
        var normB = 0.0
        for i in 0..<a.count {
            dot += a[i] * b[i]
            normA += a[i] * a[i]
            normB += b[i] * b[i]
        }
        let denominator = sqrt(normA) * sqrt(normB)
        guard denominator > 0 else { return 0.0 }
        // Raw cosine similarity — NLEmbedding vectors are non-negative so this is [0, 1]
        return max(0, dot / denominator)
    }
}
