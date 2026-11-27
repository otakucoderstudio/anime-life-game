# Handoff (anime-life-game, godot-3d)

Updated 2026-11-27 15:58 (Cairo), FINAL from the previous agent. Latest tag: **v3d-1.26** (1.12 to 1.21 Osaka, Shibuya Kobo rebuild, Sendai, Kyoto, Hiroshima, Okinawa, Nagasaki, loading screen; 1.22 phone home screen; 1.23 Kyoto trees; 1.25 wall collision fix in all zones; 1.26 trucks, motorcycles, speed bumps). APK on GitHub releases only. Only ONE agent publishes a tag at a time; the successor first reproduces the build, then asks the parent (main agent) before tagging.

## Current priority (user decisions, approved order)
Done from the approved order: zones (all 7 cities), phone home screen, trees in Kyoto only, vehicles (1.26). NEXT in order: 1) full icon set for the phone (calendar, weather, music, bank, skills, relationships, dock), 2) seasons and falling leaves, trees in other zones, 3) rooms with Quaternius Furniture Pack (CC0, download from the original source, credit in docs/CREDITS.md and Settings credits), 4) station and school (plus transport), 5) house build with workers, house food/water/lights, sewage/drainage. Then pets/animals, economy icons, Quaternius UAL animation retarget (better walking), hobbies, skills/relationships UI, ambience sounds, character creator, Settings credits clip fix, Shibuya far-end whitening, ride cars, day/night visibility check in city zones.
Owner wishlist 15:43 (all unstarted): trucks, motorcycles, speed bumps (DONE 1.26 simple), build a house with workers, house food/water/lights, sewage/drainage, animals, villas, private housing, libraries, restaurants/hospitals/centers, farms, "reduce housing" (unclear, ask him), day/night in graphics, better quality and graphics, ride cars, better walking animation.
Bug fixed 1.25: player walked through building walls in city zones (reg_walls/push_walls in main.gd). Re-check if he reports another place.
Reports to the user go through the parent as screenshot plus APK link plus honest limits and untested items (he asked for downloads at 13:57). WhatsApp has a daily limit; the parent may deliver late.

## Rules
- Free tools/hosting only. No signups or paid items without the user's explicit yes (ask the parent).
- UI in Egyptian Arabic, Japanese names in Arabic script, slice of life, no combat.
- Target phone Honor X6c (Helio G81 Ultra): first real-device report (owner, 2026-11-27, APK 1.19): takes a short while to load, then runs normally, no crash reported. Save, close and reopen: owner answered "yep" (progress kept; informal, one word, not a detailed test). Also reported running "very good" on an OPPO A15 (low-end phone, owner's word, no FPS or graphics-level details): keep the low graphics level and auto fallback working. Real FPS numbers still unmeasured. Keep load time in mind: add a loading screen and lazy loading where cheap (zones are built on first entry).
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
VRoid CC0 characters, Kenney CC0 (cars, buildings), Poly Haven CC0 sky, 3DAssets.dev Izakaya CC0, fonts Tajawal and Cairo (SIL OFL, docs/OFL-Tajawal-Cairo.txt), Shuriken Japanese Town kit (free, models not to be redistributed alone, credit in CREDITS.md; models/shuriken stripped from repo too), Quaternius UAL CC0 (downloaded from quaternius.itch.io via "No thanks, just take me to the downloads", zip at /tmp/ual, may be gone, re-download).
Kept OUT of the public repo (APK only, must stay credited in game): Kobo skyline models (models/kobo), Shuriken models (models/shuriken), WAFU rain music (audio/music_rain.ogg), j-sounds files. rel.sh strips these.
Map art is own generated art. The user's concept images are NOT in the public repo; they live only in the private GDD File.

## GDD / references
Private GDD File (his 10 phases, map section, concept images): https://files.instinct.com/q5kndiaronrj (fileId file-01M8E84GWKPCSA4EFD9GCCGWDC), project source /downloads/gdd. docs/DESIGN_REFERENCES.md has his saved directions.

## Where things are in code
All in main.gd: street (build_street, street_details), phone, world map (build_worldmap, world_select), district map (build_districts, mv_* functions for zoom/LOD/icons/filter, mv_shibuya), nav bar (build_nav, nav_go).

## Known gaps
Real-device facts are informal (owner: Honor X6c loads slowly then runs, save kept; OPPO A15 'very good'); FPS never measured. Trees only in Kyoto, no seasons, vehicles are simple own blocks and only on Shibuya main street, map places display only, animations are VRoid defaults, loading time on low-end phones is a to-do. Zones are honest small first versions. No tint on buildings. Street props (benches, bins, signals) only when he says go.

## Backlog (owner wishlist 15:43, not started)
1 trucks, 2 motorcycles (both in vehicles step), 3 build a house with workers, 4 house food/water/lights, 5 sewage/drainage, 6 speed bumps. Order stays as approved; 3-5 come after rooms.

## Backlog 2 (owner wishlist 15:43, not started)
animals, villas, residential, libraries, restaurants/hospitals/centers, farms, "reduce housing" (unclear), day/night visibility check, better graphics, ride cars, better walk animation.
## Fix 1.25
Wall collision: reg_walls() registers footprints of instanced building models per zone, push_walls() keeps the player out. Shibuya main street uses walk_rects.

## Release script ~/rel.sh (secrets removed; recreate if lost)
Steps: (1) cd ~/gp; ANDROID_HOME=~/and godot --headless --export-debug Android build/animelife.apk; copy to /tmp/AnimeLife-<ver>.apk. (2) In the clone /tmp/repo (git clone of the repo): git pull; rm -rf godot-3d; copy ~/gp to godot-3d; delete .godot, build and all *.import; delete models/kobo, models/shuriken, audio/music_rain.ogg*; copy Blender scripts ~/bld/*.py to godot-3d/blender. (3) git add, commit "Source for v3d-<ver>: <msg>", push. (4) Create the GitHub release v3d-<ver> on that commit through the GitHub API with the token from /tmp/tok.txt, then upload the APK as an asset. (5) Verify: ls /tmp/repo/godot-3d/models | grep -c "shuriken\|kobo" must print 0.
A new agent needs: a GitHub token with write access to otakucoderstudio/anime-life-game (ask the parent, never paste in chat or the repo), Godot 4.3 stable Linux + Android export templates + Android SDK/debug keystore (re-download from the official Godot site, free), and the Kobo/Shuriken/WAFU files, which are NOT in the repo: if the sandbox is gone they must be re-downloaded from the original free sources (links and licences in docs/CREDITS.md) or the APK source models must be taken from the v3d-1.26 release APK.
Do not sign in to Adobe. Do not create accounts without the owner's explicit yes.
