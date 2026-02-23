import Foundation

// MARK: - Image Item

/// Represents an image item from the GitHub repository
struct ImageItem: Identifiable, Equatable {
    let id = UUID()
    let name: String
    let url: String
    let category: String

    static func == (lhs: ImageItem, rhs: ImageItem) -> Bool {
        lhs.url == rhs.url
    }
}

// MARK: - Category

/// Represents a category of images available in FaithSaver
enum Category: String, CaseIterable, Identifiable {
    case animals
    case fall
    case geology
    case scenery
    case seasonal
    case space
    case spring
    case summer
    case textures
    case winter

    var id: String { rawValue }

    /// Display name shown in the UI
    var displayName: String {
        switch self {
        case .animals:  return "Animals"
        case .fall:     return "Fall"
        case .geology:  return "Geology"
        case .scenery:  return "Scenery"
        case .seasonal: return "Seasonal (auto - \(SeasonHelper.currentSeasonName()))"
        case .space:    return "Space"
        case .spring:   return "Spring"
        case .summer:   return "Summer"
        case .textures: return "Textures"
        case .winter:   return "Winter"
        }
    }

    /// The folder name used in the GitHub repository
    var folderName: String { rawValue }

    /// Resolves the actual folder name, converting "seasonal" to the current season
    var resolvedFolderName: String {
        if self == .seasonal {
            return SeasonHelper.currentSeasonName()
        }
        return rawValue
    }

    /// Name of the offline default image asset for this category
    var offlineDefaultAssetName: String {
        return "\(rawValue)_default"
    }

    /// Returns a Category from a folder name string, defaulting to .scenery
    static func fromFolderName(_ name: String) -> Category {
        return Category(rawValue: name.lowercased()) ?? .scenery
    }
}

// MARK: - Transition Type

/// Types of transitions between images in the slideshow
enum TransitionType: CaseIterable {
    case fade
    case slide
    case zoom

    /// Returns the next transition type in the cycle
    var next: TransitionType {
        let all = TransitionType.allCases
        guard let idx = all.firstIndex(of: self) else { return .fade }
        let nextIdx = (idx + 1) % all.count
        return all[nextIdx]
    }
}

// MARK: - GitHub API Response

/// Represents a single entry in the GitHub Contents API response
struct GitHubContentEntry: Decodable {
    let name: String
    let type: String
    let downloadUrl: String?

    enum CodingKeys: String, CodingKey {
        case name
        case type
        case downloadUrl = "download_url"
    }
}
