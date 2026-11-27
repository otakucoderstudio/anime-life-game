# Anime Life: world roadmap (owner: Marwan)

Setting: Tokyo is the main city (decided 27 Nov 2026). UI stays in Egyptian Arabic. Names stay: هاروتو, ساكورا, كايتو, أياني, مومو. Slice of life only, no combat. Free tools and free hosting only.
Rule: any Japanese text on signs must be real, correct Japanese, or abstract shapes. No gibberish kana.

## Long-term vision ("a living anime world")
1. Tokyo city (now): Shibuya-style crossing, konbini, vending machines, ramen shop, bookstore, cafe, train station area, Tokyo Tower silhouette in the skyline.
2. Countryside: small rural villages with their own look, people and quests.
3. Train travel between areas (station hook, ride scene, fast travel).
4. City services: police and fire department as ambient life and small events.
5. Planes in the sky and other ambient traffic.
6. Keep adding "everything" a living world has, one small release at a time.

## Status
- Done: Tokyo rename (neighbourhood label Shibuya, Tokyo), Tokyo Tower silhouette, shop awnings, planters, golden-hour sky, painted-style portraits, rebuilt heroine, Ayani, Kaito.
- Next: konbini storefront, station area, crosswalk, real Japanese signs; then first countryside village plan and train station travel hook.
- Graphics track: painted-face shader, remaining NPC rebuilds, facade details.
- Platforms: Godot 3D Android APK (main release train) and a Unity port (parallel; Unity becomes main after the licence step, planned 27 Nov about 1 PM Cairo).

## Map plan: a huge connected Japan (owner request, 27 Nov 2026)
Goal: a full connected world that opens region by region (city, countryside, sea and more), like a whole Japan.
Design rules so new regions can attach later:
- World = a graph of regions. Each region is its own scene with named gates (edge exits, station platforms, ferry docks, road ends). A gate stores: target region, target gate, travel type (walk, train, ferry, bus).
- Tokyo is region 1 (hub). First attach points: Shibuya station (train lines out), city edge road (bus to the countryside), harbour (ferry to the sea and islands).
- Planned order: Tokyo hub, countryside village 1 (rice fields, shrine, small station), seaside town (port, beach, ferry), mountain onsen town (snow), a second big city (Kyoto style). Each opens by story progress or by a ticket bought with in-game money.
- Train map: one shared line list (name, stations, travel time). Adding a region = add a station plus a region scene, no change to existing regions.
- Region content budget for the Honor X6c: keep each region small, stream only the current one, and unload the previous one on travel.

## Parked ideas
- AI "talk freely" mode per character (live LLM chat in Egyptian Arabic, offline fallback to scripted lines). Parked by the owner on 27 Nov 2026. Research notes: Gemini free tier is the best free fit (about 500 requests/day per project, shared by all players); a key inside the APK can be extracted, so use a small free proxy. Do not build until the owner asks.
- Japanese voice acting (VOICEVOX) is in progress: sample approved pending; needs an on-screen VOICEVOX credit.

## Two tracks (updated 27 Nov, 8:30)
- Godot light version: stays optimized for weak phones (Honor X6c). Size and speed matter here.
- Unity full version: NO size budget. Maximum graphics: high-res textures, better lighting and shaders, heavier models. Free tools only still applies (Unity Personal, free licence, free assets).
- Unity art direction target: the anime look of Marwan's 11 reference images. Soft cinematic golden-hour light, bloom, big shiny eyes, MToon-style toon shading with outlines (UniVRM / lilToon, both free), 2K textures, baked lightmaps and light probes, post-processing (bloom, colour grading, depth of field, SSAO), URP. Characters: VRM models (VRoid CC0 base, higher-res textures, then custom VRoid Studio characters for the five main names). Buildings: Kenney/Quaternius kits (CC0) first, replaced with detailed Tokyo-style modular buildings.

## Asset policy
Free only. CC0 preferred, CC-BY with credit on the in-game credits screen. Licence checked per asset before import. Credits are listed in docs/CREDITS.md.
Sources checked so far: VRoid Studio CC0 models (https://vroid.pixiv.help/hc/en-us/articles/4402614652569), Kenney City Kit and Car Kit (CC0), Quaternius Ultimate Buildings (CC0). Note: VRoid AvatarSample A-C and A-Z are NOT CC0.

## Lessons from similar games
Sources: Sakura School Simulator store pages (App Store / Google Play), Persona calendar and social link write-ups (megatenwiki.com/wiki/Calendar, gamedeveloper.com Persona social link comparison), Animal Crossing research (dl.acm.org/doi/fullHtml/10.1145/3641237.3691689, clab.iat.sfu.ca/pubs/Tong-AnimalCrossing-CHIPLAY2021.pdf), Yandere Simulator wiki (yandere-simulator.fandom.com/wiki/Events).

| Priority | Idea | From | Cost on a weak phone |
|---|---|---|---|
| P1 | Day calendar with time slots (morning, lunch, after school, evening). Each activity uses a slot. Deadlines (exam, festival) shown on the calendar. | Persona | Almost free, it is UI and logic. |
| P1 | Social links: each friend (هاروتو, ساكورا, كايتو, أياني, مومو) has ranks 1-10. Spending a slot with them unlocks scenes, voice lines and small perks. | Persona | Free, data-driven. |
| P1 | NPC daily schedules: students are in class, cafeteria, street, home at set times. You learn where to find someone. | Yandere Simulator | Cheap if only a few NPCs are active at once. |
| P2 | Real-time-of-day light and weather, seasonal changes (sakura in spring), with the world changing little by little. | Animal Crossing | Light and sky only, cheap. |
| P2 | Comfort routines: daily small tasks, collecting items, home decoration, outfits (wardrobe). | Animal Crossing | Low if decor is a few props. |
| P2 | Open town with free movement plus small interactions: sit, ride a bike, enter shops, use a vending machine, change clothes. | Sakura School Simulator | Medium, keep NPC count low. Sakura School Simulator itself asks for 3 GB RAM or more on Android (Google Play page). |
| P3 | Reputation system: how people see you changes their lines. Only positive and social, no violence. | Yandere Simulator | Free. |
| P3 | Weekly "rival" or event story arc with a clear deadline (a friendly competition for class rep). | Yandere Simulator | Free, mostly writing. |
Left out on purpose: combat, stalking, killing and any dark mechanics (Marwan wants slice-of-life only).

## Physics pass (Godot, light)
Rule: feel first, cost second. A small custom simulation is used instead of full rigid bodies, so it stays smooth on a weak phone.
1. DONE (v0.76): solid props (vending machines push the player out), 16 kickable props (cans, cones, balls) with gravity, bounce, friction, rolling, and collisions with solids.
2. Next: more solid props (lamp posts, trees, bikes), props that tip over (bikes, bins), doors that swing.
3. Next: car physics (cars stop for the player, slow in turns, bump into props), a bike the player can ride.
4. Later: clothing and hair sway (spring bones on the VRM), ragdoll-free character bump.
5. Unity version: full PhysX rigid bodies, cloth, ragdoll-free but realistic vehicles, no budget limit.
