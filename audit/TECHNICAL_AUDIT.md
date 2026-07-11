# Spendo — Evidence-based Technical Audit

Ngày audit: 2026-07-10 đến 2026-07-11

## 1. Executive summary

Spendo có nền tảng offline-first rõ ràng, feature folder nhất quán, Riverpod/GoRouter/PowerSync được dùng xuyên suốt và transaction list đã có lazy sliver. Tuy vậy, audit xác nhận một lỗi Critical trong hàng đợi đồng bộ: CRUD transaction bị gọi complete ngay cả khi upload Supabase lỗi, vì vậy thay đổi có thể mất khả năng retry và cloud lệch local. Các rủi ro High tiếp theo nằm ở backup/restore không đầy đủ, background Drive backup không khởi tạo Supabase trong isolate, số dư Ví không reactive theo giao dịch, auth Supabase không có đường vào UI, và dữ liệu wallet vượt qua ranh giới synced/local-only không nhất quán.

UI có đủ loading/empty state ở một số luồng và ảnh live cho thấy hệ thống visual mode hoạt động. Tuy nhiên, lỗi provider có thể bị hiển thị như “không có dữ liệu”, ảnh live ghi nhận lỗi render khi thu gọn Danh mục ở Settings, và reduce-motion chưa bao phủ splash, Aurora cùng carousel Ví. Không có số đo profile mobile trong phiên này; mọi nhận định về thời gian khởi động, frame hoặc pin được gắn Likely và kèm cách đo.

### Baseline đã chạy

- Flutter 3.44.0, Dart 3.12.0, DevTools 2.57.0; SDK tại D:\program\data\flutterDev\flutter\bin.
- flutter pub get --dry-run --enforce-lockfile và flutter pub get --enforce-lockfile đều thành công, không đổi resolution. Lockfile đang dùng PowerSync 1.8.5, Riverpod 2.6.1, GoRouter 14.8.1 và Supabase Flutter 2.12.4.
- dart format --output=none --set-exit-if-changed . thất bại: 62/122 file sẽ bị format lại. Chế độ output=none không sửa file.
- scripts/analyze_codex.bat tạo lại audit/flutter_analyze.txt: 139 diagnostics, gồm 0 error, 20 warning, 119 info. Footer ghi Warnings = 0 là sai vì regex ở scripts/analyze_codex.bat:113-115 đòi khoảng trắng trước từ warning trong khi diagnostic bắt đầu ngay bằng warning.
- flutter test --no-pub: 7 test pass, suite fail vì test/widget_test.dart:1-30 chỉ còn comment và không có main.
- flutter devices chỉ thấy Windows desktop và Edge; không có Android/iOS device hoặc emulator. integration_test/screenshot_test.dart không được chạy.
- Đã xem 5 ảnh chuẩn, 24 ảnh live và screenshots/live_app/ui_error/a94e39195eeedfb086ff.jpg. File MP4 có tồn tại nhưng viewer/browser/video decoder đều không hoạt động trong sandbox hiện tại, nên video không được dùng làm bằng chứng kết luận.
- Production Dart/native/schema/dependency không bị chỉnh sửa trong audit.

### Giới hạn xác minh

- Supabase migrations, RLS policies, PowerSync server sync rules và SePay webhook: Not found in codebase.
- Service-role key, private key, TLS bypass hoặc SSL validation bị tắt: Not found in codebase. Supabase anon key trong lib/core/config.dart:2-4 là public client key, không được phân loại như service secret.
- Cold-start, frame timeline, memory allocation, battery/GPU và scrolling profile trên thiết bị mobile: Not measured.

## 2. Architecture map

### Bootstrap và navigation

lib/main.dart:58-88 khởi tạo SharedPreferences, Liquid Glass và Workmanager, rồi chạy ProviderScope. _AppRoot ở lib/main.dart:91-103 hiển thị SplashScreen; _initServices ở lib/main.dart:107-154 khởi tạo Supabase, PowerSync DB, notification, reminder, widget sync và cleanup theo chuỗi. StartupGate ở lib/features/onboarding/presentation/startup_gate.dart:16-38 kiểm tra onboarding trước khi vào SpendoApp, sau đó MaterialApp.router dùng appRouter. AppShell giữ ba tab Transactions/Home/Settings bằng IndexedStack tại lib/shared/widgets/app_bottom_nav.dart:76-103.

### Luồng offline-first thực tế

UI screen/widget
→ Riverpod Provider/StreamProvider/FutureProvider
→ Repository tạo trực tiếp từ Provider
→ global PowerSyncDatabase db
→ SQLite local
→ SupabasePowerSyncConnector
→ Supabase Postgres

Luồng này áp dụng cho transactions, categories, budgets và recurring_reminders. Connector thêm user_id khi upsert tại lib/core/db/powersync_connector.dart:47-52. Server schema, RLS và sync rules không có trong repo nên quyền sở hữu phía server không thể được xác minh.

Các bảng category_budgets, detected_habits, wallets, loans và loan_payments là localOnly theo lib/core/db/schema.dart:22-73. Chúng không đi qua PowerSync upload. Dù vậy transactions.wallet_id là trường của bảng synced, tạo ranh giới dữ liệu không nhất quán được ghi ở ARCH-002.

### Các luồng song song

- Auth/session: Supabase.initialize ở lib/main.dart:113-118; auth state providers ở lib/features/auth/presentation/providers/auth_provider.dart:4-15; AuthScreen gọi email/password auth. Không có route/caller cho AuthScreen và không có Supabase signOut trong repo.
- Settings/preferences: Theme, visual mode, notification time, widget pins, onboarding và Drive metadata lưu qua SharedPreferences.
- Google Drive: Settings → gdriveProvider → GDriveAuthService/GDriveBackupService → BackupService/repositories → Drive appDataFolder. Workmanager gọi cùng luồng trong background isolate.
- SePay: SepayAccountsNotifier gọi trực tiếp Supabase table sepay_bank_accounts; không có repository, webhook hoặc server handler trong repo.
- Home widget: CategoryRepository/WidgetSync → SharedPreferences/HomeWidget → Android native widgets.
- Notification: Settings/reminder providers → NotificationService/ReminderNotificationService → flutter_local_notifications.

Không có use-case layer hoặc DI container độc lập. Đây không tự động là lỗi; vấn đề chỉ được ghi khi UI phụ thuộc trực tiếp DB/repository hoặc trách nhiệm lan rộng gây khó test.

## 3. Findings

### STAB-001 — CRUD queue bị xóa khi upload cloud thất bại

