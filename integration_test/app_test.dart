// Full-app integration test: real taps only (one marked exception: the
// arrival on /result, which has no tap path without finishing a game).
//
// The board is a CustomPaint, so token taps are computed from the same pure
// engine the app uses: a shadow GameState mirrors every roll/move and
// BoardLayout converts the chosen token to a tap offset. Interaction is
// always tester.tap / tester.tapAt; the shadow only aims the taps.
//
// Run on a device:
//   flutter test integration_test/app_test.dart -d <device-id>
// Screenshots on device are host-driven: each _shot drops
// `shot-<name>.request` in Directory.systemTemp (app code_cache on Android)
// and waits for the matching `.ack`. While the suite runs, harvest each
// request (screencap pull is binary-safe via cmd, not PowerShell `>`):
//   adb shell "run-as com.indianludo.app ls code_cache"     # spot requests
//   cmd /c "adb exec-out screencap -p > shots\<name>.png"   # capture
//   adb shell "run-as com.indianludo.app sh -c 'echo ok > code_cache/shot-<name>.ack'"
// Desktop runs also pass and rasterize to host-temp PNGs instead:
//   flutter test -d windows integration_test/app_test.dart
//   # shots: %TEMP%\indianludo-<name>.png
library;

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:indian_ludo/game/geometry.dart';
import 'package:indian_ludo/game/rules.dart';
import 'package:indian_ludo/game/types.dart';
import 'package:indian_ludo/state/game_controller.dart';
import 'package:indian_ludo/main.dart';
import 'package:indian_ludo/ui/board_painter.dart';

const _tapRollHint = 'Tap ROLL, then tap a glowing token';

/// Shadow driver: mirrors the live GameController via the pure engine so
/// the test can aim taps at highlighted tokens and assert turn sync.
class _LiveGame {
  final WidgetTester tester;
  final GameConfig config;
  final GameState shadow;
  final List<Move> played = [];
  final Map<int, Set<int>> housesUsed = {};
  bool captureSeen = false;

  _LiveGame(this.tester, this.config) : shadow = newGame(config);
}

final _shotKey = GlobalKey();

Future<void> _pumpApp(WidgetTester tester) async {
  // The RepaintBoundary is the screenshot source; it changes nothing visual.
  await tester.pumpWidget(RepaintBoundary(key: _shotKey, child: const IndianLudoApp()));
  await tester.pumpAndSettle();
}

