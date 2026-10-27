import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../game/geometry.dart';
import '../game/types.dart';
import 'theme.dart';

/// Shared layout: ring cells spread around a rounded N-gon, corners at the
/// four diagonals. Pure function so tap detection matches painting exactly.
class BoardLayout {
  final Size size;
  final GameConfig config;
  late final Offset center = Offset(size.width / 2, size.height / 2);
  late final double radius = math.min(size.width, size.height) / 2 - 28;

  BoardLayout(this.size, this.config);

  /// Center of ring cell [cell] on the circle.
  Offset ringCell(int cell) {
    final n = config.ringCells;
    final a = -math.pi / 2 + 2 * math.pi * cell / n;
    return center + Offset(math.cos(a), math.sin(a)) * radius;
  }

  double get cellRadius =>
      (2 * math.pi * radius / config.ringCells / 2).clamp(4.0, 14.0);

  /// Yard slot anchor for [house] slot [slot]: corner pockets.
  Offset yardSlot(House house, int slot) {
    final c = house.corner % 4;
    final dx = (c == 0 || c == 3) ? -1 : 1;
    final dy = (c == 0 || c == 1) ? -1 : 1;
    final base = center +
        Offset(dx * radius * 1.18, dy * radius * 1.18) * 0.62;
    const off = 13.0;
    return base +
        Offset((slot % 2 == 0 ? -1 : 1) * off, (slot < 2 ? -1 : 1) * off);
  }

  /// Home-stretch cell: progress ringSteps+k walks toward the center along
  /// the house's start spoke.
  Offset homeCell(House house, int progress, GameConfig cfg) {
    final k = progress - cfg.ringSteps; // 0..homeSteps-1
    final start = ringCell(house.startOffset % cfg.ringCells);
    final dir = (center - start);
    final t = (k + 1) / (cfg.homeSteps + 1);
    return start + dir * t;
  }

  /// Finished tokens stack at the center, offset per token.
  Offset finishedSpot(int index) {
    const off = 11.0;
    return center + Offset((index % 4 - 1.5) * off, (index ~/ 4 - 0.5) * off);
  }

  /// Screen position of a token.
  Offset tokenPos(GameConfig cfg, House house, Token token, int stackIndex) {
    if (token.inYard) return yardSlot(house, token.slot);
    if (token.isFinished(cfg)) return finishedSpot(stackIndex);
    if (token.isOnRing(cfg)) {
      return ringCell(absoluteCell(cfg, house, token.progress));
    }
    return homeCell(house, token.progress, cfg);
  }
}

class BoardPainter extends CustomPainter {
  final GameState state;
  final Set<String> highlightKeys; // "$houseId:$slot" legal-move tokens
  final double pulse; // 0..1 active-token pulse phase

  BoardPainter(
      {required this.state, this.highlightKeys = const {}, this.pulse = 0});

  @override
  void paint(Canvas canvas, Size size) {
    final cfg = state.config;
    final layout = BoardLayout(size, cfg);
    final safe = safeCells(cfg, state.houses);

    // Board disc.
    canvas.drawCircle(
      layout.center,
      layout.radius + 24,
      Paint()..color = LudoColors.track,
    );

    // Ring cells.
    for (var cell = 0; cell < cfg.ringCells; cell++) {
      final p = layout.ringCell(cell);
      final isSafe = safe.contains(cell);
      canvas.drawCircle(
        p,
        layout.cellRadius,
        Paint()
          ..color = isSafe ? LudoColors.safeStar.withValues(alpha: 0.45) : LudoColors.cream
          ..style = PaintingStyle.fill,
      );
      canvas.drawCircle(
        p,
        layout.cellRadius,
        Paint()
          ..color = Colors.brown.shade200
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
      if (isSafe) {
        final tp = TextPainter(
          text: const TextSpan(text: '★', style: TextStyle(fontSize: 10)),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, p - Offset(tp.width / 2, tp.height / 2));
      }
    }

    // Home columns: spoke from each house start toward center.
    for (final house in state.houses) {
      final color = LudoColors.house(house.corner);
      for (var k = 0; k < cfg.homeSteps; k++) {
        final p = layout.homeCell(house, cfg.ringSteps + k, cfg);
        canvas.drawCircle(
          p,
          layout.cellRadius * 0.8,
          Paint()
            ..color = color.withValues(alpha: 0.25 + 0.1 * k)
            ..style = PaintingStyle.fill,
        );
      }
      // Corner badge (diagonal-pair cue in 2p-10side mode).
      final yard = layout.yardSlot(house, 0);
      canvas.drawCircle(yard, 22, Paint()..color = color.withValues(alpha: 0.18));
    }

    // Tokens: flat discs with white ring; active pulse on legal moves.
    var finishedIndex = 0;
    for (final token in state.tokens) {
      final house = state.houses.firstWhere((h) => h.id == token.houseId);
      final key = '${token.houseId}:${token.slot}';
      final isHighlight = highlightKeys.contains(key);
      final p = layout.tokenPos(cfg, house, token,
          token.isFinished(cfg) ? finishedIndex++ : 0);
      final color = LudoColors.house(house.corner);
      final r = layout.cellRadius + 3;
      if (isHighlight) {
        canvas.drawCircle(
          p,
          r + 4 + 3 * pulse,
          Paint()
            ..color = color.withValues(alpha: 0.5)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3,
        );
      }
      canvas.drawCircle(p, r, Paint()..color = color);
      canvas.drawCircle(
        p,
        r,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
  }

  @override
  bool shouldRepaint(covariant BoardPainter old) =>
      old.state != state ||
      old.highlightKeys != highlightKeys ||
      old.pulse != pulse;
}
