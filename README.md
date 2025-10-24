# FaithSaver — Roku SceneGraph Screensaver

FaithSaver is a Roku screensaver that displays faith‑based images. The production saver pulls approved images directly from this GitHub repository (by category) using the GitHub Contents API, shuffles them client‑side on each run, and rotates through them on a timer. Preview mode is not implemented as a separate path; the Roku “Preview” trigger launches the same saver behavior.

## Quick Links

- **Submission page:** https://christhetech131.github.io/FaithSaver/
- **Finished images Dropbox (with verse):** https://www.dropbox.com/request/oHIb71WTmJk443JL0ZeA
- **Raw photos Dropbox (no verse yet):** https://www.dropbox.com/request/jPpbec3mTcXPfycknlAl
- **Project README (this file):** https://github.com/christhetech131/FaithSaver#readme

## Supported Categories

```
animals, fall, geology, scenery, space, spring, summer, textures, winter, seasonal
```

Repository layout (root‑level folders; each contains finished JPG/PNG files):

```
/animals/*.jpg
/fall/*.jpg
/geology/*.jpg
/scenery/*.jpg
/space/*.jpg
/spring/*.jpg
/summer/*.jpg
/textures/*.jpg
/winter/*.jpg
/seasonal/*.jpg
```

> Filenames are case‑sensitive over HTTP. Prefer baseline sRGB **JPG** (non‑progressive, 8‑bit). PNGs are supported but typically larger.

---

## Behavior Overview

- **Single Saver Scene**: `SaverScene` is used for both production and “preview” triggers. There is no separate preview code path.
- **Settings**: `SettingsScene` provides a list of categories. OK saves the selected category to the registry (`section: FaithSaver`, `key: category`). Back exits settings via the host.
- **Online Images**: On launch, the saver fetches a single listing from the GitHub Contents API for the selected category folder, shuffles the returned URLs locally, and rotates them using a timer.
- **Offline Fallback**: If the listing fails or the folder is empty, the saver shows a local offline “first frame” for the category and does not start rotation.
- **Low Bandwidth**: Only one HTTP call per launch to list files. Optional `ETag` reuse is supported: if nothing changed, the app can reuse cached URLs (304 Not Modified). Images themselves are loaded as the saver rotates.
- **Keys**: Saver swallows all keys. Settings handles Up/Down/OK. Back exits settings. There is no navigation in saver mode.

---

## About Page (in Settings)

- In Settings, the last row is **About**. Pressing OK shows a modal overlay:
  - **Left**: About image with QR (file: `pkg:/images/about/FaithSaver-About-1920x1080.png`). A QR asset can be shown as `pkg:/images/faithsaverqr.png`.
  - **Right**: Project info and the **README URL** printed for convenience.
  - Back or OK closes the overlay and returns focus to the settings list.

---

## Submissions Workflow

Contributors can submit either:
1) **Finished images (with verse already applied)** — likely to be approved faster.
2) **Raw photos (no verse)** — we’ll add scripture and export a finished image later.

Use the public file‑request links:
- Finished (with verse): https://www.dropbox.com/request/oHIb71WTmJk443JL0ZeA
- Raw (no verse): https://www.dropbox.com/request/jPpbec3mTcXPfycknlAl

**Recommended filename format** (optional, helps sorting):

```
category__short-title__attribution.jpg
# example: scenery__sunrise-over-lake__jane-doe.jpg
```

Approved finished images are moved into the appropriate category folder in this repo. The app auto‑discovers them on the next launch.

**Image guidelines**
- Landscape orientation preferred (16:9 works best)
- Minimum size **1920×1080**
- Color: sRGB, **non‑progressive**, 8‑bit
- Avoid logos/watermarks
- Ensure text is legible over the background for finished images

---

## Implementation Details

### Entry Points (manifest)

```
run_screensaver=RunScreenSaver
run_screensaver_settings=RunScreenSaverSettings
run_screensaver_preview=RunScreenSaverPreview  # Calls the same saver path
```

### Scenes

