// Bots: easy (random) and normal (capture-preferring). Pure Dart.
library;

import 'dart:math';

import 'types.dart';

/// Easy bot: uniform random legal move. Returns null when no moves exist.
Move? chooseEasy(List<Move> moves, [Random? rng]) {
  if (moves.isEmpty) return null;
  return moves[(rng ?? Random()).nextInt(moves.length)];
}

/// Normal bot: capture > finish > leave yard > furthest-advanced token.
Move? chooseNormal(List<Move> moves) {
  if (moves.isEmpty) return null;
  final captures = moves.where((m) => m.isCapture).toList();
  if (captures.isNotEmpty) {
    captures.sort((a, b) => b.captured.length.compareTo(a.captured.length));
    return captures.first;
  }
  final finishes = moves.where((m) => m.isFinish).toList();
  if (finishes.isNotEmpty) return finishes.first;
  final leaves = moves.where((m) => m.leavesYard).toList();
  if (leaves.isNotEmpty) return leaves.first;
  final sorted = moves.toList()..sort((a, b) => b.to.compareTo(a.to));
  return sorted.first;
}
