# FaithSaver (Roku Screensaver)

A Roku SceneGraph screensaver with offline-first images, optional online feed, and a simple settings UI for choosing categories. Designed for rock-solid stability across “saver”, “preview”, and “settings” launch paths.

## Features

- **Production screensaver**
  - Starts on an **offline image** while network images cache
  - **5-minute** (300s) rotation
  - **Any key exits** (Back/Home/OK/arrows/etc.)
- **Preview**
  - **5-second** rotation using only packaged offline art
  - **Up/Down** to step images
  - **Back/Home exits**
- **Settings**
  - Static splash background
  - Simple list of categories
  - Persists selection to registry (`FaithSaver/category`)
  - Shows "FaithSaver Settings" inside **Settings ▸ Theme ▸ Screensavers** once the sideloaded saver is active

---

## Project Layout

manifest
source/
main.brs # Entry + mode router + screen lifecycle
components/
SaverScene.xml # SceneGraph class "SaverScene" (UI for saver/preview)
SaverScene.brs # Logic: timers, rotation, key handling
SettingsScene.xml # SceneGraph class "SettingsScene" (menu)
SettingsScene.brs # Logic: list building, highlight, save to registry
ImageFeedTask.xml # Task node "ImageFeedTask"
ImageFeedTask.brs # Builds image URI list (offline + optional online)
images/
FaithSaver-Splash-1920x1080.jpg
FaithSaver-Splash-1280x720.jpg
Logo-Full.png # Used for manifest icon_fhd
offline/ # Offline JPGs used as first frame + fallback
Shrink-FaithSaver-Zip.ps1 # (Optional) packager that builds .dist and zip
README.md

yaml
Copy code

> **Component names must match** what `main.brs` creates: `SaverScene`, `SettingsScene`, `ImageFeedTask`.

---

## Manifest

```ini
title=FaithSaver
is_screensaver=1
screensaver_title=FaithSaver
screensaver_settings_title=FaithSaver Settings
screensaver_settings=1
screensaver_settings_available=1

major_version=1
minor_version=2
build_version=11

ui_resolutions=hd,fhd

splash_screen_fhd=pkg:/images/FaithSaver-Splash-1920x1080.jpg
splash_screen_hd=pkg:/images/FaithSaver-Splash-1280x720.jpg
splash_color=#103A57

icon_fhd=pkg:/images/Logo-Full.png
mm_icon_focus_hd=pkg:/images/icon_hd.png
mm_icon_focus_fhd=pkg:/images/icon_fhd.png
mm_icon_side_hd=pkg:/images/FaithSaver-BrandTile-147x113.png

entry_point=Main
screensaver_entry_point=RunSaverEntry
screensaver_preview_entry_point=RunPreviewEntry
screensaver_settings_entry_point=RunSettingsEntry

bs_libs_required=
```

These manifest keys ensure Roku OS lists FaithSaver in **Settings ▸ Theme ▸ Screensavers** with a dedicated **FaithSaver Settings** button that launches `RunSettingsEntry`. Roku OS 12+ also expects `screensaver_settings_available=1` to surface the entry.

Modes & Key Handling
Production (“saver”)

Rotation: 300s

Keys: any key → exit

Preview (“preview”)

Rotation: 5s

Up/Down: step to prev/next image

Back/Home: exit preview

Settings (“settings”)

Static background: images/FaithSaver-Splash-1920x1080.jpg

Up/Down to move, OK to save, Back to exit

Persistence (Registry)
Section: FaithSaver

Key: category (lowercase string)

Default: seasonal (season chosen by current month)

Event Flow
source/main.brs inspects Roku launch arguments (mode/launchReason/intent/etc.) to decide between saver, preview, and settings flows.

Creates roSGScreen, attaches roMessagePort.

scene = screen.CreateScene("<SaverScene|SettingsScene>")

screen.Show(), scene.SetFocus(true)

Observes scene.close; when true → screen.Close().

Do not call screen.SetScene(); your Roku OS associates the created scene automatically. Calling SetScene caused the Member function not found (&hf4) errors you saw.

Offline & Online Images
Offline images live in images/offline/*.jpg. These are always available and used as:

First frame while network fetch warms up (production)

The entire set for preview (or combined with online if desired)

ImageFeedTask returns imageUris to SaverScene.

SaverScene rotates through imageUris (timer) and supports manual step in preview.

Packaging (optional helper)
Use Shrink-FaithSaver-Zip.ps1 to build .dist/ and zip only required files:

Copies manifest, source/, components/, and only the needed images (two splash JPGs, Logo-Full.png, and the offline/ folder).

Fails fast if a required file is missing.

Produces FaithSaver-small.zip ready for sideload.

Do not mutate/append the manifest in the packager; edit manifest in the repo directly.

Asset regeneration

If you ever need to recreate the bundled artwork (splashes, icon, offline set), run:

```
python tools/generate_assets.py
```

The script emits deterministic solid-color placeholders that satisfy the Roku sizing requirements so sideload packages always include real binary image data (not Git LFS pointers).

Troubleshooting (real issues you hit)
“No such node SaverScene”

SaverScene.xml class name must be "SaverScene", file present, compiled, and main.brs must create exactly that name.

Member function not found (&hf4) on screen.SetScene

Remove the call; use only CreateScene() + Show().

“Missing or invalid PHY: …”

The files don’t exist in the zip. Ensure the packager copies:

images/FaithSaver-Splash-1920x1080.jpg

images/Logo-Full.png (for icon_fhd)

“BS lib provider not found: roku_ads_lib”

Remove it: bs_libs_required= should be empty.

Type Mismatch in the close loop (String vs roSGNode)

Only compare msg.getNode() to scene inside a type(msg) = "roSGNodeEvent" check.

Randomize() crash (Function Call Operator on non-function)

Don’t call Randomize() at all (it was shadowed or unsupported on your build). If you need randomness, shuffle by time (e.g., index offset using roDateTime().AsSeconds()).

Acceptance Checklist
 App opens to production saver when launched from Home.

 Production: offline image shows first, feed warms up, rotates every 300s.

 Production: any key exits.

 Screensaver Preview (from OS settings): shows offline images, rotates every 5s.

 Preview: Up/Down steps images; Back/Home exits.

 Settings: static splash background; category list saves to registry; Back exits.

 manifest uses only Logo-Full.png for icon_fhd and the two splash JPGs.

 Zip contains all required files, no mm_ assets, no roku_ads_lib.

yaml
Copy code

---
