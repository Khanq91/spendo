# PLAN — Review 09/2026: sửa bug · cờ cloud · tính năng nhỏ · dọn repo/docs

> Nối tiếp `plan/hieu-ung-snipz/PLAN.md` (GĐ4 xong, commit `35ccac7`, docs `588e43d`).
> **File này thắng** cho mọi quyết định của đợt này; quy tắc UI chung vẫn theo
> HANDOFF-STATE mục 2–3 và quy trình mục 5
> (`plan/ui-info/ui-audit/design_handoff_spendo_redesign/HANDOFF-STATE.md`).
>
> Nguồn: 1 lượt review toàn project ngày 2026-09-03 (3 lượt quét song song:
> hygiene/dead code · tầng dữ liệu · UI/feature gap) + `audit/TECHNICAL_AUDIT.md`
> tháng 7 để đối chiếu cái nào còn mở.
>
> Cập nhật bảng tiến độ mục 1 khi xong từng GĐ.

## 0. Bối cảnh

Baseline trước khi làm: `flutter analyze` sạch · **420 test** xanh · version
`1.7.31+36` · CI build APK chạy test nhưng chưa chạy analyze · 23 dependency
tụt major (không nâng đợt này) · repo pack 30 MB, trong đó
`screenshots/live_app/demo.mp4` 26,5 MB.

Những gì review thấy mà **không** làm đợt này (user chốt): dọn provider chết
(`nearLimitCategoriesProvider`, `incomeCategoriesProvider`,
`deleteCategoryWithUndo`, `activeLoansProvider`, `loanSummaryProvider`,
`dailyTotalsProvider`), `import_service.dart` không ai import, 6 dep không
dùng trong pubspec, nâng dependency. Ghi ở mục 6.

---

## 1. Tiến độ

| GĐ | Nội dung | Trạng thái | Commit |
|---|---|---|---|
| 1 — Bug dữ liệu & thông báo | Khóa loại/tiền gốc khi sửa khoản vay · nhắc nhở tự tiến lịch · quyền thông báo khi tạo nhắc/lịch · `RECEIVE_BOOT_COMPLETED` + `INTERNET` · guard xóa danh mục đủ 3 bảng · restore đặt lại lịch + widget · Drive đăng nhập lại đăng ký lại task nền | ✅ xong — analyze sạch · 439 test · APK debug OK · `1.7.32+37` | (đề xuất) `fix: lock loan type/principal on edit, catch up overdue reminders, boot + notification permissions, category delete guard, restore follow-up` |
| 2 — Bug UI & tính năng nhỏ | Nhân bản giữ loại + ví · notice backup đúng màu · back về Home · bỏ mũi tên back ở tab Cài đặt · ví dùng gần nhất · "Lưu & thêm tiếp" · xuất CSV theo ví | ✅ xong — analyze sạch · 449 test · `1.7.33+38` · APK kiểm gộp ở GĐ3 | (đề xuất) `feat: keep type+wallet on duplicate, back-to-home, last-used wallet, save & add another, per-wallet CSV` |
| 3 — Cờ cloud | `AppConfig.cloudEnabled=false` · gate splash/hub/Bank · sheet đăng nhập/đăng ký (ẩn khi cờ tắt) · xóa migrate no-op | ✅ xong — analyze sạch · 464 test · APK debug OK · `1.7.34+39` | (đề xuất) `feat(cloud): put Supabase/SePay behind AppConfig.cloudEnabled with a sign-in sheet ready for later` |
| 4 — Dọn repo & docs | Bỏ track `report.html`, `audit/flutter_analyze.txt` · `.gitignore`/`.gitattributes` · script chụp màn ghi vào `screenshots/generated/` · CI thêm analyze · README viết lại · `CLAUDE.md` mới, `AGENTS.md` rút gọn trỏ sang | ✅ xong — không đụng code app, không bump | (đề xuất) `chore: untrack generated files, add analyze to CI, rewrite README, add CLAUDE.md` |

Quy trình mỗi GĐ: analyze → test → build apk debug → tự kiểm mục 5 →
cập nhật bảng này. **Không commit** trừ khi user bảo; message đề xuất ghi ở
cột Commit dạng `(đề xuất) …`. Version bump patch mỗi GĐ có code app
(`1.7.32+37` → `1.7.33+38` → `1.7.34+39`; GĐ4 không đụng code app nên không
bump).

