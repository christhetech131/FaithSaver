import SwiftUI

/// Settings screen for selecting the image category.
/// Mirrors Roku SettingsScene behavior:
/// - Lists all categories (Animals, Fall, Geology, Scenery, Seasonal, Space, Spring, Summer, Textures, Winter)
/// - Highlights the currently saved selection
/// - Persists choice to UserDefaults (Roku uses roRegistrySection)
/// - Includes an "About" entry at the bottom separated visually
/// - Shows "Saved: <category>" in the header (matches Roku title bar)
struct SettingsView: View {

    @Environment(\.dismiss) private var dismiss
    @State private var selectedCategory: String = PreferencesManager.shared.selectedCategory
    @State private var showAbout = false

    /// Light blue accent for readability on dark backgrounds
    private let accentColor = Color(red: 0.4, green: 0.7, blue: 0.9)

    var body: some View {
        ZStack {
            // Dark background
            Color(red: 0.1, green: 0.1, blue: 0.1)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("FaithSaver Settings")
                        .font(.title)
                        .fontWeight(.semibold)
                        .foregroundColor(accentColor)

                    Spacer()

                    Text("Saved: \(displayNameForSaved)")
                        .font(.title3)
                        .foregroundColor(Color(white: 0.6))
                }
                .padding(.horizontal, 80)
                .padding(.top, 60)
                .padding(.bottom, 16)

                Divider()
                    .background(accentColor)
                    .padding(.horizontal, 80)

                // Category list
                ScrollView {
                    VStack(spacing: 4) {
                        ForEach(Category.allCases) { category in
                            CategoryRow(
                                category: category,
                                isSelected: selectedCategory == category.folderName,
                                accentColor: accentColor
                            ) {
                                selectedCategory = category.folderName
                                PreferencesManager.shared.selectedCategory = category.folderName
                            }
                        }

                        Divider()
                            .padding(.vertical, 12)
                            .padding(.horizontal, 20)

                        // About button
                        Button(action: { showAbout = true }) {
                            HStack {
                                Image(systemName: "info.circle")
                                    .font(.title3)
                                Text("About FaithSaver")
                                    .font(.title3)
                                Spacer()
                            }
                            .padding(.horizontal, 24)
                            .padding(.vertical, 16)
                        }
                        .buttonStyle(.card)
                    }
                    .padding(.horizontal, 80)
                    .padding(.top, 24)
                    .padding(.bottom, 40)
                }

                // Footer hint
                Text("Press MENU to go back")
                    .font(.callout)
                    .foregroundColor(Color(white: 0.5))
                    .padding(.bottom, 40)
            }
        }
        .onExitCommand {
            dismiss()
        }
        .fullScreenCover(isPresented: $showAbout) {
            AboutView()
        }
    }

    private var displayNameForSaved: String {
        Category.fromFolderName(selectedCategory).displayName
    }
}

// MARK: - Category Row

private struct CategoryRow: View {
    let category: Category
    let isSelected: Bool
    let accentColor: Color
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack {
                Text(category.displayName)
                    .font(.title3)
                    .fontWeight(isSelected ? .semibold : .regular)

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(accentColor)
                        .font(.title3)
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
        }
        .buttonStyle(.card)
    }
}
