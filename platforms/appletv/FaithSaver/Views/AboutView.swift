import SwiftUI

/// About overlay showing project description, README link, and QR code.
/// Mirrors Roku AboutOverlay layout:
/// - Left pane: title, description paragraph, separator, README link
/// - Right pane: QR code image + caption
struct AboutView: View {

    @Environment(\.dismiss) private var dismiss

    /// The navy accent color used in the Roku UI (0x103A57)
    private let navyAccent = Color(red: 16/255, green: 58/255, blue: 87/255)
    private let mutedColor = Color(red: 34/255, green: 48/255, blue: 65/255)

    var body: some View {
        ZStack {
            // Semi-transparent scrim (matches Roku 0x00000088)
            Color.black.opacity(0.55)
                .ignoresSafeArea()

            // Card panel
            HStack(alignment: .top, spacing: 48) {
                // Left: text pane
                leftPane
                    .frame(maxWidth: .infinity, alignment: .leading)

                // Right: QR code pane
                rightPane
                    .frame(width: 380)
            }
            .padding(48)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(UIColor.systemBackground))
            )
            .padding(80)
        }
        .onExitCommand {
            dismiss()
        }
    }

    // MARK: - Left Pane

    private var leftPane: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("FaithSaver")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(navyAccent)

            Text("FaithSaver is a lightweight screensaver that shows faith-based imagery from a public GitHub repository. Open the project README to learn how to contribute images.")
                .font(.body)
                .foregroundColor(.primary)
                .lineLimit(8)
                .fixedSize(horizontal: false, vertical: true)

            Divider()
                .background(navyAccent)

            VStack(alignment: .leading, spacing: 8) {
                Text("README (project details):")
                    .font(.callout)
                    .foregroundColor(mutedColor)

                Text("https://github.com/christhetech131/FaithSaver#readme")
                    .font(.callout)
                    .foregroundColor(mutedColor)
                    .lineLimit(2)
            }

            Text("Version 1.0")
                .font(.footnote)
                .foregroundColor(.secondary)

            Spacer()
        }
    }

    // MARK: - Right Pane (QR Code)

    private var rightPane: some View {
        VStack(spacing: 24) {
            Spacer()

            // QR Code image (loaded from Assets.xcassets as "faithsaverqr")
            if let qrImage = UIImage(named: "faithsaverqr") {
                Image(uiImage: qrImage)
                    .resizable()
                    .interpolation(.none)
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 280, height: 280)
                    .cornerRadius(12)
            } else {
                // Placeholder if QR asset not yet added
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 280, height: 280)
                    .overlay(
                        VStack(spacing: 8) {
                            Image(systemName: "qrcode")
                                .font(.system(size: 60))
                                .foregroundColor(.secondary)
                            Text("QR Code")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    )
            }

            Text("Scan to open submissions and info")
                .font(.callout)
                .foregroundColor(mutedColor)
                .multilineTextAlignment(.center)

            Spacer()
        }
    }
}