- Nhóm / Mức độ / Độ tin cậy / Effort: Stability / Critical / Confirmed / M.
- Vị trí: lib/core/db/powersync_connector.dart:29-63.
- Bằng chứng: uploadData lấy một CRUD transaction, upload từng operation, rồi gọi tx.complete ở dòng 59. Khối catch ở dòng 60-62 cũng gọi tx.complete trước khi rethrow. complete đánh dấu transaction đã xử lý; lỗi network, RLS hoặc payload vì vậy không còn transaction để retry.
- Tác động: local vẫn có dữ liệu nhưng cloud có thể thiếu put/patch/delete; sync đa thiết bị và backup cloud trở nên không đáng tin. Nếu vài operation đầu thành công rồi operation sau lỗi, batch còn có thể lệch một phần.
- Tái hiện/đo: dùng connector test double làm Supabase throw ở operation thứ nhất và thứ hai; sau uploadData, gọi getNextCrudTransaction lần nữa và xác nhận transaction hiện bị mất.
- Giải pháp ít rủi ro: chỉ complete sau khi toàn bộ CRUD upload thành công; giữ transaction pending khi throw. Thêm test cho network/RLS failure và idempotent retry.
- Rủi ro khi sửa: retry operation đã thành công một phần; upsert an toàn hơn patch/delete nhưng vẫn cần kiểm tra idempotency và thứ tự.

### STAB-002 — Background Google Drive backup khởi tạo DB trước Supabase

- Nhóm / Mức độ / Độ tin cậy / Effort: Stability / High / Confirmed / M.
- Vị trí: lib/main.dart:23-40, 113-118; lib/core/db/powersync_db.dart:10-24, 59-78; lib/features/settings/presentation/providers/gdrive_provider.dart:168-188.
- Bằng chứng: callbackDispatcher chạy trong background isolate và gọi openDatabase ở main.dart:31 trước mọi Supabase.initialize. openDatabase luôn gọi _setupSync, nơi truy cập Supabase.instance tại powersync_db.dart:60 và 66. Supabase chỉ được khởi tạo trong _initServices của UI isolate. Periodic task thực sự được đăng ký ở gdrive_provider.dart:178-187.
- Tác động: autoGDriveBackup có thể fail trước signInSilently/uploadBackup; tùy chọn hàng ngày/tuần/tháng cho người dùng cảm giác đã bật nhưng không tạo backup nền.
- Tái hiện/đo: chạy callback entrypoint trong isolate/process sạch không gọi _initServices; kiểm tra task result và gdrive_last_backup_time.
- Giải pháp ít rủi ro: tạo bootstrap background riêng, khởi tạo Supabase trước DB hoặc mở DB ở chế độ backup không setup sync/auth listener; thêm Workmanager integration test.
- Rủi ro khi sửa: double initialization, nhiều auth listener hoặc cạnh tranh cùng file DB giữa UI/background isolate.

### STAB-003 — “Backup toàn bộ” bỏ sót dữ liệu local-only quan trọng

- Nhóm / Mức độ / Độ tin cậy / Effort: Stability / High / Confirmed / M.
- Vị trí: lib/core/utils/backup_service.dart:16-31, 100-189; lib/core/db/schema.dart:21-25, 48-73; lib/features/wallets/data/wallet_repository.dart:23-27; lib/features/settings/presentation/screens/settings_screen.dart:561-585.
- Bằng chứng: payload có wallets, categories, transactions, recurring_reminders, category_budgets và loans, nhưng không có monthly budgets hoặc loan_payments. WalletRepository.getAll chỉ lấy is_archived = 0 nên ví đã lưu trữ bị bỏ. BackupResult/UI success cũng không đếm loans/payments/monthly budgets.
- Tác động: restore có thể mất lịch sử trả nợ, ngân sách tháng và liên kết transaction với ví archived. loans/loan_payments/wallets là localOnly nên không có PowerSync cloud copy thay thế.
- Tái hiện/đo: tạo một monthly budget, archived wallet, loan kèm payment; export JSON rồi restore vào DB sạch và so sánh row count/các liên kết.
- Giải pháp ít rủi ro: tăng backup schema version, export/restore mọi bảng user-owned, bao gồm archived rows và quan hệ; thêm manifest row counts/checksum và round-trip test.
- Rủi ro khi sửa: tương thích backup v1-v3, thứ tự restore foreign references và kích thước file.

### STAB-004 — Restore có thể ghi một phần rồi thất bại

- Nhóm / Mức độ / Độ tin cậy / Effort: Stability / High / Confirmed / M.
- Vị trí: lib/core/utils/backup_service.dart:204-259, 276-405, 425-434.
- Bằng chứng: _validate chỉ kiểm app/version và hai list bắt buộc; sau đó cast Map/List trực tiếp và insert tuần tự loans, wallets, categories, transactions, reminders, budgets. Không có database transaction hoặc rollback.
- Tác động: file hỏng/khác schema có thể insert vài bảng trước khi TypeError/DB exception; UI chỉ bắt exception nên DB còn trạng thái partial, lần restore sau lại skip một phần theo ID.
- Tái hiện/đo: backup có wallet hợp lệ ở đầu và category sai type phía sau; gọi restore, bắt lỗi rồi query wallet/category counts.
- Giải pháp ít rủi ro: validate toàn bộ payload thành typed DTO trước khi ghi; thực hiện một write transaction; chỉ invalidate provider sau commit.
- Rủi ro khi sửa: transaction lớn, migration schema cũ và chính sách xử lý row không hợp lệ cần được quyết định rõ.

### STAB-005 — Startup deduplicate category có thể tạo reference mồ côi

- Nhóm / Mức độ / Độ tin cậy / Effort: Stability / High / Confirmed / M.
- Vị trí: lib/core/db/powersync_db.dart:18-24, 48-56; lib/features/categories/data/category_repository.dart:31-57; lib/core/utils/backup_service.dart:131-140, 481-493.
- Bằng chứng: mỗi openDatabase xóa mọi duplicate theo name,is_income và giữ MIN(id), nhưng không remap transactions, reminders hoặc category_budgets. CategoryRepository.add không chặn tên trùng. Backup không lưu is_default và restore luôn insert is_default = 0, làm khả năng trùng default/custom tăng.
- Tác động: transaction hoặc reminder có thể trỏ category đã bị xóa; UI hiện “Không rõ”, budget/habit mất liên kết, và delete có thể sync lên cloud.
- Tái hiện/đo: chèn hai category cùng tên, tạo transaction trỏ ID lớn hơn, restart/openDatabase rồi kiểm tra left join category null.
- Giải pháp ít rủi ro: bỏ delete mù; áp unique policy ở write boundary, chọn canonical ID và remap mọi reference trong một transaction trước khi xóa.
- Rủi ro khi sửa: merge category đồng tên nhưng khác ý nghĩa/màu/icon; cần preview và backup trước migration.

### STAB-006 — Retention xóa dữ liệu dựa trên backup “gần đây”, không phải backup hiện tại

