import SwiftUI
import os.log

/// Full-screen image slideshow that mirrors Roku SaverScene behavior:
/// - Double-buffered image display (bgA / bgB)
/// - 30-second rotation timer
/// - 3 transition types: Fade, Slide, Zoom (cycling)
/// - Offline-first with category-specific default image
/// - Online feed from GitHub Contents API
struct SlideshowView: View {

    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = SlideshowViewModel()

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            // Background layer (outgoing image)
            if let bgImage = viewModel.backgroundImage {
                Image(uiImage: bgImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .ignoresSafeArea()
                    .opacity(viewModel.bgOpacity)
                    .offset(x: viewModel.bgOffsetX)
                    .scaleEffect(viewModel.bgScale)
            }

            // Foreground layer (incoming image)
            if let fgImage = viewModel.foregroundImage {
                Image(uiImage: fgImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .ignoresSafeArea()
                    .opacity(viewModel.fgOpacity)
                    .offset(x: viewModel.fgOffsetX)
                    .scaleEffect(viewModel.fgScale)
            }
        }
        .ignoresSafeArea()
        .onAppear {
            viewModel.start()
        }
        .onDisappear {
            viewModel.stop()
        }
        .onExitCommand {
            viewModel.stop()
            dismiss()
        }
    }
}

// MARK: - ViewModel

@MainActor
final class SlideshowViewModel: ObservableObject {

    private let logger = Logger(subsystem: "com.faithsaver.appletv", category: "Slideshow")

    // MARK: Published state for the two image layers

    @Published var backgroundImage: UIImage?
    @Published var foregroundImage: UIImage?

    @Published var bgOpacity: Double = 1.0
    @Published var bgOffsetX: CGFloat = 0
    @Published var bgScale: CGFloat = 1.0

    @Published var fgOpacity: Double = 0.0
    @Published var fgOffsetX: CGFloat = 0
    @Published var fgScale: CGFloat = 1.0

    // MARK: Internal state

    private var imageItems: [ImageItem] = []
    private var currentIndex = 0
    private var transitionType: TransitionType = .fade
    private var isActiveLayerForeground = false // tracks which layer is "on top"

    private var rotationTask: Task<Void, Never>?
    private var fetchTask: Task<Void, Never>?

    private let rotationInterval: TimeInterval = 30 // 30 seconds, matching Roku
    private let transitionDuration: TimeInterval = 0.65

    private let apiClient = GitHubApiClient.shared
    private let imageCache = ImageCache.shared
    private let prefs = PreferencesManager.shared

    private let screenWidth: CGFloat = 1920 // tvOS is always 1920x1080

    // MARK: - Lifecycle

    func start() {
        logger.info("Slideshow starting")
        loadOfflineDefault()
        startRotationTimer()
        fetchOnlineImages()
    }

    func stop() {
        logger.info("Slideshow stopping")
        rotationTask?.cancel()
        rotationTask = nil
        fetchTask?.cancel()
        fetchTask = nil
    }

    // MARK: - Offline Default

    /// Loads the category-specific offline default image (mirrors Roku ShowFirstFrameForCategory)
    private func loadOfflineDefault() {
        let category = prefs.selectedCategoryEnum
        let assetName = category.offlineDefaultAssetName

        if let image = UIImage(named: assetName) {
            backgroundImage = image
            bgOpacity = 1.0
            foregroundImage = nil
            fgOpacity = 0.0
            isActiveLayerForeground = false
            logger.info("Loaded offline default: \(assetName)")
        } else if let fallback = UIImage(named: "default_image") {
            backgroundImage = fallback
            bgOpacity = 1.0
            logger.info("Loaded generic fallback default")
        } else {
            logger.warning("No offline default found for \(assetName)")
        }
    }

    // MARK: - Online Feed

