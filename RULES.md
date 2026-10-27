# indianLudo v1 — Rules

## 1. Classic base
Standard Ludo: 4 tokens per player, roll 6 to leave home, 6 grants an extra
roll, capture sends opponent token home, safe squares block capture, exact
roll to finish, first to bring all 4 home wins.

## 2. Shared dice pool (v1 twist)
One N-sided die is shared by all players on their turn (roll values 1..N).
Turn order is clockwise; a 6 (or max face, see §3) grants an extra roll.
No per-player dice; the pool UI shows last rolls for all to see.

## 3. N-sided die, N = 2..10
Game setup picks N in 2..10. Extra-roll face = 6 when N ≥ 6, else N.
Leave-home roll = 6 when N ≥ 6, else N. Win check unchanged.

## 4. House-allocation table
Houses = seating positions around the board (colors). For player count P
and side count N, houses are assigned:

| Players | Sides N | Houses each | Layout |
|---|---|---|---|
| 2 | 2–9 | 1 | opposite corners |
| 2 | 10 | 5+5 (see §5) | diagonal pairs, 5 tokens slot-mapped |
| 3 | any | 1 | every other corner, 4th corner empty |
| 4 | any | 1 | one corner each |
| 5–10 | any | 1 each, colors cycle | extra players share color set, distinct token ring |

## 5. Special: 2 players, 10 sides → 5+5 diagonal pairs
Each player fields 5 tokens split across a diagonal corner pair
(P1: NW+SE, P2: NE+SW). Each corner runs its own home/leave/finish track;
tokens are slot-mapped 3+2. Capture and safe rules apply per corner track.
Win = all 5 home.
