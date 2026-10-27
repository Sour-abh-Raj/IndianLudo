import 'package:flutter_test/flutter_test.dart';
import 'package:indian_ludo/game/bot.dart';
import 'package:indian_ludo/game/geometry.dart';
import 'package:indian_ludo/game/rules.dart';
import 'package:indian_ludo/game/types.dart';

void main() {
  group('leave yard', () {
    test('leave face opens a move from yard', () {
      final s = newGame(GameConfig(playerCount: 2, sides: 6));
      final moves = legalMoves(s, 6);
      expect(moves.length, 4);
      expect(moves.every((m) => m.leavesYard), isTrue);
    });
    test('non-leave roll with all in yard -> no moves', () {
      final s = newGame(GameConfig(playerCount: 2, sides: 6));
      expect(legalMoves(s, 3), isEmpty);
    });
    test('N=4: leave face is 4', () {
      final s = newGame(GameConfig(playerCount: 2, sides: 4));
      expect(legalMoves(s, 4).length, 4);
      expect(legalMoves(s, 6), isEmpty); // 6 out of range for N=4
    });
  });

  group('shared pool across owned houses (5+5)', () {
    test('one roll offers moves from both diagonal corners', () {
      final s = newGame(GameConfig(playerCount: 2, sides: 10));
      final moves = legalMoves(s, 6);
      expect(moves.length, 5);
      final houseIds = moves.map((m) => m.houseId).toSet();
      expect(houseIds.length, 2); // both P0 corners represented
    });
  });

  group('capture', () {
    test('landing on opponent on open cell captures', () {
      final s = newGame(GameConfig(playerCount: 2, sides: 6));
      // P1 token sits at absolute cell 1 (house 1 start 26, progress p:
      // (26+p)%78=1 -> p=53). Use progress directly via P0 landing cell.
      final p1 = s.tokenAt(1, 0);
      p1.progress = 53; // absolute (26+53)%78 = 1
      expect(absoluteCell(s.config, s.houses[1], 53), 1);
      final p0 = s.tokenAt(0, 0);
      p0.progress = 0; // absolute 0
      final moves = legalMoves(s, 1);
      final cap = moves.where((m) => m.isCapture);
      expect(cap.length, 1);
      final res = applyMove(s, cap.first, 1);
      expect(res.captured, 1);
      expect(s.tokenAt(1, 0).progress, -1); // sent home
    });

    test('safe cell blocks capture', () {
      final s = newGame(GameConfig(playerCount: 2, sides: 6));
      // P1 token on P0 start (cell 0, safe): (26+p)%78=0 -> p=52
      s.tokenAt(1, 0).progress = 52;
      final moves = legalMoves(s, 6); // leave-yard moves to cell 0
      expect(moves.every((m) => !m.isCapture), isTrue);
      applyMove(s, moves.first, 6);
      expect(s.tokenAt(1, 0).progress, 52); // survivor stays
    });
  });

  group('extra turns and win', () {
    test('extra face keeps the turn', () {
      final s = newGame(GameConfig(playerCount: 2, sides: 6));
      applyMove(s, legalMoves(s, 6).first, 6);
      expect(s.turnPlayer, 0);
      expect(s.poolHistory, [6]);
    });
    test('normal roll passes the turn', () {
      final s = newGame(GameConfig(playerCount: 2, sides: 6));
      s.tokenAt(0, 0).progress = 0;
      applyMove(s, legalMoves(s, 3).firstWhere((m) => !m.leavesYard), 3);
      expect(s.turnPlayer, 1);
    });
    test('exact roll to finish; overshoot illegal', () {
      final s = newGame(GameConfig(playerCount: 2, sides: 6));
      final fin = s.config.finishProgress;
      s.tokenAt(0, 0).progress = fin - 2;
      expect(legalMoves(s, 3).where((m) => m.slot == 0), isEmpty);
      final exact = legalMoves(s, 2).where((m) => m.slot == 0);
      expect(exact.length, 1);
      expect(exact.first.isFinish, isTrue);
    });
    test('all tokens home wins (4-token and 5-token modes)', () {
      for (final cfg in [
        GameConfig(playerCount: 4, sides: 6),
        GameConfig(playerCount: 2, sides: 10),
      ]) {
        final s = newGame(cfg);
        final mine = s.tokensOf(0);
        for (var i = 0; i < mine.length - 1; i++) {
          mine[i].progress = cfg.finishProgress;
        }
        mine.last.progress = cfg.finishProgress - 1;
        final mv =
            legalMoves(s, 1).firstWhere((m) => m.slot == mine.last.slot);
        final res = applyMove(s, mv, 1);
        expect(res.won, isTrue);
        expect(s.phase, Phase.finished);
        expect(s.winner, 0);
      }
    });
  });

  group('bots', () {
    test('easy returns null on empty, a move otherwise', () {
      expect(chooseEasy([]), isNull);
      final s = newGame(GameConfig(playerCount: 2, sides: 6));
      expect(chooseEasy(legalMoves(s, 6)), isNotNull);
    });
    test('normal prefers capture over other moves', () {
      final s = newGame(GameConfig(playerCount: 2, sides: 6));
      s.tokenAt(1, 0).progress = 53; // absolute cell 1
      s.tokenAt(0, 0).progress = 0;
      s.tokenAt(0, 1).progress = 10;
      final pick = chooseNormal(legalMoves(s, 1))!;
      expect(pick.isCapture, isTrue);
      expect(pick.slot, 0);
    });
  });
}
