import Foundation

/// Manages user preferences using UserDefaults
final class PreferencesManager {

    static let shared = PreferencesManager()

    private let defaults = UserDefaults.standard

    private enum Keys {
        static let selectedCategory = "selected_category"
    }

    private static let defaultCategory = "animals"

    private init() {}

    // MARK: - Category

    /// Returns the saved category folder name (e.g., "animals")
    var selectedCategory: String {
        get {
            defaults.string(forKey: Keys.selectedCategory) ?? Self.defaultCategory
        }
        set {
            defaults.set(newValue, forKey: Keys.selectedCategory)
        }
    }

    /// Returns the saved category as a `Category` enum value
    var selectedCategoryEnum: Category {
        Category.fromFolderName(selectedCategory)
    }
}
