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
