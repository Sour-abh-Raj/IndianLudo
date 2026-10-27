# indianLudo v1 — Architecture (Flutter)

## Module map
- `lib/game/` — pure Dart rules engine: `rules.dart` (moves, captures,
  extra rolls), `dice.dart` (N-sided pool, N=2..10), `houses.dart`
  (allocation table + 5+5 diagonal mapping), `state.dart` (GameState).
  No Flutter imports; unit-testable.
- `lib/ui/` — screens + widgets: `screens/` (home, setup, board, result),
  `widgets/` (board painter, dice pool strip, token), `theme.dart` (tokens).
- `lib/net/` — `online_service.dart` (abstract), `offline_stub.dart`
  (local pass-and-play impl), `firebase_service.dart` OR
  `websocket_service.dart` (one real backend; FLAG: decision open).

## State
Single `GameState extends ChangeNotifier` in `lib/game/state.dart`:
board, turn, pool history, phase. UI subscribes via Provider/Consumer.
Engine methods mutate then `notifyListeners()`. No other global state.

## OnlineService contract
```dart
abstract class OnlineService {
  Future<Room> createRoom(GameConfig cfg);
  Future<Room> joinRoom(String code);
  Stream<GameEvent> events(String roomId);
  Future<void> sendMove(String roomId, Move m);
}
```
`OfflineStub` implements locally (broadcast StreamController, no network).
FLAG: pick Firebase (Realtime DB, easy auth) vs self-hosted WebSocket
(lower latency, ops cost) before beta.

## Signing (placeholders)
- Android: `android/key.properties` (storeFile/storePassword/keyAlias —
  FILL AT RELEASE), referenced by `app/build.gradle`.
- iOS: Xcode signing team + bundle id `com.example.indianLudo` — FILL.
- Never commit keystores or passwords; CI injects via secrets.
