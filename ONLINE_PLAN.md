# Online Plan (v1 stub)

Interface `lib/net/online_service.dart` is live; `offline_stub.dart` backs it
with zero network. Provider integration is **unresolved**.

## Contract
- `createRoom(GameRoomSpec)` → roomId; `joinRoom`, `sendMove` (JSON
  `{houseId, slot, roll}`), `watchRoom` stream, `leaveRoom`.
- Moves apply through the same `applyMove` engine path as local play;
  remote moves arrive via `OnlineEvents.onRemoteMove` and re-validate with
  `legalMoves` before applying (no trust in the peer).

## Options (all free, no paid SDKs)
1. **LAN / hotspot WebSocket** — host relays; best for family play, no cloud.
2. **Free-tier realtime DB** (Supabase/Firebase free tier) — room docs +
   move subcollection; needs signup + rules.
3. **P2P WebRTC signaling stub** — highest effort, no server cost.

## TODO
- Pick option 1 or 2, implement `OnlineService`, add reconnect + rematch.
- Studio art pass may restyle lobby; JSON move shape is frozen.
