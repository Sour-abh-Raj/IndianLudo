# indianLudo v1 — Design

## Tokens
- Houses: P1 red `#E53935`, P2 green `#43A047`, P3 yellow `#FBC02D`,
  P4 blue `#1E88E5`; extras cycle. Text ink `#212121`.
- Materials: felt table `#1B5E43` (edge `#12402E`), wooden rim
  `#8D5A2B`/`#5D3A17`, ivory face `#FFF6E3`, track wells `#F3E7C8`,
  gold accents `#FFC107`, ivory die `#FFFFFA`.
- Type: display 28/bold, title 20/600, body 14, caption 12.
- Spacing 8pt grid; radius 12 cards, 8 buttons; elevation 4.

## Screens
1. Home: token row on felt, gold Play Local / tonal Online /
   outlined How to Play.
2. Setup: ivory cards on felt (steppers, toggles), gold Start button.
3. Board: slim top strip (quit + Calm toggle), full-house-color turn
   banner, wooden board canvas, pool strip (gold = latest), ivory die
   + full-width gold ROLL button, white state hint, capture toasts.
4. Result: gold winner banner, ivory standings cards, Play Again /
   Home.

## Board language
Physical tabletop: felt backdrop, wooden rim with grain arcs, ivory
face, inset track wells, gold safe stars, house-color home wells
deepening toward a gold center medallion. Yard pockets are recessed
house-color discs (diagonal-pair cue in 2p-10side mode). Tokens are
glossy pawns: drop shadow, dark edge, color body, top-light gloss.
Legal moves get an unmissable gold halo + white inner ring with pulse.
Die shows gold rim + glow once rolled; Roll button reads ROLL (dN) /
ROLLED n. Layout math (BoardLayout) unchanged so taps match paint.
