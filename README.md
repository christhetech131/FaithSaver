# FaithSaver — Roku SceneGraph Screensaver

FaithSaver is a Roku screensaver that displays faith‑based images. The **production saver** pulls approved images directly from this GitHub repository (by category) using the GitHub Contents API, shuffles them client‑side on each run, and rotates through them on a timer. Roku’s “Preview” trigger routes to the same saver behavior (no separate preview path).

## Quick Links

- **Landing / Submission page:** https://christhetech131.github.io/FaithSaver/
- **Finished images Dropbox (with verse):** https://www.dropbox.com/request/oHIb71WTmJk443JL0ZeA
- **Raw photos Dropbox (no verse yet):** https://www.dropbox.com/request/jPpbec3mTcXPfycknlAl
- **Email (verses only):** faithsaver131@gmail.com
- **Project README (this file):** https://github.com/christhetech131/FaithSaver#readme

---

## Supported Categories & Repo Layout

Supported categories:
```
animals, fall, geology, scenery, seasonal, space, spring, summer, textures, winter
```

**Repository layout** (root-level folders; each contains finished JPG/PNG files — no subfolders inside categories):
```
/animals/*.jpg
/fall/*.jpg
/geology/*.jpg
/scenery/*.jpg
/seasonal/*.jpg
/space/*.jpg
/spring/*.jpg
/summer/*.jpg
/textures/*.jpg
/winter/*.jpg
```

> Filenames are case-sensitive over HTTP. Prefer baseline sRGB **JPG** (non‑progressive, 8‑bit). PNGs are supported but typically larger.

---

## Behavior Overview

- **Single Saver Scene**: `SaverScene` used for production and for Roku “Preview” trigger.
- **Settings**: `SettingsScene` shows a label list with a highlight bar. OK saves the selected category to the registry (`section: FaithSaver`, `key: category`). Back exits settings via the host.
  - **Order**: Animals, Fall, Geology, Scenery, **Seasonal**, Space, Spring, Summer, Textures, Winter, About.
  - Header uses `font:LargeSystemFont` and updates immediately after save.
- **About overlay (in Settings)**: Left pane has a wrapped paragraph and README URL; right pane shows a QR code (`pkg:/images/faithsaverqr.png`) pointing to the public landing/submission page.
- **Online Images (production)**: On launch, the saver fetches a single listing from GitHub for the selected category, **shuffles** the URLs (Fisher–Yates) and rotates them on a timer.
- **Offline Fallback**: If the listing fails or is empty, the saver shows a local offline “first frame” for the category and does not start rotation.
- **Low Bandwidth**: Exactly one HTTP call per launch to list files. If desired, the task can cache and reuse `ETag` (304 not modified) to avoid re-listing when nothing changed. Images themselves are fetched as they’re shown.

---

## Submissions Workflow

Contributors can send either:
1) **Finished images (verse already applied)** — faster approval.  
   Upload: https://www.dropbox.com/request/oHIb71WTmJk443JL0ZeA
2) **Raw photos (no verse yet)** — we’ll add scripture before publishing.  
   Upload: https://www.dropbox.com/request/jPpbec3mTcXPfycknlAl
3) **Verse‑only (no image)** — email the verse text and translation preferences.  
   Email: **faithsaver131@gmail.com** (include reference and preferred translation(s); we’ll typeset it and include available translations as licensing permits).

**Recommended filename format** (optional, helps sorting):
```
category__short-title__attribution.jpg
# example: scenery__sunrise-over-lake__jane-doe.jpg
```

Approved finished images are moved into the appropriate category folder in this repo. The app auto-discovers them on the next launch.

**Image guidelines**
- Landscape orientation preferred (16:9 best)
- Minimum size **1920×1080**
- Color: sRGB, **non‑progressive**, 8‑bit
- Avoid logos/watermarks
- For finished images, ensure verse text is legible over the background

---

## Implementation Details

### Entry Points (manifest)
```
run_screensaver=RunScreenSaver
run_screensaver_settings=RunScreenSaverSettings
run_screensaver_preview=RunScreenSaverPreview  # Routed to same saver path
```

### Scenes
- **SaverScene** (unified saver)
  - Reads registry `FaithSaver/category` (default `animals`).
  - Shows offline first frame immediately.
  - Runs `ImageFeedTask` to fetch GitHub URLs, shuffles results, starts rotation timer only if items exist.
  - Swallows keys in saver mode.
- **SettingsScene**
  - Label list + custom highlight.
  - Colors: highlight `0x103A57FF`, focused text `0xFFFFFFFF`, unfocused `0x000000FF`.
  - Registry write to `FaithSaver/category` on OK (with `Flush()`).
  - “About” overlay with QR and README link; Back exits settings.

