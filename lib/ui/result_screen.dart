import 'package:flutter/material.dart';

import '../game/types.dart';
import 'theme.dart';

/// Result: winner banner, standings, Play Again / Home.
class ResultScreen extends StatelessWidget {
  const ResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = ModalRoute.of(context)!.settings.arguments as GameState;
    final cfg = state.config;
    final standings = List<int>.generate(cfg.playerCount, (p) => p)
      ..sort((a, b) {
        if (a == state.winner) return -1;
        if (b == state.winner) return 1;
        final fa = state.tokensOf(a).where((t) => t.isFinished(cfg)).length;
        final fb = state.tokensOf(b).where((t) => t.isFinished(cfg)).length;
        return fb.compareTo(fa);
      });
    return Scaffold(
      appBar: AppBar(title: const Text('Game Over')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: LudoColors.gold,
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: LudoColors.woodDark, width: 2),
              ),
              child: Text('Player ${(state.winner ?? 0) + 1} wins!',
                  key: const ValueKey('winnerBanner'),
                  style:
                      Theme.of(context).textTheme.displaySmall,
                  textAlign: TextAlign.center),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                children: [
                  for (var i = 0; i < standings.length; i++)
                    Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: LudoColors.house(state
                              .houses
                              .firstWhere((h) => h.owner == standings[i])
                              .corner),
                          child: Text('${standings[i] + 1}',
                              style: const TextStyle(color: Colors.white)),
                        ),
                        title: Text('Player ${standings[i] + 1}'),
                        subtitle: Text(
                            '${state.tokensOf(standings[i]).where((t) => t.isFinished(cfg)).length} tokens home'),
                        trailing: i == 0
                            ? const Text('🏆',
                                style: TextStyle(fontSize: 24))
                            : Text('#${i + 1}'),
                      ),
                    ),
                ],
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                FilledButton(
                  key: const ValueKey('resultPlayAgain'),
                  style: FilledButton.styleFrom(
                      backgroundColor: LudoColors.gold,
                      foregroundColor: LudoColors.ink),
                  onPressed: () => Navigator.pushNamed(context, '/setup'),
                  child: const Text('Play Again'),
                ),
                OutlinedButton(
                  key: const ValueKey('resultHome'),
                  style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side:
                          const BorderSide(color: Colors.white54)),
                  onPressed: () =>
                      Navigator.popUntil(context, (r) => r.isFirst),
                  child: const Text('Home'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