- Nhóm / Mức độ / Độ tin cậy / Effort: Stability / High / Confirmed / M.
- Vị trí: lib/main.dart:157-173; lib/core/services/gdrive_backup_service.dart:139-150; lib/shared/widgets/app_bottom_nav.dart:35-73.
- Bằng chứng: hasRecentBackup chỉ kiểm file Drive mới nhất không quá 30 ngày. Nếu true, startup xóa mọi transaction quá 730 ngày mà không chứng minh backup chứa row hiện tại, không dùng high-water mark/checksum và không có opt-out riêng.
- Tác động: transaction cũ mới import/chỉnh sau backup gần nhất vẫn có thể bị xóa vĩnh viễn ở lần mở app kế tiếp.
- Tái hiện/đo: tạo backup, sau đó import transaction có created_at cũ hơn 730 ngày, relaunch và query row.
- Giải pháp ít rủi ro: tạm ngừng cleanup tự động; chỉ xóa row đã được snapshot xác nhận bằng backup ID/timestamp/hash, cho người dùng preview/count và rollback.
- Rủi ro khi sửa: tăng dung lượng DB và cần migration metadata cho backup cũ.

### STAB-007 — Cấu hình iOS chưa đủ cho notification, Google Sign-In và backup nền

- Nhóm / Mức độ / Độ tin cậy / Effort: Stability / High / Confirmed / L.
- Vị trí: lib/core/notifications/notification_service.dart:16-44, 144-148; lib/core/services/gdrive_auth_service.dart:12-14; ios/Runner/Info.plist:4-48; ios/Runner/AppDelegate.swift:4-11.
- Bằng chứng: NotificationService chỉ tạo AndroidInitializationSettings và request Android permission. Info.plist không có GID client/URL scheme, BGTask identifiers hoặc background mode; AppDelegate chỉ register plugin. Native config tương ứng: Not found in codebase.
- Tác động: các setting notification/Drive/periodic backup được render trên iOS nhưng luồng có thể không đăng nhập, xin quyền hoặc chạy nền.
- Tái hiện/đo: integration smoke trên iPhone thật: Google login callback, notification permission/schedule và periodic task delivery.
- Giải pháp ít rủi ro: hoặc hoàn thiện Darwin/OAuth/BGTask config theo từng feature, hoặc ẩn/ghi rõ feature không hỗ trợ iOS cho đến khi có test.
- Rủi ro khi sửa: entitlement, App Store background policy, OAuth redirect và khác biệt scheduling của iOS.

### STAB-008 — Exception khởi tạo không có đường thoát khỏi splash

- Nhóm / Mức độ / Độ tin cậy / Effort: Stability / High / Confirmed / M.
- Vị trí: lib/shared/widgets/splash_screen.dart:68-73, 161-193; lib/main.dart:107-154.
- Bằng chứng: _startInit await widget.onInit không có try/catch hoặc timeout/fallback. Supabase.initialize, openDatabase và WidgetSync được await ngoài catch trong _initServices. Chỉ reminder/cleanup có catch cục bộ.
- Tác động: một lỗi DB/plugin/network có thể tạo unhandled future và để splash đứng vĩnh viễn, không retry/offline continuation.
- Tái hiện/đo: inject onInit throw trong widget test; xác nhận không có error state/retry và nextScreen không mở.
- Giải pháp ít rủi ro: model hóa init result theo critical/optional step, thêm error UI + retry; timeout chỉ cho tác vụ thật sự có thể bỏ qua, không nuốt lỗi DB.
- Rủi ro khi sửa: cho vào app khi DB chưa sẵn sàng; phải định nghĩa rõ step nào bắt buộc.

### ARCH-001 — Auth Supabase tồn tại nhưng không thể truy cập từ UI

- Nhóm / Mức độ / Độ tin cậy / Effort: Architecture / High / Confirmed / M.
- Vị trí: lib/features/auth/presentation/screens/auth_screen.dart:4-58; lib/features/auth/presentation/providers/auth_provider.dart:4-15; lib/core/router/app_router.dart:17-59.
- Bằng chứng: AuthScreen có signInWithPassword/signUp và auth providers đã định nghĩa, nhưng router không có auth route, rg không tìm thấy caller/import của AuthScreen ngoài chính file, và Supabase signOut: Not found in codebase. Google login ở onboarding là tài khoản Drive riêng.
- Tác động: người dùng cài mới không có luồng bật Supabase session, nên PowerSync cloud sync và SePay mapping phụ thuộc session không thể dùng theo UI hiện tại.
- Tái hiện/đo: cài sạch, duyệt onboarding/Settings/All Features và xác nhận không có entry Supabase login; kiểm currentSession luôn null.
- Giải pháp ít rủi ro: thêm một entry auth rõ ràng trong Settings/onboarding, trạng thái signed-in/signed-out và sign-out có xử lý dữ liệu local; không biến auth thành gate bắt buộc cho offline mode.
- Rủi ro khi sửa: account switching và ownership của dữ liệu offline hiện có phải được giải quyết trước khi công khai sign-out.

### ARCH-002 — wallet_id được sync nhưng bảng wallets chỉ local

- Nhóm / Mức độ / Độ tin cậy / Effort: Architecture / High / Confirmed / L.
- Vị trí: lib/core/db/schema.dart:4-12, 48-56; lib/features/settings/presentation/providers/sepay_provider.dart:43-62; lib/features/wallets/data/wallet_repository.dart:98-129.
- Bằng chứng: transactions là synced table và chứa wallet_id, còn wallets là Table.localOnly. SePay lưu wallet_id local vào bảng remote sepay_bank_accounts. Không có cơ chế đồng bộ/remap wallet ID giữa thiết bị hoặc sau reinstall.
- Tác động: transaction từ cloud/SePay có thể trỏ wallet không tồn tại ở thiết bị khác; balance, filter và mapping ngân hàng bị orphan.
- Tái hiện/đo: tạo wallet + transaction trên thiết bị A, sync transaction sang DB B không có wallet, rồi kiểm join/balance và SePay mapping.
- Giải pháp ít rủi ro: quyết định rõ wallet là user-cloud entity hay device-local. Nếu cloud, thêm bảng synced/user_id/RLS và migration; nếu local, không đưa wallet_id local vào record remote mà dùng mapping server-side ổn định.
- Rủi ro khi sửa: migration ID, merge wallet trùng, webhook compatibility và dữ liệu đã sync.

### ARCH-003 — SettingsScreen gom quá nhiều trách nhiệm presentation và data orchestration

- Nhóm / Mức độ / Độ tin cậy / Effort: Architecture / Medium / Confirmed / M.
- Vị trí: lib/features/settings/presentation/screens/settings_screen.dart:26-783 và 785-1501.
- Bằng chứng: file 1501 dòng vừa build export/backup/SePay/Drive/theme/notification/widget/category UI, vừa new CategoryRepository, gọi BackupService/ImportService, invalidate provider và sở hữu nhiều dialog/result type. Screen còn watch categoriesProvider ở dòng 31 nên thay đổi category rebuild toàn bộ screen.
- Tác động: blast radius lớn, unit test khó, xử lý dialog async lặp lại và thay đổi một integration dễ ảnh hưởng layout khác.
- Tái hiện/đo: dependency graph/file coverage; thay provider category trong widget test và đếm build của toàn Settings.
- Giải pháp ít rủi ro: tách từng section thành widget/controller nhỏ theo dependency hiện tại; giữ Riverpod và public behavior, không dựng thêm use-case layer nếu chưa cần.
- Rủi ro khi sửa: mất state scroll/dialog context và vô tình đổi visual hierarchy; tách theo từng section với golden/widget test.

