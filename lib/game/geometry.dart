// Board geometry: N-sided ring, start offsets, safe cells, house allocation.
// Pure Dart. No Flutter imports.
library;

import 'types.dart';

/// Corner entries on the classic 13-grid, wrapped to this ring and spread
/// apart when small rings would collide (e.g. 2 players on a 2-sided ring,
/// where corner 2's classic offset 26 wraps onto corner 0's 0). Classic
/// configs keep their exact offsets; only colliding entries move.
List<int> _spreadOffsets(GameConfig cfg, List<int> corners) {
  final used = <int>{};
  final step =
      (cfg.ringCells / corners.length).floor().clamp(1, cfg.ringCells);
  return corners.map((c) {
    var o = (c * 13) % cfg.ringCells;
    while (used.contains(o)) {
      o = (o + step) % cfg.ringCells;
    }
    used.add(o);
    return o;
  }).toList();
}

/// Allocate houses per RULES §4–§5. Returns houses with unique ids.
List<House> allocateHouses(GameConfig cfg) {
  final p = cfg.playerCount;
  if (cfg.isDiagonalPairMode) {
    // P1: NW(0)+SE(2) slot-mapped 3+2; P2: NE(1)+SW(3) slot-mapped 3+2.
    final offs = _spreadOffsets(cfg, [0, 2, 1, 3]);
    return [
      House(id: 0, owner: 0, corner: 0, startOffset: offs[0], slots: 3),
      House(id: 1, owner: 0, corner: 2, startOffset: offs[1], slots: 2),
      House(id: 2, owner: 1, corner: 1, startOffset: offs[2], slots: 3),
      House(id: 3, owner: 1, corner: 3, startOffset: offs[3], slots: 2),
    ];
  }
  if (p == 2) {
    final offs = _spreadOffsets(cfg, [0, 2]);
    return [
      House(id: 0, owner: 0, corner: 0, startOffset: offs[0], slots: 4),
      House(id: 1, owner: 1, corner: 2, startOffset: offs[1], slots: 4),
    ];
  }
  if (p == 3) {
    // Every other corner pattern; 4th corner stays empty.
    final offs = _spreadOffsets(cfg, [0, 1, 2]);
    return [0, 1, 2]
        .map((c) => House(
            id: c, owner: c, corner: c, startOffset: offs[c], slots: 4))
        .toList();
  }
  if (p == 4) {
    final offs = _spreadOffsets(cfg, [0, 1, 2, 3]);
    return [0, 1, 2, 3]
        .map((c) => House(
            id: c, owner: c, corner: c, startOffset: offs[c], slots: 4))
        .toList();
  }
  // 5..10 players: each owns one house; colors cycle over 4 corners;
  // start offsets spread evenly so every house has a distinct ring entry.
  return List.generate(
    p,
    (i) => House(
      id: i,
      owner: i,
      corner: i % 4,
      startOffset: (i * cfg.ringCells / p).floor() % cfg.ringCells,
      slots: 4,
    ),
  );
}

/// Absolute ring cell for a token progress, or -1 when off the ring.
int absoluteCell(GameConfig cfg, House house, int progress) {
  if (progress < 0 || progress >= cfg.ringSteps) return -1;
  return (house.startOffset + progress) % cfg.ringCells;
}

/// Safe cells: every house start + the classic star 8 steps past each
/// corner start. Tokens here cannot be captured.
Set<int> safeCells(GameConfig cfg, List<House> houses) {
  final safe = <int>{};
  for (final h in houses) {
    safe.add(h.startOffset % cfg.ringCells);
    safe.add((h.startOffset + 8) % cfg.ringCells);
  }
  return safe;
}

/// Build a fresh token list for the given houses (all in yard).
List<Token> freshTokens(List<House> houses) => [
      for (final h in houses)
        for (var s = 0; s < h.slots; s++)
          Token(houseId: h.id, slot: s),
    ];
