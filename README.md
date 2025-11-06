# FaithSaver — Roku SceneGraph Screensaver

FaithSaver is a **stand‑alone Roku screensaver** that cycles faith‑based photography and Scripture artwork.
It shows an offline image immediately, then fetches and rotates online images from a public GitHub repository
with smooth transitions (Fade → Slide → Zoom).

This README supersedes the prior version and reflects the changes verified in v1.0.105.

---

## Key characteristics

- **Stand‑alone screensaver** package (not a channel); no `Main()` or deep linking.
- Entry points: `RunScreenSaver` and optional `RunScreenSaverSettings`.
- **Offline‑first**: displays `pkg:/images/offline/default.jpg` immediately.
- **Online feed**: pulls JPEG/PNG files from GitHub folder paths per category.
- **Rotation**: 30‑second Timer; deterministic start index; round‑robin thereafter.
- **Transitions**: double‑buffered Posters with Fade/Slide/Zoom.
- **Settings**: category selector; **About** overlay closes on any key and returns to the list.
- **Robust timer start**: rotation starts even if the feed is empty/slow; offline image rotates until items arrive.

---

## Repository layout (expected)

```
/<category>/*.jpg|png         # animals, fall, geology, scenery, seasonal, space, spring, summer, textures, winter
/images/offline/default.jpg
/components/  SaverScene.*  SettingsScene.*  ImageFeedTask.*  AboutOverlay.*
/source/main.brs
manifest
```

**Categories**
```
animals, fall, geology, scenery, seasonal, space, spring, summer, textures, winter
```

---

## Manifest (screensaver‑only)

> Keep the manifest *screensaver‑only* — do **not** include `title=`.

```properties
# FaithSaver — manifest
screensaver_title=FaithSaver
ui_resolutions=fhd

# Icons / splash
mm_icon_focus_fhd=pkg:/images/FaithSaver-Poster-540x405.jpg
mm_icon_focus_hd=pkg:/images/FaithSaver-Poster-290x218.jpg
splash_screen_fhd=pkg:/images/FaithSaver-Splash-1920x1080.jpg
splash_screen_hd=pkg:/images/FaithSaver-Splash-1280x720.jpg

# Entry points
run_screensaver=RunScreenSaver
run_screensaver_settings=RunScreenSaverSettings

# Optional (recommended): keep the saver off the Home screen
hidden=1

# Versioning
major_version=1
minor_version=0
build_version=105
```

**Notes**
- Use `screensaver_title` (omit `title=` for a stand‑alone screensaver).
- `hidden=1` prevents a Home‑screen tile for saver packages.
- Do not include channel‑only fields (e.g., deep linking) or `Main()`.

---

## How it works

- **ImageFeedTask**: calls GitHub Contents API for the selected category, filters to `.jpg|.jpeg|.png`, and
  maps them to raw GitHub URLs.
- **SaverScene**:
  - Shows the offline default first.
  - Starts the 30s **cycler** unconditionally in `init()` (so rotation is reliable).
  - When items arrive, transitions begin (Fade first, then Slide/Zoom).
  - Pauses/resumes the cycler on visibility changes.
- **SettingsScene**:
  - Lists categories; writes the chosen key to `roRegistrySection("FaithSaver")`.
  - Opens **About** overlay; any key closes the overlay and returns to the list (does not exit Settings).

---

## Build & package

1. Bump `build_version` in `manifest`.
2. Sideload the ZIP and verify behavior.
3. Use Roku Packager (or device Dev UI) to generate a **.pkg** signed with the same key as prior releases.

**Minimum firmware**: choose per your dashboard’s guidance for your package format; current app tested on modern OS with HTTPS and SceneGraph.

---

## Test plan (quick)

- **Settings (runscreensaversettings)**: change categories; About overlay closes on any key and returns to list.
- **Saver (runscreensaver)**:
  - Expect logs like `Cycler started (unconditional)` when run from dev entrypoint.
  - Images rotate every ~30s; transitions occur.
- **Feed‑robustness**: temporarily use an empty category or briefly disconnect network — offline default still rotates; online images begin when items arrive.
- **Visibility**: exiting/returning resumes the cycler.

> Note: When the OS auto‑starts the saver (Preview/idle), telnet logs may be silent; launch via the dev entrypoint to view logs.

---

## Troubleshooting

- **Static Analysis flags “channel … Main() missing” or “in‑channel screensaver (4.5)”**  
  Ensure the manifest is screensaver‑only (no `title=`; keep `screensaver_title` + `run_screensaver*`). Re‑upload the **.pkg**.

- **About overlay warning**  
  If you ever see `Rectangle` field warnings, set `color` on the rectangle (not `blendColor`).

- **No online images**  
  Confirm the GitHub category folders exist at repo root and contain supported image types.

---

## License

All third‑party images must be licensed appropriately for redistribution and display.

```

# End of README