### ARCH-004 — Quality gate không chạy test/analyzer và test suite hiện đang đỏ

- Nhóm / Mức độ / Độ tin cậy / Effort: Architecture/Testability / Medium / Confirmed / S.
- Vị trí: test/widget_test.dart:1-30; .github/workflows/flutter-build.yml:37-56; audit/flutter_analyze.txt.
- Bằng chứng: toàn bộ widget_test.dart bị comment nên flutter test fail vì thiếu main. CI chỉ pub get và build release APK; không có flutter test, analyzer hoặc format check. Test hiện có tập trung motion/stats/list, không có repository/sync/auth/backup/SePay coverage.
- Tác động: lỗi queue/backup/background nêu trong báo cáo có thể merge và release mà CI vẫn xanh.
- Tái hiện/đo: chạy flutter test --no-pub như baseline; inspect workflow.
- Giải pháp ít rủi ro: sửa/xóa placeholder test, thêm test job trước; thêm analyzer ratchet theo số error/warning thay vì buộc dọn 139 diagnostics trong một PR.
- Rủi ro khi sửa: CI ban đầu đỏ do debt hiện có và plugin native; tách unit/widget khỏi device integration.

### ARCH-005 — Baseline format/analyzer tạo ma sát nâng SDK

- Nhóm / Mức độ / Độ tin cậy / Effort: Architecture/Maintainability / Low / Confirmed / M.
- Vị trí: audit/flutter_analyze.txt; scripts/analyze_codex.bat:104-115; các diagnostic được ghi trong log.
- Bằng chứng: 62/122 file không đạt dart format; analyzer có 20 warning và 119 info, gồm unused code, async-context và deprecated API. Wrapper đếm warning sai.
- Tác động: diff lớn khi format/nâng SDK, warning thật dễ bị chìm và báo cáo CI sai số.
- Tái hiện/đo: hai lệnh baseline đã ghi ở Executive summary.
- Giải pháp ít rủi ro: sửa counter trước, ratchet diagnostic theo nhóm, format theo feature trong PR riêng sau khi khóa behavior test.
- Rủi ro khi sửa: broad formatting gây conflict với worktree/branch đang phát triển.

### STATE-001 — Provider Ví không reactive theo transaction và tạo N+1 query

- Nhóm / Mức độ / Độ tin cậy / Effort: State / High / Confirmed / M.
- Vị trí: lib/features/wallets/presentation/providers/wallet_provider.dart:21-70, 73-94; lib/features/wallets/data/wallet_repository.dart:108-129.
- Bằng chứng: balance/breakdown watch walletsProvider rồi chạy one-shot query transactions. walletTxByMonth/walletTxAll cũng chỉ watch WalletRepository.watchAll trước khi query transaction. Add/edit/delete transaction không làm stream bảng wallets emit. total providers lặp calculateBalance/getIncomeExpense tuần tự cho từng wallet.
- Tác động: số dư, net worth, breakdown và lịch sử theo wallet có thể stale sau giao dịch; nhiều wallet tạo 2N query và tăng latency.
- Tái hiện/đo: watch walletBalanceProvider, insert transaction trực tiếp, chờ stream và xác nhận provider không emit; log SQL với 20 wallet.
- Giải pháp ít rủi ro: repository expose db.watch cho aggregate/join transaction theo wallet; dùng một GROUP BY query cho tổng toàn bộ wallet.
- Rủi ro khi sửa: SQL reactive dependency, null wallet và archived wallet semantics; cần provider tests trên DB fixture.

### PERF-001 — Startup bị serialize và có network path không timeout

- Nhóm / Mức độ / Độ tin cậy / Effort: Performance / High / Likely / M.
- Vị trí: lib/main.dart:107-154, 157-173; lib/shared/widgets/splash_screen.dart:91-193; lib/core/services/gdrive_backup_service.dart:72-109, 139-150; lib/core/services/gdrive_auth_service.dart:66-76.
- Bằng chứng: splash chờ tuần tự Supabase → DB/migrations/sync → notification → reminder scheduling → widget sync → cleanup, cộng delay 100/200/500 ms và animation entry/exit. Cleanup gọi Drive files.list qua HTTP client không timeout/cancellation.
- Tác động dự kiến: cold start dài hoặc treo khi Drive/network không phản hồi; chưa có số đo mobile nên không tuyên bố mức chậm cụ thể.
- Tái hiện/đo: profile build trên Android thật, trace từng step bằng TimelineTask, đo p50/p95 cold-start offline/slow network và time-to-first-interactive.
- Giải pháp ít rủi ro: chỉ gate UI bằng DB và state bắt buộc; chạy cleanup/widget/reminder/Drive sau first frame, song song khi độc lập; timeout có error state cho network.
- Rủi ro khi sửa: UI đọc service chưa init, race schedule duplicate và task bị OS kill.

### PERF-002 — Habit analysis có thể full-scan mỗi lần mở khi không phát hiện habit

- Nhóm / Mức độ / Độ tin cậy / Effort: Performance / Medium / Likely / M.
- Vị trí: lib/features/reminders/presentation/screens/reminders_screen.dart:20-25; lib/features/habits/presentation/providers/habit_provider.dart:17-20; lib/features/habits/data/habit_detector.dart:18-85.
- Bằng chứng: mở Reminders watch autoDispose FutureProvider và gọi analyze. Throttle lấy analyzed_at từ detected_habits; nếu phân tích không tạo row thì bảng trống, throttle luôn false. _runAnalysis tải toàn bộ expense note, group/sort/tính variance trên UI isolate rồi upsert tuần tự.
- Tác động dự kiến: history lớn nhưng không đủ pattern vẫn bị scan mỗi lần vào màn hình, gây latency/jank và DB churn.
- Tái hiện/đo: seed 10k-100k expense notes duy nhất, mở/đóng Reminders nhiều lần trong profile và đo query/CPU frame.
- Giải pháp ít rủi ro: lưu last_analysis_at độc lập kết quả, chỉ chạy khi transaction version đổi; batch/upsert và cân nhắc isolate cho phần CPU.
- Rủi ro khi sửa: suggestion chậm cập nhật hoặc cache invalidation sai.

### PERF-003 — Ba tab được build/giữ sống; timer Home tiếp tục khi tab ẩn

- Nhóm / Mức độ / Độ tin cậy / Effort: Performance / Medium / Likely / M.
- Vị trí: lib/shared/widgets/app_bottom_nav.dart:76-103; lib/features/wallets/presentation/widgets/wallet_card_home.dart:19-48, 92-95.
- Bằng chứng: static _screens đi vào IndexedStack nên Transactions/Home/Settings đều build và giữ state ngay lần vào AppShell. WalletCardHome tạo Timer.periodic mỗi 3 giây và chỉ cancel khi dispose; tab Home offstage không dispose.
- Tác động dự kiến: hidden provider/UI init sớm, wake-up/animateToPage ngoài màn hình và memory cao hơn cần thiết. Chưa đo frame/battery.
- Tái hiện/đo: DevTools provider/CPU timeline khi đứng 2 phút ở Settings; đếm timer callback và widget build, so với lazy tab host.
- Giải pháp ít rủi ro: lazy-create tab lần đầu nhưng giữ state sau đó; pause carousel khi route/tab không active và khi reduce motion bật.
- Rủi ro khi sửa: mất scroll state, tab restoration và Hero/FAB behavior.

