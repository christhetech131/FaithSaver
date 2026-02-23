import SwiftUI

/// Main menu screen for FaithSaver on Apple TV.
/// Mirrors the Fire TV MainActivity layout:
/// - Title + subtitle
/// - Start Slideshow button
/// - Settings button
/// - Submit Images button (shows QR code dialog)
/// - Navigation instructions
struct MainMenuView: View {

    @State private var showSlideshow = false
    @State private var showSettings = false
    @State private var showSubmitImages = false

    /// The navy accent color used throughout the app (0x103A57)
    private let navyAccent = Color(red: 16/255, green: 58/255, blue: 87/255)

    var body: some View {
        NavigationStack {
            ZStack {
                // Dark background matching Fire TV (0xFF1a1a1a)
                Color(red: 0.1, green: 0.1, blue: 0.1)
                    .ignoresSafeArea()

                VStack(spacing: 40) {
                    Spacer()

                    // App title
                    Text("FaithSaver")
                        .font(.system(size: 76, weight: .bold))
                        .foregroundColor(.white)

                    Text("Faith-Based Photo Slideshow")
                        .font(.title2)
                        .foregroundColor(Color(white: 0.8))

                    Spacer()
                        .frame(height: 20)

                    // Menu buttons
                    VStack(spacing: 20) {
                        MenuButton(title: "Start Slideshow", icon: "play.fill") {
                            showSlideshow = true
                        }

                        MenuButton(title: "Settings", icon: "gearshape.fill") {
                            showSettings = true
                        }

                        MenuButton(title: "Submit Images", icon: "square.and.arrow.up") {
                            showSubmitImages = true
                        }
                    }

                    Spacer()
                        .frame(height: 20)

                    // Navigation instructions
                    VStack(spacing: 8) {
                        Text("Use the Siri Remote to navigate")
                        Text("Press MENU to exit slideshow")
                    }
                    .font(.callout)
                    .foregroundColor(Color(white: 0.6))
                    .multilineTextAlignment(.center)

                    Spacer()
                }
                .padding(.horizontal, 80)
            }
            .fullScreenCover(isPresented: $showSlideshow) {
                SlideshowView()
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
            .sheet(isPresented: $showSubmitImages) {
                SubmitImagesView()
            }
        }
    }
}

// MARK: - Menu Button

private struct MenuButton: View {
    let title: String
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title2)
                    .frame(width: 36)

                Text(title)
                    .font(.title2)
                    .fontWeight(.medium)
            }
            .frame(width: 420, height: 80)
        }
        .buttonStyle(.card)
    }
}

// MARK: - Submit Images View (QR Code Dialog)

/// Displays a QR code for image submissions.
/// Mirrors the Fire TV showQRCodeDialog() behavior.
struct SubmitImagesView: View {

    @Environment(\.dismiss) private var dismiss

    private let mutedColor = Color(red: 34/255, green: 48/255, blue: 65/255)

    var body: some View {
        VStack(spacing: 32) {
            Text("Submit Your Faith-Based Images")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.primary)

            // QR Code image
            if let qrImage = UIImage(named: "faithsaverqr") {
                Image(uiImage: qrImage)
                    .resizable()
                    .interpolation(.none)
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 320, height: 320)
                    .cornerRadius(12)
            } else {
                // Placeholder if QR asset not yet added
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 320, height: 320)
                    .overlay(
                        VStack(spacing: 8) {
                            Image(systemName: "qrcode")
                                .font(.system(size: 80))
                                .foregroundColor(.secondary)
                            Text("QR Code")
                                .font(.callout)
                                .foregroundColor(.secondary)
                        }
                    )
            }

            Text("Scan this QR code with your phone\nto submit images to our GitHub repository")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Button("Close") {
                dismiss()
            }
            .buttonStyle(.card)
        }
        .padding(60)
        .onExitCommand {
            dismiss()
        }
    }
}
