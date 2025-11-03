# Changelog

All notable changes to **FaithSaver** are documented here.

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