---

## 2. Quyết định đã chốt với user (2026-09-03)

### 2.1 Khoản vay: khóa loại + tiền gốc khi sửa
`repo.update` chỉ ghi bảng `loans`; giao dịch gốc, thanh toán và lịch trả góp
không đổi theo → số dư ví lệch, đợt đã trả nhảy về chưa trả. Chọn **khóa**
(giống `is_tracking_only` đã khóa từ PLAN loan-theo-doi §2.2) thay vì lan
sang giao dịch. Muốn đổi thì xóa tạo lại.

### 2.2 SePay + sync: để sẵn sau cờ, không gỡ
User giữ SePay/sync để bật khi server sẵn sàng. Phía app làm xong hẳn:
`AppConfig.cloudEnabled` (const, mặc định `false`) + provider
`cloudEnabledProvider` để test override. Cờ tắt: không `Supabase.initialize`,
không có hàng Ngân hàng ở hub, không listener auth. Cờ bật: sheet đăng nhập /
đăng ký email trong Sao lưu & đồng bộ; Ngân hàng hiện empty state "Cần đăng
nhập" thay vì lỗi; PowerSync connect sau `signedIn` (code cũ đã có).

### 2.3 Phạm vi
Sửa bug (GĐ1–2) · tính năng nhỏ (GĐ2) · cờ cloud (GĐ3) · dọn repo + docs
(GĐ4). Không dọn provider/dep chết, không nâng dependency — "dọn xong mà app
sập" là rủi ro user không muốn nhận đợt này.

### 2.4 Dependency
Không nâng. Chỉ kiểm tra kỹ: analyze + test + build apk sau mỗi GĐ.

---

## 3. Thiết kế từng GĐ

### GĐ1 — Bug dữ liệu & thông báo

| # | Bug | Sửa | Test |
|---|---|---|---|
| 1 | Sửa khoản vay đổi được loại + tiền gốc | `loan_form_sheet.dart`: khi `_isEdit`, segmented loại → chip meta read-only, numpad ẩn, số tiền hiện tĩnh kèm chú thích "Loại và tiền gốc cố định sau khi tạo — xoá tạo lại nếu cần". `_submit` khi edit luôn dùng `existing.type/principal`. | `loan_form_sheet_test`: edit không có segmented/numpad, lưu giữ nguyên principal |
| 4 | `next_trigger` chỉ tiến khi bấm thông báo | `RecurringReminder.calcNextTrigger` nhận `now`; thêm `isOverdueAt(now)`, `nextTriggerAfter(now)`, `warnTriggerAfter(now)`. `ReminderRescheduleService.catchUp(reminders)` chạy ở `main._initServices` trước `scheduleAll`: reminder active có trigger đã qua → ghi DB, rồi `scheduleAll` đặt lại cả warn. `toggleActive` ghi luôn `next_trigger`. Subtitle "Lần tới" dùng `nextTriggerAfter(now)` nên không bao giờ hiện ngày quá khứ. | unit `recurring_reminder_test` (daily/weekly/monthly, không đổi khi chưa qua, warn sống lại); `reminder_catch_up_test`; `reminders_screen_test` subtitle |
| 5 | Thiếu quyền boot | `AndroidManifest.xml`: `RECEIVE_BOOT_COMPLETED`, `INTERNET` (release đang nhờ google_sign_in merge). | — (manifest) |
| 6 | Quyền thông báo chỉ xin ở toggle hằng ngày | `NotificationService.ensurePermission()`: xin quyền; `null` (Android < 13) hoặc plugin vắng → coi như có, chỉ `false` mới cảnh báo. Gọi ở `reminder_form_sheet._submit` và `installment_schedule_screen._save`; từ chối → `AppNotice.warning` nhưng vẫn lưu. | form test hiện có vẫn lưu được khi plugin vắng |
| 8 | Xóa danh mục chỉ check `transactions` | `CategoryRepository.delete` đếm `transactions`, `recurring_reminders`, `category_budgets`; ném lỗi nói rõ cái nào chặn ("còn 2 nhắc nhở"). Xóa được thì dọn `detected_habits` của danh mục. Màn Danh mục: xóa chạy trong `confirmDismiss` để hàng bị chặn không biến mất rồi hiện lại; hint nói đủ 3 thứ chặn. | `category_integrity_test`: 3 case chặn + 1 case xóa dọn habit |
| 9 | Restore không đặt lại lịch nhắc/widget | `lib/core/services/restore_followup.dart`: `runRestoreFollowUp()` = catchUp + scheduleAll reminder · `LoanRescheduleService.rescheduleAll` · `WidgetSync.syncCategories`, mỗi bước best-effort; `backup_screen._refreshData` gọi + invalidate thêm ví/khoản vay/nhắc nhở/hạn mức. | `restore_followup_test` với hàm inject như `gdrive_background_backup_test` |
| 10 | Drive sign-in không đăng ký lại task nền | `gdrive_provider`: tách `_syncPeriodicTask(freq)` dùng chung cho `setFrequency` và `signIn` thành công; dùng const `autoGDriveBackupTaskName`; try/catch (plugin vắng trong test). | — (plugin) |