/// Screenshot at a named moment. Two paths:
/// - Desktop runs rasterize the root RepaintBoundary to a host-temp PNG.
/// - On device, in-app GPU readback hangs on this emulator (SwiftShader-class
///   GL: convertFlutterSurfaceToImage AND RenderRepaintBoundary.toImage never
///   resolve), so the test only emits a logcat marker and holds the screen 3s
///   while the host harvest script screencaps (see header).
Future<void> _shot(WidgetTester tester, String name) async {
  if (Platform.isAndroid || Platform.isIOS) {
    // File handshake: drop a request, wait for the host harvest script to
    // screencap and ack (timeout => suite still passes standalone).
    final dir = Directory.systemTemp; // app code_cache on Android
    final ack = File('${dir.path}/shot-$name.ack');
    if (await ack.exists()) await ack.delete();
    await File('${dir.path}/shot-$name.request').writeAsString('go');
    debugPrint('SHOT-MARKER $name dir=${dir.path}');
    for (var i = 0; i < 100 && !await ack.exists(); i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    return;
  }
  await tester.pump();
  final boundary =
      _shotKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  final image = await boundary.toImage(pixelRatio: 1.0);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  final file = File('${Directory.systemTemp.path}/indianludo-$name.png');
  await file.writeAsBytes(bytes!.buffer.asUint8List());
  debugPrint('shot $name -> ${file.path} (${await file.length()} bytes)');
}

Future<void> _pump(WidgetTester tester, [int n = 3]) async {
  for (var i = 0; i < n; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// Wait until no SnackBar is visible. Stale bars both obscure the Roll
/// button (tap misses) and look like a fresh pass signal to [_doRoll].
Future<void> _drainSnackbars(WidgetTester tester) async {
  for (var i = 0; i < 100; i++) {
    if (find.byType(SnackBar).evaluate().isEmpty) return;
    await tester.pump(const Duration(milliseconds: 100));
  }
}

String _banner(WidgetTester tester) =>
    (tester.widget(find.byKey(const ValueKey('turnBanner'))) as Text).data!;

String _hint(WidgetTester tester) =>
    (tester.widget(find.byKey(const ValueKey('rollHint'))) as Text).data!;

List<int> _chips(WidgetTester tester) => tester
    .widgetList<Chip>(find.byType(Chip))
    .map((c) => int.parse(((c.label) as Text).data!))
    .toList();

void _expectBannerSync(_LiveGame g) {
  expect(_banner(g.tester).startsWith("Player ${g.shadow.turnPlayer + 1}'s turn"),
      isTrue,
      reason: 'banner=${_banner(g.tester)} shadowTurn=${g.shadow.turnPlayer}');
}

Future<void> _setStepper(WidgetTester tester, String label, int target) async {
  int cur() => int.parse(
      (tester.widget(find.byKey(ValueKey('stepper:$label:value'))) as Text)
          .data!);
  var guard = 0;
  while (cur() < target && guard++ < 12) {
    await tester.tap(find.byKey(ValueKey('stepper:$label:plus')));
    await tester.pump();
  }
  while (cur() > target && guard++ < 24) {
    await tester.tap(find.byKey(ValueKey('stepper:$label:minus')));
    await tester.pump();
  }
  expect(cur(), target, reason: 'stepper $label');
}

/// Start a game via real taps. Returns the shadow driver.
/// NOTE: the 'Houses per player' stepper is currently ignored by Start Game
/// (GameConfig carries no such field); 2p+10s auto-enables diagonal-pair.
Future<_LiveGame> _startGame(
  WidgetTester tester, {
  required int players,
  required int sides,
  int houses = 1,
  int bots = 0,
}) async {
  await _pumpApp(tester);
  await tester.tap(find.byKey(const ValueKey('homePlayLocal')));
  await tester.pumpAndSettle();
  await _setStepper(tester, 'Players', players);
  await _setStepper(tester, 'Houses per player', houses);
  await _setStepper(tester, 'Die sides (N)', sides);
  await _setStepper(tester, 'Bots', bots);
  await tester.tap(find.byKey(const ValueKey('setupReduced')));
  await tester.pump();
  await tester.tap(find.byKey(const ValueKey('setupStart')));
  await _pump(tester, 5);
  // Board renders.
  expect(find.byKey(const ValueKey('gameBoard')), findsOneWidget);
  expect(find.byType(CustomPaint), findsWidgets);
  expect(find.byKey(const ValueKey('gameRoll')), findsOneWidget);
  expect(find.text('No rolls yet'), findsOneWidget);
  final g = _LiveGame(tester, GameConfig(playerCount: players, sides: sides));
  _expectBannerSync(g);
  return g;
}

void _mirrorPass(_LiveGame g, int roll) {
  g.shadow.poolHistory.add(roll);
  if (roll != g.config.extraFace) {
    g.shadow.turnPlayer = (g.shadow.turnPlayer + 1) % g.config.playerCount;
  }
}

/// True when the pool strip gained roll(s) since [before] (chips show the
/// last 5, so growth is either a longer strip or shifted values).
bool _poolGrew(List<int> before, List<int> after) {
  if (after.length > before.length) return true;
  for (var i = 0; i < after.length; i++) {
    if (i >= before.length || after[i] != before[i]) return true;
  }
  return false;
}

/// Our pass roll given the strip before/after. Untruncated: the first new
/// chip (nothing else can roll before our pass resolves). Truncated shift:
/// the newest chip (only reachable in bot-free games, where only we roll).
int _ourPassRoll(List<int> before, List<int> after) {
  if (after.length > before.length) return after[before.length];
  return after.last;
}

/// Tap Roll. Returns the roll, or null when the turn passed (mirrored).
/// A pending roll belongs to the banner player. With [sync] false the
/// caller skips the immediate banner check (a bot may have played on).
Future<int?> _doRoll(_LiveGame g, {bool sync = true}) async {
  final tester = g.tester;
  await _drainSnackbars(tester); // stale bars obscure the Roll button
  final chips0 = _chips(tester);
  await tester.tap(find.byKey(const ValueKey('gameRoll')));
  for (var i = 0; i < 60; i++) {
    await tester.pump(const Duration(milliseconds: 100));
    final m = RegExp(r'^Rolled (\d+)').firstMatch(_hint(tester));
    if (m != null && !_banner(tester).contains('(bot)')) {
      return int.parse(m.group(1)!); // our roll, still pending
    }
    final cur = _chips(tester);
    if (!_poolGrew(chips0, cur)) continue;
    // Pool grew: our roll resolved. A pending bot roll just means the bot
    // is already mid-turn; either way our turn ended via pass (moves run
    // in _doMove, strictly later).
    if (chips0.length == 5 && _banner(tester).contains('(bot)')) {
      fail('ambiguous pass read under truncation + bot turn');
    }
    _mirrorPass(g, _ourPassRoll(chips0, cur));
    if (sync) _expectBannerSync(g);
    return null;
  }
  fail('roll never resolved (hint=${_hint(tester)})');
}

/// Forward ring distance from [m]'s landing cell to the nearest opponent
/// ahead (hunt heuristic: chase the closest prey).
int _preyGap(_LiveGame g, Move m) {
  final cfg = g.config;
  final house = g.shadow.houses.firstWhere((h) => h.id == m.houseId);
  final cell = absoluteCell(cfg, house, m.to);
  if (cell < 0) return 1 << 30;
  var best = 1 << 30;
  for (final t in g.shadow.tokens) {
    if (t.inYard || t.isFinished(cfg)) continue;
    final h = g.shadow.houses.firstWhere((hh) => hh.id == t.houseId);
    if (h.owner == m.player) continue;
    final oc = absoluteCell(cfg, h, t.progress);
    if (oc < 0) continue;
    final gap = (oc - cell) % cfg.ringCells;
    if (gap < best) best = gap;
  }
  return best;
}

/// Tap a highlighted token for [roll]. Prefers captures, then [prefer],
/// then (when [hunt]) the token landing closest behind an opponent.
Future<Move> _doMove(_LiveGame g, int roll,
    {bool Function(Move m)? prefer, bool hunt = false, bool sync = true}) async {
  final tester = g.tester;
  await _drainSnackbars(tester); // a stale bar could cover a yard token
  final legal = legalMoves(g.shadow, roll);
  expect(legal, isNotEmpty);
  final box =
      tester.renderObject(find.byKey(const ValueKey('gameBoard'))) as RenderBox;
  final layout = BoardLayout(box.size, g.config);
  // Positions in _onTapBoard order (mirror its finishedIndex counting).
  final pos = <Move, Offset>{};
  var finishedIndex = 0;
  for (final m in legal) {
    final token = g.shadow.tokenAt(m.houseId, m.slot);
    final house = g.shadow.houses.firstWhere((h) => h.id == m.houseId);
    pos[m] = layout.tokenPos(g.config, house, token,
        token.isFinished(g.config) ? finishedIndex++ : 0);
  }
  // Group stacked tokens: the app taps the first legal move at a position.
  final groups = <List<Move>>[];
  for (final m in legal) {
    List<Move>? hit;
    for (final gr in groups) {
      if ((pos[gr.first]! - pos[m]!).distance < 1.0) hit = gr;
    }
    if (hit == null) {
      groups.add([m]);
    } else {
      hit.add(m);
    }
  }
  List<Move> pick = groups.first;
  final caps = groups.where((gr) => gr.any((m) => m.isCapture));
  if (caps.isNotEmpty) {
    pick = caps.first;
  } else if (prefer != null) {
    final pref = groups.where((gr) => prefer(gr.first));
    if (pref.isNotEmpty) pick = pref.first;
  } else if (hunt) {
    for (final gr in groups) {
      if (_preyGap(g, gr.first) < _preyGap(g, pick.first)) pick = gr;
    }
  }
  final chosen = pick.first;
  // The app is authoritative: crowded tap targets may resolve to a legal
  // move other than the shadow's pick. Snapshot real progress, then mirror
  // whichever move the app actually played (prevents silent shadow drift
  // that later surfaces as a flaky tap-miss).
  final routeEl = tester.element(find.byKey(const ValueKey('gameBoard')));
  final real =
      ModalRoute.of(routeEl)!.settings.arguments as GameController;
  final before = {
    for (final t in real.state.tokens) '${t.houseId}:${t.slot}': t.progress
  };
  await tester.tapAt(box.localToGlobal(pos[chosen]!));
  await _pump(tester);
  expect(_hint(tester), _tapRollHint, reason: 'tap missed its token');
  final changed = real.state.tokens
      .where((t) => t.progress != before['${t.houseId}:${t.slot}'])
      .toList();
  // Captures move extra tokens (victims go home to -1); the mover is the
  // one that did not go home.
  final moved = changed.where((t) => t.progress != -1).toList();
  expect(moved.length, 1, reason: 'tap must move exactly one token');
  final actual = legal.firstWhere((m) =>
      m.houseId == moved.single.houseId && m.slot == moved.single.slot);
  applyMove(g.shadow, actual, roll);
  g.played.add(actual);
  g.housesUsed
      .putIfAbsent(actual.player, () => <int>{})
      .add(actual.houseId);
  if (actual.isCapture) {
    g.captureSeen = true;
    expect(find.textContaining('Capture!'), findsOneWidget);
  }
  if (g.shadow.phase == Phase.finished) {
    await _pump(tester);
    expect(find.byKey(const ValueKey('winnerBanner')), findsOneWidget);
  } else if (sync) {
    _expectBannerSync(g);
  }
  return chosen;
}

/// Play one full turn (roll + optional move). Returns false at game end.
Future<bool> _playTurn(_LiveGame g,
    {bool Function(Move m)? prefer,
    bool hunt = false,
    bool sync = true}) async {
  final roll = await _doRoll(g, sync: sync);
  if (roll != null) {
    await _doMove(g, roll, prefer: prefer, hunt: hunt, sync: sync);
  }
  return g.shadow.phase != Phase.finished;
}

/// Wait until a human banner holds with a stable pool (bot quiescent).
Future<void> _waitHuman(WidgetTester tester) async {
  var guard = 0;
  while (guard++ < 300) {
    await tester.pump(const Duration(milliseconds: 100));
    if (_banner(tester).contains('(bot)')) continue;
    final n = _chips(tester).length;
    var stable = true;
    for (var s = 0; s < 10; s++) {
      await tester.pump(const Duration(milliseconds: 100));
      if (_chips(tester).length != n ||
          _banner(tester).contains('(bot)')) {
        stable = false;
        break;
      }
    }
    if (stable) return;
  }
  fail('bot never quiesced (banner=${_banner(tester)})');
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('home: How-to-Play dialog + Play Local navigation',
      (tester) async {
    await _pumpApp(tester);
    await _shot(tester, 'home');
    await tester.tap(find.byKey(const ValueKey('homeHowTo')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('howToDialog')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('howToGotIt')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('howToDialog')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('homePlayLocal')));
    await tester.pumpAndSettle();
    expect(find.text('Game Setup'), findsOneWidget);
    await _shot(tester, 'setup');
  });

  testWidgets('board renders + moves: (2p,2s)', (tester) async {
    final g = await _startGame(tester, players: 2, sides: 2);
    await _shot(tester, 'board-2p-2s');
    for (var i = 0; i < 6; i++) {
      if (!await _playTurn(g)) break;
    }
    expect(_chips(tester), isNotEmpty, reason: 'pool history grew');
  });

  testWidgets('board renders + moves: (2p,5s)', (tester) async {
    final g = await _startGame(tester, players: 2, sides: 5);
    await _shot(tester, 'board-2p-5s');
    for (var i = 0; i < 6; i++) {
      if (!await _playTurn(g)) break;
    }
  });

  testWidgets('board renders + moves: (5p,5s)', (tester) async {
    final g = await _startGame(tester, players: 5, sides: 5);
    await _shot(tester, 'board-5p-5s');
    for (var i = 0; i < 6; i++) {
      if (!await _playTurn(g)) break;
    }
  });

  testWidgets('board renders + moves: (2p,10s) diagonal shared pool',
      (tester) async {
    final g =
        await _startGame(tester, players: 2, sides: 10, houses: 2);
    expect(_banner(tester), contains('diagonal-pair'));
    await _shot(tester, 'board-2p-10s');
    // Diversify houses: on an owned turn, prefer a house the player
    // hasn't moved from yet — proves the roll is a shared pool.
    bool poolProof() =>
        g.housesUsed.values.any((used) => used.length >= 2);
    var turns = 0;
    while (!poolProof() && turns < 60) {
      final me = g.shadow.turnPlayer;
      final ok = await _playTurn(g,
          prefer: (m) =>
              m.player == me &&
              !(g.housesUsed[me]?.contains(m.houseId) ?? false));
      turns++;
      if (!ok) break;
    }
    expect(poolProof(), isTrue,
        reason: 'one player moved from both diagonal houses in $turns turns');
  });

  testWidgets('board renders + moves: (4p,6s)', (tester) async {
    final g = await _startGame(tester, players: 4, sides: 6);
    await _shot(tester, 'board-4p-6s');
    for (var i = 0; i < 6; i++) {
      if (!await _playTurn(g)) break;
    }
  });

  testWidgets('capture evidence within 60 turns (4p,2s)', (tester) async {
    // Dense table (16 tokens, 26 cells) + capture-preferring hunter play.
    final g = await _startGame(tester, players: 4, sides: 2);
    var turns = 0;
    while (!g.captureSeen && turns < 60) {
      if (!await _playTurn(g, hunt: true)) break;
      turns++;
    }
    expect(g.captureSeen, isTrue, reason: 'no capture in $turns turns');
    await _shot(tester, 'capture');
  });

  testWidgets('bot turns advance + restart resets', (tester) async {
    // Up to 3 fresh games; each attempt plays at most 2 human turns, then
    // waits for quiescence. More pool rolls than human taps proves the bot
    // rolled. Fresh games keep the pool untruncated (exact chip reads) and
    // the shadow exact (it is never used after a bot visit).
    var proven = false;
    for (var attempt = 0; attempt < 3 && !proven; attempt++) {
      final g = await _startGame(tester, players: 2, sides: 6, bots: 1);
      var humanRolls = 0;
      for (var t = 0; t < 2; t++) {
        if (_banner(tester).contains('(bot)')) break;
        await _playTurn(g, sync: false);
        humanRolls++;
      }
      await _waitHuman(tester);
      if (_chips(tester).length > humanRolls) proven = true;
    }
    expect(proven, isTrue, reason: 'no bot roll in 3 fresh games');
    // Restart: quit to home via the top-strip home button, then start a
    // fresh game through setup; board is fresh.
    await tester.tap(find.byTooltip('Quit to home'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('homePlayLocal')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('homePlayLocal')));
    await tester.pumpAndSettle();
    expect(find.text('Game Setup'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('setupStart')));
    await _pump(tester, 5);
    expect(_banner(tester), startsWith("Player 1's turn"));
    expect(find.text('No rolls yet'), findsOneWidget);
  });

  testWidgets('result screen navigation (DIRECT route injection, marked)',
      (tester) async {
    // MARKED EXCEPTION to real-taps-only: reaching /result by taps needs a
    // full game (hundreds of turns), so the arrival is programmatic while
    // every navigation assertion below uses real taps.
    final cfg = GameConfig(playerCount: 4, sides: 6);
    final done = newGame(cfg);
    for (final t in done.tokensOf(0)) {
      t.progress = cfg.finishProgress;
    }
    done.phase = Phase.finished;
    done.winner = 0;
    await _pumpApp(tester);
    Navigator.of(tester.element(find.text('Indian Ludo')))
        .pushNamed('/result', arguments: done);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('winnerBanner')), findsOneWidget);
    expect(find.text('Player 1 wins!'), findsOneWidget);
    await _shot(tester, 'result');
    await tester.tap(find.byKey(const ValueKey('resultPlayAgain')));
    await tester.pumpAndSettle();
    expect(find.text('Game Setup'), findsOneWidget);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('winnerBanner')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('resultHome')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('homePlayLocal')), findsOneWidget);
  });
}
