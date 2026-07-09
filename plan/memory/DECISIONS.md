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
