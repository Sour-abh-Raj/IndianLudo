// Online play interface. Live contract; provider integration is unresolved.
// No paid SDKs. Pure Dart so the engine/tests stay Flutter-free.
library;

/// Opponent move / lobby events delivered to the UI.
abstract class OnlineEvents {
  void onRemoteMove(Map<String, Object?> moveJson);
  void onPlayerJoined(String playerId);
  void onPlayerLeft(String playerId);
  void onError(String message);
}

/// Abstract online service: lobby + move relay. Implementations (realtime DB,
/// WebSocket relay, LAN) plug in behind this interface.
abstract class OnlineService {
  Future<String> createRoom(GameRoomSpec spec);
  Future<void> joinRoom(String roomId, String playerId);
  Future<void> sendMove(String roomId, Map<String, Object?> moveJson);
  Stream<Map<String, Object?>> watchRoom(String roomId);
  Future<void> leaveRoom(String roomId);
  void dispose();
}

/// Room parameters shared by all providers.
class GameRoomSpec {
  final int playerCount;
  final int sides;
  final int housesPerPlayer;
  final String hostPlayerId;

  const GameRoomSpec({
    required this.playerCount,
    required this.sides,
    required this.housesPerPlayer,
    required this.hostPlayerId,
  });
}