- `SaverScene`: unified saver
  - Reads registry for `category` (default `animals`).
  - Shows offline first frame immediately.
  - Creates and runs `ImageFeedTask` to fetch URLs.
  - Starts rotation timer only when items exist.
  - Swallows keys in saver mode.

- `SettingsScene`:
  - Label list with a custom highlight bar.
  - Colors: highlight `0x103A57FF`, focused text `0xFFFFFFFF`, unfocused `0x000000FF`.
  - Registry section `FaithSaver`, key `category`, flushed on OK.
  - Back returns control to the host.
  - Includes **About** overlay.

### Online Image Listing

`/components/ImageFeedTask.brs` calls the GitHub **Contents API**:

```
GET https://api.github.com/repos/christhetech131/FaithSaver/contents/<category>?ref=main
Headers:
  User-Agent: FaithSaver/1.0 (+roku)
  Accept: application/vnd.github+json
  If-None-Match: "<etag>"       # optional
```

The task parses the JSON array, collects `download_url` values (or builds raw URLs as a fallback), shuffles the list (Fisher–Yates), optionally clamps to a max count, and sets `m.top.items`. If an `ETag` is returned, it is stored in the Roku registry under `etag_<category>` and used on the next launch to avoid re‑downloading when unchanged.

**Rate limits**: Unauthenticated GitHub API allows ~60 requests/hour per IP. The app makes one listing call per launch and does not poll, which is well within limits.

### Rotation Timer

- Runs only in saver mode and only after items exist.
- Interval is configurable in `SaverScene.brs`.
- Typical comfortable value: **8–12 seconds** per image.

---

## Assets & Manifest Keys (filenames must match exactly)

- Tile (opaque): `pkg:/images/FaithSaver-BrandTile-147x113.jpg`
- Splash FHD: `pkg:/images/FaithSaver-Splash-1920x1080.jpg`
- Splash HD:  `pkg:/images/FaithSaver-Splash-1280x720.jpg`
- Optional poster(s): `pkg:/images/FaithSaver-Poster-540x405.jpg`
- About image: `pkg:/images/about/FaithSaver-About-1920x1080.png`
- QR image: `pkg:/images/faithsaverqr.png`

Manifest keys should reference the exact files above (case‑sensitive).

---

## Build & Packaging

- **PowerShell**: `Build-FaithSaver.ps1` (zero flags by default)
  - Validates presence of required files and folders
  - Does not mutate image bytes (no re‑encode)
  - Emits packaged ZIP to `./dist/` and current directory
  - Exits non‑zero with clear messages on failure

Minimum project structure:

```
/manifest
/source/main.brs
/components/SaverScene.xml
/components/SaverScene.brs
/components/SettingsScene.xml
/components/SettingsScene.brs
/components/ImageFeedTask.xml
/components/ImageFeedTask.brs
/components/AboutOverlay.xml
/components/AboutOverlay.brs
/images/FaithSaver-BrandTile-147x113.jpg
/images/FaithSaver-Splash-1920x1080.jpg
/images/FaithSaver-Splash-1280x720.jpg
/images/faithsaverqr.png
/images/about/FaithSaver-About-1920x1080.png
/animals/*.jpg
/... (other category folders)
```

---

## Troubleshooting

- **Only splash shows**: Check manifest asset paths and filenames. Confirm `SaverScene` created and `ImageFeedTask` ran.
- **No rotation**: Folder may be empty or API failed; check logs for `ok: N images, shuffled` or HTTP errors.
- **Decode errors**: Re‑export image as baseline sRGB JPG (non‑progressive).
- **Settings not saving**: Verify registry writes to `section=FaithSaver`, `key=category` and `Flush()` is called.
- **Rate limit**: Unlikely with one call per launch. If needed, back off and rely on offline first frame.

---

## Licensing & Permissions

By uploading, you affirm you own the rights (or have permission) to share the image and grant FaithSaver permission to display, crop, and resize it across Roku devices. For raw photos, you also permit adding scripture text and exporting a finished derivative for display.

---

## Roadmap

- Optional size/EXIF checks before admitting images
- Automated curation helpers (scripts)
- Optional MaxItems clamp tuning per category
- Optional About image variants for HD vs FHD
