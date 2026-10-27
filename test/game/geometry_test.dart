import 'package:flutter_test/flutter_test.dart';
import 'package:indian_ludo/game/geometry.dart';
import 'package:indian_ludo/game/types.dart';

void main() {
  group('ring scaling', () {
    for (final n in [2, 4, 5, 6, 10]) {
      test('N=$n -> ring cells ${13 * n}', () {
        final cfg = GameConfig(playerCount: 4, sides: n);
        expect(cfg.ringCells, 13 * n);
        expect(cfg.homeSteps, 6);
        expect(cfg.finishProgress, 13 * n - 1 + 6);
      });
    }
  });

  group('extra/leave faces', () {
    test('N>=6 uses 6', () {
      final cfg = GameConfig(playerCount: 2, sides: 6);
      expect(cfg.extraFace, 6);
      expect(cfg.leaveFace, 6);
    });
    test('N<6 uses N', () {
      final cfg = GameConfig(playerCount: 2, sides: 4);
      expect(cfg.extraFace, 4);
      expect(cfg.leaveFace, 4);
    });
  });

  group('allocation', () {
    test('2p N=6: opposite corners', () {
      final houses =
          allocateHouses(GameConfig(playerCount: 2, sides: 6));
      expect(houses.length, 2);
      expect(houses[0].corner, 0);
      expect(houses[1].corner, 2);
      expect(houses[0].startOffset, 0);
      expect(houses[1].startOffset, 26);
    });

    test('2p N=10: 5+5 diagonal pairs slot-mapped 3+2', () {
      final cfg = GameConfig(playerCount: 2, sides: 10);
      expect(cfg.isDiagonalPairMode, isTrue);
      final houses = allocateHouses(cfg);
      expect(houses.length, 4);
      final p0 = houses.where((h) => h.owner == 0).toList();
      final p1 = houses.where((h) => h.owner == 1).toList();
      expect(p0.map((h) => h.corner), [0, 2]); // NW+SE
      expect(p1.map((h) => h.corner), [1, 3]); // NE+SW
      expect(p0.map((h) => h.slots), [3, 2]);
      expect(p1.map((h) => h.slots), [3, 2]);
      expect(freshTokens(houses).length, 10);
    });

    test('3p: three corners, 4th empty', () {
      final houses =
          allocateHouses(GameConfig(playerCount: 3, sides: 6));
      expect(houses.map((h) => h.corner), [0, 1, 2]);
    });

    test('4p: one corner each', () {
      final houses =
          allocateHouses(GameConfig(playerCount: 4, sides: 6));
      expect(houses.map((h) => h.corner), [0, 1, 2, 3]);
    });

    test('small rings: 2p/3p/4p entries stay distinct', () {
      for (final sides in [2, 3, 4]) {
        for (final p in [2, 3, 4]) {
          final cfg = GameConfig(playerCount: p, sides: sides);
          final houses = allocateHouses(cfg);
          final offsets = houses.map((h) => h.startOffset).toSet();
          expect(offsets.length, houses.length,
              reason: 'P=$p N=$sides distinct entries');
        }
      }
    });

    test('2p N=2: entries truly opposite on the 26-ring', () {
      final houses = allocateHouses(GameConfig(playerCount: 2, sides: 2));
      expect(houses.map((h) => h.startOffset).toSet(), {0, 13});
    });

    test('classic 4-side entries unchanged', () {
      final houses = allocateHouses(GameConfig(playerCount: 4, sides: 4));
      expect(houses.map((h) => h.startOffset), [0, 13, 26, 39]);
    });

    test('5..10p: distinct offsets, colors cycle', () {
      for (var p = 5; p <= 10; p++) {
        final cfg = GameConfig(playerCount: p, sides: 6);
        final houses = allocateHouses(cfg);
        expect(houses.length, p);
        final offsets = houses.map((h) => h.startOffset).toSet();
        expect(offsets.length, p, reason: 'P=$p distinct entries');
        expect(houses[4].corner, 0); // color cycle
      }
    });
  });

  group('safe cells', () {
    test('starts and +8 stars are safe', () {
      final cfg = GameConfig(playerCount: 4, sides: 6);
      final houses = allocateHouses(cfg);
      final safe = safeCells(cfg, houses);
      for (final h in houses) {
        expect(safe.contains(h.startOffset), isTrue);
        expect(safe.contains((h.startOffset + 8) % cfg.ringCells), isTrue);
      }
    });
  });

  test('absoluteCell wraps around ring', () {
    final cfg = GameConfig(playerCount: 4, sides: 2); // ring = 26
    final houses = allocateHouses(cfg);
    // corner 1 starts at 13; progress 20 -> (13+20) % 26 = 7
    expect(absoluteCell(cfg, houses[1], 20), 7);
    expect(absoluteCell(cfg, houses[0], -1), -1);
    expect(absoluteCell(cfg, houses[0], cfg.ringSteps), -1);
  });
}
