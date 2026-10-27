// Engine fuzz: full random games driven directly against GameState/rules.
// No UI. Invariants per step: token counts conserved, progress in range,
// finished tokens never move, winner has all tokens home, legalMoves never
// throws. Turn cap 5000 player-turns; non-termination fails. A "turn" is one
// player's turn: extra rolls stay inside the same turn (RULES §1–§2: the
// extra face "grants an extra roll", not a new turn). A 100k-roll tripwire
// guards against a degenerate same-player extra chain.
library;

import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:indian_ludo/game/rules.dart';
import 'package:indian_ludo/game/types.dart';

const int _turnCap = 5000;
const int _rollTripwire = 100000;
const List<int> _sidesSet = [2, 4, 5, 6, 10];
const List<int> _baseSeeds = [1, 7, 42];
const List<int> _diagonalSeeds = [1, 7, 42, 99, 1234];

String _key(int houseId, int slot) => '$houseId:$slot';

void _checkInvariants(GameState s, int expectedTotal, Set<String> wasFinished) {
  final cfg = s.config;
  expect(s.tokens.length, expectedTotal, reason: 'total tokens conserved');
  for (var p = 0; p < cfg.playerCount; p++) {
    expect(s.tokensOf(p).length, cfg.tokensForPlayer(p),
        reason: 'P$p token count conserved');
  }
  for (final t in s.tokens) {
    expect(t.progress >= -1 && t.progress <= cfg.finishProgress, isTrue,
        reason: 'token ${t.houseId}:${t.slot} progress ${t.progress} in range');
    if (wasFinished.contains(_key(t.houseId, t.slot))) {
      expect(t.progress, cfg.finishProgress,
          reason: 'finished token ${t.houseId}:${t.slot} never moves');
    }
  }
  expect(s.turnPlayer >= 0 && s.turnPlayer < cfg.playerCount, isTrue,
      reason: 'turn player in range');
  if (s.phase == Phase.finished) {
    expect(s.winner, isNotNull, reason: 'finished game has a winner');
    final home = cfg.isDiagonalPairMode ? 5 : 4;
    final wt = s.tokensOf(s.winner!);
    expect(wt.length, home, reason: 'winner token count');
    expect(wt.every((t) => t.progress == cfg.finishProgress), isTrue,
        reason: 'winner has all tokens home');
  }
}

void _checkMoveShapes(GameState s, List<Move> moves, int roll) {
  final cfg = s.config;
  final mine = s.tokensOf(s.turnPlayer);
  for (final m in moves) {
    expect(m.player, s.turnPlayer, reason: 'move belongs to roller');
    expect(
        mine.any((t) => t.houseId == m.houseId && t.slot == m.slot), isTrue,
        reason: 'move token owned by roller');
    final tok = s.tokenAt(m.houseId, m.slot);
    expect(m.from, tok.progress, reason: 'move from matches token');
    expect(tok.progress != cfg.finishProgress, isTrue,
        reason: 'no move offered from a finished token');
    if (m.leavesYard) {
      expect(m.from, -1, reason: 'leave starts in yard');
      expect(m.to, 0, reason: 'leave lands on progress 0');
      expect(roll, cfg.leaveFace, reason: 'leave needs leave face');
    } else {
      expect(m.to, m.from + roll, reason: 'advance equals roll');
      expect(m.to <= cfg.finishProgress, isTrue, reason: 'no overshoot');
    }
    if (m.isFinish) {
      expect(m.to, cfg.finishProgress, reason: 'finish lands exactly home');
    }
    for (final v in m.captured) {
      final owner =
          s.houses.firstWhere((h) => h.id == v.houseId).owner;
      expect(owner != s.turnPlayer, isTrue,
          reason: 'captures are opponents only');
      expect(v.inYard, isFalse, reason: 'victim was on track');
      expect(v.isFinished(cfg), isFalse, reason: 'victim was not finished');
    }
  }
}

void _runRandomGame(GameConfig cfg, int seed) {
  final tag = 'P=${cfg.playerCount} N=${cfg.sides} seed=$seed';
  final rng = Random(seed);
  final s = newGame(cfg);
  final expectedTotal = s.tokens.length;
  expect(expectedTotal,
      cfg.playerCount * (cfg.isDiagonalPairMode ? 5 : 4),
      reason: '$tag token plan');
  final finished = <String>{};
  var turns = 1; // player-turns elapsed; extra rolls do not open a new turn
  var lastRoller = s.turnPlayer;
  var rolls = 0;
  while (s.phase != Phase.finished && turns <= _turnCap) {
    if (rolls >= _rollTripwire) {
      fail('$tag exceeded $_rollTripwire rolls without finishing');
    }
    if (s.turnPlayer != lastRoller) {
      turns++;
      lastRoller = s.turnPlayer;
    }
    _checkInvariants(s, expectedTotal, finished);
    final roll = 1 + rng.nextInt(cfg.sides);
    late final List<Move> moves;
    try {
      moves = legalMoves(s, roll);
    } catch (e) {
      fail('$tag turn=$turns roll=$roll: legalMoves threw: $e');
    }
    if (rolls % 50 == 0) {
      // Full-face sweep incl. out-of-range rolls: must never throw,
      // out-of-range must yield no moves.
      for (var r = 0; r <= cfg.sides + 1; r++) {
        try {
          final m = legalMoves(s, r);
          if (r < 1 || r > cfg.sides) {
            expect(m, isEmpty, reason: '$tag roll=$r out of range');
          }
        } catch (e) {
          fail('$tag turn=$turns roll=$r: legalMoves threw: $e');
        }
      }
    }
    _checkMoveShapes(s, moves, roll);
    if (moves.isEmpty) {
      // No-move pass mirrors GameController.rollDice.
      s.poolHistory.add(roll);
      if (roll != cfg.extraFace) {
        s.turnPlayer = (s.turnPlayer + 1) % cfg.playerCount;
      }
    } else {
      applyMove(s, moves[rng.nextInt(moves.length)], roll);
    }
    for (final t in s.tokens) {
      if (t.progress == cfg.finishProgress) {
        finished.add(_key(t.houseId, t.slot));
      }
    }
    rolls++;
  }
  _checkInvariants(s, expectedTotal, finished);
  expect(s.phase, Phase.finished,
      reason: '$tag did not terminate in $_turnCap player-turns');
  expect(s.poolHistory.length, rolls, reason: '$tag history per roll');
}

