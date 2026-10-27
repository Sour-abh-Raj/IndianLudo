import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:indian_ludo/game/rules.dart';
import 'package:indian_ludo/game/types.dart';
import 'package:indian_ludo/main.dart';
import 'package:indian_ludo/state/game_controller.dart';
import 'package:indian_ludo/ui/game_screen.dart';
import 'package:indian_ludo/ui/result_screen.dart';
import 'package:indian_ludo/ui/theme.dart';

/// Real-pixel goldens for review. Generate with:
///   flutter test --update-goldens test/golden_test.dart
/// All scenes are deterministic (no random rolls, reduced motion, fixed size).

void _goldSurface(WidgetTester tester) {
  tester.view.physicalSize = const Size(480, 960);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

/// Deterministic mid-game: tokens on ring, start, home stretch, one home.
GameController _midGame(int players, int sides) {
  final c = GameController()
    ..startGame(GameConfig(playerCount: players, sides: sides), reduced: true);
  final s = c.state;
  final cfg = s.config;
  int ring(int p) => p.clamp(0, cfg.ringSteps - 1);
  final h0 = s.housesOf(0).first.id;
  final h1 = s.housesOf(1).first.id;
  s.tokenAt(h0, 0).progress = ring(10); // out on the ring
  s.tokenAt(h0, 1).progress = 0; // just left the yard (safe start)
  // Home, center stack (last slot: 3 normally, 2 in diagonal 3+2 houses).
  s.tokenAt(h0, s.housesOf(0).first.slots - 1).progress = cfg.finishProgress;
  s.tokenAt(h1, 0).progress = ring(20);
  s.tokenAt(h1, 1).progress = cfg.ringSteps + 2; // home stretch
  if (cfg.isDiagonalPairMode) {
    // Shared pool: diagonal house token also in play.
    s.tokenAt(1, 0).progress = ring(34);
  }
  if (players >= 5) {
    final h4 = s.housesOf(4).first.id;
    s.tokenAt(h4, 0).progress = ring(7);
  }
  s.poolHistory.addAll([1, 2, 3, sides, 2].map((r) => r.clamp(1, sides)));
  s.turnPlayer = 1;
  return c;
}

Future<void> _pumpGame(WidgetTester tester, GameController c) async {
  await tester.pumpWidget(MaterialApp(
    theme: ludoTheme(),
    home: Builder(builder: (ctx) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushNamed(ctx, '/game', arguments: c);
      });
      return const SizedBox();
    }),
    routes: {'/game': (_) => const GameScreen()},
  ));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
}

void main() {
  testWidgets('golden home', (tester) async {
    _goldSurface(tester);
    await tester.pumpWidget(const IndianLudoApp());
    await tester.pump();
    await expectLater(
        find.byType(MaterialApp), matchesGoldenFile('goldens/home.png'));
  });

  testWidgets('golden setup', (tester) async {
    _goldSurface(tester);
    await tester.pumpWidget(const IndianLudoApp());
    await tester.tap(find.text('Play Local'));
    await tester.pumpAndSettle();
    await expectLater(
        find.byType(MaterialApp), matchesGoldenFile('goldens/setup.png'));
  });

  for (final cfg in const [
    (2, 2, 'board_2p2s'),
    (2, 5, 'board_2p5s'),
    (5, 5, 'board_5p5s'),
    (2, 10, 'board_2p10s'),
    (4, 6, 'board_4p6s'),
  ]) {
    testWidgets('golden ${cfg.$3}', (tester) async {
      _goldSurface(tester);
      await _pumpGame(tester, _midGame(cfg.$1, cfg.$2));
      await expectLater(find.byType(MaterialApp),
          matchesGoldenFile('goldens/${cfg.$3}.png'));
    });
  }

  testWidgets('golden result', (tester) async {
    _goldSurface(tester);
    final st = newGame(GameConfig(playerCount: 4, sides: 6));
    for (final t in st.tokensOf(0)) {
      t.progress = st.config.finishProgress;
    }
    st.tokensOf(1).first.progress = st.config.finishProgress;
    st.phase = Phase.finished;
    st.winner = 0;
    await tester.pumpWidget(MaterialApp(
      theme: ludoTheme(),
      home: Builder(builder: (ctx) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.pushNamed(ctx, '/result', arguments: st);
        });
        return const SizedBox();
      }),
      routes: {'/result': (_) => const ResultScreen()},
    ));
    await tester.pump();
    await tester.pumpAndSettle();
    await expectLater(
        find.byType(MaterialApp), matchesGoldenFile('goldens/result.png'));
  });
}
