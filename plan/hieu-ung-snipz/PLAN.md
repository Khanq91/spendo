# PLAN — Hiệu ứng từ Snipz: nav lơ lửng · reveal list · notice slide-in · nền hạt

> Nối tiếp `old-plan/loan-theo-doi/PLAN.md` (GĐ1 xong, commit `550b591`).
> **File này thắng** cho mọi quyết định của đợt này; quy tắc UI chung vẫn theo
> HANDOFF-STATE mục 2–3 và quy trình mục 5
> (`plan/ui-info/ui-audit/design_handoff_spendo_redesign/HANDOFF-STATE.md`).
>
> Nguồn tham khảo: repo **Snipz** `D:\program\data\flutterDev\project\snipz`,
> thư mục `lib/components/<id>/` — mỗi component là 1 file Dart, không dep
> ngoài, có README ghi rõ số liệu gốc. Luật của Snipz khi port: **không sửa
> logic bên trong entry file**, chỉ đổi style qua constructor. Ở Spendo, luật
> đó áp cho `particle_field.dart` (copy nguyên). Ba hiệu ứng còn lại KHÔNG
> copy nguyên được (lý do ở mục 2) → dựng lại theo số liệu gốc.
>
> Cập nhật bảng tiến độ mục 1 khi xong từng GĐ.

## 0. Bối cảnh — cái gì đang có, cái gì đổi

| Vùng | Hiện trạng (AS-IS) | Đổi thành |
|---|---|---|
| Bottom nav | 2 nav: **Bình thường** = `SpendoBottomNav` thanh đặc 80px, pill brand sau icon ([spendo_nav.dart:17](../../lib/shared/widgets/spendo/spendo_nav.dart)); **Xịn xò** = `GlassTabBar.bottom` của liquid_glass, đã lơ lửng ([app_bottom_nav.dart:116](../../lib/shared/widgets/app_bottom_nav.dart)) | Bình thường → Snap Rail lơ lửng. Xịn xò giữ nguyên GlassTabBar. |
| Danh sách | Giao dịch = sliver chung có `MotionListItem` (fade + trượt 10px, so le 30ms, chỉ lượt build đầu) ([grouped_transaction_sliver.dart:61](../../lib/features/transactions/presentation/widgets/grouped_transaction_sliver.dart)). Các list khác = `ListView(children:)` tĩnh, Danh mục = `ReorderableListView`. Không list nào reveal khi cuộn tới. | Mọi list **dữ liệu** pop-in (scale 0.7→1 + fade, `easeOutBack`) lần đầu lọt ≥50% viewport, so le ở batch đầu. Không gradient mép. |
| Thông báo | **31** `showSnackBar` trong **19** file, toàn bộ là Material SnackBar floating ở đáy (theme tại [app_theme.dart:408](../../lib/core/theme/app_theme.dart)). 8 cái có nút Hoàn tác 5s. 21 cái là lỗi "Không … được", còn lại thành công/thông tin. Sheet đang mở thì snackbar bị sheet che. | 1 kiểu duy nhất: pill rơi từ mép trên, dot màu theo loại; 8 cái Hoàn tác cũng slide-in nhưng có nút và dot màu cố định. |
| Nền Xịn xò | `AuroraThemeBackground` 4 blob + parallax cảm biến nghiêng, dùng ở `AppShell` (fancy) và `WelcomeScreen` (luôn) | `ParticleField` (copy nguyên từ Snipz) + blur nhẹ 1 lượt cả lớp, thay ở cả 2 chỗ. Aurora xoá. |

Baseline trước khi làm: `flutter analyze` sạch · **390 test** (đo bằng `flutter test`
trước GĐ0; 394 sau GĐ0) ·
version `1.7.26+31`.

---

## 1. Tiến độ

