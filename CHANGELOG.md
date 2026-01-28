# Changelog

All notable changes to **FaithSaver** are documented here.

## v1.0.107 — Category-Specific Defaults & Platform Optimization
- **NEW**: Category-specific offline default images for all categories (animals, fall, geology, scenery, seasonal, space, spring, summer, textures, winter)
- **NEW (Fire TV)**: Images now shuffle randomly when loaded from online feed for better variety
- **IMPROVED (Fire TV)**: Fixed first image transition timing - now waits full 30 seconds like subsequent transitions
- **IMPROVED (Fire TV)**: All transitions now timer-driven for consistent 30-second intervals
- **IMPROVED (Roku)**: Optimized offline images from 400-700 KB to 95-160 KB each
- **IMPROVED (Roku)**: Total package size reduced from 6 MB to 2.3 MB (60% reduction)
- **IMPROVED (Roku)**: Build script now preserves pre-optimized offline folder
- **FIXED**: Geology category now displays geology/rock images instead of animals
- **FIXED**: Scenery category now displays scenery/landscape images instead of animals
- **FIXED**: Added missing Seasonal category support across both platforms
- **TECHNICAL**: Added `getOfflineDefaultForCategory()` function to Fire TV for category mapping
- **TECHNICAL**: Added `GetOfflineDefaultForCategory()` function to Roku for category mapping
- **TECHNICAL**: Implemented image shuffling using Collections.shuffle() on Fire TV
- **TECHNICAL**: Offline images now 1280x720 resolution with optimized JPEG quality (50-75%)

## v1.0.106 — Seasonal Auto-Resolution Fix
- **Fixed** "Seasonal (auto)" category not loading images on some devices.
- **Added** `CurrentSeasonName()` function to `ImageFeedTask.brs` that resolves "seasonal" to the actual season folder (`spring`, `summer`, `fall`, `winter`) before fetching from GitHub.
- **Added** `ToLocalTime()` call for accurate month detection across all Roku firmware versions and timezones.
- **Improved** device compatibility for season detection (UTC vs local time handling).

## v1.0.105 — Stability & Compatibility
- Minor stability improvements.
- Verified compatibility with current Roku OS.

## v1.0.103 — Initial Public Release
- Stand-alone **screensaver** package (no in-channel UI).  
- **Settings** available via **Settings ▸ Theme ▸ Screensavers ▸ Change screensaver settings**.  
- **Offline-first**: shows `pkg:/images/offline/default.jpg` immediately, then switches to online images when ready.  
- **Online feed** from GitHub (Contents API → raw file URLs) with required headers and TLS CA bundle.  
- **Transitions**: Fade (first), then Fade/Slide/Zoom; timer ~30s; deterministic rotation.  
- **Removed** deep linking (`supports_input_launch`) to comply with screensaver policy.  
- **Removed** all `onKeyEvent` handlers from saver and components.  
- **Added** guarded memory-monitor hooks (`roAppMemoryMonitor` / `roDeviceInfo`) to quiet analyzer warnings.  
- **Minimum firmware guidance**: runs on 7.0+; recommend 9.0+ for reliable HTTPS.

## v1.0.0 (build 103) — Initial Public Release
- Stand-alone **screensaver** package (no in-channel UI).  
- **Settings** available via **Settings ▸ Theme ▸ Screensavers ▸ Change screensaver settings**.  
- **Offline-first**: shows `pkg:/images/offline/default.jpg` immediately, then switches to online images when ready.  
- **Online feed** from GitHub (Contents API → raw file URLs) with required headers and TLS CA bundle.  
- **Transitions**: Fade (first), then Fade/Slide/Zoom; timer ~30s; deterministic rotation.  
- **Removed** deep linking (`supports_input_launch`) to comply with screensaver policy.  
- **Removed** all `onKeyEvent` handlers from saver and components.  
- **Added** guarded memory-monitor hooks (`roAppMemoryMonitor` / `roDeviceInfo`) to quiet analyzer warnings.  
- **Minimum firmware guidance**: runs on 7.0+; recommend 9.0+ for reliable HTTPS.
