import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../game/bot.dart';
import '../game/rules.dart';
import '../game/types.dart';

/// Setup knobs collected on the setup screen.
class SetupChoices {
  int playerCount;
  int housesPerPlayer;
  int sides;
  int botCount;
  bool online;
  bool reducedMotion;

  SetupChoices({
    this.playerCount = 4,
    this.housesPerPlayer = 1,
    this.sides = 6,
    this.botCount = 0,
    this.online = false,
    this.reducedMotion = false,
  });
}

/// ChangeNotifier wrapper around the pure-Dart engine. No extra deps.
class GameController extends ChangeNotifier {
  GameState? _state;
  final Random _rng = Random();
  int? _roll;
  List<Move> _legal = const [];
  bool _rolling = false;
  bool reducedMotion = false;
  bool online = false;
  int botCount = 0;
  String? lastEvent; // capture / safe / extra-turn / win toast text
  Timer? _botTimer;

  GameState get state => _state!;
  bool get hasState => _state != null;
  int? get roll => _roll;
  List<Move> get legal => _legal;
  bool get rolling => _rolling;

  bool isBot(int player) =>
      botCount > 0 && player >= _state!.config.playerCount - botCount;

  void startGame(GameConfig config,
      {int bots = 0, bool onlineMode = false, bool reduced = false}) {
    _botTimer?.cancel();
    _state = newGame(config);
    _roll = null;
    _legal = const [];
    _rolling = false;
    botCount = bots.clamp(0, config.playerCount - 1);
    online = onlineMode;
    reducedMotion = reduced;
    lastEvent = null;
    notifyListeners();
    _maybeBotTurn();
  }

  /// Roll the shared N-sided pool die.
  Future<void> rollDice() async {
    if (_state == null ||
        _rolling ||
        _roll != null ||
        _state!.phase == Phase.finished) {
      return;
    }
    _rolling = true;
    lastEvent = null;
    notifyListeners();
    if (!reducedMotion) {
      await Future<void>.delayed(const Duration(milliseconds: 450));
    }
    _roll = 1 + _rng.nextInt(_state!.config.sides);
    _rolling = false;
    _legal = legalMoves(_state!, _roll!);
    if (_legal.isEmpty) {
      // No legal move: pass the turn (still records the roll).
      _state!.poolHistory.add(_roll!);
      final cfg = _state!.config;
      if (_roll != cfg.extraFace) {
        _state!.turnPlayer = (_state!.turnPlayer + 1) % cfg.playerCount;
      }
      lastEvent = 'No legal move — turn passes';
      _roll = null;
    }
    notifyListeners();
    _maybeBotTurn();
  }

  /// Apply a tapped legal move.
  void playMove(Move move) {
    if (_state == null || _roll == null) return;
    final result = applyMove(_state!, move, _roll!);
    final bits = <String>[];
    if (move.isCapture) bits.add('Capture! ${result.captured} sent home');
    if (move.isFinish) bits.add('Token home!');
    if (move.leavesYard) bits.add('Token leaves the yard');
    if (result.extraTurn) bits.add('Extra turn (rolled ${state.config.extraFace})');
    if (result.won) bits.add('Player ${move.player + 1} wins!');
    lastEvent = bits.isEmpty ? null : bits.join(' • ');
    _roll = null;
    _legal = const [];
    notifyListeners();
    _maybeBotTurn();
  }

  void setReducedMotion(bool value) {
    reducedMotion = value;
    notifyListeners();
  }

  /// Bots play themselves with a short delay so humans can follow.
  void _maybeBotTurn() {
    _botTimer?.cancel();
    if (_state == null || _state!.phase == Phase.finished) return;
    if (!isBot(_state!.turnPlayer)) return;
    _botTimer = Timer(
      Duration(milliseconds: reducedMotion ? 150 : 700),
      () async {
        if (_state == null || _state!.phase == Phase.finished) return;
        if (!isBot(_state!.turnPlayer)) return;
        if (_roll == null) {
          await rollDice();
          return; // rollDice re-triggers _maybeBotTurn
        }
        final move = chooseNormal(_legal);
        if (move != null) playMove(move);
      },
    );
  }

  @override
  void dispose() {
    _botTimer?.cancel();
    super.dispose();
  }
}
