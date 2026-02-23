# FaithSaver — Apple TV (tvOS)

A faith-based photo slideshow app for Apple TV that displays Scripture-themed imagery fetched from a public GitHub repository. This is the tvOS port of the FaithSaver screensaver, mirroring the Roku and Fire TV implementations.

## Features

- **10 Image Categories**: Animals, Fall, Geology, Scenery, Seasonal (auto), Space, Spring, Summer, Textures, Winter
- **Seasonal Auto-Resolution**: The "Seasonal" category automatically maps to the current season (winter, spring, summer, fall) based on the local date
- **30-Second Image Rotation**: Images cycle every 30 seconds, matching the Roku/Fire TV timer
- **3 Transition Types**: Fade, Slide, and Zoom transitions that cycle automatically
- **Double-Buffered Display**: Two image layers for smooth transitions (mirrors Roku bgA/bgB)
- **Offline-First**: Shows a category-specific default image immediately while fetching online content
- **GitHub Feed**: Fetches images from the FaithSaver GitHub repository via the Contents API
- **In-Memory Image Cache**: LRU cache (NSCache) to avoid re-downloading images
- **Settings Persistence**: Selected category saved to UserDefaults
- **About Screen**: Project description, README link, and QR code for image submissions
- **Submit Images**: QR code dialog for contributing images to the repository

## Requirements

- Xcode 15.0+
- tvOS 16.0+ deployment target
- Swift 5.9+
- Apple TV HD or Apple TV 4K

## Project Structure

```
platforms/appletv/
├── FaithSaver.xcodeproj/       # Xcode project
├── FaithSaver/
│   ├── FaithSaverApp.swift     # App entry point (@main)
│   ├── Views/
│   │   ├── MainMenuView.swift  # Main menu (Start, Settings, Submit)
│   │   ├── SlideshowView.swift # Full-screen slideshow + ViewModel
│   │   ├── SettingsView.swift  # Category selection
│   │   └── AboutView.swift     # About overlay with QR code
│   ├── Models/
│   │   └── Models.swift        # ImageItem, Category, TransitionType, GitHubContentEntry
│   ├── Network/
│   │   └── GitHubApiClient.swift  # GitHub Contents API client
│   ├── Utils/
│   │   ├── PreferencesManager.swift  # UserDefaults wrapper
│   │   ├── SeasonHelper.swift        # Season resolution
│   │   └── ImageCache.swift          # NSCache-based image cache
│   ├── Assets.xcassets/        # Image assets and app icon
│   └── Info.plist              # App configuration
└── README.md
```

## Setup Instructions

### Option A: Open the Existing Xcode Project

1. Open `platforms/appletv/FaithSaver.xcodeproj` in Xcode 15+
2. Select your development team under **Signing & Capabilities**
3. Add the offline default images to the asset catalog (see below)
4. Build and run on an Apple TV simulator or device

### Option B: Create a Fresh Xcode Project (Recommended)

If the included `.xcodeproj` doesn't open cleanly (hand-generated project files can sometimes need adjustment):

1. Open Xcode → **File → New → Project**
2. Choose **tvOS → App** template
3. Set:
   - Product Name: `FaithSaver`
   - Team: Your development team
   - Organization Identifier: `com.faithsaver`
   - Interface: **SwiftUI**
   - Language: **Swift**
   - Minimum Deployments: **tvOS 16.0**
4. Save the project inside `platforms/appletv/`
5. Delete the auto-generated `ContentView.swift`
6. Drag all files from the `FaithSaver/` source folder into the Xcode project navigator
7. Make sure all `.swift` files are added to the **FaithSaver** target

### Adding Offline Default Images

The asset catalog has placeholder image sets for each category. You need to copy the actual default images:

1. From the repo root, copy each file from `images/offline/` into the corresponding asset catalog image set:

   ```
   images/offline/animals_default.jpg  →  Assets.xcassets/animals_default.imageset/
   images/offline/fall_default.jpg     →  Assets.xcassets/fall_default.imageset/
   images/offline/geology_default.jpg  →  Assets.xcassets/geology_default.imageset/
   images/offline/scenery_default.jpg  →  Assets.xcassets/scenery_default.imageset/
   images/offline/seasonal_default.jpg →  Assets.xcassets/seasonal_default.imageset/
   images/offline/space_default.jpg    →  Assets.xcassets/space_default.imageset/
   images/offline/spring_default.jpg   →  Assets.xcassets/spring_default.imageset/
   images/offline/summer_default.jpg   →  Assets.xcassets/summer_default.imageset/
   images/offline/textures_default.jpg →  Assets.xcassets/textures_default.imageset/
   images/offline/winter_default.jpg   →  Assets.xcassets/winter_default.imageset/
   images/offline/default.jpg          →  Assets.xcassets/default_image.imageset/default_image.jpg
   ```

2. Copy the QR code image:
   ```
   images/faithsaverqr.png  →  Assets.xcassets/faithsaverqr.imageset/
   ```

3. For the App Icon, add your layered images to `Assets.xcassets/AppIcon.brandassets/`
   - Primary app icon: 1280x768 (layered)
   - Top Shelf image: 1920x720
   - Top Shelf wide: 2320x720

## Architecture Comparison

| Feature | Roku | Fire TV | Apple TV |
|---------|------|---------|----------|
| Language | BrightScript | Kotlin | Swift |
| UI Framework | SceneGraph XML | Android Views | SwiftUI |
| Entry Point | RunScreenSaver() | DreamService / Activity | @main App |
| Image Rotation | 30s Timer node | 30s Handler.postDelayed | 30s Task.sleep |
| Transitions | Fade/Slide/Zoom | Fade/Slide/Zoom | Fade/Slide/Zoom |
| Settings Storage | roRegistrySection | SharedPreferences | UserDefaults |
| Network | roURLTransfer | HttpURLConnection | URLSession async/await |
| Image Cache | N/A (Roku handles) | LruCache | NSCache |
| Offline Default | pkg:/images/offline/ | R.drawable | Assets.xcassets |

## Bundle Identifier

`com.faithsaver.appletv`

## Version

1.0 (Build 107) — matches Roku/Fire TV version numbering.
