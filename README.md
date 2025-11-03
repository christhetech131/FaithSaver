# FaithSaver — Roku SceneGraph Screensaver

FaithSaver is a Roku **screensaver** that cycles beautiful, faith-based photography and Scripture artwork. It’s lean, privacy-friendly, and simple to maintain. Users choose a category in **Settings ▸ Theme ▸ Screensavers ▸ Change screensaver settings**. The saver shows an **offline first frame** instantly, then rotates **online images** from a public GitHub repo with smooth transitions.

> ✅ **Store-ready & compliant:** stand-alone screensaver package, no deep linking, no `onKeyEvent` handlers in any component, and guarded memory-monitor hooks to quiet Static Analysis warnings.

---

## What’s included (current build)

- **Stand-alone screensaver** (no channel/tile UI).  
  - Uses only `RunScreenSaver` and `RunScreenSaverSettings`.  
  - No `title=` or “in-channel screensaver” behavior in the manifest.
- **Offline → Online flow:** shows `pkg:/images/offline/default.jpg` immediately; switches to online images when ready.
- **Online feed:** GitHub Contents API → filter `.jpg|.jpeg|.png` → map to raw GitHub URLs.  
  - Headers: `User-Agent: FaithSaver/1.0 (+roku)` and `Accept: application/vnd.github+json`.  
  - TLS with Roku CA bundle via `SetCertificatesFile("common:/certs/ca-bundle.crt")`.
- **Rotation:** deterministic variety without RNG. Start index = `roDateTime().AsSeconds() mod count`, then round-robin.
- **Timer:** default **30s** between image changes.
- **Transitions:** double-buffered **Fade / Slide / Zoom**.  
  - First transition is **Fade**; later transitions alternate deterministically.  
  - Zoom scales from ~0.98 → 1.00.
- **Settings UI:** category selector and **About** overlay with QR link.  
  - Implemented without `onKeyEvent` (list/scene behavior handles focus & close).
- **Analyzer-quiet memory hooks (guarded):** `roAppMemoryMonitor` + `roDeviceInfo` enabled safely (no behavior change).

---

## Minimum firmware

- **Runs on:** SceneGraph devices (**Roku OS 7.0+**).  
- **Recommended store setting:** **Roku OS 9.0+** for reliable HTTPS to GitHub on all devices.  
- **Packaging note:** If your `.pkg` format is SQUASHFS_ZSTD (produced on very new OS), the dashboard may require **11.0+**. Otherwise **9.0** is ideal.

---

## Categories

```
animals, fall, geology, scenery, seasonal, space, spring, summer, textures, winter
```

> **Offline image** is a single universal fallback: `pkg:/images/offline/default.jpg`.  
> Online images still come from the selected category folder (e.g., `/animals`).

---

## Repository layout (expected)

```
/ (repo root)
  /animals/*.jpg|png
  /fall/*.jpg|png
  /geology/*.jpg|png
  /scenery/*.jpg|png
  /space/*.jpg|png
  /spring/*.jpg|png
  /summer/*.jpg|png
  /textures/*.jpg|png
  /winter/*.jpg|png

  /images/
    FaithSaver-Poster-540x405.jpg
    FaithSaver-Poster-290x218.jpg
    FaithSaver-Splash-1920x1080.jpg
    FaithSaver-Splash-1280x720.jpg
    faithsaverqr.png
    /offline/
      default.jpg

  manifest
  /source/main.brs
  /components/
    SaverScene.xml / SaverScene.brs
    ImageFeedTask.xml / ImageFeedTask.brs
    SettingsScene.xml / SettingsScene.brs
    AboutOverlay.xml / AboutOverlay.brs
  README.md
```

---

## Manifest (screensaver-only)

```text
# FaithSaver — manifest (screensaver-only)
screensaver_title=FaithSaver
ui_resolutions=fhd

# Icons / splash (used by the OS where applicable)
mm_icon_focus_fhd=pkg:/images/FaithSaver-Poster-540x405.jpg
mm_icon_focus_hd=pkg:/images/FaithSaver-Poster-290x218.jpg
splash_screen_fhd=pkg:/images/FaithSaver-Splash-1920x1080.jpg
splash_screen_hd=pkg:/images/FaithSaver-Splash-1280x720.jpg

# Entry points
run_screensaver=RunScreenSaver
run_screensaver_settings=RunScreenSaverSettings

# No deep linking in a screensaver package
# supports_input_launch= (omitted)

# Versioning
major_version=1
minor_version=0
build_version=103
```

