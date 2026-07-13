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

## [Phase 5] - 2026-07-10 18:23
- Close Phase 5 after the user's manual test confirmation and proceed to Phase 6.

## [Phase 6] - 2026-07-10 18:23
- Split the broad secondary-screen phase into small presentation-only slices: expansion timing, CTA/loading state, local list feedback, and visual-mode selection feedback.
- Reuse MotionSpec and Flutter built-ins instead of adding a package; every new duration respects the existing reduce-motion policy.
- Animate only the Loan payment block and Reminder list block when their IDs change, rather than transitioning an entire screen or modifying repository/provider behavior.
- Keep Settings plain and data-focused; improve hierarchy and selected-state feedback without adding Liquid Glass to the long settings list.
- Do not turn the supplied analyzer output into a broad deprecated-API cleanup pass; fix Phase 6 regressions and safe unused imports, then record the remaining pre-existing diagnostics separately.

## [Phase 6] - 2026-07-10 18:32
- Treat app-version bumping as a required completion step for every plan implementation session that changes code, not as optional release cleanup.
- Increment both patch version and build number once per completed code-delivery session so user-visible versioning and Android/iOS build identity advance together; skip the bump for documentation-only sessions.

## [Phase 6] - 2026-07-10 19:12
- Close Phase 6 after the user's manual test confirmation and proceed directly to Phase 7.

## [Phase 7] - 2026-07-10 19:12
- Use liquid_glass_widgets root adaptiveQuality as the device-performance ceiling instead of creating a custom benchmark; persist the settled tier so repeat cold starts avoid a fresh warm-up window.
- Keep the inherited theme and interactive controls at GlassQuality.standard; reserve premium requests for fixed focal surfaces such as the fancy bottom nav and onboarding hero, while allowing adaptive fallback to minimal.
- Do not add a user-facing standard/premium preference in this phase. Quality remains derived from the existing normal/fancy presentation choice plus package device policy, avoiding a new provider/settings migration.
- Accept the package's annotated experimental adaptive config with a scoped analyzer ignore and focused tests because it is the installed package's intended API for automatic quality capping; keep the opt-in isolated in main.dart.
- Use RepaintBoundary only around the existing heavy fixed glass surfaces and do not expand Liquid Glass into data-heavy or long-scroll surfaces.

## [Phase 7] - 2026-07-10 19:19
- Close Phase 7 from the user's manual test confirmation and treat the Phase 0-7 roadmap as complete.
- Do not invent a Phase 8 because `plan/03-ui-motion-refactor-master-plan.md` ends at Phase 7; any follow-up work must be separately scoped.
- Keep version 1.7.6+11 because this closeout changes tracker documentation only.

## [Phase 1] - 2026-07-13 09:55
- Chỉ xử lý STAB-001 vì đây là finding Critical duy nhất và có rollback boundary nhỏ; không gộp session/account boundary rộng hơn vào cùng thay đổi.
- Giữ nguyên constructor và API Supabase/PowerSync hiện tại. Dùng seam upload/acknowledge nhỏ để test retry invariant mà không thêm mocking package.
- Propagate exception gốc và cố ý không complete CRUD transaction. Remote operation thành công một phần có thể bị retry, nên tính idempotent vẫn cần staging test ở mức cao hơn.

## [Phase 7] - 2026-07-13 10:21
- Chọn ARCH-004 làm issue duy nhất của session vì tạo quality gate nhỏ, kiểm chứng được và không chạm business state, database hoặc navigation.
- Xóa placeholder test thay vì tạo smoke test giả cho app bootstrap; các test hiện có đã cung cấp 9 assertion paths thực, còn bootstrap đầy đủ phụ thuộc plugin/native services và cần fixture riêng.
- Đặt test gate ngay sau `flutter pub get` và trước keystore/build để CI fail sớm, không cần secret ký APK khi test đã lỗi.
- Dọn APK cũ sau khi APK mới đã build/rename thành công và ngay trước upload; nếu tag `latest` chưa tồn tại thì bỏ qua, đồng thời giữ nguyên các asset không phải APK.
- Chưa thêm analyzer/format gate: baseline hiện còn 139 diagnostics và 66 file lệch format; bật gate tuyệt đối trong cùng diff sẽ làm CI đỏ vì debt ngoài scope. Ratchet phải là issue riêng.

## [Phase 7] - 2026-07-13 11:56
- Neo regex theo đầu dòng và token `severity -` thay vì tìm severity ở bất kỳ vị trí nào; cách này đếm đúng cả warning không thụt lề lẫn info có thụt lề, đồng thời tránh metadata/footer.
- Chỉ sửa độ chính xác báo cáo của wrapper trong session này. Analyzer ratchet CI là tradeoff riêng vì baseline vẫn cố ý exit 1 với 139 diagnostic hiện có.

## [Phase 4] - 2026-07-13 12:26
- Giữ nguyên tên các Riverpod provider và kiểu dữ liệu UI nhận qua `AsyncValue`, nhưng đổi implementation từ one-shot `FutureProvider` sang `StreamProvider` để dependency thực sự là thay đổi của bảng `transactions`.
- Dùng một aggregate CTE cho toàn bộ Ví active thay vì gọi `calculateBalance`/`getIncomeExpense` tuần tự theo từng Ví; đây là thay đổi query cục bộ, không đổi model, schema hoặc state management.
- Cho phép inject `PowerSyncDatabase` vào repository nhưng giữ constructor mặc định dùng global `db`; seam này bổ sung testability mà không buộc các caller hiện tại thay đổi.
- Ghim `sqlite3 2.4.5` và `sqlite_async 0.8.3` dưới dev_dependencies đúng các phiên bản đã có trong lock để test factory có thể nạp PowerSync/SQLite native binary; không upgrade hoặc thay package production.
- Giữ các one-shot repository method hiện có để tránh đổi API ngoài nhu cầu; provider mới chỉ dùng các watch method bổ sung.
