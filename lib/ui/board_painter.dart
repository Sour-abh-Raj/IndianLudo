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
    final c = layout.center;
    final rimR = layout.radius + 24;

    // Drop shadow under the physical board.
    canvas.drawCircle(
      c + const Offset(0, 6),
      rimR,
      Paint()..color = Colors.black.withValues(alpha: 0.35),
    );

    // Wooden rim: dark outer edge, wood band, inner bevel.
    canvas.drawCircle(c, rimR, Paint()..color = LudoColors.woodDark);
    canvas.drawCircle(
        c, rimR - 5, Paint()..color = LudoColors.wood);
    // Wood grain: faint concentric arcs (deterministic, golden-safe).
    final grain = Paint()
      ..color = LudoColors.woodDark.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    for (var i = 0; i < 3; i++) {
      final rr = rimR - 9 - i * 5;
      canvas.drawArc(Rect.fromCircle(center: c, radius: rr),
          math.pi * (0.15 + 0.5 * i), math.pi * 1.2, false, grain);
    }
    canvas.drawCircle(
        c,
        rimR - 22,
        Paint()
          ..color = LudoColors.woodDark
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2);

    // Ivory board face.
    canvas.drawCircle(c, rimR - 24, Paint()..color = LudoColors.ivory);

    // Ring cells: inset ivory wells with wood-tone borders.
    for (var cell = 0; cell < cfg.ringCells; cell++) {
      final p = layout.ringCell(cell);
      final isSafe = safe.contains(cell);
      canvas.drawCircle(
        p + const Offset(0, 1),
        layout.cellRadius,
        Paint()..color = Colors.black.withValues(alpha: 0.12),
      );
      canvas.drawCircle(
        p,
        layout.cellRadius,
        Paint()
          ..color = isSafe
              ? LudoColors.gold.withValues(alpha: 0.55)
              : LudoColors.cellInset
          ..style = PaintingStyle.fill,
      );
      canvas.drawCircle(
        p,
        layout.cellRadius,
        Paint()
          ..color =
              isSafe ? LudoColors.woodDark : LudoColors.cellEdge
          ..style = PaintingStyle.stroke
          ..strokeWidth = isSafe ? 2 : 1,
      );
      if (isSafe) {
        final tp = TextPainter(
          text: const TextSpan(
              text: '★',
              style: TextStyle(fontSize: 11, color: LudoColors.woodDark)),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, p - Offset(tp.width / 2, tp.height / 2));
      }
    }

    // Home columns: house-color wells deepening toward the center.
    for (final house in state.houses) {
      final color = LudoColors.house(house.corner);
      for (var k = 0; k < cfg.homeSteps; k++) {
        final p = layout.homeCell(house, cfg.ringSteps + k, cfg);
        canvas.drawCircle(
          p,
          layout.cellRadius * 0.8,
          Paint()
            ..color = color.withValues(alpha: 0.3 + 0.12 * k)
            ..style = PaintingStyle.fill,
        );
        canvas.drawCircle(
          p,
          layout.cellRadius * 0.8,
          Paint()
            ..color = LudoColors.houseDark(house.corner)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1,
        );
      }
      // Yard pocket: recessed house-color disc (diagonal-pair cue).
      final yard = layout.yardSlot(house, 0);
      canvas.drawCircle(
          yard + const Offset(0, 1.5),
          24,
          Paint()..color = Colors.black.withValues(alpha: 0.15));
      canvas.drawCircle(
          yard, 24, Paint()..color = color.withValues(alpha: 0.28));
      canvas.drawCircle(
        yard,
        24,
        Paint()
          ..color = LudoColors.houseDark(house.corner)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }

    // Center medallion.
    canvas.drawCircle(
        c, 20, Paint()..color = LudoColors.gold.withValues(alpha: 0.5));
    canvas.drawCircle(
      c,
      20,
      Paint()
        ..color = LudoColors.woodDark
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Tokens: glossy wooden pawns (shadow + body + top highlight + ring).
    var finishedIndex = 0;
    for (final token in state.tokens) {
      final house = state.houses.firstWhere((h) => h.id == token.houseId);
      final key = '${token.houseId}:${token.slot}';
      final isHighlight = highlightKeys.contains(key);
      final p = layout.tokenPos(cfg, house, token,
          token.isFinished(cfg) ? finishedIndex++ : 0);
      final color = LudoColors.house(house.corner);
      final dark = LudoColors.houseDark(house.corner);
      final r = layout.cellRadius + 3;
      if (isHighlight) {
        // Unmissable legal-move halo: gold outer + pulsing white inner.
        canvas.drawCircle(
          p,
          r + 6 + 3 * pulse,
          Paint()
            ..color = LudoColors.gold
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3.5,
        );
        canvas.drawCircle(
          p,
          r + 2.5,
          Paint()
            ..color = Colors.white.withValues(alpha: 0.85)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5,
        );
      }
      canvas.drawCircle(
        p + Offset(0, r * 0.35),
        r,
        Paint()..color = Colors.black.withValues(alpha: 0.3),
      );
      canvas.drawCircle(p, r, Paint()..color = dark);
      canvas.drawCircle(p, r - 1.5, Paint()..color = color);
      // Glossy top-light.
      canvas.drawCircle(
        p + Offset(-r * 0.3, -r * 0.35),
        r * 0.38,
        Paint()..color = Colors.white.withValues(alpha: 0.55),
      );
      canvas.drawCircle(
        p,
        r,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.9)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }
  }

  @override
  bool shouldRepaint(covariant BoardPainter old) =>
      old.state != state ||
      old.highlightKeys != highlightKeys ||
      old.pulse != pulse;
}
