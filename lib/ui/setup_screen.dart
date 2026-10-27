import 'package:flutter/material.dart';

import '../game/types.dart';
import '../state/game_controller.dart';
import 'theme.dart';

/// Setup: players 2–10, houses/player, N sides, bot count, online toggle.
class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final choices = SetupChoices();
  bool _initOnline = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initOnline) {
      _initOnline = true;
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map && args['online'] == true) choices.online = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Game Setup')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _stepper('Players', choices.playerCount, 2, 10,
              (v) => setState(() => choices.playerCount = v)),
          _stepper('Houses per player', choices.housesPerPlayer, 1, 2,
              (v) => setState(() => choices.housesPerPlayer = v),
              note: '2 houses/player uses the diagonal-pair track (2p + N=10).'),
          _stepper('Die sides (N)', choices.sides, 2, 10,
              (v) => setState(() => choices.sides = v)),
          _stepper('Bots', choices.botCount, 0, choices.playerCount - 1,
              (v) => setState(() => choices.botCount = v)),
          Card(
            child: SwitchListTile(
              key: const ValueKey('setupOnline'),
              title: const Text('Online game'),
              subtitle:
                  const Text('Interface live; provider stub for now'),
              value: choices.online,
              onChanged: (v) => setState(() => choices.online = v),
            ),
          ),
          Card(
            child: SwitchListTile(
              key: const ValueKey('setupReduced'),
              title: const Text('Reduced motion'),
              subtitle:
                  const Text('Disables dice animation and token pulse'),
              value: choices.reducedMotion,
              onChanged: (v) =>
                  setState(() => choices.reducedMotion = v),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            key: const ValueKey('setupStart'),
            style: FilledButton.styleFrom(
                backgroundColor: LudoColors.gold,
                foregroundColor: LudoColors.ink,
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(
                    fontSize: 17, fontWeight: FontWeight.bold)),
            onPressed: () {
              final config = GameConfig(
                  playerCount: choices.playerCount, sides: choices.sides);
              final controller = GameController()
                ..startGame(
                  config,
                  bots: choices.botCount,
                  onlineMode: choices.online,
                  reduced: choices.reducedMotion,
                );
              Navigator.pushNamed(context, '/game', arguments: controller);
            },
            child: const Text('Start Game'),
          ),
        ],
      ),
    );
  }

  Widget _stepper(
      String label, int value, int min, int max, ValueChanged<int> onChanged,
      {String? note}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(label,
                      style: Theme.of(context).textTheme.titleLarge)),
                Row(
                  children: [
                    IconButton(
                      key: ValueKey('stepper:$label:minus'),
                      icon: const Icon(Icons.remove),
                      onPressed: value > min ? () => onChanged(value - 1) : null,
                    ),
                    Text('$value',
                        key: ValueKey('stepper:$label:value'),
                        style: Theme.of(context).textTheme.titleLarge),
                    IconButton(
                      key: ValueKey('stepper:$label:plus'),
                      icon: const Icon(Icons.add),
                      onPressed: value < max ? () => onChanged(value + 1) : null,
                    ),
                  ],
                ),
              ],
            ),
            if (note != null)
              Text(note, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