### UI-001 — Lỗi dữ liệu bị hiển thị thành empty hoặc bị ẩn

- Nhóm / Mức độ / Độ tin cậy / Effort: UI/UX / High / Confirmed / M.
- Vị trí: lib/features/transactions/presentation/providers/transaction_provider.dart:11-42; lib/features/transactions/presentation/screens/transactions_screen.dart:31-38, 105-142; lib/features/stats/presentation/screens/stats_screen.dart:216-243, 427-451; lib/features/stats/presentation/providers/stats_provider.dart:67-107; lib/features/wallets/presentation/widgets/wallet_card_home.dart:51-59; lib/features/home/presentation/screens/home_screen.dart:89-97.
- Bằng chứng: Transactions chỉ watch filtered list valueOrNull mặc định rỗng và render _EmptyState; Stats chỉ kiểm isLoading rồi dùng derived map rỗng, nên initial Stream.error đi vào _EmptyStats. WalletCardHome trả SizedBox.shrink cho error. Home có Text lỗi nhưng không retry.
- Tác động: người dùng có thể hiểu nhầm dữ liệu tài chính bằng 0/không tồn tại hoặc thấy card biến mất, thay vì biết DB/provider đang lỗi.
- Tái hiện/đo: override transactionsProvider, statsTransactionsProvider, categoriesProvider và walletsProvider bằng Stream.error trong widget tests; xác nhận state hiện tại.
- Giải pháp ít rủi ro: truyền AsyncValue tới screen/state view, kiểm hasError && !hasValue trước empty, dùng error state có retry và giữ dữ liệu cũ khi refresh lỗi nếu có.
- Rủi ro khi sửa: error surface chiếm layout và retry loop; cần phân biệt initial load với refresh.

### UI-002 — Ảnh live ghi nhận render hỏng tạm thời khi chuyển trạng thái Danh mục

- Nhóm / Mức độ / Độ tin cậy / Effort: UI/UX / Medium / Confirmed / S.
- Vị trí: screenshots/live_app/ui_error/a94e39195eeedfb086ff.jpg; lib/features/settings/presentation/screens/settings_screen.dart:471-480, 1194-1350.
- Bằng chứng: ảnh lỗi cho thấy header “Danh mục thu chi” nhưng nội dung category bị ép/chồng thành chuỗi ký tự dọc trên nền Aurora. screenshots/live_app/6098bdd2da255b7b023412.jpg cho thấy state ổn sau transition. _CategoriesExpansionTile cross-fade giữa SizedBox.shrink và Column động nhiều row, nên AnimatedCrossFade layout bị nghi ngờ mạnh nhưng causal root vẫn là Likely.
- Tác động: trong transition, nội dung Settings khó đọc và tạo cảm giác app lỗi; bằng chứng không cho thấy state hỏng là persistent.
- Tái hiện/đo: Fancy + dark mode, cuộn cuối Settings, expand/collapse category với 12+ row; chụp golden ở 0/50/100%, text scale 1/2 và 60/120 Hz. Triệu chứng là Confirmed, nguyên nhân cần runtime xác nhận.
- Giải pháp ít rủi ro: thử conditional child trong ClipRect + AnimatedSize hoặc ExpansionTile chuẩn, giữ width constraints ổn định và thêm widget/golden test cho collapse.
- Rủi ro khi sửa: thay scroll extent, focus và state tab Chi/Thu.

### UI-003 — Reduce-motion policy không bao phủ animation nền, splash và carousel

- Nhóm / Mức độ / Độ tin cậy / Effort: UI/Accessibility / Medium / Confirmed / M.
- Vị trí: lib/shared/widgets/motion/motion_spec.dart:29-37; lib/shared/widgets/aurora_theme_background.dart:16-42, 67-80; lib/shared/widgets/splash_screen.dart:91-193; lib/features/wallets/presentation/widgets/wallet_card_home.dart:30-41; lib/shared/widgets/app_bottom_nav.dart:271-352.
- Bằng chứng: MotionSpec đọc disableAnimations/accessibleNavigation, nhưng Aurora luôn repeat controller + ticker + accelerometer, Splash dùng controller/duration hardcoded, wallet carousel dùng Timer/animateToPage, và normal bottom nav dùng controller/AnimatedContainer 280 ms không hỏi policy.
- Tác động: người dùng bật Reduce Motion vẫn thấy chuyển động toàn màn hình/auto carousel; đồng thời có chi phí GPU/sensor/timer chưa đo.
- Tái hiện/đo: bật Remove animations/Reduce Motion trên device, dùng Fancy mode và quan sát splash/Aurora/wallet; trace controller/sensor.
- Giải pháp ít rủi ro: dùng một policy cho các animation này, stop controller/sensor/timer và render frame tĩnh khi reduce motion.
- Rủi ro khi sửa: trạng thái controller khi setting đổi runtime và chất lượng hình nền Fancy.

### UI-004 — Chart tương tác chưa có semantics chuyên biệt

- Nhóm / Mức độ / Độ tin cậy / Effort: UI/Accessibility / Medium / Confirmed / M.
- Vị trí: lib/features/stats/presentation/screens/stats_screen.dart:302-373, 510-604, 608-726; lib/shared/widgets/motion/animated_progress_bar.dart:29-35.
- Bằng chứng: PieChart/BarChart dùng touch tooltip và màu nhưng không có Semantics wrapper/summary. Toàn repo chỉ có semantics chuyên biệt cho progress bar; legend/daily rows có text nên một phần dữ liệu vẫn đọc được, nhưng quan hệ chart và trạng thái touched không được diễn đạt.
- Tác động: screen-reader/keyboard user không nhận được cùng thông tin tương tác; màu/touch là kênh chính của chart.
- Tái hiện/đo: Accessibility Scanner/TalkBack/VoiceOver trên Stats, duyệt pie/bar và so nội dung đọc với legend/tooltip.
- Giải pháp ít rủi ro: thêm container semantics tóm tắt, MergeSemantics cho legend row, sort traversal và alternative data table; không cần thay chart package.
- Rủi ro khi sửa: announcement dài/lặp với text hiện có.

### UI-005 — Nút chuông Home là control chết

