import UIKit

/// Thread-safe, LRU-style in-memory image cache using NSCache
final class ImageCache {

    static let shared = ImageCache()

    private let cache = NSCache<NSString, UIImage>()

    private init() {
        // Limit to ~80 MB (estimated) or 50 images
        cache.totalCostLimit = 80 * 1024 * 1024
        cache.countLimit = 50
    }

    /// Store an image in the cache
    func set(_ image: UIImage, forKey key: String) {
        let cost = image.cgImage.map { $0.bytesPerRow * $0.height } ?? 0
        cache.setObject(image, forKey: key as NSString, cost: cost)
    }

    /// Retrieve an image from the cache, if available
    func get(forKey key: String) -> UIImage? {
        cache.object(forKey: key as NSString)
    }

    /// Remove all cached images
    func clear() {
        cache.removeAllObjects()
    }
}
