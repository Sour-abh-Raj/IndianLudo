import 'package:flutter/material.dart';

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
              Text('Indian Ludo',
                  style: Theme.of(context).textTheme.displaySmall),
              const SizedBox(height: 8),
              const Text('2–10 players • N-sided dice • houses & safe stars'),
              const SizedBox(height: 32),
              FilledButton(
                key: const ValueKey('homePlayLocal'),
                onPressed: () => Navigator.pushNamed(context, '/setup',
                    arguments: {'online': false}),
                child: const Text('Play Local'),
              ),
              const SizedBox(height: 12),
              FilledButton.tonal(
                key: const ValueKey('homePlayOnline'),
                onPressed: () => Navigator.pushNamed(context, '/setup',
                    arguments: {'online': true}),
                child: const Text('Play Online'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                key: const ValueKey('homeHowTo'),
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (_) => const _HowToPlay(),
                ),
                child: const Text('How to Play'),
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
