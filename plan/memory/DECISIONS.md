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

## [Phase 1] - 2026-07-10 11:25
- Do not mark Phase 1 accepted from the passing widget test alone; rendering, screenshot comparison, fancy-mode behavior, and list scrolling require a live device/emulator.
- Keep the existing `assets/images/` warning separate from motion acceptance because it does not fail the scoped widget test and is outside this phase's UI behavior.

## [Phase 1] - 2026-07-10 11:40
- Close Phase 1 after user confirmation; the remaining live-device checks are treated as accepted for this handoff.

## [Phase 2] - 2026-07-10 11:40
- Use `Tween(end: value)` in shared motion primitives so `TweenAnimationBuilder` interpolates from its current rendered value when providers emit a new amount/progress.
- Keep privacy-masked money values static; do not animate hidden balances into visible numeric frames.
- Preserve existing text overflow and layout APIs when replacing `Text` with `AnimatedMoneyText`.
- Apply progress motion first to existing `LinearProgressIndicator` locations; do not introduce new layout, providers, or animation packages.

## [Phase 2] - 2026-07-10 11:52
- Extend the same primitive to Wallets and Transactions summaries because they are compact, value-focused surfaces; leave list rows and large data-heavy lists untouched until the keyed/lazy list phase.

## [Phase 2] - 2026-07-10 12:05
- Reuse `AnimatedProgressBar` in Wallet Detail instead of maintaining a second local progress renderer, so value duration and reduce-motion behavior remain centralized while preserving the existing overflow track/value colors.
- Animate Wallet Detail's current balance with `AnimatedMoneyText`; keep the initial-balance reference text static because only the provider-derived current value changes.

## [Phase 3] - 2026-07-10 12:32
- Use `AnimatedSwitcher` for the formatted amount string rather than changing `AmountInputController`; this keeps numpad/input behavior and amount validation untouched while adding visible feedback.
- Wrap ChoiceChip with `PressableScale(deferTapToChild: true)` so the chip remains the owner of selection semantics and the new press effect cannot duplicate the selection callback.
- Set `_isSubmitting` before budget/wallet checks and reset it in `finally`; this covers confirmation-dialog waits as well as repository writes without changing the existing transaction payload.

## [Phase 3] - 2026-07-10 12:45
- Prefer the shared `AnimatedMoneyText` for Add Transaction amount after confirming `AmountInputController.value` is numeric and `SummaryCard` already uses the same `formatVND` path. This keeps duration, tabular figures, curve, and reduce-motion behavior consistent across finance surfaces.

## [Phase 3] - 2026-07-10 16:54
- Close Phase 3 after the user's manual test confirmation and proceed to Phase 4 without reopening the older plan drafts.

## [Phase 4] - 2026-07-10 16:54
- Use one shared sliver with lightweight row descriptors instead of prebuilding grouped widget lists; this preserves the existing Riverpod data inputs while making actual row construction lazy.
- Keep two presentation styles (`plain` and `filledHeader`) so Home/Wallet Detail and Transactions retain their existing hierarchy and divider treatment.
- Apply `MotionListItem` only to transaction rows, not day headers, and keep animation built-in/reduce-motion-aware to avoid adding a package or making group labels visually noisy.
- Keep stable key-to-index lookup in the sliver delegate so filtered/updated lists can preserve keyed child state without a linear scan per lookup.

## [Phase 4] - 2026-07-10 17:05
- Close Phase 4 after the user's manual test confirmation and proceed directly to Phase 5.

## [Phase 5] - 2026-07-10 17:05
- Use the implicit `PieChartData`/`BarChartData` tweening already provided by `fl_chart 0.68.0`, configured through shared `MotionSpec`, instead of adding controllers, custom painters, or another animation package.
- Keep pie touch index state inside `_CategoryPieChart`; only the chart should rebuild for radius feedback, not the legend/list around it.
- Preserve prior data while Riverpod refreshes when `AsyncValue` still has a value, allowing chart values to tween rather than replacing the chart with a loading surface on every date-range change.
- Add the Stats summary as a plain Material data surface above both tabs; do not add Liquid Glass around summaries or charts.
- Treat Phase 5 as code-complete but acceptance-pending until live-device checks cover date ranges, tooltips, themes, accessibility motion settings, and chart performance.
