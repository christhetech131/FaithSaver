import Foundation

/// Resolves the current season based on the local date
enum SeasonHelper {

    /// Returns the current season folder name (e.g., "winter", "spring", "summer", "fall")
    static func currentSeasonName() -> String {
        let month = Calendar.current.component(.month, from: Date())
        switch month {
        case 12, 1, 2:
            return "winter"
        case 3, 4, 5:
            return "spring"
        case 6, 7, 8:
            return "summer"
        default: // 9, 10, 11
            return "fall"
        }
    }
}
