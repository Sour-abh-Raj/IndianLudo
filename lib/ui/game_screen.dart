import 'package:flutter/material.dart';

import '../game/types.dart';
import '../state/game_controller.dart';
import 'board_painter.dart';
import 'dice_widget.dart';
import 'theme.dart';

/// Game: N-sided board canvas, dice + pool strip, turn banner, toasts.
class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with SingleTickerProviderStateMixin {
  GameController? _controller;
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _controller ??= ModalRoute.of(context)!.settings.arguments as GameController;
  }

  @override
  void dispose() {
    _pulse.dispose();
    _controller?.dispose();
    super.dispose();
  }

  void _onTapBoard(Offset local, Size size) {
    final c = _controller!;
    if (!c.hasState || c.roll == null || c.legal.isEmpty) return;
    final cfg = c.state.config;
    final layout = BoardLayout(size, cfg);
    var finishedIndex = 0;
    for (final move in c.legal) {
      final token = c.state.tokenAt(move.houseId, move.slot);
      final house = c.state.houses.firstWhere((h) => h.id == move.houseId);
      final p = layout.tokenPos(cfg, house, token,
          token.isFinished(cfg) ? finishedIndex++ : 0);
      if ((p - local).distance < layout.cellRadius + 10) {
        c.playMove(move);
        if (c.state.phase == Phase.finished && mounted) {
          Navigator.pushReplacementNamed(context, '/result',
              arguments: c.state);
        }
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = _controller;
    if (c == null) return const Scaffold(body: Center(child: Text('No game')));
    return ListenableBuilder(
      listenable: c,
      builder: (context, _) {
        if (!c.hasState) {
          return const Scaffold(body: Center(child: Text('No game')));
        }
        final state = c.state;
        final cfg = state.config;
        final highlight = {for (final m in c.legal) '${m.houseId}:${m.slot}'};
        final turnColor = LudoColors.house(
            state.houses.firstWhere((h) => h.owner == state.turnPlayer).corner);
        if (c.lastEvent != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(
                  content: Text(c.lastEvent!), duration: const Duration(seconds: 2)));
          });
        }
        return Scaffold(
          appBar: AppBar(
            title: const Text('Indian Ludo'),
            actions: [
              Row(children: [
                const Text('Calm', style: TextStyle(fontSize: 12)),
                Switch(
                  value: c.reducedMotion,
                  onChanged: c.setReducedMotion,
                ),
              ]),
            ],
          ),
          body: Column(
            children: [
              // Turn banner.
              Container(
                width: double.infinity,
                color: turnColor.withValues(alpha: 0.2),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  'Player ${state.turnPlayer + 1}\'s turn'
                  '${c.isBot(state.turnPlayer) ? ' (bot)' : ''}'
                  '${cfg.isDiagonalPairMode ? ' • diagonal-pair' : ''}',
                  key: const ValueKey('turnBanner'),
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
              ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final size = Size(
                        constraints.maxWidth, constraints.maxHeight);
                    return GestureDetector(
                      key: const ValueKey('gameBoard'),
                      onTapUp: (d) => _onTapBoard(d.localPosition, size),
                      child: AnimatedBuilder(
                        animation: _pulse,
                        builder: (_, _) => CustomPaint(
                          size: size,
                          painter: BoardPainter(
                            state: state,
                            highlightKeys: highlight,
                            pulse: c.reducedMotion ? 0 : _pulse.value,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              PoolStrip(history: state.poolHistory),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  DiceWidget(
                    sides: cfg.sides,
                    value: c.roll,
                    rolling: c.rolling,
                    reducedMotion: c.reducedMotion,
                  ),
                  const SizedBox(width: 16),
                  FilledButton(
                    key: const ValueKey('gameRoll'),
                    onPressed: (c.roll == null &&
                            !c.rolling &&
                            state.phase == Phase.playing &&
                            !c.isBot(state.turnPlayer))
                        ? c.rollDice
                        : null,
                    child: const Text('Roll (N-sided)'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                c.roll == null
                    ? 'Tap Roll, then tap a highlighted token'
                    : 'Rolled ${c.roll} — tap a highlighted token',
                key: const ValueKey('rollHint'),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }
}