- Nhóm / Mức độ / Độ tin cậy / Effort: UI/UX / Low / Confirmed / S.
- Vị trí: lib/features/home/presentation/screens/home_screen.dart:52-57; screenshots/01_home.png.
- Bằng chứng: IconButton chuông hiển thị rõ nhưng onPressed là callback rỗng.
- Tác động: tap không có feedback, làm giảm độ tin cậy của navigation.
- Tái hiện/đo: tap chuông trên Home; route, dialog và SnackBar đều không đổi.
- Giải pháp ít rủi ro: route tới Reminders/notification settings nếu đó là intent, hoặc ẩn nút đến khi chức năng sẵn sàng.
- Rủi ro khi sửa: cần chốt product intent của icon.

### UI-006 — Aurora làm giảm độ ổn định thị giác của nội dung Fancy

- Nhóm / Mức độ / Độ tin cậy / Effort: UI/UX / High / Confirmed / M.
- Vị trí: screenshots/live_app/6d534e0429f3a8adf1e224.jpg; screenshots/live_app/a7f283a5e452650c3c4319.jpg; screenshots/live_app/a6cb52823575b42bed6414.jpg; lib/shared/widgets/app_bottom_nav.dart:84-104; lib/shared/widgets/aurora_theme_background.dart:176-204.
- Bằng chứng: AppShell làm scaffold/canvas trong suốt trên Aurora. Painter dùng alpha 0.55 ở dark mode và BlendMode.plus; ảnh live cho thấy bloom hồng/tím đi xuyên qua amount, date, action và list surface. Chưa đo contrast ratio nên không tuyên bố fail WCAG.
- Tác động: độ đọc thay đổi theo từng frame/vị trí blob, đặc biệt với số tiền nhỏ và secondary text; người dùng khó quét dữ liệu tài chính.
- Tái hiện/đo: ghi frame ở nhiều thời điểm Aurora, sample foreground/background contrast cho primary/secondary text trên Home/Transactions/Settings và test light/dark.
- Giải pháp ít rủi ro: thêm scrim/surface ổn định phía sau data-heavy content hoặc hạ/cap alpha và blend; giữ glass cho focal surface.
- Rủi ro khi sửa: Fancy mất chiều sâu/brand feel; cần so sánh screenshot với normal mode.

### UI-007 — Filter/tab chips có hit target nhỏ hơn 48 dp

- Nhóm / Mức độ / Độ tin cậy / Effort: UI/Accessibility / Medium / Confirmed / M.
- Vị trí: lib/features/transactions/presentation/screens/transactions_screen.dart:163-233; lib/features/settings/presentation/screens/settings_screen.dart:1365-1400; screenshots/02_transactions.png.
- Bằng chứng: transaction filter bar cao 44 nhưng padding dọc 6 chỉ còn khoảng 32 dp; _FilterChip padding dọc 4. Settings _TabChip là GestureDetector với text 12 và padding dọc 4, không có minimumSize/Material tap target.
- Tác động: khó tap với một tay, motor impairment hoặc màn hình nhỏ; GestureDetector không có ripple/focus semantics chuẩn như InkWell.
- Tái hiện/đo: widget test lấy RenderBox size từng chip và Accessibility Scanner; thử 320 dp width/text scale 2.
- Giải pháp ít rủi ro: thêm ConstrainedBox minHeight 48 và InkResponse/InkWell, giữ visual pill nhỏ bên trong nếu cần.
- Rủi ro khi sửa: tăng chiều cao toolbar/scroll extent.

### UI-008 — Date picker tiếng Anh trong app locale Việt

- Nhóm / Mức độ / Độ tin cậy / Effort: UI/UX / Medium / Confirmed / S.
- Vị trí: screenshots/live_app/0b7bfe3199c6189841d76.jpg; lib/main.dart:91-103; lib/app.dart:34-50; lib/features/loan/presentation/widgets/loan_form_sheet.dart:65-72.
- Bằng chứng: ảnh live hiển thị “Select date”, “Mon, Aug”, “Cancel”, “OK”. App có outer MaterialApp không locale ở main.dart và inner MaterialApp.router locale vi ở app.dart; showDatePicker mặc định dùng root navigator nên dialog lên outer app.
- Tác động: trải nghiệm ngôn ngữ không nhất quán ngay trong flow tạo khoản vay.
- Tái hiện/đo: mở LoanFormSheet và due-date picker sau onboarding; kiểm locale/labels.
- Giải pháp ít rủi ro: useRootNavigator false hoặc cấu hình locale/delegates cho outer MaterialApp; về dài hạn tránh nested MaterialApp.
- Rủi ro khi sửa: dialog z-order/theme và notification navigator context.

### UI-009 — AddTransactionSheet có nguy cơ overflow khi mở bàn phím hệ thống

- Nhóm / Mức độ / Độ tin cậy / Effort: UI/Responsive / High / Likely / M.
- Vị trí: lib/features/transactions/presentation/widgets/add_transaction_sheet.dart:363-673; lib/features/transactions/presentation/widgets/numpad.dart:8-21.
- Bằng chứng: sheet là Column mainAxisSize.min, chỉ cộng viewInsets; custom numpad GridView bốn hàng vẫn tồn tại khi note TextField mở system keyboard. Không có Flexible/scroll constraint cho toàn nội dung.
- Tác động dự kiến: màn hình thấp, split screen hoặc text scale lớn có thể overflow và che CTA/note.
- Tái hiện/đo: widget/device test 320×568, textScaler 2.0, focus note để viewInsets > 0; assert không overflow và CTA reachable.
- Giải pháp ít rủi ro: ẩn/thu custom numpad khi system keyboard mở và bọc phần biến thiên trong constrained scrollable sheet.
- Rủi ro khi sửa: thay đổi chiều cao sheet, focus và cảm giác nhập nhanh.

### UI-010 — Fancy bottom bar phủ phần cuối nội dung Settings

- Nhóm / Mức độ / Độ tin cậy / Effort: UI/Responsive / Medium / Confirmed / S.
- Vị trí: lib/shared/widgets/app_bottom_nav.dart:84-109, 211-249; lib/features/settings/presentation/screens/settings_screen.dart:471-484; screenshots/live_app/6098bdd2da255b7b023412.jpg.
- Bằng chứng: Fancy mode đặt extendBody true; GlassTabBar có barHeight 64 và verticalPadding 16. Settings ListView chỉ chừa SizedBox 32 ở cuối, nhỏ hơn vùng bar + safe inset. Ảnh live cho thấy glass bar nằm trên nội dung cuối.
- Tác động: category/action ở cuối khó cuộn hoàn toàn ra khỏi nav, làm giảm khả năng đọc/tap.
- Tái hiện/đo: Fancy mode trên gesture/3-button navigation, cuộn Settings tới maxScrollExtent và kiểm rect item cuối so với top rect bottom bar.
- Giải pháp ít rủi ro: áp bottom content padding theo nav extent + MediaQuery padding khi extendBody; dùng token chung cho các tab.
- Rủi ro khi sửa: tạo khoảng trắng thừa ở normal mode hoặc double-safe-area.

### SEC-001 — Database local không được scope/clear theo Supabase user