    /// Fetches images from GitHub (mirrors Roku ImageFeedTask + Fire TV fetchOnlineImages)
    private func fetchOnlineImages() {
        let category = prefs.selectedCategoryEnum

        fetchTask = Task {
            do {
                let items = try await apiClient.fetchImages(for: category)

                guard !Task.isCancelled else { return }

                if items.isEmpty {
                    logger.warning("Feed returned empty; staying on offline default")
                    return
                }

                imageItems = items
                // Time-based start index (matching Roku behavior)
                let now = Int(Date().timeIntervalSince1970)
                currentIndex = now % imageItems.count
                logger.info("Feed loaded \(items.count) images, start index=\(self.currentIndex)")
            } catch {
                guard !Task.isCancelled else { return }
                logger.error("Feed fetch error: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Rotation Timer

    /// 30-second cycle timer (mirrors Roku <Timer id="cycler" duration="30">)
    private func startRotationTimer() {
        rotationTask = Task {
            // Wait for the first interval before advancing
            // (matches Roku: shows offline default immediately, first online image on first tick)
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: UInt64(rotationInterval * 1_000_000_000))
                guard !Task.isCancelled else { break }

                if !imageItems.isEmpty {
                    currentIndex = (currentIndex + 1) % imageItems.count
                    await showImage(imageItems[currentIndex])
                }
            }
        }
    }

    // MARK: - Image Loading & Display

    /// Downloads an image (with cache) and triggers a transition
    private func showImage(_ item: ImageItem) async {
        guard let image = await loadImage(from: item.url) else {
            logger.error("Failed to load image: \(item.url)")
            return
        }

        guard !Task.isCancelled else { return }

        // Cycle transition type (matches Roku: mode = (seconds + index) mod 3)
        cycleTransition()

        // Perform the animated transition
        performTransition(with: image)
    }

    /// Downloads or retrieves a cached image
    private func loadImage(from urlString: String) async -> UIImage? {
        // Check cache first
        if let cached = imageCache.get(forKey: urlString) {
            return cached
        }

        guard let url = URL(string: urlString) else { return nil }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            guard let image = UIImage(data: data) else { return nil }
            imageCache.set(image, forKey: urlString)
            return image
        } catch {
            logger.error("Image download failed: \(error.localizedDescription)")
            return nil
        }
    }

    // MARK: - Transitions

    /// Cycles through fade -> slide -> zoom (matches Roku cycling logic)
    private func cycleTransition() {
        transitionType = transitionType.next
    }

    /// Performs the selected transition between the current and next image
    private func performTransition(with newImage: UIImage) {
        // Place the new image on the inactive layer
        if isActiveLayerForeground {
            // Foreground is active (visible), load new onto background
            resetBackgroundLayer()
            backgroundImage = newImage
            animateTransition(incomingIsForeground: false)
        } else {
            // Background is active (visible), load new onto foreground
            resetForegroundLayer()
            foregroundImage = newImage
            animateTransition(incomingIsForeground: true)
        }

        isActiveLayerForeground.toggle()
    }

    private func resetForegroundLayer() {
        fgOpacity = 0.0
        fgOffsetX = 0
        fgScale = 1.0
    }

    private func resetBackgroundLayer() {
        bgOpacity = 0.0
        bgOffsetX = 0
        bgScale = 1.0
    }

    /// Animates between the two layers based on the current transition type
    private func animateTransition(incomingIsForeground: Bool) {
        switch transitionType {
        case .fade:
            fadeTransition(incomingIsForeground: incomingIsForeground)
        case .slide:
            slideTransition(incomingIsForeground: incomingIsForeground)
        case .zoom:
            zoomTransition(incomingIsForeground: incomingIsForeground)
        }

        logger.info("Transition = \(String(describing: self.transitionType))")
    }

    // MARK: Fade (matches Roku animFade, duration 0.35s)

    private func fadeTransition(incomingIsForeground: Bool) {
        withAnimation(.easeInOut(duration: transitionDuration)) {
            if incomingIsForeground {
                fgOpacity = 1.0
                bgOpacity = 0.0
            } else {
                bgOpacity = 1.0
                fgOpacity = 0.0
            }
        }
    }

    // MARK: Slide (matches Roku animSlide, duration 0.65s)

    private func slideTransition(incomingIsForeground: Bool) {
        if incomingIsForeground {
            fgOffsetX = screenWidth
            fgOpacity = 1.0
            withAnimation(.easeInOut(duration: transitionDuration)) {
                fgOffsetX = 0
                bgOffsetX = -screenWidth
            }
        } else {
            bgOffsetX = screenWidth
            bgOpacity = 1.0
            withAnimation(.easeInOut(duration: transitionDuration)) {
                bgOffsetX = 0
                fgOffsetX = -screenWidth
            }
        }
    }

    // MARK: Zoom (matches Roku animZoom, scale 0.98 -> 1.0, duration 0.35s)

    private func zoomTransition(incomingIsForeground: Bool) {
        if incomingIsForeground {
            fgScale = 0.98
            fgOpacity = 0.0
            withAnimation(.easeInOut(duration: transitionDuration)) {
                fgOpacity = 1.0
                fgScale = 1.0
                bgOpacity = 0.0
            }
        } else {
            bgScale = 0.98
            bgOpacity = 0.0
            withAnimation(.easeInOut(duration: transitionDuration)) {
                bgOpacity = 1.0
                bgScale = 1.0
                fgOpacity = 0.0
            }
        }
    }
}