### Online Image Listing
`/components/ImageFeedTask.brs` calls GitHub **Contents API** for the selected category:
```
GET https://api.github.com/repos/christhetech131/FaithSaver/contents/<category>?ref=main
Headers:
  User-Agent: FaithSaver/1.0 (+roku)
  Accept: application/vnd.github+json
  If-None-Match: "<etag>"       # optional
```
The task parses the JSON array, collects `download_url` values (or builds raw URLs), shuffles (Fisher–Yates), optionally clamps a max count, sets `m.top.items`, and starts the rotation timer in the scene. If `ETag` present, it’s cached per‑category (e.g., `etag_scenery`) for the next run.

**Rate limits**: Unauthenticated API allows ~60 requests/hour per IP. With one listing per launch (no polling), usage is minimal.

### Rotation Timer
- Runs only after items are present (saver mode).
- Interval is configurable in `SaverScene.brs` (cycler/timer node).
- A practical starting range is **8–12 seconds** per image.

---

## Assets & Manifest Keys (filenames must match exactly)

- Tile (opaque): `pkg:/images/FaithSaver-BrandTile-147x113.jpg`
- Splash FHD: `pkg:/images/FaithSaver-Splash-1920x1080.jpg`
- Splash HD:  `pkg:/images/FaithSaver-Splash-1280x720.jpg`
- Poster (if used in store art previews): `pkg:/images/FaithSaver-Poster-540x405.jpg`
- About image: `pkg:/images/about/FaithSaver-About-1920x1080.png`
- QR image: `pkg:/images/faithsaverqr.png`

Manifest keys must reference the exact files above (case‑sensitive). The tile must be **opaque** (no transparency).

---

## Build & Packaging

- **PowerShell**: `Build-FaithSaver.ps1` (zero flags by default)
  - Validates required files/folders
  - Does not mutate image bytes
  - Emits packaged ZIP to `./dist/` and current directory
  - Exits non‑zero with clear error messages on failure

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
/... (other category folders at repo root)
```

---

## Troubleshooting

- **Only splash shows**: Confirm SaverScene created and feed task ran; verify category folder has at least one valid image.
- **No rotation**: Feed may be empty or failed; check logs for `items=Array(N)` and cycler start.
- **Decode errors**: Re‑export as baseline sRGB JPG (non‑progressive).
- **Settings not saving**: Verify `roRegistrySection("FaithSaver")` writes `category` and calls `Flush()`.
- **Rate limit**: Very unlikely. If hit, rely on offline first frame; relaunch later.

---

## Store Submission Readiness (Checklist)

**Functional**
- [ ] Runs crash‑free on current Roku OS (tested on at least one FHD device; if possible, also test an HD device).
- [ ] Settings: Up/Down/OK work; Back exits to host. Header updates after save.
- [ ] Saver: shows offline first frame immediately; cycles through online images when available.
- [ ] No navigation or focus leaks in saver mode; Back/Home are swallowed.
- [ ] Network: exactly one GitHub list call on launch; no polling.

**Assets & Manifest**
- [ ] `mm_icon_focus_hd` and `mm_icon_focus_fhd` both point to `pkg:/images/FaithSaver-Poster-540x405.jpg` (or your final poster art).  
- [ ] `splash_screen_hd` and `splash_screen_fhd` point to the exact splash filenames listed above.
- [ ] `ui_brand_tile` references opaque `pkg:/images/FaithSaver-BrandTile-147x113.jpg`.
- [ ] All referenced files exist in the package; no case/spacing mismatches.

**Store Listing Materials**
- [ ] Channel/Screensaver name: *FaithSaver*.
- [ ] Short & long descriptions (non‑promotional, accurate).
- [ ] Category: Screensaver.
- [ ] **Store poster** (540×405) and **screenshots** (1920×1080) prepared.
- [ ] Support contact: **faithsaver131@gmail.com**.
- [ ] Privacy: No collection of personal data by the app (document this in the listing).
- [ ] Landing page URL (optional): https://christhetech131.github.io/FaithSaver/

**QA Pass**
- [ ] Load time reasonable; splash displays correctly.
- [ ] Remote keys behave as described (no unintended exits).
- [ ] Images render correctly (no progressive/CMYK issues).
- [ ] GitHub listing works for at least one category with >1 image and shuffles order between runs.

**Packaging**
- [ ] Built with `Build-FaithSaver.ps1`; ZIP validated and uploaded for certification/testing.

---

## Licensing & Permissions

By uploading, you affirm you own the rights (or have permission) to share the image and grant FaithSaver permission to display, crop, and resize it across Roku devices. For raw photos, you also permit adding scripture text and exporting a finished derivative for display.

---

## Roadmap

- Optional size/EXIF checks before admitting images
- Automated curation helpers (scripts)
- Optional per‑category max‑items clamp and timer
- Optional About image variants for HD vs FHD
