# FaithSaver
# Roku Screensaver Assets (GitHub Pages)


Static image library served via GitHub Pages for the Roku screensaver app.


## Categories
- animals
- fall
- geology
- scenery
- space
- spring
- summer
- textures
- winter


## JSON Manifest (`index.json`)
The Roku app fetches `/index.json` (cache‑busted). Schema:
{ "version": 1, "updated": "2025-09-22T00:00:00Z", "categories": { "animals": ["/animals/red_fox_01.jpg", "/animals/otter_02.webp"], "fall": [], "geology": [], "scenery": [], "space": [], "spring": [], "summer": [], "textures": [], "winter": [] } }



- `version` — bump when schema changes.
- `updated` — ISO‑8601 timestamp for clients to detect changes.
- `categories` — keys match folder names; values are arrays of **path‑relative** URLs (the app can prepend the site origin).


## File naming & optimization
- Export at ≤ 3840×2160 (4K) when possible.
- Prefer **WebP** or high‑quality **JPG**. Target ~300–600 KB each.
- Lowercase, hyphen/underscore names. Example: `red-fox-01.jpg`.


## Hosting
Enable GitHub Pages: **Settings → Pages → Source: `main` branch → `/` (root)**.
Your site will be available at: `https://<username>.github.io/<repo>/`.


## Attributions
- Put per‑image or per‑folder credits into `NOTICE.md` files alongside the assets if attribution is required.


## Local testing
Any static server will do:
Python 3

python -m http.server 8080

or

npx serve .