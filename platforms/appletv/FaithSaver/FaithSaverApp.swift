import SwiftUI

/// FaithSaver — tvOS App Entry Point
///
/// A faith-based photo slideshow app for Apple TV that displays
/// Scripture-themed imagery fetched from a public GitHub repository.
///
/// Mirrors functionality from the Roku screensaver and Fire TV app.
@main
struct FaithSaverApp: App {
    var body: some Scene {
        WindowGroup {
            MainMenuView()
        }
    }
}
