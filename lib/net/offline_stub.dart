// Offline stub: OnlineService that works with no network. Rooms are local,
// moves echo back to the watcher. Keeps the UI + controller testable.
library;

import 'dart:async';

import 'online_service.dart';

class OfflineStubService implements OnlineService {
  final _controllers = <String, StreamController<Map<String, Object?>>>{};
  var _roomSeq = 0;

  @override
  Future<String> createRoom(GameRoomSpec spec) async {
    final id = 'local-${++_roomSeq}';
    _controllers[id] = StreamController<Map<String, Object?>>.broadcast();
    return id;
  }

  @override
  Future<void> joinRoom(String roomId, String playerId) async {
    _controllers[roomId]?.add({'type': 'join', 'player': playerId});
  }

  @override
  Future<void> sendMove(String roomId, Map<String, Object?> moveJson) async {
    _controllers[roomId]?.add({'type': 'move', ...moveJson});
  }

  @override
  Stream<Map<String, Object?>> watchRoom(String roomId) =>
      _controllers[roomId]?.stream ?? const Stream.empty();

  @override
  Future<void> leaveRoom(String roomId) async {
    await _controllers.remove(roomId)?.close();
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.close();
    }
    _controllers.clear();
  }
}
