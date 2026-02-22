import Foundation

/// A simple LRU cache with fixed capacity. Evicts least-recently-used entries when full.
/// Thread-safe via a lock. Designed for caching expensive computations like syntax highlighting.
final class OrderedCache<Key: Hashable, Value> {
    private var storage: [Key: Value] = [:]
    private var order: [Key] = []
    private let capacity: Int
    private let lock = NSLock()

    init(capacity: Int) {
        self.capacity = capacity
    }

    subscript(key: Key) -> Value? {
        get {
            lock.lock()
            defer { lock.unlock() }
            guard let value = storage[key] else { return nil }
            // Move to end (most recently used)
            if let idx = order.firstIndex(of: key) {
                order.remove(at: idx)
                order.append(key)
            }
            return value
        }
        set {
            lock.lock()
            defer { lock.unlock() }
            if let value = newValue {
                if storage[key] != nil {
                    // Update existing — move to end
                    if let idx = order.firstIndex(of: key) {
                        order.remove(at: idx)
                    }
                } else if order.count >= capacity {
                    // Evict oldest
                    let oldest = order.removeFirst()
                    storage.removeValue(forKey: oldest)
                }
                storage[key] = value
                order.append(key)
            } else {
                storage.removeValue(forKey: key)
                order.removeAll { $0 == key }
            }
        }
    }
}
