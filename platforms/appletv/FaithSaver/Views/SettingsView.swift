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

    /// The navy accent color used in the Roku UI (0x103A57)
    private let navyAccent = Color(red: 16/255, green: 58/255, blue: 87/255)

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 0) {
                // Header (matches Roku: "FaithSaver Settings — Saved: <category>")
                headerView
                    .padding(.horizontal, 48)
                    .padding(.top, 24)
                    .padding(.bottom, 8)

                Divider()
                    .background(navyAccent)
                    .padding(.horizontal, 48)

                // Category list
                List {
                    Section {
                        ForEach(Category.allCases) { category in
                            CategoryRow(
                                category: category,
                                isSelected: selectedCategory == category.folderName,
                                accentColor: navyAccent
                            ) {
                                selectedCategory = category.folderName
                                PreferencesManager.shared.selectedCategory = category.folderName
                            }
                        }
                    }

                    Section {
                        Button(action: { showAbout = true }) {
                            HStack {
                                Text("About")
                                    .font(.title3)
                                Spacer()
                                Image(systemName: "info.circle")
                                    .font(.title3)
                            }
                        }
                    }
                }
                .listStyle(.grouped)
            }
            .sheet(isPresented: $showAbout) {
                AboutView()
            }
        }
    }

    // MARK: - Header

    private var headerView: some View {
        HStack {
            Text("FaithSaver Settings")
                .font(.title)
                .fontWeight(.semibold)
                .foregroundColor(navyAccent)

            Text("—")
                .foregroundColor(.secondary)

            Text("Saved: \(displayNameForSaved)")
                .font(.title3)
                .foregroundColor(.secondary)

            Spacer()
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

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(accentColor)
                        .font(.title3)
                }
            }
        }
    }
}
