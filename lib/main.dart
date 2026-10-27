import 'package:flutter/material.dart';

import 'ui/home_screen.dart';
import 'ui/result_screen.dart';
import 'ui/game_screen.dart';
import 'ui/setup_screen.dart';
import 'ui/theme.dart';

void main() {
  runApp(const IndianLudoApp());
}

class IndianLudoApp extends StatelessWidget {
  const IndianLudoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Indian Ludo',
      theme: ludoTheme(),
      initialRoute: '/',
      routes: {
        '/': (_) => const HomeScreen(),
        '/setup': (_) => const SetupScreen(),
        '/game': (_) => const GameScreen(),
        '/result': (_) => const ResultScreen(),
      },
    );
  }
}