- Nhóm / Mức độ / Độ tin cậy / Effort: Security / High / Likely / M.
- Vị trí: lib/core/db/powersync_db.dart:8-16, 59-78; lib/core/db/schema.dart:22-73.
- Bằng chứng: mọi session dùng file spendo.db cố định. signedOut chỉ db.disconnect, không clear/rekey DB. Nhiều bảng tài chính là localOnly và không có user_id. Hiện UI chưa có Supabase sign-out, nên trigger account switch chưa thể chạy từ app nhưng boundary dữ liệu vẫn thiếu.
- Tác động dự kiến: nếu sign-out/account switch được nối vào UI, user mới trên cùng thiết bị có thể thấy wallets/loans/budgets/habits của user trước; synced rows cũng có thể còn trong local DB đến khi được clear.
- Tái hiện/đo: integration test hai Supabase users trên cùng app data, sign out/in và query mọi table trước/ sau sync.
- Giải pháp ít rủi ro: quyết định offline persona ownership; dùng DB theo user hoặc disconnect-and-clear/migrate local-only data có consent khi đổi account.
- Rủi ro khi sửa: xóa nhầm dữ liệu anonymous chưa sync và migration file DB lớn.

### SEC-002 — Tenancy phụ thuộc RLS/sync rules không có trong repo

- Nhóm / Mức độ / Độ tin cậy / Effort: Security / High / Likely / M.
- Vị trí: lib/core/db/powersync_connector.dart:47-56; lib/features/settings/presentation/providers/sepay_provider.dart:18-26, 34-38, 67-73.
- Bằng chứng: put thêm user_id, nhưng PowerSync patch/delete và SePay toggle/delete chỉ filter id. Supabase SQL migrations/RLS, PowerSync sync rules và webhook authorization: Not found in codebase.
- Tác động dự kiến: nếu server policy thiếu/sai, client có session có thể sửa/xóa row ngoài ownership bằng ID; audit client không thể chứng minh server đang chặn.
- Tái hiện/đo: review/deploy-test bằng hai user trên staging, thử select/update/delete ID của user kia và kiểm sync bucket isolation.
- Giải pháp ít rủi ro: đưa migrations/RLS/sync rules vào version control hoặc tài liệu kiểm chứng; thêm user_id filter defense-in-depth và cross-tenant integration tests.
- Rủi ro khi sửa: client filter không thay thế RLS; policy sai có thể chặn upload hợp lệ và kích hoạt STAB-001 nếu chưa sửa trước.

### SEC-003 — Bảo vệ dữ liệu tài chính at-rest/OS backup chưa được cấu hình

- Nhóm / Mức độ / Độ tin cậy / Effort: Security / Medium / Likely / L.
- Vị trí: lib/core/db/powersync_db.dart:10-16; android/app/src/main/AndroidManifest.xml:5-9; ios/Runner/Info.plist:4-48.
- Bằng chứng: PowerSync DB nằm trong ApplicationDocuments với tên cố định; không thấy SQLCipher/field encryption, Android data-extraction/backup exclusion hoặc iOS backup exclusion. Chính sách threat model: Not found in codebase.
- Tác động dự kiến: dữ liệu giao dịch/ghi chú/loan có thể đi vào OS backup hoặc bị đọc trên thiết bị/backup đã compromise. App sandbox vẫn là lớp bảo vệ cơ bản; đây không phải bằng chứng remote exploit.
- Tái hiện/đo: inspect Android backup rules/application data extraction và iOS container backup trên build release; threat-model rooted/lost-device/desktop backup.
- Giải pháp ít rủi ro: trước hết định nghĩa threat model và exclude DB khỏi backup hệ thống nếu Drive/local backup là nguồn chuẩn; chỉ thêm encryption sau khi có key lifecycle/recovery design.
- Rủi ro khi sửa: mất khả năng restore OS, key loss làm dữ liệu không thể mở và tăng startup cost.

## 4. Top 10 ưu tiên

Công thức: Impact × Frequency × Confidence ÷ Effort. Thang dùng đúng plan: Impact/Frequency 1-4; Confirmed = 1.0, Likely = 0.7, Optional = 0.4; S = 1, M = 2, L = 3. Nếu bằng điểm, severity rồi confidence được ưu tiên. Nếu vẫn hòa, các mục giữ nguyên cùng score; thứ tự trình bày chỉ phản ánh phạm vi người dùng trực tiếp.

| Hạng | ID | I | F | C | E | Điểm | Lý do ưu tiên |
|---:|---|---:|---:|---:|---:|---:|---|
| 1 | ARCH-001 | 4 | 4 | 1.0 | 2 | 8.0 | Cloud sync/SePay không có entry auth cho mọi cài đặt mới. |
| 2 | STATE-001 | 4 | 4 | 1.0 | 2 | 8.0 | Balance/net worth stale ngay trong flow giao dịch thường xuyên. |
| 3 | ARCH-004 | 2 | 4 | 1.0 | 1 | 8.0 | Mỗi thay đổi đều thiếu test gate; suite hiện đỏ nhưng CI vẫn release. |
| 4 | STAB-001 | 4 | 3 | 1.0 | 2 | 6.0 | Critical data-sync integrity; transient upload failure mất retry. |
| 5 | STAB-003 | 4 | 3 | 1.0 | 2 | 6.0 | Mọi backup được quảng bá “toàn bộ” đều thiếu các bảng local-only quan trọng. |
| 6 | STAB-008 | 4 | 3 | 1.0 | 2 | 6.0 | Init exception có thể chặn toàn bộ app ở splash. |
| 7 | UI-001 | 4 | 3 | 1.0 | 2 | 6.0 | Provider error có thể giả thành “không có dữ liệu” trên nhiều bề mặt tài chính. |
| 8 | UI-006 | 3 | 3 | 1.0 | 2 | 4.5 | Fancy background ảnh hưởng khả năng đọc trên Home/Transactions/Settings trong bằng chứng live. |
| 9 | PERF-001 | 3 | 4 | 0.7 | 2 | 4.2 | Startup ảnh hưởng mọi lần cold start; cần profile trước/sau nên confidence Likely. |
| 10 | ARCH-002 | 4 | 3 | 1.0 | 3 | 4.0 | Cross-device/SePay wallet reference sai ranh giới, migration lớn nhưng impact cao. |

STAB-002, STAB-004, STAB-005 và STAB-006 đều có impact rất cao nhưng trigger ít thường xuyên hơn, nên đứng ngay sau Top 10; không nên bỏ qua trong phase bảo toàn dữ liệu.

## 5. Kế hoạch refactor

Mỗi phase là một PR/nhóm PR độc lập; không triển khai quick win trong phiên audit này.

