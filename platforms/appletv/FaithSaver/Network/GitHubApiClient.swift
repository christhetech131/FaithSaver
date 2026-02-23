import Foundation
import os.log

/// Fetches image listings from the FaithSaver GitHub repository using the Contents API.
/// Mirrors the Roku ImageFeedTask and Fire TV GitHubApiClient behavior.
final class GitHubApiClient {

    static let shared = GitHubApiClient()

    private let logger = Logger(subsystem: "com.faithsaver.appletv", category: "GitHubAPI")

    private let repoOwner = "christhetech131"
    private let repoName  = "FaithSaver"
    private let branch    = "main"

    private let validExtensions: Set<String> = ["jpg", "jpeg", "png"]

    private let session: URLSession

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 15
        config.timeoutIntervalForResource = 30
        session = URLSession(configuration: config)
    }

    // MARK: - Public

    /// Fetches image URLs for a given category from the GitHub repository.
    /// Automatically resolves "seasonal" to the current season folder.
    /// - Parameter category: The category to fetch (e.g., "animals", "seasonal").
    /// - Returns: An array of `ImageItem` objects with raw image URLs.
    func fetchImages(for category: Category) async throws -> [ImageItem] {
        let folderName = category.resolvedFolderName
        let apiURL = buildAPIURL(for: folderName)

        logger.info("GET \(apiURL.absoluteString)")

        let (data, response) = try await session.data(from: apiURL)

        guard let httpResponse = response as? HTTPURLResponse else {
            logger.error("Non-HTTP response")
            return []
        }

        guard httpResponse.statusCode == 200 else {
            logger.error("HTTP \(httpResponse.statusCode) for \(folderName)")
            return []
        }

        let entries = try JSONDecoder().decode([GitHubContentEntry].self, from: data)

        let items = entries.compactMap { entry -> ImageItem? in
            guard entry.type == "file" else { return nil }
            guard isImageFile(entry.name) else { return nil }

            // Build raw.githubusercontent.com URL (same as Roku implementation)
            let rawURL = "https://raw.githubusercontent.com/\(repoOwner)/\(repoName)/\(branch)/\(folderName)/\(entry.name)"

            return ImageItem(name: entry.name, url: rawURL, category: folderName)
        }

        logger.info("Discovered \(items.count) image(s) in '\(folderName)'")
        return items
    }

    // MARK: - Private

    private func buildAPIURL(for folder: String) -> URL {
        URL(string: "https://api.github.com/repos/\(repoOwner)/\(repoName)/contents/\(folder)")!
    }

    private func isImageFile(_ name: String) -> Bool {
        let ext = (name as NSString).pathExtension.lowercased()
        return validExtensions.contains(ext)
    }
}
