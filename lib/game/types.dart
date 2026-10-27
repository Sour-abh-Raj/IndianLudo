// Pure-Dart core types for the indianLudo rules engine. No Flutter imports.
library;

enum Phase { setup, playing, finished }

/// Game setup: player count P (2..10) and shared die side count N (2..10).
class GameConfig {
  final int playerCount;
  final int sides;

  GameConfig({required this.playerCount, required this.sides}) {
    if (playerCount < 2 || playerCount > 10) {
      throw ArgumentError('playerCount must be 2..10');
    }
    if (sides < 2 || sides > 10) throw ArgumentError('sides must be 2..10');
  }

  /// Roll value granting an extra turn (RULES §3).
  int get extraFace => sides >= 6 ? 6 : sides;

  /// Roll value that lets a token leave the yard (RULES §3).
  int get leaveFace => sides >= 6 ? 6 : sides;

  /// Shared ring cells scale with N (13 per side count).
  int get ringCells => 13 * sides;

  /// Steps travelled on the ring before turning into the home stretch.
  int get ringSteps => ringCells - 1;

  /// Home stretch length per house (RULES: 6/house).
  int get homeSteps => 6;

  /// Exact progress value meaning "finished".
  int get finishProgress => ringSteps + homeSteps;

  /// Special 2-player / 10-side diagonal-pair mode (RULES §5).
  bool get isDiagonalPairMode => playerCount == 2 && sides == 10;

  int tokensForPlayer(int player) => isDiagonalPairMode ? 5 : 4;
}

/// A house = one corner track. A player may own several (5+5 mode).
class House {
  final int id;
  final int owner;
  final int corner; // 0..3 color corner (cycles for 5..10 players)
  final int startOffset; // absolute ring cell where progress 0 lands
  final int slots; // tokens fielded from this house

  const House({
    required this.id,
    required this.owner,
    required this.corner,
    required this.startOffset,
    required this.slots,
  });
}

/// One token. progress: -1 = yard, 0..ringSteps-1 = ring,
/// ringSteps..finishProgress-1 = home stretch, finishProgress = home.
class Token {
  final int houseId;
  final int slot;
  int progress;

  Token({required this.houseId, required this.slot, this.progress = -1});

  bool get inYard => progress == -1;
  bool isFinished(GameConfig cfg) => progress == cfg.finishProgress;
  bool isOnRing(GameConfig cfg) =>
      progress >= 0 && progress < cfg.ringSteps;
}

/// A candidate/applied move. Shared pool: moves may come from any house
/// owned by the current player.
class Move {
  final int player;
  final int houseId;
  final int slot;
  final int from;
  final int to;
  final bool leavesYard;
  final bool isFinish;
  final List<Token> captured;

  const Move({
    required this.player,
    required this.houseId,
    required this.slot,
    required this.from,
    required this.to,
    this.leavesYard = false,
    this.isFinish = false,
    this.captured = const [],
  });

  bool get isCapture => captured.isNotEmpty;
}

/// Mutable game state. Pure Dart; UI wraps it in a ChangeNotifier.
class GameState {
  final GameConfig config;
  final List<House> houses;
  final List<Token> tokens;
  int turnPlayer;
  final List<int> poolHistory = [];
  Phase phase = Phase.playing;
  int? winner;

  GameState(this.config, this.houses, this.tokens, this.turnPlayer);

  List<House> housesOf(int player) =>
      houses.where((h) => h.owner == player).toList();

  Token tokenAt(int houseId, int slot) =>
      tokens.firstWhere((t) => t.houseId == houseId && t.slot == slot);

  List<Token> tokensOf(int player) {
    final ids = houses.where((h) => h.owner == player).map((h) => h.id).toSet();
    return tokens.where((t) => ids.contains(t.houseId)).toList();
  }
}
