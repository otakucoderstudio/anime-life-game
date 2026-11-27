# Handoff (anime-life-game, godot-3d)

Updated 2026-11-27 13:22 (Cairo). Latest verified tag: **v3d-1.08** (APK on GitHub releases only). Only ONE agent publishes a new tag at a time; the successor first reproduces the build, then asks the parent before tagging.

## Current priority (user decisions)
1. One city zone per release, Kyoto first. Cheap first version: small own-made zone, own palette and one landmark. Never present a city as real if it is a Tokyo copy, say so.
2. Retarget Quaternius Universal Animation Library (CC0, free, no login) onto the VRoid characters. Mixamo not needed (needs an Adobe signup; the user said yes once, still not used).
3. Then: j-sounds ambience, character creator, FPS counter with auto low-quality switch.
4. Street props (benches, bins, signals) later, user said not now.
The user wants quality and honesty over speed. Reports to the user go through the parent as screenshots plus a short honest note, no APK links (APK stays on GitHub releases).

## Rules
- Free tools/hosting only. No signups or paid items without the user's explicit yes (ask the parent).
- UI in Egyptian Arabic, Japanese names in Arabic script, slice of life, no combat.
- Target phone Honor X6c (Helio G81 Ultra) is NOT tested on a real device. Every release says so. Real FPS is unknown.
- Not publishing the game publicly for now. Voice (VOICEVOX) needs approval, never answered.
- Do not restructure the project from pasted layouts. One system per release.

## Build (no secrets here)
- Godot 4.3 stable Linux at ~/g/Godot_v4.3-stable_linux.x86_64, Android SDK at ~/and (ANDROID_HOME), project in ~/gp (same as godot-3d/ in the repo).
- Export: `ANDROID_HOME=~/and godot --headless --export-debug Android build/animelife.apk` (debug signing; package com.otakucoder.animelife; Compatibility renderer, 30 FPS, 1280x720 landscape).
- After adding assets run `godot --headless --import --path .` (new textures must be PNG; GLBs need dequantize).
- Screenshots: `xvfb-run -a -s "-screen 0 1280x720x24" godot --path . -- shot <hook>` writes /tmp/shot1.png (hooks: street, worldmap, districts, districtz, mapicons, mapapp...). Kill stray Godot processes after.
- Release script ~/rel.sh <ver> "<msg>": exports, copies source to the repo clone /tmp/repo (godot-3d/), tags v3d-<ver>, uploads the APK to GitHub releases. The GitHub token is in /tmp/tok.txt (not in the repo, never print or message it). If /tmp/tok.txt is gone, ask the parent for a new token; do not paste tokens in chat.
- Repo: github.com/otakucoderstudio/anime-life-game, folder godot-3d.

## Assets and licences (see docs/CREDITS.md)
VRoid CC0 characters, Kenney CC0 (cars, buildings), Poly Haven CC0 sky, 3DAssets.dev Izakaya CC0, fonts Tajawal and Cairo (SIL OFL, docs/OFL-Tajawal-Cairo.txt), Quaternius UAL CC0 (downloaded from quaternius.itch.io via "No thanks, just take me to the downloads", zip at /tmp/ual, may be gone, re-download).
Kept OUT of the public repo (APK only, must stay credited in game): Kobo skyline models (models/kobo), WAFU rain music (audio/music_rain.ogg), j-sounds files. rel.sh strips these.
Map art is own generated art. The user's concept images are NOT in the public repo; they live only in the private GDD File.

## GDD / references
Private GDD File (his 10 phases, map section, concept images): https://files.instinct.com/q5kndiaronrj (fileId file-01M8E84GWKPCSA4EFD9GCCGWDC), project source /downloads/gdd. docs/DESIGN_REFERENCES.md has his saved directions.

## Where things are in code
All in main.gd: street (build_street, street_details), phone, world map (build_worldmap, world_select), district map (build_districts, mv_* functions for zoom/LOD/icons/filter, mv_shibuya), nav bar (build_nav, nav_go).

## Known gaps
No real-device test; map places are display only; other districts and cities locked/generic; animations are still the VRoid defaults; pinch zoom untested on a phone.