### GĐ2 — Bug UI & tính năng nhỏ

| # | Việc | Sửa |
|---|---|---|
| 2 | Nhân bản thu → chi, mất ví | `showAddTransactionSheet` thêm `initialIsExpense`; `_duplicate` truyền `isExpense` + `walletId` (`preselectedWalletId` đã có). |
| 3 | Backup báo thành công màu lỗi | 3 điểm `_snack(..., kind: success)`; thêm notice sau `exportCSV`. |
| 7 | Back hệ thống thoát app ở tab khác | `AppShell` bọc `PopScope(canPop: tab == home)`; pop ở tab khác → về Home. |
| 11 | Mũi tên back chết ở tab Cài đặt | `SpendoScreenHeader.showBack` (mặc định true); Cài đặt truyền false. |
| F1 | Ví dùng gần nhất | pref `last_wallet_id`; sheet thêm mới (không edit, không preselected) chọn sẵn ví đó nếu còn và chưa lưu trữ; lưu xong ghi lại. Vẫn bỏ được ("Không ghi vào ví"). |
| F2 | "Lưu & thêm tiếp" | nút phụ trong sheet thêm (chỉ khi thêm mới): lưu, giữ loại/danh mục/ví/ngày, reset số tiền + ghi chú, notice success ngắn. |
| F3 | Xuất CSV theo ví | `ExportService.exportCSV(range, {walletId})`; menu Ví chi tiết thêm "Xuất CSV". |

### GĐ3 — Cờ cloud

- `AppConfig.cloudEnabled = false` + `cloudEnabledProvider`.
- `main._initServices`: `Supabase.initialize` + bước "Đang kết nối máy chủ…"
  chỉ khi cờ bật; `openDatabase(setupSync: cloudEnabled)`.
- `powersync_db.dart`: xóa `_migrateLocalDataIfNeeded` (no-op + delay 2 s),
  `_migrateWalletId`/`_migrateSource` (ALTER trên view luôn throw, cột đã
  có từ schema).
- `lib/features/auth/`: `auth_provider.dart` (session stream + actions
  signIn/signUp/signOut, inject được), `presentation/widgets/sign_in_sheet.dart`
  (email + mật khẩu, chuyển Đăng nhập ⇄ Đăng ký, lỗi inline, busy).
- Sao lưu & đồng bộ: nhóm "TÀI KHOẢN SPENDO" chỉ khi cờ bật — chưa đăng nhập:
  nút Đăng nhập; đã: email + Đăng xuất (confirm sheet).
- Hub Cài đặt: hàng Ngân hàng chỉ khi cờ bật; subtitle "Cần đăng nhập" khi
  chưa có session. `bank_screen`: chưa đăng nhập → `SpendoEmptyState` có nút
  mở sheet đăng nhập, FAB ẩn.
- Test: hub/bank/backup ở cả 2 trạng thái cờ; sheet đăng nhập với actions giả.

### GĐ4 — Dọn repo & docs

- `git rm --cached report.html audit/flutter_analyze.txt`; `.gitignore` thêm 2
  file đó, bỏ dòng `/lib/structure.txt`; `.gitattributes` (`* text=auto`,
  `*.mp4 *.png *.jpg binary`). `demo.mp4` **giữ track** (bỏ khỏi HEAD không
  nhỏ lịch sử; có track thì `rm -rf` nhầm còn `git checkout` lại được).
