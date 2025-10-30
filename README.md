# FaithSaver — Roku SceneGraph Screensaver

FaithSaver is a Roku screensaver that displays faith‑based photography and Scripture artwork. It is lean, network‑efficient, and simple to maintain. Users pick a category in **Settings**, and the saver shows an **offline first frame** immediately, then cycles **online images** from your GitHub repository using a deterministic rotation with lightweight transitions.

---

## TL;DR (What it does)
- **Single production saver** (no separate preview path)
- **Offline first frame** shown instantly per category (`pkg:/images/offline/<key>.jpg`)
- **Online fetch**: GitHub Contents API → filter image files → map to raw URLs
- **Deterministic rotation**: start index = `roDateTime().AsSeconds() mod count`, then round‑robin
- **Timer**: default 30s between image changes (configured in XML)
- **Transitions**: Fade / Slide / Zoom chosen per change (deterministic “random”), with **Fade enforced for the very first transition**; Slide is a bit slower for polish
- **Settings**: Category selector with header and About overlay (QR to project site)
- **No RNG APIs**, no heavy effects; works consistently across Roku firmware

---

## Quick Links
- **Project Website (GitHub Pages):** https://christhetech131.github.io/FaithSaver/
- **Submit Images (Dropbox File Request):** https://www.dropbox.com/request/oHIb71WTmJk443JL0ZeA  
  (Raw form URL: https://www.dropbox.com/request/jPpbec3mTcXPfycknlAl)
- **Email:** mailto:faithsaver131@gmail.com

> This README supersedes the previous version while keeping its intent and links.  (Original reference kept for history.)

---

## How It Works

### Mode
- **Production Saver (only).** The Roku “Preview” entry routes to the same saver path by design.
- On start, the saver reads the saved **category** from the Roku Registry: `FaithSaver/category` (defaults to `animals`).

### Offline → Online flow
1. **Offline first frame**: immediately shows `pkg:/images/offline/<category>.jpg`.  
2. **Online fetch**: a `Task` (`ImageFeedTask`) calls the GitHub Contents API:  
   `https://api.github.com/repos/<user>/<repo>/contents/<category>`  
   The task filters for `.jpg|.jpeg|.png` files and maps them to raw URLs:  
   `https://raw.githubusercontent.com/<user>/<repo>/main/<category>/<name>`  
3. **Rotation** (no RNG): pick `start = roDateTime().AsSeconds() mod count`, then `index = (index + 1) mod count` each tick.
4. **Timer**: set in `components/SaverScene.xml` (`<Timer id="cycler" duration="30" repeat="true" />`).

### Transitions (portable & simple)
We use a double‑buffer (`bgA`, `bgB`) with **Animation + FieldInterpolators**:
- **Fade** (350ms): cross‑fade opacity between buffers.
- **Slide** (650ms): push left; incoming slides from right while outgoing slides left. (Both at full opacity.)
- **Zoom** (350ms): quick ease‑in — incoming fades 0→1 while slightly scaling from 0.98→1.00.

**Selection strategy:** For each ready image, choose transition mode via `(roDateTime().AsSeconds() + index) mod 3`. This yields a stable “random‑ish” mix **without RNG**. The **very first** transition after startup is always **Fade** (to avoid a slide revealing a gray base).

**Changing speeds:**  
- **Fade speed:** `m.animFade.duration` in `SaverScene.brs` (seconds)  
- **Slide speed:** `m.animSlide.duration` in `SaverScene.brs` (seconds)  
- **Zoom speed:** `m.animZoom.duration` in `SaverScene.brs` (seconds)  ← *adjust this to change zoom speed*

> Subtlety (not speed) of Zoom is controlled by the scale range in `m.zoomScale.keyValue` (`[0.98, 0.98] → [1.0, 1.0]`).

### Categories
Supported keys (used by Settings UI and offline images):
```
animals, fall, geology, scenery, seasonal, space, spring, summer, textures, winter
```
- **seasonal** uses `offline/default.jpg` for the first frame; online images still come from the `/seasonal` folder (if populated).

---

## Repo Layout (expected)
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
    FaithSaver-BrandTile-147x113.jpg
    FaithSaver-Splash-1920x1080.jpg
    FaithSaver-Splash-1280x720.jpg
    faithsaverqr.png
    /offline/
      animals.jpg
      fall.jpg
      geology.jpg
      scenery.jpg
      space.jpg
      spring.jpg
      summer.jpg
      textures.jpg
      winter.jpg
      default.jpg
    /about/
      FaithSaver-About-1920x1080.png (optional)
  manifest
  /source/main.brs
  /components/
    SaverScene.xml / SaverScene.brs
    ImageFeedTask.xml / ImageFeedTask.brs
    SettingsScene.xml / SettingsScene.brs
    AboutOverlay.xml / AboutOverlay.brs
  README.md
  index.html (landing page used by QR)
```

---

## UI Details

### Settings
- Background: `pkg:/images/FaithSaver-Splash-1920x1080.jpg`
- Highlight bar: navy rectangle; labels created in BRS
- **Header:** `FaithSaver Settings — Saved: <title>` (updates after saving)
- **Up/Down:** move selection; **OK:** save; **Back:** exit (host screen handles close)
- **About** row opens a modal overlay with text (left) and a QR poster (right)

### About overlay
- Right pane QR: `pkg:/images/faithsaverqr.png`
- Optional full‑image about background supported (`/images/about/*`)

---

## Image Requirements
- Baseline (non‑progressive) JPG or PNG
- sRGB, 8‑bit; no CMYK; avoid EXIF rotations that confuse decoders
- **1920×1080 or larger** recommended
- Keep sizes reasonable for older devices

---

## Manifest Essentials
```text
title=FaithSaver
screensaver_title=FaithSaver
ui_resolutions=fhd

mm_icon_focus_fhd=pkg:/images/FaithSaver-Poster-540x405.jpg
mm_icon_focus_hd=pkg:/images/FaithSaver-Poster-540x405.jpg

splash_screen_fhd=pkg:/images/FaithSaver-Splash-1920x1080.jpg
splash_screen_hd=pkg:/images/FaithSaver-Splash-1280x720.jpg

ui_brand_tile=pkg:/images/FaithSaver-BrandTile-147x113.jpg

run_screensaver=RunScreenSaver
run_screensaver_settings=RunScreenSaverSettings
# (No preview entry by design)
```
> Ensure art files exist and match the exact filenames above.

---

## Build, Package, and Run (Dev)
1. Verify required paths (see **Repo Layout**). Ensure each **offline image** exists.
2. Zip from project root and sideload via Roku dev web UI.
3. Watch telnet logs at `telnet <roku-ip> 8085` for diagnostics (look for `[FaithSaver][...]`).
4. In Settings, choose a category (OK to save). When the saver runs, you’ll see:
   - Offline first frame instantly
   - Online images rotating every 30s (or your test value)

**Logging prefixes**:  
`[FaithSaver][Main]`, `[FaithSaver][Settings]`, `[FaithSaver][Saver]`, `[FaithSaver][Feed]`

---

## Troubleshooting
- **Grey screen:** For Slide, both posters must be non‑transparent; code sets `opacity=1.0` for slide mode. If customized, ensure incoming/outgoing opacity isn’t left at 0.
- **No online images:** Confirm the repo folder exists and includes `.jpg/.jpeg/.png` at the **category root**. Watch logs:
  - `[Feed] GET …` then `Discovered N image file(s)`
- **Hangs/crashes in dev:** Some sideloaded sessions differ from published behavior. Let the saver start from Home and retest.
- **Back/Home behavior:** Dev builds swallow **Back** to avoid accidental exits; published savers are governed by Roku system keys.
- **First transition oddness:** First transition is forced to **Fade** to avoid sliding over a blank/gray base.

---

## Privacy & Attribution
- Uploaded images must be original or properly licensed. By submitting, you permit display in the FaithSaver app and repository.
- No analytics or tracking are included.

---

## Contact
- Email: **faithsaver131@gmail.com**
- Project site: https://christhetech131.github.io/FaithSaver/
- Repository: https://github.com/christhetech131/FaithSaver/
