import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'theme.dart';

/// N-sided die with a pop/shake animation. Static when [reducedMotion].
class DiceWidget extends StatefulWidget {
  final int sides;
  final int? value;
  final bool rolling;
  final bool reducedMotion;

  const DiceWidget({
    super.key,
    required this.sides,
    required this.value,
    required this.rolling,
    required this.reducedMotion,
  });

  @override
  State<DiceWidget> createState() => _DiceWidgetState();
}

class _DiceWidgetState extends State<DiceWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 450));
  }

  @override
  void didUpdateWidget(covariant DiceWidget old) {
    super.didUpdateWidget(old);
    if (widget.rolling && !old.rolling && !widget.reducedMotion) {
      _ctrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final face = widget.value?.toString() ?? '–';
    final rolled = widget.value != null;
    final box = Container(
      width: 72,
      height: 72,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        // Ivory die with a wood-tone edge; gold rim once rolled.
        color: LudoColors.diceFace,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: rolled ? LudoColors.gold : LudoColors.woodDark,
            width: rolled ? 3 : 2),
        boxShadow: [
          const BoxShadow(
              blurRadius: 6, offset: Offset(0, 3), color: Colors.black45),
          if (rolled)
            BoxShadow(
                blurRadius: 12,
                color: LudoColors.gold.withValues(alpha: 0.6)),
        ],
      ),
      child: Text(face,
          style: const TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.bold,
              color: LudoColors.dicePip)),
    );
    if (widget.reducedMotion || !widget.rolling) return box;
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, child) {
        final t = _ctrl.value;
        final shake = math.sin(t * math.pi * 6) * (1 - t) * 6;
        final scale = 1 + math.sin(t * math.pi) * 0.25; // pop
        return Transform.translate(
          offset: Offset(shake, 0),
          child: Transform.scale(scale: scale, child: child),
        );
      },
      child: box,
    );
  }
}

/// Last-5 shared pool history strip (DESIGN.md: horizontal chips).
class PoolStrip extends StatelessWidget {
  final List<int> history;
  const PoolStrip({super.key, required this.history});

  @override
  Widget build(BuildContext context) {
    final last = history.length > 5
        ? history.sublist(history.length - 5)
        : history;
    if (last.isEmpty) {
      return const Text('No rolls yet',
          style: TextStyle(fontSize: 12, color: Colors.white70));
    }
    return Wrap(
      spacing: 6,
      children: [
        for (var i = 0; i < last.length; i++)
          Chip(
            label: Text('${last[i]}',
                style: TextStyle(
                    fontWeight: i == last.length - 1
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: LudoColors.ink)),
            visualDensity: VisualDensity.compact,
            backgroundColor: i == last.length - 1
                ? LudoColors.gold
                : LudoColors.ivory,
            side: const BorderSide(color: LudoColors.woodDark),
          ),
      ],
    );
  }
}
