## [Phase 0] - 2026-07-09 14:38
- Use a shared `MotionSpec` instead of hardcoded durations so future widgets can respect one reduce-motion policy.
- Keep Phase 0 primitives disconnected from business providers and PowerSync state; Phase 1 can wire them into screens with smaller diffs.
- Use built-in Flutter animation widgets first (`AnimatedScale`, `TweenAnimationBuilder`, `LinearProgressIndicator`) and do not add a motion package.
- Keep Liquid Glass as an explicit fancy-mode surface policy; Phase 0 does not expand glass into data-heavy lists or charts.

## [Phase 0] - 2026-07-09 15:13
- Treat existing repo analyzer warnings/infos as out of scope for Phase 0 unless they are caused by the new motion primitives.

## [Phase 1] - 2026-07-09 15:47
- Use existing `PressableScale` and `AnimatedSwitcher` for Phase 1 polish instead of adding animation packages.
- Keep transaction grouped-list eager rendering unchanged in this pass because lazy/keyed grouped list refactor belongs to Phase 4.
- Use skeleton loading only for Home in this pass; Transactions data currently comes from the synchronous filtered provider, so no new loading branch was introduced.
- Convert `withOpacity` only in touched analyzer-reported areas to reduce diagnostics without turning this into a broad cleanup pass.

## [Phase 1] - 2026-07-09 16:17
- Keep Home header/content cards outside the transaction loading state; loading skeletons should represent the list area only so stable summary/wallet surfaces do not visually disappear.

## [Phase 1] - 2026-07-10 08:40
- Let nested FAB implementations keep ownership of tap callbacks; `PressableScale.deferTapToChild` uses pointer observation only, avoiding gesture-arena conflicts and double submission.
- Use the existing pulse-only `SkeletonBlock` for Wallets instead of adding shimmer/package dependencies; its reduce-motion behavior remains centralized in `MotionSpec`.
- Do not force an `AnimatedSwitcher` around Home slivers in Phase 1 because that would replace the current sliver render strategy; defer keyed list transitions to the shared lazy list work in Phase 4.
- Treat Phase 1 as code-complete but acceptance-pending until visual, screenshot, and list-performance smoke checks are performed on a device/emulator.

## [Phase 1] - 2026-07-10 10:52
- Keep Phase 2 blocked behind Phase 1 visual acceptance rather than treating a narrow unit test as evidence for rendering, scroll performance, or fancy-mode behavior.

## [Phase 1] - 2026-07-10 11:11
- Keep `AnimatedSwitcher` only for the empty/list state in Transactions; a category filter is a data update, not a page transition, so the list key must remain stable to prevent text overlap.