| GĐ | Nội dung | Trạng thái | Commit |
|---|---|---|---|
| 0 — Chip ôm chữ | Sửa `SpendoChip` nở full width trong `Wrap` (bug), + pop 1.12 spring kiểu Choice Chips khi chọn | ✅ xong | `23476e8` |
| 1 — Nav lơ lửng | Snap Rail thay `SpendoBottomNav` (chế độ Bình thường), `extendBody` cả 2 mode | ⬜ chưa | |
| 2 — Reveal list | `RevealScope`/`RevealItem` dùng chung, áp 10 màn list dữ liệu, xoá `MotionListItem` | ⬜ chưa | |
| 3 — Notice slide-in | `NoticeHost` + `AppNotice.show`, thay 31 `showSnackBar`, xoá `snackBarTheme` | ⬜ chưa | |
| 4 — Nền hạt | `ParticleField` + blur thay Aurora ở Shell + Welcome, sửa copy, bỏ `sensors_plus` | ⬜ chưa | |

Quy trình mỗi GĐ: analyze → test → build apk → tự kiểm mục 5 → **1 commit** →
cập nhật bảng này → dừng chờ duyệt. Version bump patch mỗi GĐ có code
(quy ước `plan/memory/PROGRESS.md`).

---

## 2. Quyết định đã chốt với user (2026-09-02)

### 2.1 Snap Rail chỉ cho chế độ Bình thường
Xịn xò giữ `GlassTabBar.bottom` (đã lơ lửng, có jelly indicator riêng của
package). Lý do user chọn: không đụng liquid glass. Hệ quả: 2 mode có motion
nav khác nhau — chấp nhận.

### 2.2 Reveal = hiệu ứng, không phải widget list
`RevealList` gốc là một `ListView.separated` riêng, kèm tap-selection và
gradient mép. Spendo không dùng được nguyên vì: (a) 3 list giao dịch là
**sliver** trong `CustomScrollView`; (b) Danh mục là `ReorderableListView`;
(c) hàng đã có tap/Dismissible riêng, không cần selection; (d) gradient mép
là overlay màu đặc → ở Xịn xò nền trong suốt sẽ lộ vệt (README gốc cảnh báo).
→ Dựng lại phần lõi thành cặp `RevealScope` (bọc scrollable bất kỳ) +
`RevealItem` (bọc từng hàng), giữ đúng số liệu: scale 0.7→1, fade, 260ms,
`easeOutBack`, ngưỡng 50%, so le 80ms batch đầu, reveal đúng 1 lần.
**Không gradient mép.**

Phạm vi = list **dữ liệu**: Giao dịch (Home · tab Giao dịch · Ví chi tiết),
Ví, Khoản vay + Sổ theo dõi, Thanh toán trong khoản vay, Lịch trả góp,
Nhắc nhở, Hạn mức, Danh mục, breakdown Thống kê. **Không** áp cho: nhóm
Cài đặt, hub Tính năng, form/sheet, dải chip ngang, dải ví ngang ở Home.

### 2.3 Tất cả thông báo là slide-in, kể cả Hoàn tác
"Ngoại trừ" trong yêu cầu = **dot màu**: thông báo Hoàn tác có dot màu cố
định (trung tính), không theo loại. Component gốc không có action → mở rộng
có chủ đích: slot nút chữ bên phải, thời gian 5s như SnackBar cũ.

Bảng loại → dot → thời gian:

| Loại | Dot | Tự ẩn | Ví dụ |
|---|---|---|---|
| `success` | `spendo.income` | 2,2s | "Đã kết nối Google Drive." |
| `info` | `spendo.brand` | 2,2s | "Thông báo sẽ hiện sau 5 giây" |
| `warning` | `spendo.warning` | 3,2s | "Giao dịch của khoản vay — xoá từ màn khoản vay." |
| `error` | `cs.error` | 3,2s | "Không lưu được giao dịch. Thử lại." |
| `undo` | `cs.outline` (cố định) | 5s | "Đã xoá 120.000 ₫" + nút Hoàn tác |

