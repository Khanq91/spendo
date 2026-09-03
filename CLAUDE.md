# Spendo — hướng dẫn cho agent & người đóng góp

Flutter app quản lý chi tiêu cá nhân, Android là mục tiêu chính, UI tiếng
Việt. Offline-first trên PowerSync (SQLite); phần cloud (Supabase auth,
PowerSync sync, SePay) nằm sau cờ `AppConfig.cloudEnabled` và đang **tắt**.
Đọc `README.md` để biết tính năng và cấu trúc; file này chỉ nói cách làm việc.

## Lệnh chuẩn

```bash
flutter analyze --no-pub          # phải sạch: 0 error, 0 warning, 0 info
flutter test --no-pub             # phải xanh
flutter build apk --debug         # kiểm lần cuối trước khi khép một GĐ
```

## Cổng chất lượng (không thương lượng)

- Analyzer sạch tuyệt đối. Không dùng `// ignore:` trừ khi là giới hạn thật
  của package/API và có ghi lý do ngay dòng trên.
- Không đưa lại API Flutter đã bỏ trong repo: dùng `withValues(alpha:)`,
  `initialValue`, `activeThumbColor`; bỏ tham số `isInDebugMode` của
  Workmanager.
- Sau `await` phải guard đúng `BuildContext` bằng `context.mounted` /
  `mounted`. `if`/`while` luôn có ngoặc nhọn.
- Xóa import/biến/field/hàm không dùng thay vì suppress.
- Mỗi bug sửa có test khóa; mỗi tính năng có widget test. DB test dùng
  `PowerSyncDatabase` tạm như `test/core/db/category_integrity_test.dart`;
  widget test override provider bằng `ProviderScope(overrides:)`.

## Cách làm việc với user

- Trao đổi bằng tiếng Việt. Code comment tiếng Anh, chuỗi UI tiếng Việt.
- **Báo cáo trước, hỏi rồi mới làm**: với việc không tầm thường — chẩn đoán,
  báo cáo ngắn, 2–4 câu hỏi có phương án đề xuất, làm sau khi được chốt.
- **Không commit** khi chưa được bảo. Khi được hỏi thì đưa message ngắn,
  tiếng Anh, dạng `feat(...)`/`fix(...)`/`docs:`.
- Mỗi đợt việc có `plan/<feature>/PLAN.md`: quyết định đã chốt, thiết kế từng
  GĐ, bảng tiến độ. Mỗi GĐ: analyze → test → build apk → tự kiểm → cập nhật
  bảng. GĐ có code app thì bump patch version trong `pubspec.yaml`.
- Kết quả cuối phải tự đứng được: làm gì, đã kiểm thế nào, còn gì chưa.

## Quy tắc UI

- Luật chung ở `plan/ui-info/ui-audit/design_handoff_spendo_redesign/HANDOFF-STATE.md`
  mục 2–3. Tóm tắt: dùng bộ component `lib/shared/widgets/spendo/`
  (`SpendoButton`, `SpendoChip`, `SpendoSheet`, `SpendoSettingsRow`,
  `SpendoScreenHeader`, `SpendoNumpad`, `SpendoEmptyState`…) thay vì
  Material thô; màn được push dùng `SpendoScreenHeader`, tab trong shell truyền
  `showBack: false`.
- Thông báo: `AppNotice.success/info/warning/error/undo` — không còn
  `SnackBar`/`ScaffoldMessenger` trong `lib/`.
- Xóa thì có Hoàn tác (`AppNotice.undo`), không hộp thoại xác nhận, trừ hành
  động không đảo được.
- Motion: qua `appMotion` / `MotionSpec`, list dữ liệu bọc
  `RevealScope`/`RevealItem`, tôn trọng reduce-motion.
- Màu/kích thước lấy từ theme (`context.spendo`, `colorScheme`), không hex
  ngoài `core/theme`.

## Kho hiệu ứng Snipz

Các hiệu ứng (Snap Rail nav, reveal list, notice slide-in, particle field…)
port từ vault `D:\khang\data\flutterDev\project\Snipz` (`lib/components/<id>/`,
mỗi component một file Dart + README có `version` và Changelog). Luật port:
không sửa logic trong entry file, chỉ đổi style qua constructor. Bug tìm thấy
ở bản port thường có ở bản gốc — sửa cả hai; sửa Snipz xong thì bump
`version` trong README, thêm dòng Changelog, chạy `dart tools/build_index.dart`
và thêm test dưới `test/`.

## Cờ cloud

`AppConfig.cloudEnabled = false`. Tắt: không gọi `Supabase.instance`, splash
không có bước máy chủ, hub không có hàng Ngân hàng. Bật (khi server có RLS,
sync rules và webhook SePay): nhóm "Tài khoản Spendo" ở Sao lưu & đồng bộ,
`authUserProvider` có session, PowerSync connect. Test dùng
`cloudEnabledProvider`/`authUserProvider` override — không chạm Supabase.

## Những gì đã cân nhắc và để lại (xem `plan/review-t9-2026/PLAN.md` mục 6)

Provider chưa dùng, `import_service.dart`, vài dependency thừa và việc nâng
dependency major được **giữ nguyên có chủ ý**; đừng dọn/nâng nếu user không
yêu cầu.
