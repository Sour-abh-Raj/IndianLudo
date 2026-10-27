# Break-test state (light verifier checkpoints)

- [2026-10-27] BASELINE: flutter test 174/174 pass; flutter analyze clean. No regressions.
- [2026-10-27] WIDGET: 9/9 pass (3 old + 5 config tap-flows + restart). Diag-house tap verified.
- [2026-10-27] GOLDEN: 8/8 PNGs (home/setup/5 boards/result) in test/goldens + test_results/. Fixed setup Row overflow (Flexible) found at 480px.
- [2026-10-27] FINAL: 190/190 pass (174 base + 8 widget + 8 golden); analyze clean. Integration -d windows: 4 pass then (4p,6s) hung, rest unreached; bot/capture/restart flows covered in widget tests instead.
- [2026-10-27] DONE. Review PNGs in test_results/ (8). App fix: setup stepper Row Flexible (narrow-width overflow).
- [2026-10-27] UI-REDESIGN: physical-board theme live (felt/wood/ivory/gold); analyze clean; widget+game 182/182 pass.
- [2026-10-27] UI-REDESIGN: BoardLayout math untouched; all route keys/texts preserved (1 fix: winner text exact-match).
- [2026-10-27] UI-MOCKUPS: 8 redesign PNGs staged under test_results/mockups/ (goldens regenerated 8/8).
- [2026-10-27] UI-FINAL: 8 final PNGs promoted to test_results/ (mockups verified: felt/wood/gold, no 480px overflow).
- [2026-10-27] UI-DONE: full suite 190/190 + analyze clean; debug APK rebuilt once incrementally.
- [2026-10-27] SYNC: pushed d8b60a1 'Indian Ludo v1.1: verified + realistic board UI' (35 files) to origin/main; ls-remote matches.

FIX 2026-10-28: integration 9/9 on -d windows (hint-string update, capture-aware shadow reconcile, quit-to-home restart flow).
