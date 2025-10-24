# FaithSaver — Roku SceneGraph Screensaver

FaithSaver is a Roku screensaver that displays faith‑based photography and scripture artwork. It supports a simple Settings screen with a category selector, an About overlay, and an online shuffle of approved images hosted in this repository.

---

## Quick Links

- **Project Website (GitHub Pages):** https://christhetech131.github.io/FaithSaver/
- **Submit Images (Dropbox File Request):** https://www.dropbox.com/request/oHIb71WTmJk443JL0ZeA  
  (Raw form URL: https://www.dropbox.com/request/jPpbec3mTcXPfycknlAl)
- **Email for verse submissions / questions:** mailto:faithsaver131@gmail.com

---

## How It Works

### Modes
- **Production Saver (only)**
  - No navigation. Back/Home keys are swallowed by the saver.
  - Reads the selected **category** from the Roku Registry (`FaithSaver:category`).
  - Immediately shows an **offline fallback image** for that category (from `pkg:/images/offline/*.jpg`).
  - Starts an **online image feed** that lists the image files in the project’s GitHub repo under `/<category>/*.jpg` and shuffles them per run.
  - Images then rotate on a timer (default **30 seconds**) using a double‑buffered crossfade to avoid black frames.

- **Settings**
  - Labels + highlight bar UI.
  - **Back** exits Settings (handled by the host screen).
  - Saves the selection to Registry (`FaithSaver:category`) and updates the header to show the saved choice.
  - An **About** item opens the About overlay (see below).

> Note: FaithSaver **does not** implement a separate preview mode. Roku’s “Preview” entry uses the same saver scene.

### Categories
Currently supported keys:
`animals`, `fall`, `geology`, `scenery`, `seasonal`, `space`, `spring`, `summer`, `textures`, `winter`

If you pick **Seasonal**, the saver shows the seasonal offline frame and will pull from the `/seasonal` folder online (if populated).

---

## Online Image Source (GitHub)

The production saver fetches URLs using the GitHub Contents API for this repo:
- Owner: `christhetech131`
- Repo: `FaithSaver`
- Branch: `main`
- Path per category: `/<category>/*.jpg`

Only files at the **category root** are included (no subfolders). The feed client filters for `.jpg`, `.jpeg`, or `.png` file names and shuffles them once per run. It also supports ETag caching to keep bandwidth low when images haven’t changed.

**Tip:** If you are adding a new image to be used online, place it in the appropriate category folder at the repository root (e.g., `/spring/new-image.jpg`).

---

## Submitting Images

We accept **two types** of contributions:

1) **Finished images** with verses already designed on the artwork.  
2) **Raw photographs** where we will add verses and typographic treatment before approval.

### Submit via Dropbox (no account required)
- **File Request Link:** https://www.dropbox.com/request/oHIb71WTmJk443JL0ZeA  
  (Raw form link, if needed: https://www.dropbox.com/request/jPpbec3mTcXPfycknlAl)

Upload your files there. The maintainer moves approved images into the proper category in this repo.

### Submit verses only (no image)
- Email **faithsaver131@gmail.com** with the verse text and translation notes.  
  We will typeset the verse onto curated photos and include commonly available Bible translations.

**Image Requirements**
- Baseline sRGB JPG/PNG, **8‑bit**, **non‑progressive**, **no CMYK**, no EXIF rotations that break Roku decoders.
- **1920×1080 or larger** recommended (landscape).

---

## UI Details

### Settings Screen
- Background splash: `pkg:/images/FaithSaver-Splash-1920x1080.jpg`
- Highlight color: `0x103A57FF` (Roku RGBA)
- Focused text: `0xFFFFFFFF`, Unfocused text: `0x000000FF`
- Title shows: “FaithSaver Settings — Saved: <current selection>”
- **About** item at the bottom of the list

### About Overlay
- Left: large image card (e.g., `pkg:/images/about/FaithSaver-About-1920x1080.png`)
- Right: QR and descriptive text (long text wraps)
- A README link is displayed so users can visit on their phone
- Optional QR asset at `pkg:/images/faithsaverqr.png`

---

## Transitions & Rotation

- Double‑buffered **crossfade** implemented with two Posters (`bgA`, `bgB`) and a short fade:
  - `bgNext.opacity` fades from 0 to 1
  - `bgCurrent.opacity` fades from 1 to 0
  - Swap active buffer after the fade completes
- Rotation **interval** default is **30 seconds** (configurable in `components/SaverScene.xml` Timer `duration` value).

---

## Build, Package, and Run (Dev)

1) Ensure the following required files exist:
   - `/manifest`
   - `/source/main.brs`
   - `/components/SaverScene.xml`, `/components/SaverScene.brs`
   - `/components/ImageFeedTask.xml`, `/components/ImageFeedTask.brs`
   - `/components/SettingsScene.xml`, `/components/SettingsScene.brs`
   - `/components/AboutOverlay.xml`, `/components/AboutOverlay.brs`
   - `/images/FaithSaver-BrandTile-147x113.jpg`
   - `/images/FaithSaver-Splash-1920x1080.jpg`
   - `/images/FaithSaver-Splash-1280x720.jpg`
   - `/images/offline/*.jpg` (one per category fallback)

2) Pack into a zip and side‑load to your Roku dev device.  
   Watch telnet logs at `telnet <roku-ip> 8085` for diagnostics.

3) In Settings, select a category and hit **OK** to save.  
   When the screensaver runs, it will show the offline image immediately, then rotate through the online list if available.

---

## Manifest Essentials

```text
title=FaithSaver
subtitle=Faith-based photo screensaver
major_version=1
minor_version=0
build_version=0

mm_icon_focus_fhd=pkg:/images/FaithSaver-Poster-540x405.jpg
mm_icon_focus_hd=pkg:/images/FaithSaver-Poster-540x405.jpg

splash_screen_fhd=pkg:/images/FaithSaver-Splash-1920x1080.jpg
splash_screen_hd =pkg:/images/FaithSaver-Splash-1280x720.jpg

ui_brand_tile=pkg:/images/FaithSaver-BrandTile-147x113.jpg
search_button_logo=pkg:/images/FaithSaver-SearchButton-165x60.png

ui_resolutions=fhd

run_screensaver=RunScreenSaver
run_screensaver_settings=RunScreenSaverSettings

screensaver_title=FaithSaver
```

> Ensure `FaithSaver-BrandTile-147x113.jpg` is **opaque** and filenames match exactly (case‑sensitive on some toolchains).

---

## Troubleshooting

- **No online rotation:** Verify your Roku has network access and that the GitHub category folder has `.jpg` images at the root.  
- **Crashes in dev mode when cycling:** Some firmware builds are stricter with networking APIs in dev sessions. The app is coded to use broadly compatible `roUrlTransfer` calls (no unsupported methods). If you still see issues, test by letting the screensaver auto‑launch from the Home screen.
- **Black frames between images:** The app now uses a crossfade. If you notice abrupt transitions, confirm both Posters are present and `animationDurationMs` is set in the scene (see code).

---

## Privacy & Attribution

- Uploaded images should be original or licensed for redistribution. You retain rights to your work; by submitting, you grant permission to display the image within the FaithSaver app and repository.
- No tracking or analytics are included in the saver.

---

## Contact

- Email: **faithsaver131@gmail.com**
- Project site: https://christhetech131.github.io/FaithSaver/
- Repository: https://github.com/christhetech131/FaithSaver/