| Phase | Phạm vi | Tiêu chí hoàn thành | Test/đo | Rollback |
|---|---|---|---|---|
| 0 — Safety harness | Tạo DB fixtures và failing regression tests cho STAB-001, backup round-trip, wallet reactivity, category dedup; không đổi behavior. | Mỗi lỗi trọng yếu có test đỏ tái hiện ổn định; snapshot schema/backup v3 được lưu làm fixture. | Unit/integration DB test bằng temp database; flutter test pass ngoài các test cố ý đỏ trên branch harness. | Revert riêng test/fixture; production không đổi. |
| 1 — Sync queue và session boundary | Sửa complete-on-error; định nghĩa retry/idempotency; quyết định DB anonymous/user scope và sign-out policy. | CRUD còn pending sau upload failure; retry thành công một lần; account B không thấy data của A; anonymous data có flow migrate/keep rõ. | Mock connector failure ở từng operation; two-user staging test; PowerSync queue inspection. | Feature flag connector cũ chỉ trong staging; giữ backup DB trước migration, không rollback bằng cách drop queue. |
| 2 — Backup/restore/retention | Backup schema mới gồm monthly budgets, archived wallets, loans/payments và manifest; typed validation + atomic restore; ngừng cleanup dựa trên recent-date đơn thuần. | Round-trip bảo toàn toàn bộ row/reference; malformed file ghi 0 row; cleanup chỉ xóa row có snapshot xác nhận và preview. | Golden JSON v1-v4, DB row/hash comparison, failure injection giữa restore, retention fixture. | Reader vẫn hỗ trợ v1-v3; tắt cleanup bằng flag; không hạ version bằng cách xóa backup mới. |
| 3 — Auth/cloud data model | Nối auth entry/sign-out; chốt wallet synced hay local; version-control RLS/sync rules và SePay authorization contract. | Cài mới login/logout được nhưng offline vẫn dùng; wallet/transaction mapping nhất quán hai thiết bị; cross-tenant requests bị deny. | Two-device/two-user staging, RLS tests, SePay webhook contract test. | Ẩn auth/SePay entry bằng feature flag; giữ migration forward-only và export trước chuyển model. |
| 4 — Reactive state và query | Thay wallet one-shot/N+1 bằng reactive aggregate SQL; xử lý AsyncValue error/refresh nhất quán. | Add/edit/delete transaction cập nhật mọi wallet surface tự động; query count không tăng tuyến tính theo wallet; error không giả empty. | Provider DB tests, SQL trace 1/20/100 wallets, widget tests error/loading/data. | Giữ provider API, swap implementation về query cũ nếu regression; không đổi model UI cùng PR. |
| 5 — Startup/background/platform | Tách critical/optional init; thêm error/retry; bootstrap Workmanager isolate; timeout/cancellation; hoàn thiện hoặc ẩn iOS integrations. | Time-to-interactive không phụ thuộc Drive; background backup cập nhật timestamp/file; init failure có retry; iOS capability matrix đúng UI. | Android profile p50/p95 offline/slow network, Workmanager instrumentation, iPhone notification/OAuth/BGTask smoke. | Feature flag optional tasks, disable periodic registration, giữ synchronous DB init bắt buộc. |
| 6 — UI/accessibility/motion | Sửa category collapse artifact; error/retry surfaces; reduce-motion cho Aurora/splash/carousel; chart semantics; xử lý bell Home. | Không tái hiện ui_error ở light/dark/normal/fancy; TalkBack/VoiceOver đọc chart summary; Reduce Motion tạo frame tĩnh; mọi control có action/feedback. | Widget/golden ở text scale 1.0/1.3/2.0, 320/600/840dp; accessibility scan; device screenshot/video. | Tắt animation mới, dùng layout không animation; giữ component cũ sau flag trong một release. |
| 7 — Maintainability và CI ratchet | Sửa placeholder test/analyzer counter; thêm CI test; tách Settings từng section; format/diagnostic theo scope. | flutter test xanh; CI chặn regression; warning count không tăng; Settings sections test độc lập; không broad rewrite. | CI matrix, diff-based analyzer budget, git diff --check và widget tests từng section. | Revert từng CI gate/section extraction riêng; không gom format với behavior changes. |

## 6. Quick wins

1. Sửa hoặc xóa placeholder test/widget_test.dart, rồi thêm flutter test --no-pub vào CI. Kết quả kiểm được ngay: suite không còn load error và regression mới chặn release.
2. Sửa regex scripts/analyze_codex.bat:113-115 để đếm diagnostic ở đầu dòng; đối chiếu footer 0/20/119 với body.
3. Thêm explicit error + retry branch cho Stats và thay WalletCardHome error SizedBox.shrink bằng trạng thái nhỏ có thông báo; test bằng provider override Stream.error.
4. Pause Timer.periodic của WalletCardHome khi tab không active/reduce motion bật; kiểm callback count trong fake_async/widget test.
5. Hủy StreamSubscription trong AuthScreen và guard mọi setState sau async bằng mounted/context.mounted trước khi nối screen này vào router.
6. Ẩn hoặc nối nút chuông Home tới route Reminders đã tồn tại; kiểm tap tạo đúng navigation thay vì callback rỗng.
7. Đặt useRootNavigator false cho Loan due-date picker hoặc truyền locale Việt rõ ràng; widget test xác nhận “Chọn ngày/Hủy/OK” theo product copy.
8. Thêm bottom content padding cho Settings khi Fancy extendBody; test rect item cuối không giao với glass bar.
9. Nâng hit target filter/tab chip lên tối thiểu 48 dp nhưng giữ pill visual hiện tại; kiểm RenderBox size và keyboard focus.

Không xếp việc thêm bảng vào backup, sửa sync queue hoặc migration wallet vào quick win dù code diff có thể nhỏ; blast radius dữ liệu của chúng cần regression fixture và rollback như Phase 0-3.

## 7. Những việc không nên làm

- Không rewrite toàn bộ sang Clean Architecture, BLoC hoặc Riverpod 3 chỉ vì các file lớn. Repository/Provider hiện tại vẫn dùng được; tách theo finding và giữ API trước.
- Không chạy pub upgrade cho 97 package cùng lúc. Nâng PowerSync/Supabase/Workmanager/liquid_glass theo từng nhóm sau khi có sync/backup/platform tests.
- Không gọi tx.complete trong catch, không nuốt exception hoặc clear queue để làm sync “hết lỗi”.
- Không xóa duplicate category trước khi remap mọi reference và có backup/transaction rollback.
- Không bật sign-out/account switching trước khi định nghĩa ownership/migration cho DB localOnly.
- Không biến wallets thành synced table chỉ bằng đổi Table.localOnly; cần user_id, RLS, SePay migration và conflict policy.
- Không thêm encryption trước khi có key lifecycle/recovery; một key bị mất nguy hiểm hơn DB plaintext trong app sandbox.
- Không dùng const/withValues/format toàn repo như một PR performance. Baseline chưa có profile chứng minh các thay đổi đó cải thiện runtime và diff sẽ che khuất fix dữ liệu.
- Không thêm debounce/network cache cho search hiện tại: search chỉ lọc danh sách tháng local; trước hết đo với dataset thực.
- Không mở rộng Liquid Glass vào list/chart dài. Ảnh live và code cho thấy Fancy đã có Aurora/glass focal surfaces; ưu tiên correctness, reduce motion và contrast.
- Không tuyên bố startup/frame/pin tốt hơn cho đến khi có profile Android/iOS trước và sau trên cùng fixture/device.
