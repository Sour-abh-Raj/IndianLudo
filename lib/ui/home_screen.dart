import 'package:flutter/material.dart';

import 'theme.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Four house tokens on the felt, like pieces set out.
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 0; i < 4; i++)
                    Container(
                      width: 34,
                      height: 34,
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: LudoColors.house(i),
                        border: Border.all(
                            color: LudoColors.houseDark(i), width: 3),
                        boxShadow: const [
                          BoxShadow(
                              blurRadius: 4,
                              offset: Offset(0, 2),
                              color: Colors.black45)
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Text('Indian Ludo',
                  style: Theme.of(context)
                      .textTheme
                      .displaySmall
                      ?.copyWith(color: Colors.white)),
              const SizedBox(height: 8),
              const Text(
                  '2–10 players • N-sided dice • houses & safe stars',
                  style: TextStyle(color: Colors.white70)),
              const SizedBox(height: 32),
              SizedBox(
                width: 260,
                child: FilledButton(
                  key: const ValueKey('homePlayLocal'),
                  style: FilledButton.styleFrom(
                      backgroundColor: LudoColors.gold,
                      foregroundColor: LudoColors.ink,
                      padding:
                          const EdgeInsets.symmetric(vertical: 16),
                      textStyle: const TextStyle(
                          fontSize: 17, fontWeight: FontWeight.bold)),
                  onPressed: () => Navigator.pushNamed(context, '/setup',
                      arguments: {'online': false}),
                  child: const Text('Play Local'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: 260,
                child: FilledButton.tonal(
                  key: const ValueKey('homePlayOnline'),
                  onPressed: () => Navigator.pushNamed(context, '/setup',
                      arguments: {'online': true}),
                  child: const Text('Play Online'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: 260,
                child: OutlinedButton(
                  key: const ValueKey('homeHowTo'),
                  style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white54)),
                  onPressed: () => showDialog<void>(
                    context: context,
                    builder: (_) => const _HowToPlay(),
                  ),
                  child: const Text('How to Play'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HowToPlay extends StatelessWidget {
  const _HowToPlay();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      key: const ValueKey('howToDialog'),
      title: const Text('How to Play'),
      content: const Text(
        'Roll the shared N-sided die. Roll the leave face (6, or N when N < 6) '
        'to bring a token out of the yard. Land on an opponent to capture them '
        'back to the yard — unless they stand on a safe ★ square. '
        'Finish all your tokens with exact rolls to win. '
        'Rolling the extra face grants another turn.',
      ),
      actions: [
        TextButton(
            key: const ValueKey('howToGotIt'),
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it')),
      ],
    );
  }
}
