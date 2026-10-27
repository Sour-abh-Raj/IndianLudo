import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:indian_ludo/game/geometry.dart';
import 'package:indian_ludo/game/rules.dart';
import 'package:indian_ludo/game/types.dart';
import 'package:indian_ludo/main.dart';
import 'package:indian_ludo/state/game_controller.dart';
import 'package:indian_ludo/ui/board_painter.dart';
import 'package:indian_ludo/ui/game_screen.dart';
import 'package:indian_ludo/ui/home_screen.dart';
import 'package:indian_ludo/ui/result_screen.dart';
import 'package:indian_ludo/ui/setup_screen.dart';
import 'package:indian_ludo/ui/theme.dart';

/// Capture slot for the GameController built by the real setup flow.
class _Capture {
  GameController? c;
}

/// Tall surface so the whole setup list is tappable without scrolling.
void _bigSurface(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 1400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

/// Pump the real screens (same widgets/routes as IndianLudoApp) while
/// observing the GameController the setup flow creates.
Future<void> _pumpApp(WidgetTester tester, _Capture cap) async {
  await tester.pumpWidget(MaterialApp(
    theme: ludoTheme(),
    routes: {
      '/': (_) => const HomeScreen(),
      '/setup': (_) => const SetupScreen(),
      '/game': (ctx) {
        cap.c = ModalRoute.of(ctx)!.settings.arguments as GameController;
        return const GameScreen();
      },
      '/result': (_) => const ResultScreen(),
    },
  ));
}

Future<void> _setStepper(
    WidgetTester tester, String label, int target) async {
  final valueFinder = find.byKey(ValueKey('stepper:$label:value'));
  for (var i = 0; i < 20; i++) {
    final current = int.parse(tester.widget<Text>(valueFinder).data!);
    if (current == target) return;
    await tester.tap(find.byKey(
        ValueKey('stepper:$label:${current < target ? 'plus' : 'minus'}')));
    await tester.pumpAndSettle();
  }
  fail('stepper $label did not reach $target');
}

/// Real taps: Play Local -> steppers -> reduced motion -> Start Game.
/// Uses fixed pumps after entering /game (the board pulse never settles).
Future<void> _startViaSetup(WidgetTester tester,
    {required int players,
    required int sides,
    int houses = 1,
    int bots = 0,
    bool reduced = true}) async {
  await tester.tap(find.text('Play Local'));
  await tester.pumpAndSettle();
  await _setStepper(tester, 'Players', players);
  await _setStepper(tester, 'Houses per player', houses);
  await _setStepper(tester, 'Die sides (N)', sides);
  await _setStepper(tester, 'Bots', bots);
  if (reduced) {
    await tester.tap(find.byKey(const ValueKey('setupReduced')));
    await tester.pumpAndSettle();
  }
  await tester.tap(find.byKey(const ValueKey('setupStart')));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
  expect(find.byType(GameScreen), findsOneWidget);
}

/// Tap the board exactly where [houseId]/[slot] is painted (same layout math
/// the game uses for hit-testing).
Future<void> _tapToken(WidgetTester tester, GameController c,
    {required int houseId, required int slot}) async {
  final finder = find.byKey(const ValueKey('gameBoard'));
  final origin = tester.getTopLeft(finder);
  final size = tester.getSize(finder);
  final layout = BoardLayout(size, c.state.config);
  final token = c.state.tokenAt(houseId, slot);
  final house = c.state.houses.firstWhere((h) => h.id == houseId);
  await tester.tapAt(origin + layout.tokenPos(c.state.config, house, token, 0));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

/// Tap Roll, then tap one highlighted token; repeat. Returns moves played.
Future<List<Move>> _playMoves(WidgetTester tester, GameController c,
    {required int maxRolls, bool Function(Move m)? prefer}) async {
  final played = <Move>[];
  for (var i = 0;
      i < maxRolls && c.state.phase == Phase.playing;
      i++) {
    expect(c.roll, isNull, reason: 'previous roll must be consumed');
    await tester.tap(find.byKey(const ValueKey('gameRoll')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    if (c.roll == null || c.legal.isEmpty) continue; // auto-passed
    var pick = c.legal.first;
    if (prefer != null) {
      for (final m in c.legal) {
        if (prefer(m)) {
          pick = m;
          break;
        }
      }
    }
    await _tapToken(tester, c, houseId: pick.houseId, slot: pick.slot);
    played.add(pick);
  }
  return played;
}

void main() {
  testWidgets('Home renders entry points', (WidgetTester tester) async {
    await tester.pumpWidget(const IndianLudoApp());

    expect(find.text('Indian Ludo'), findsOneWidget);
    expect(find.text('Play Local'), findsOneWidget);
    expect(find.text('Play Online'), findsOneWidget);
    expect(find.text('How to Play'), findsOneWidget);
  });

  testWidgets('How to Play dialog opens and closes',
      (WidgetTester tester) async {
    await tester.pumpWidget(const IndianLudoApp());

    await tester.tap(find.text('How to Play'));
    await tester.pumpAndSettle();
    expect(find.text('Got it'), findsOneWidget);

    await tester.tap(find.text('Got it'));
    await tester.pumpAndSettle();
    expect(find.text('Got it'), findsNothing);
  });

  testWidgets('Play Local navigates to setup', (WidgetTester tester) async {
    await tester.pumpWidget(const IndianLudoApp());

    await tester.tap(find.text('Play Local'));
    await tester.pumpAndSettle();
    expect(find.byType(SetupScreen), findsOneWidget);
  });

  testWidgets('2p2s: roll and tap highlighted moves',
      (WidgetTester tester) async {
    _bigSurface(tester);
    final cap = _Capture();
    await _pumpApp(tester, cap);
    await _startViaSetup(tester, players: 2, sides: 2);
    final c = cap.c!;
    expect(find.textContaining("Player 1's turn"), findsOneWidget);

    final played = await _playMoves(tester, c, maxRolls: 12);
    expect(played, isNotEmpty, reason: 'leave face 2 hits fast');
    // Auto-passed rolls also land in the pool history, so it can only grow.
    expect(c.state.poolHistory.length, greaterThanOrEqualTo(played.length));
    expect(
        c.state.tokens.any((t) => !t.inYard), isTrue,
        reason: 'a token left the yard via real taps');
  });

  testWidgets('2p5s: roll and tap highlighted moves',
      (WidgetTester tester) async {
    _bigSurface(tester);
    final cap = _Capture();
    await _pumpApp(tester, cap);
    await _startViaSetup(tester, players: 2, sides: 5);
    final c = cap.c!;

    final played = await _playMoves(tester, c, maxRolls: 30);
    expect(played, isNotEmpty);
    expect(c.state.tokens.any((t) => !t.inYard), isTrue);
  });

  testWidgets('5p5s: roll and tap highlighted moves',
      (WidgetTester tester) async {
    _bigSurface(tester);
    final cap = _Capture();
    await _pumpApp(tester, cap);
    await _startViaSetup(tester, players: 5, sides: 5);
    final c = cap.c!;
    expect(c.state.houses, hasLength(5));

    final played = await _playMoves(tester, c, maxRolls: 40);
    expect(played, isNotEmpty);
    expect(c.state.tokens.any((t) => !t.inYard), isTrue);
  });

  testWidgets('2p10s diagonal pair: shared pool incl. diagonal house',
      (WidgetTester tester) async {
    _bigSurface(tester);
    final cap = _Capture();
    await _pumpApp(tester, cap);
    await _startViaSetup(tester, players: 2, sides: 10, houses: 2);
    final c = cap.c!;
    expect(find.textContaining('diagonal-pair'), findsOneWidget);
    expect(c.state.config.isDiagonalPairMode, isTrue);
    // Player 0 owns houses 0 (3 slots) + 1 (2 slots): the 5+5 shared pool.
    expect(c.state.housesOf(0).map((h) => h.id), containsAll([0, 1]));

    final played = await _playMoves(tester, c,
        maxRolls: 150,
        prefer: (m) => m.player == 0 && m.houseId == 1);
    expect(played, isNotEmpty);
    expect(
        played.any((m) => m.houseId == 1), isTrue,
        reason: 'a later owned turn tapped a token from the diagonal house');
    expect(c.state.tokenAt(1, 0).inYard, isFalse);
  });

  testWidgets('4p6s classic: roll and tap highlighted moves',
      (WidgetTester tester) async {
    _bigSurface(tester);
    final cap = _Capture();
    await _pumpApp(tester, cap);
    await _startViaSetup(tester, players: 4, sides: 6);
    final c = cap.c!;

    final played = await _playMoves(tester, c, maxRolls: 40);
    expect(played, isNotEmpty);
    expect(c.state.tokens.any((t) => !t.inYard), isTrue);
  });

  testWidgets('bot turns advance the game alone', (WidgetTester tester) async {
    _bigSurface(tester);
    final cap = _Capture();
    await _pumpApp(tester, cap);
    await _startViaSetup(tester, players: 2, sides: 6, bots: 1);
    final c = cap.c!;
    expect(c.botCount, 1);
    expect(c.isBot(1), isTrue);

    Future<void> rollOnce() async {
      await tester.tap(find.byKey(const ValueKey('gameRoll')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
    }

    // Human (P0) plays until the turn reaches the bot (extra turns possible).
    for (var i = 0;
        i < 12 && c.state.turnPlayer == 0 && c.state.phase == Phase.playing;
        i++) {
      await rollOnce();
      if (c.roll != null && c.legal.isNotEmpty) {
        final m = c.legal.first;
        await _tapToken(tester, c, houseId: m.houseId, slot: m.slot);
      }
    }
    expect(c.state.turnPlayer, 1, reason: 'bot now owns the turn');

    // Nobody taps: the bot's timers must roll, move, and yield the turn.
    final before = c.state.poolHistory.length;
    for (var i = 0;
        i < 40 && c.state.turnPlayer == 1 && c.state.phase == Phase.playing;
        i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
    expect(c.state.turnPlayer, 0);
    expect(c.state.poolHistory.length, greaterThan(before));
    final btn = tester.widget<FilledButton>(
        find.byKey(const ValueKey('gameRoll')));
    expect(btn.onPressed, isNotNull, reason: 'human Roll live again');
  });

  testWidgets('capture sends the victim home via real taps',
      (WidgetTester tester) async {
    _bigSurface(tester);
    final cap = _Capture();
    await _pumpApp(tester, cap);
    await _startViaSetup(tester, players: 2, sides: 6);
    final c = cap.c!;
    final cfg = c.state.config;
    final h0 = c.state.housesOf(0).first;
    final h1 = c.state.housesOf(1).first;
    // Victim seeded exactly one cell ahead of the hunter, off safe stars.
    const p = 5;
    final targetAbs = (h0.startOffset + p + 1) % cfg.ringCells;
    final q = (targetAbs - h1.startOffset) % cfg.ringCells;
    expect(q >= 0 && q < cfg.ringSteps, isTrue);
    expect(safeCells(cfg, c.state.houses).contains(targetAbs), isFalse);
    final own = c.state.tokenAt(h0.id, 0);
    final victim = c.state.tokenAt(h1.id, 0);

    Future<void> rollOnce() async {
      await tester.tap(find.byKey(const ValueKey('gameRoll')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
    }

    Future<void> tapMove(Move m) =>
        _tapToken(tester, c, houseId: m.houseId, slot: m.slot);

    var captured = false;
    for (var i = 0;
        i < 80 && !captured && c.state.phase == Phase.playing;
        i++) {
      if (c.state.turnPlayer == 0) {
        // Reseed the trap each owned turn; yard everything else.
        for (final t in c.state.tokens) {
          t.progress = -1;
        }
        own.progress = p;
        victim.progress = q;
        await rollOnce();
        if (c.roll == null || c.legal.isEmpty) continue;
        final caps = c.legal.where((m) => m.isCapture).toList();
        if (caps.isNotEmpty) {
          await tapMove(caps.first);
          captured = true;
        } else {
          await tapMove(c.legal.first); // turn passes; trap resets next time
        }
      } else {
        await rollOnce(); // play P1 out so the turn comes back
        if (c.roll != null && c.legal.isNotEmpty) {
          await tapMove(c.legal.first);
        }
      }
    }
    expect(captured, isTrue, reason: 'rolled 1 with the trap set');
    expect(victim.inYard, isTrue);
  });

  testWidgets('Play Again restarts with a fresh game',
      (WidgetTester tester) async {
    _bigSurface(tester);
    final cap = _Capture();
    // Enter /result with a finished state, then restart via Play Again.
    final done = newGame(GameConfig(playerCount: 2, sides: 6))
      ..phase = Phase.finished
      ..winner = 1
      ..poolHistory.addAll(const [6, 6, 3]);
    await tester.pumpWidget(MaterialApp(
      theme: ludoTheme(),
      routes: {
        '/': (_) => const HomeScreen(),
        '/setup': (_) => const SetupScreen(),
        '/game': (ctx) {
          cap.c = ModalRoute.of(ctx)!.settings.arguments as GameController;
          return const GameScreen();
        },
        '/result': (_) => const ResultScreen(),
      },
    ));
    final ctx = tester.element(find.byType(HomeScreen));
    Navigator.pushNamed(ctx, '/result', arguments: done);
    await tester.pumpAndSettle();
    expect(find.text('Player 2 wins!'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('resultPlayAgain')));
    await tester.pumpAndSettle();
    expect(find.byType(SetupScreen), findsOneWidget);

    await _setStepper(tester, 'Players', 2);
    await _setStepper(tester, 'Die sides (N)', 6);
    await tester.tap(find.byKey(const ValueKey('setupStart')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    final c = cap.c!;
    expect(find.textContaining("Player 1's turn"), findsOneWidget);
    expect(find.text('No rolls yet'), findsOneWidget);
    expect(c.state.poolHistory, isEmpty);
    expect(c.state.tokens.every((t) => t.inYard), isTrue);
    expect(c.state.phase, Phase.playing);
  });
}