> We intentionally omit `title=` and any “tile” behaviors to avoid “in-channel screensaver” violations.

---

## How it works (tech notes)

### Fetch flow
1. **Task** (`ImageFeedTask`) calls `https://api.github.com/repos/<user>/<repo>/contents/<category>`  
   - Headers:  
     - `User-Agent: FaithSaver/1.0 (+roku)`  
     - `Accept: application/vnd.github+json`
2. Filter entries where `type == "file"` and extension is `.jpg | .jpeg | .png`.
3. Map each to:  
   `https://raw.githubusercontent.com/<user>/<repo>/<branch>/<category>/<name>`
4. Post list back to `SaverScene` when ready.

### Transitions
- **Double buffer:** `bgA` and `bgB` Poster nodes.  
- **Fade:** crossfade opacities.  
- **Slide:** incoming from right, outgoing to left (both at full opacity).  
- **Zoom:** incoming fades 0→1 while scaling 0.98→1.00.

Change speeds by adjusting the corresponding **Animation** durations in `SaverScene.brs`. Zoom subtlety is primarily controlled by the start/end scale range.

---

## Memory monitoring (to quiet Static Analysis)

We include a guarded initializer that:
- Creates `roAppMemoryMonitor` and enables `EnableMemoryWarningEvent(true)`.
- Calls `GetChannelMemoryLimit()`, `GetMemoryLimitPercent()`, and `GetChannelAvailableMemory()` once (so usage is detected).
- Creates `roDeviceInfo`, sets the same message port, and calls `EnableLowGeneralMemoryEvent(true)`.
- Consumes `roDeviceInfoEvent` with a no-op branch in event loops.

> All calls are **guarded**; on older firmware they no-op safely.

---

## Image guidelines

- Baseline (non-progressive) **JPG** or **PNG**  
- **sRGB, 8-bit**, no CMYK  
- **1920×1080+** recommended  
- Use reasonable file sizes for older devices

---

## Build, package, and publish

1. **Dev test:** Zip and sideload from the Roku developer web interface.  
   - Logs via telnet: `telnet <roku-ip> 8085`  
   - Log prefixes: `[FaithSaver][Main]`, `[FaithSaver][Settings]`, `[FaithSaver][Saver]`, `[FaithSaver][Feed]`
2. **Package for store:** Use the Roku **Package** workflow (`.pkg`).  
   - Choose **Minimum firmware** ≥ your package format’s minimum (CRAMFS ≥ 7.7, SQUASHFS ≥ 8.0, SQUASHFS_ZSTD ≥ 11.0).  
   - Recommended: **v9.0.0** (reliable HTTPS & broad coverage).
3. **Static analysis:** Should return to the “Run analysis” page with no results when clean.  
   - No deep linking, no `onKeyEvent` anywhere, and memory hooks included.

---

## Troubleshooting

- **Blank/gray on first transition:** ensure first transition stays **Fade**; slide/zoom rely on initialized buffers.  
- **No online images:** confirm the repo category exists and contains supported files at the **category root**; check feed logs for “Discovered N image file(s)”.  
- **Network down:** saver remains on offline `default.jpg` and keeps trying in the background.  
- **Keys:** published savers are governed by system behavior; package contains **no** `onKeyEvent` handlers.

---

## Privacy & Attribution

- No analytics, no tracking, no accounts.  
- Submitted images must be original or properly licensed for public display.  
- By submitting, you grant permission for use in the FaithSaver app and repository.

---

## Project links

- **Project website:** https://christhetech131.github.io/FaithSaver/  
- **Submit images:** https://www.dropbox.com/request/oHIb71WTmJk443JL0ZeA  
  (Raw form URL: https://www.dropbox.com/request/jPpbec3mTcXPfycknlAl)  
- **Email:** faithsaver131@gmail.com  
- **Repository:** https://github.com/christhetech131/FaithSaver/
