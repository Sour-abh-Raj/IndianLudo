// Rules: legal moves over the SHARED pool, captures, extra turns, win.
// Pure Dart. No Flutter imports.
library;

import 'geometry.dart';
import 'types.dart';

/// Result of applying a move.
class ApplyResult {
  final bool extraTurn;
  final int captured;
  final bool won;
  const ApplyResult(
      {required this.extraTurn, required this.captured, required this.won});
}

/// Create a new game in the playing phase, player 0 to move.
GameState newGame(GameConfig config) {
  final houses = allocateHouses(config);
  return GameState(config, houses, freshTokens(houses), 0);
}

/// Legal moves for the current player given a shared-pool [roll] (1..N).
/// The pool is shared across ALL houses owned by the player: in 5+5 mode
/// one roll may move a token from either diagonal corner.
List<Move> legalMoves(GameState s, int roll) {
  final cfg = s.config;
  if (s.phase == Phase.finished) return [];
  if (roll < 1 || roll > cfg.sides) return [];
  final moves = <Move>[];
  for (final token in s.tokensOf(s.turnPlayer)) {
    final house = s.houses.firstWhere((h) => h.id == token.houseId);
    if (token.inYard) {
      if (roll == cfg.leaveFace) {
        final cell = absoluteCell(cfg, house, 0);
        moves.add(Move(
          player: s.turnPlayer,
          houseId: house.id,
          slot: token.slot,
          from: -1,
          to: 0,
          leavesYard: true,
          captured: _victims(s, cell),
        ));
      }
      continue;
    }
    if (token.isFinished(cfg)) continue;
    final to = token.progress + roll;
    if (to > cfg.finishProgress) continue; // exact roll to finish
    if (to == cfg.finishProgress) {
      moves.add(Move(
        player: s.turnPlayer,
        houseId: house.id,
        slot: token.slot,
        from: token.progress,
        to: to,
        isFinish: true,
      ));
      continue;
    }
    final cell = absoluteCell(cfg, house, to);
    moves.add(Move(
      player: s.turnPlayer,
      houseId: house.id,
      slot: token.slot,
      from: token.progress,
      to: to,
      captured: _victims(s, cell),
    ));
  }
  return moves;
}

/// Opponent tokens on ring [cell] that a landing token would capture.
/// Empty when the cell is safe, off-ring, or holds no opponents.
List<Token> _victims(GameState s, int cell) {
  if (cell < 0) return [];
  if (safeCells(s.config, s.houses).contains(cell)) return [];
  return s.tokens.where((t) {
    if (t.inYard || t.isFinished(s.config)) return false;
    final house = s.houses.firstWhere((h) => h.id == t.houseId);
    if (house.owner == s.turnPlayer) return false;
    return absoluteCell(s.config, house, t.progress) == cell;
  }).toList();
}

/// Apply [move] rolled with [roll]. Captures send victims to the yard.
/// Extra turn on the extra face; win when all the player's tokens finish.
ApplyResult applyMove(GameState s, Move move, int roll) {
  final cfg = s.config;
  final token = s.tokenAt(move.houseId, move.slot);
  token.progress = move.to;
  for (final v in move.captured) {
    v.progress = -1;
  }
  s.poolHistory.add(roll);
  final won = s.tokensOf(s.turnPlayer).every((t) => t.isFinished(cfg));
  final extra = roll == cfg.extraFace && !won;
  if (won) {
    s.phase = Phase.finished;
    s.winner = s.turnPlayer;
  } else if (!extra) {
    s.turnPlayer = (s.turnPlayer + 1) % cfg.playerCount;
  }
  return ApplyResult(
      extraTurn: extra, captured: move.captured.length, won: won);
}