void main() {
  group('fuzz full random games', () {
    for (var p = 2; p <= 10; p++) {
      for (final n in _sidesSet) {
        final seeds =
            (p == 2 && n == 10) ? _diagonalSeeds : _baseSeeds;
        for (final seed in seeds) {
          test('P=$p N=$n seed=$seed terminates, invariants hold', () {
            _runRandomGame(
                GameConfig(playerCount: p, sides: n), seed);
          });
        }
      }
    }
  });

  group('negative move-set cases', () {
    test('opponent tokens never offered to the roller', () {
      final s = newGame(GameConfig(playerCount: 2, sides: 6));
      s.tokenAt(1, 0).progress = 5; // opponent movable
      s.tokenAt(0, 0).progress = 5; // self movable
      for (var roll = 1; roll <= 6; roll++) {
        for (final m in legalMoves(s, roll)) {
          expect(m.player, 0);
          final owner =
              s.houses.firstWhere((h) => h.id == m.houseId).owner;
          expect(owner, 0, reason: 'roll=$roll move on own token');
        }
      }
      // Only the opponent is movable and self is fully yarded: empty set.
      final s2 = newGame(GameConfig(playerCount: 2, sides: 6));
      s2.tokenAt(1, 0).progress = 5;
      expect(legalMoves(s2, 3), isEmpty);
    });

    test('overshoot absent, exact finish present', () {
      for (final n in _sidesSet) {
        final cfg = GameConfig(playerCount: 2, sides: n);
        final fin = cfg.finishProgress;
        final s = newGame(cfg);
        s.tokenAt(0, 0).progress = fin - 1;
        for (var roll = 2; roll <= n; roll++) {
          final bad = legalMoves(s, roll)
              .where((m) => m.houseId == 0 && m.slot == 0);
          expect(bad, isEmpty, reason: 'N=$n roll=$roll overshoot');
        }
        final exact = legalMoves(s, 1)
            .where((m) => m.houseId == 0 && m.slot == 0);
        expect(exact.length, 1, reason: 'N=$n exact finish exists');
        expect(exact.first.isFinish, isTrue);
      }
    });

    test('yard leave requires the leave face', () {
      for (final n in _sidesSet) {
        final cfg = GameConfig(playerCount: 4, sides: n);
        for (var roll = 1; roll <= n; roll++) {
          final s = newGame(cfg);
          final moves = legalMoves(s, roll);
          if (roll == cfg.leaveFace) {
            expect(moves.length, 4, reason: 'N=$n leave opens 4');
            expect(moves.every((m) => m.leavesYard), isTrue);
          } else {
            expect(moves, isEmpty, reason: 'N=$n roll=$roll no leave');
          }
        }
      }
    });

    test('finished token absent from the legal set', () {
      for (final n in _sidesSet) {
        final cfg = GameConfig(playerCount: 3, sides: n);
        final s = newGame(cfg);
        s.tokenAt(0, 0).progress = cfg.finishProgress;
        s.tokenAt(0, 1).progress = 0; // keep the set non-empty at times
        for (var roll = 1; roll <= n; roll++) {
          final bad = legalMoves(s, roll)
              .where((m) => m.houseId == 0 && m.slot == 0);
          expect(bad, isEmpty, reason: 'N=$n roll=$roll finished moved');
        }
      }
    });

    test('finished game offers no moves', () {
      final cfg = GameConfig(playerCount: 2, sides: 6);
      final s = newGame(cfg);
      final mine = s.tokensOf(0);
      for (var i = 0; i < mine.length - 1; i++) {
        mine[i].progress = cfg.finishProgress;
      }
      mine.last.progress = cfg.finishProgress - 1;
      final mv = legalMoves(s, 1)
          .firstWhere((m) => m.slot == mine.last.slot);
      final res = applyMove(s, mv, 1);
      expect(res.won, isTrue);
      for (var roll = 1; roll <= cfg.sides; roll++) {
        expect(legalMoves(s, roll), isEmpty);
      }
    });
  });
}