- `scripts/run_screenshots.ps1/.sh`: chỉ xóa thư mục output sinh ra, chừa
  `screenshots/live_app/`.
- CI: bước `flutter analyze --no-pub` trước test.
- README viết lại theo app hiện tại (11 bảng, ví/vay/nhắc/hạn mức danh
  mục/backup Drive/reset/visual mode, cờ cloud, không còn auth email khi cờ
  tắt).
- `CLAUDE.md` mới: analyzer gate, quy trình PLAN/GĐ, không commit khi chưa
  bảo, Snipz vault, tiếng Việt. `AGENTS.md` rút còn vài dòng trỏ sang
  `CLAUDE.md` (Codex vẫn đọc được).

---

## 4. Rủi ro & điểm cần để mắt

- **GĐ1 #4 catch-up ở startup** chạy trước `scheduleAll`, thêm 1 UPDATE mỗi
  reminder đã qua hạn — ít hàng, rẻ. Reminder là synced table → khi cloud bật
  sẽ sinh PATCH op, chấp nhận.
- **GĐ1 #6** `requestNotificationsPermission` trả `null` ở thiết bị < Android
  13 → coi như có; chỉ `false` mới cảnh báo.
- **GĐ2 F2** "Lưu & thêm tiếp" giữ ngày: nếu user đang nhập cho hôm qua thì
  giao dịch tiếp theo cũng hôm qua — đúng ý "thêm tiếp cùng đợt".
- **GĐ3** `cloudEnabledProvider` override được trong test nhưng runtime là
  const → không có toggle ẩn; bật = sửa 1 dòng + build.
- **GĐ4** `git rm --cached` chỉ đổi HEAD; file vẫn nằm trên đĩa và bị ignore
  từ đó.

---

## 5. Nghiệm thu

- GĐ1: sửa khoản vay không đổi được loại/tiền; nhắc nhở quá hạn mở app lên là
  "Lần tới" nhảy sang kỳ sau và warn được đặt lại; tạo nhắc nhở lần đầu trên
  Android 13 hiện hộp xin quyền; xóa danh mục đang có nhắc nhở bị chặn có lý
  do và hàng không biến mất; khôi phục backup xong không cần mở lại app để có
  lịch nhắc.
- GĐ2: nhân bản giao dịch thu ra giao dịch thu cùng ví; "Đã xuất…" dot xanh;
  back ở tab Thống kê về Home, back ở Home mới thoát; Cài đặt không có mũi
  tên; thêm giao dịch mở lên đã có ví lần trước; "Lưu & thêm tiếp" giữ danh
  mục.
- GĐ3: cờ tắt — splash không có bước máy chủ, hub không có Ngân hàng; cờ bật
  (test) — có nhóm Tài khoản, Ngân hàng hiện "Cần đăng nhập".
- GĐ4: `git status` sạch sau khi chạy script chụp màn; CI có analyze; README
  khớp cây `lib/`.
- Mỗi GĐ: `flutter analyze` sạch · `flutter test` xanh · APK debug OK.

---

## 6. Backlog (không làm lần này)

- Dọn provider chết + `import_service.dart` + 6 dep không dùng
  (`riverpod_annotation`, `build_runner`, `riverpod_generator`,
  `cupertino_icons`, `uuid`, `collection`); `flutter_launcher_icons` sang
  dev_dependencies.
- Nâng dependency theo nhóm (riverpod 3, go_router 18, powersync 2, fl_chart
  1.x, flutter_local_notifications 22).
- Chuyển tiền giữa ví · tự tạo giao dịch khi nhắc nhở nổ · rollover hạn mức ·
  số dư trên widget nhỏ.
- Clamp text scale 1.3 + đổi `height:` cố định sang `minHeight` ở chip/segmented.
- Tap target/Semantics cho X trên chip, X ô tìm kiếm, ô icon trong form danh mục.
- `category_matcher`: rule cho nhà/du lịch/phim/gym/thú cưng, bỏ token mơ hồ
  (`nước`, `vé`, `xe`), highlight ô vừa tự chọn.
- `SpendoConfirmDialog` thay 7 `AlertDialog` M3; Note picker bỏ `AppBar` thô.
- Snipz port tiếp: `pull_reveal_refresh`, `expanding_search`, `step_progress`,
  `tab_pill_glide`.
- Rewrite history để bỏ `demo.mp4` (quyết định riêng, phá hash commit).