Lệch bản gốc có chủ đích: lỗi/cảnh báo 3,2s thay vì 2,2s (đọc kịp câu dài);
message tối đa 2 dòng thay vì 1 (câu tiếng Việt dài hơn "New message
received"). Pill dùng `inverseSurface/onInverseSurface` — giữ đúng tương phản
của SnackBar hiện tại ở cả sáng/tối, không lấy màu hex của kinetics.

### 2.4 Nền hạt thay hẳn Aurora, cả Welcome
`AuroraThemeBackground` xoá. Mất parallax theo cảm biến nghiêng (ParticleField
chỉ có parallax theo chạm, và luật "không sửa logic entry file" không cho
thêm input nghiêng) → `sensors_plus` không còn ai dùng, gỡ khỏi pubspec.
Copy ở Welcome ("Nền aurora và hiệu ứng mềm hơn.") và Cài đặt › Giao diện
("Aurora + liquid glass…") sửa theo.

---

## 3. Thiết kế từng GĐ

### GĐ0 — Chip ôm chữ (bug) + pop kiểu Choice Chips

**Triệu chứng:** chip danh mục / gợi ý ghi chú mỗi cái chiếm trọn một dòng.
**Nguyên nhân (đã đo bằng widget test):** [spendo_chip.dart:111](../../lib/shared/widgets/spendo/spendo_chip.dart)
dựng chip bằng `Container(height: 34, alignment: Alignment.center)` không có
`width`. Theo hợp đồng của `Container`, có `alignment` + parent cho maxWidth
hữu hạn → nó **nở hết maxWidth** rồi mới căn con. `Wrap` cho con
maxWidth = bề ngang màn → chip rộng 800/800; `ListView` ngang cho width vô
hạn → chip ôm chữ (121). Vì thế chỗ nào dùng `Wrap` là hỏng, chỗ dùng
`ListView` ngang (bộ lọc Giao dịch, gợi ý inline dưới ô ghi chú, gợi ý Nhắc
nhở) thì bình thường.

9 chỗ đang hỏng (đều là `Wrap` chứa `SpendoChip`): Danh mục trong form Nhắc
nhở · Danh mục + Ví trong sheet lọc Giao dịch · Gợi ý trong màn Ghi chú
(`note_picker_screen`) · Chọn danh mục để đặt hạn mức · Loại ví trong form Ví
· Preset kỳ trong `period_picker_sheet` · Ví trong `sepay_mapping_sheet` ·
meta chips ở Khoản vay chi tiết / form / trả góp / thêm thanh toán.

**Sửa:** bỏ `alignment` khỏi `Container` (Row bên trong đã tự căn giữa dọc
theo `height`) — 1 dòng, sửa cả 9 chỗ cùng lúc, không đụng call-site. Thêm
test khoá: chip trong `Wrap` rộng < parent.

**Thêm hiệu ứng Choice Chips (Snipz `choice_chips.dart`, class `PopChips`):**
khi tap, chip pop `AnimatedScale` 1 → 1.12 giữ 300ms `Cubic(0.34,1.56,0.64,1)`
rồi về 1; màu nền/chữ crossfade 200ms `ease` (`AnimatedContainer` +
`AnimatedDefaultTextStyle`). Gốc là multi-select; ở Spendo `selected` vẫn do
parent giữ nên tự nhiên là **chọn đơn** — không cần port class `PopChips`,
chỉ ghép pop + crossfade vào `SpendoChip`. Kích pop chỉ khi chip có `onTap`;
`meta` không pop (là read-out, không phải lựa chọn). Reduce motion → không
pop, đổi màu tức thì. Lưu ý gốc: pop 1.12 vẽ tràn bounds chip → không bọc
chip bằng clip sát (PressableScale hiện chỉ clip khi có `borderRadius`, chip
không truyền → OK). Giữ luật 2.9 HANDOFF: nền đặc, không viền.

Test: `spendo_chip_test.dart` thêm 2 case — hug width trong Wrap; tap →
scale 1.12 rồi về 1, reduce-motion không scale.

### GĐ1 — Nav lơ lửng (Snap Rail)

Số liệu gốc (`snap_rail.dart`): khung radius pill, padding 4, ô chia **đều**
(`Expanded`), pill = 1 ô, `AnimatedPositioned` 450ms `Cubic(0.34,1.56,0.64,1)`,
pill = accent 16% fill + 50% border, label active đổi màu 250ms `ease`.

Áp vào Spendo:
- Sửa tại chỗ `SpendoBottomNav` trong [spendo_nav.dart](../../lib/shared/widgets/spendo/spendo_nav.dart)
  — giữ tên class, API (`destinations/selectedIndex/onSelected`), key
  `spendo_tab_$i`, haptic `lightImpact`, `Semantics(button, selected)`.
- Khung: cao 64, margin ngang 16, cách đáy `safeArea.bottom + 12`, nền
  `cs.surfaceContainer`, viền 1px `cs.outlineVariant`, bóng nhẹ chỉ ở sáng
  (như `SpendoFab`). Pill: `spendo.brand` 16% / viền 50%, radius pill.
- Ô = icon 20 + label 11 xếp dọc (app có label, bản gốc chỉ label — giữ
  label vì 4 tab đã quen). Active: icon + label màu `spendo.brand`.
- Reduce motion: `appMotion.whenMotionAllowed` → cả 2 duration về 0.
- `AppShell`: `extendBody: true` cho **cả 2 mode** (trước chỉ fancy) để nội
  dung cuộn dưới nav. Scaffold tự đặt FAB lên trên nav và tự bơm
  `MediaQuery.padding.bottom` = chiều cao nav cho body.
- Rà 4 tab: Home/Giao dịch/Thống kê đã có spacer 96 ở đáy → đủ. Cài đặt
  đang cộng `paddingOf.bottom` chỉ khi fancy → bỏ điều kiện, cộng luôn.

Test: sửa 4 test `SpendoBottomNav` trong
[spendo_components_test.dart:124](../../test/shared/widgets/spendo/spendo_components_test.dart)
(pill giờ là `AnimatedPositioned`, không còn `ShapeDecoration` sau icon);
thêm test pill dời `left` khi đổi index; reduce-motion không animate.

### GĐ2 — Reveal list

File mới `lib/shared/widgets/motion/reveal.dart` (export qua `motion.dart`):
- `RevealScope({child})`: `NotificationListener<ScrollNotification>` + đăng ký
  item; sweep sau post-frame và mỗi scroll notification; đo bằng
  `RenderAbstractViewport.maybeOf` + `getOffsetToReveal` (chạy được cho cả
  sliver lẫn ListView — y hệt gốc). Giữ `Set<Object> _revealed`.
- `RevealItem({required Object id, child})`: `FadeTransition` +
  `ScaleTransition` 0.7→1, `easeOutBack`, `appMotion.listDuration` (260ms =
  gốc), stagger gấp vào `Interval` của controller như gốc (không `Timer`).
  Reduce motion → controller value 1 ngay.
- **Khác gốc có chủ đích:** identity theo `id` (transaction.id, wallet.id…)
  thay vì index — list dữ liệu xoá/lọc làm index trượt, theo index sẽ reveal
  sai hàng hoặc replay hàng cũ.
- Thêm `MotionSpec.revealStagger = 80ms` (gốc); `staggerShort` 30ms giữ cho
  chỗ khác.

Áp vào (bọc `RevealScope` quanh scrollable, `RevealItem` ngoài cùng mỗi hàng,
ngoài `Dismissible`):

| Màn | Scrollable | Hàng |
|---|---|---|
| Home, Giao dịch, Ví chi tiết | `CustomScrollView` | `_TransactionRow` trong sliver chung — thay `MotionListItem` |
| Ví | `ListView` | `_WalletTile` + hàng lưu trữ |
| Khoản vay / Sổ theo dõi | `ListView` | card khoản vay |
| Khoản vay chi tiết | `ListView` | hàng thanh toán |
| Lịch trả góp | `ListView` | hàng đợt |
| Nhắc nhở | `ListView` | tile nhắc nhở |
| Hạn mức | `ListView` | hàng danh mục có hạn mức |
| Danh mục | `ReorderableListView.builder` | tile danh mục (item vẫn keyed; proxy kéo là widget riêng nên không ảnh hưởng) |
| Thống kê | 3 `ListView` | hàng legend danh mục, hàng breakdown ngày |

Day header trong sliver giao dịch **không** reveal (giữ quyết định Phase 4).
`MotionListItem` chỉ còn 1 chỗ dùng → xoá file + export.

Test: `reveal_test.dart` — batch đầu reveal so le; hàng ngoài viewport chỉ
reveal khi cuộn tới; cùng `id` không replay sau rebuild; reduce-motion tức
thì. Chạy lại test màn Giao dịch/Home vì hàng khởi đầu opacity 0 (hit-test
vẫn ăn, `find.text` vẫn thấy — chỉ ảnh hưởng test có so màu/ảnh).

### GĐ3 — Notice slide-in

Số liệu gốc (`notification_slide_in.dart`): `AnimatedSlide` -1.6 → 0 trong
550ms `Cubic(0.18,1.25,0.4,1)`, `AnimatedOpacity` 300ms `ease`, cùng curve cho
cả vào lẫn ra (không `reverse()`), đồng hồ tự ẩn là `AnimationController`
(không `Timer`), retrigger khi đang hiện chỉ gia hạn đồng hồ, không replay
cú rơi. Pill: padding 11×18, gap 9, dot 8px, radius pill, chữ 13.

File mới `lib/shared/widgets/notice/`:
- `notice_slide_in.dart` — widget port, thêm 2 param: `action` (label +
  callback, vẽ bên phải, `spendo.brand` 13/600, tap → gọi rồi ẩn ngay) và
  `maxLines: 2`. Giữ nguyên máy trạng thái gốc.
- `app_notice.dart` — `enum NoticeKind {success, info, warning, error, undo}`
  và `AppNotice.show(String message, {NoticeKind kind = info, NoticeAction?
  action})`. Không cần `BuildContext` → bỏ được pattern "bắt `messenger`
  trước async gap" ở 19 file. Lõi là `ValueNotifier<NoticeRequest?>`
  singleton có `reset()` cho test.
- `notice_host.dart` — gắn qua `MaterialApp.builder` trong
  [main.dart:78](../../lib/main.dart): `Stack[child, Positioned(top:
  safeTop + 12) NoticeSlideIn]`. Nằm **trên** Navigator nên hiện đè cả
  sheet/dialog — sửa luôn điểm yếu SnackBar bị sheet che.

Thay 31 điểm gọi theo bảng 2.3. Riêng 8 điểm Hoàn tác: `kind: undo`,
`action: NoticeAction('Hoàn tác', onPressed)`, giữ nguyên logic restore và
thông báo lỗi khôi phục (thành `error`). Debug panel: bỏ `backgroundColor`
tự chế, dùng `kind`. Xoá `snackBarTheme` trong `app_theme.dart` (không còn
SnackBar nào). `clearSnackBars()` → không cần: retrigger tự thay message.

Test: `notice_host_test.dart` — show/ẩn theo `requestId`; auto-dismiss đúng
thời gian theo loại; nút Hoàn tác gọi callback và ẩn; retrigger gia hạn không
replay; reduce-motion.

### GĐ4 — Nền hạt

- Copy nguyên `snipz/lib/components/particle_field/particle_field.dart` →
  `lib/shared/widgets/particle_field/particle_field.dart` (giữ header
  Origin, không sửa logic).
- File mới `lib/shared/widgets/particle_theme_background.dart` thay
  `AuroraThemeBackground`:
  ```
  RepaintBoundary(
    Stack[
      ColoredBox(scaffoldBackgroundColor),
      ImageFiltered(blur σ=1.6, child: ParticleField(
        colors: [spendo.brand, cs.primary, cs.secondary, cs.tertiary],
        density: 4, maxParticles: 260, baseSize: 3,
        speed: 0.6, twinkle: true, interactive: true,
      )),
    ])
  ```
  Blur **1 lượt cho cả lớp** (`ImageFiltered`) thay vì `softParticles: true`
  (MaskFilter cho từng hạt — README gốc cảnh báo tốn perf). Nền phẳng vẽ
  riêng bên dưới để blur không ăn ra mép.
- Thay ở [app_bottom_nav.dart:67](../../lib/shared/widgets/app_bottom_nav.dart)
  và [welcome_screen.dart:104](../../lib/features/onboarding/presentation/welcome_screen.dart);
  xoá `aurora_theme_background.dart`; gỡ `sensors_plus` khỏi pubspec (chỉ
  Aurora dùng); sửa 2 câu copy (mục 2.4).
- Ticker: `ParticleField` dùng `createTicker` → tự dừng khi route bị đè
  (TickerMode) và khi widget offstage; không cần `animate: false` thủ công.

Test: `particle_theme_background_test.dart` pump 1 frame không lỗi ở sáng/tối;
test Welcome hiện có chạy lại.

---

## 4. Rủi ro & điểm cần để mắt

- **GĐ1 `extendBody` ở mode Bình thường**: nội dung cuộn dưới nav mà nav
  có nền đặc bo tròn → phần lộ ra 2 bên là màu scaffold, đúng ý "lơ lửng".
  Nếu màn nào thiếu spacer đáy sẽ bị nav che hàng cuối — rà 4 tab khi tự kiểm.
- **GĐ2 chi phí sweep**: mỗi scroll notification duyệt các item *đang được
  build và chưa reveal* (thường < 20) → rẻ, như gốc. Không đo `RenderBox`
  của hàng đã reveal.
- **GĐ2 + Dismissible**: `RevealItem` bọc ngoài `Dismissible`; key vẫn nằm
  trên `KeyedSubtree`/`RevealItem` để sliver delegate tìm được index.
- **GĐ3 thông báo chồng nhau**: gốc chỉ có 1 pill; message mới thay message
  cũ và gia hạn đồng hồ. Với Hoàn tác: thông báo khác đến trong 5s sẽ thay
  mất nút Hoàn tác — chấp nhận, SnackBar Material cũng xếp hàng chứ không
  hiện song song.
- **GĐ4 perf**: ~120 `drawCircle` + 1 blur toàn màn mỗi frame + liquid glass
  ở fancy. Adaptive glass quality đã có; nếu máy yếu giật thì hạ `density`
  3 hoặc σ 1.2 — chỉ đổi số, không đổi cấu trúc.
- **GĐ4 mất parallax nghiêng** — user đã đồng ý (mục 2.4). Muốn lấy lại thì
  vào backlog, phải fork `particle_field.dart` (vi phạm luật copy nguyên).

---

## 5. Nghiệm thu

- GĐ1: chuyển tab → pill trượt spring, không nhảy; FAB nằm trên nav; 4 tab
  không bị che hàng cuối; tắt animation hệ thống → pill nhảy tức thì; Xịn xò
  không đổi.
- GĐ2: mở Giao dịch → hàng pop-in so le; cuộn xuống → hàng mới pop-in đúng
  lúc lọt nửa; cuộn lên lại không replay; xoá/lọc không replay hàng còn lại;
  kéo thứ tự Danh mục vẫn hoạt động.
- GĐ3: lưu lỗi trong sheet → pill rơi từ trên **đè lên sheet**; xoá giao
  dịch → pill có Hoàn tác, bấm là khôi phục; 5 loại dot đúng màu ở sáng/tối;
  không còn `SnackBar` nào trong `lib/` (`grep`).
- GĐ4: Xịn xò + Welcome nền hạt mờ nhẹ, không viền lạ ở mép; đổi theme
  màu hạt đổi theo; push trang con rồi quay lại không giật; `sensors_plus`
  đã gỡ.
- Mỗi GĐ: `flutter analyze` sạch · `flutter test` xanh · APK debug OK.

---

## 6. Backlog (không làm lần này)

- Parallax nghiêng cho nền hạt (cần fork painter).
- Snap Rail cho mode Xịn xò (user chọn giữ GlassTabBar).
- Gradient mép cho list ở mode Bình thường (user chọn bỏ).
- `SnapRail` dạng bộ chọn kỳ (Ngày/Tuần/Tháng) — đúng use-case gốc, có thể
  thay `SpendoPeriodStepper`/chip chọn kỳ sau.
