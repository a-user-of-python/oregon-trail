# UI Brief — Oregon Trail iPad overhaul (2026-10-29)

Sean's verdict on v1: "pretty good for a first try, but it looks like a first try,
and the screen is squished." Reference: Gameloft's *The Oregon Trail*
(Apple Arcade, 2021) — mimic its **composition and UI language**, rendered in
**our own code-drawn pixel art** (Sean's art-direction call, same night).
No Gameloft assets, art, or text are used; everything is drawn in code.

## What the reference does (from screenshots + reviews)

1. **The scene is the screen.** The illustrated landscape fills the whole
   display edge-to-edge — layered sky, distant mountain silhouettes, rolling
   ground, foreground grass framing the bottom. The wagon sits in the world,
   not in a card. There is no scrolling column of boxes.
2. **HUD is a whisper, not a dashboard.** A small calendar chip top-left;
   a single row of compact icon+value stats top-right (pace, rations, food,
   money). Everything else is hidden until needed.
3. **Destination floats on the world.** "Fort Boise — 15 miles" sits directly
   on the scene at mid-left with a dotted-trail glyph, not in a panel.
4. **Party lives in a bottom strip.** Compact member chips pinned to the
   bottom edge: portrait, name, thin stat bars; the dead go grey with a
   tombstone mark. Always visible, never a cavernous card.
5. **Events arrive as a toast.** A single dark chip with a bright outline
   floats over the scene ("Hannah has Dysentery") — information without
   breaking the world.
6. **Decisions are journal moments.** Story/choice beats slow down into
   parchment-toned panels with serif display type — the "trail journal"
   register — while moment-to-moment play stays clean sans HUD.
7. **Palette is natural and warm.** Saturated sky gradients (golden hour,
   dusk violet), earthy greens and ochres, bright green accents reserved
   for interactive/important information.

## Our translation (pixel art rendering)

- **Rendering:** every visual is drawn on a coarse pixel grid in SwiftUI
  Canvas — chunky visible pixels, stepped silhouettes, banded skies with
  checker dithering, one disciplined palette (~28 colors) shared by scenes,
  sprites, map, and landmark art. Sprites (wagon, oxen, hunt animals,
  tombstone, avatars) are code-drawn on the same grid; wheels, legs, water,
  and weather animate in quantized steps, like real pixel art.
- **Composition:** Gameloft's layout grammar above, adapted to our screens:
  - *Travel:* full-bleed scene in landscape; tall hero scene in portrait.
    Date/weather chip top-left, compact stat chips top-right, destination +
    journey-progress floating on the scene, party chips as a bottom strip,
    pace/rations as refined segmented controls in a slim dock — no dead
    card space anywhere.
  - *Decision screens* (river, landmark, event, trade): scene/art hero on
    top, journal-parchment panel for the story text, choices as full-width
    decision cards (title + one-line consequence).
  - *Store:* a ledger — parchment rows, serif headings, prices and holdings
    in tabular alignment.
  - *Map:* a parchment journal page — ink-brown dashed route, pixel wagon
    marker, landmark list in ink on parchment.
- **Typography:** serif display (system serif — New York) for titles,
  landmark names, and journal headings; clean system sans for HUD values
  and body. All text uses Dynamic Type styles — natural proportions,
  nothing artificially inflated (Sean's standing calibration). Legibility
  comes from contrast: cream on deep green, ink-brown on parchment.
- **Surfaces:** deep-green translucent docks over the scene (blurred),
  parchment panels for journal content, amber for the primary action,
  sage for secondary. Corner radii tighten (10–12), hairline highlights
  instead of heavy borders.
- **Untouched:** game logic, balance, content, and the save format
  (`oregontrail.save`, Game's manual Codable) — presentation only.
