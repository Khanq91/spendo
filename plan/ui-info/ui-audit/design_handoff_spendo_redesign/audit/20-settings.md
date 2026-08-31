# 20 — Settings (Cài đặt)

## A. Metadata
- **Tên**: `SettingsScreen`
- **Route**: tab index 2 trong AppShell **và** `/settings` push (`app_router.dart:28`)
- **File**: `lib/features/settings/presentation/screens/settings_screen.dart` (1366 LOC) + `widgets/gdrive_backup_section.dart` (410) + `widgets/sepay_connection_section.dart` (420) + `widgets/widget_pin_section.dart` (268)
- **Vào từ**: bottom nav; AllFeatures (8 ô); (không có anchor)
- **Thoát đi**: `/reminders`; 6 sheet; ~10 dialog; share/url ngoài

## B. Mục đích
Gom **9 nhóm** chức năng: xuất CSV, backup JSON, SePay, Google Drive, giao diện, thông báo, nhắc nhở định kỳ, widget, danh mục.

## C. Layout skeleton
```
┌───────────────────────────────┐ AppBar 'Cài đặt' 16 w600 (không action)
├───────────────────────────────┤ ListView (bg scaffold #F5F5F5; tile bg surface white) pad B(fancy: safe+16)
│ XUẤT BÁO CÁO                  │ _SectionHeader pad (16,16,8,4) 12 w600 ls.5
│ [↓] Tháng này               › │ _ExportTile ×3: leading 36 r8 primary α.1 download 18; title 14; subtitle 12; chevronRight 18
│ [↓] 3 tháng gần đây         › │
│ [↓] Tất cả                  › │
│ SAO LƯU & KHÔI PHỤC           │
│ [💾] Xuất backup toàn bộ    › │ leading #6C63FF α.1 hardDriveDownload
│ ──────────────────────────────│ Divider indent 16
│ [💾] Khôi phục từ backup    › │ hardDriveUpload
│ KẾT NỐI NGÂN HÀNG TỰ ĐỘNG     │
│ [🏛] Quản lý kết nối SePay  ↗ │ SepayConnectionSection: #1E88E5; externalLink 16
│ [🏛] VCB ****1234  [◉] [🗑]   │ _AccountTile ×N (xanh #43A047 nếu active)
│ + Thêm tài khoản ngân hàng    │ ListTile plus primary
│ Sau khi kết nối ngân hàng… 11 │ hướng dẫn pad (16,4,16,12)
│ SAO LƯU GOOGLE DRIVE          │
│ [☁] Kết nối Google Drive    › │ GDriveBackupSection (chưa đăng nhập) #4285F4
│   | [☁✓] email   [↪]          │ (đã đăng nhập) + 3 hàng contentPadding L68: Tự động sao lưu [▾], Sao lưu ngay ☁↑, Khôi phục từ Drive ☁↓
│ GIAO DIỆN                     │
│ [🖥] Theo hệ thống          ✓ │ _ThemeTile ×3 (monitor/sun/moon 18)
│ [☀] Sáng                      │
│ [🌙] Tối                       │
│ ──────────────────────────────│
│ [✨] Đồ họa   Bình thường   › │
│ [🎨] Màu chủ đạo      ●     › │ swatch 20
│ THÔNG BÁO                     │
│ [🔔] Nhắc nhập chi tiêu  [◉ ]│ Switch; subtitle 'Mỗi ngày lúc HH:mm'
│ [🕐] Giờ nhắc nhở      20:00  │ chỉ khi bật
│ [🔔] Gửi thông báo thử      › │ chỉ khi bật
│ NHẮC CHI TIÊU ĐỊNH KỲ         │
│ [🔔] Quản lý nhắc nhở       › │ → /reminders
│ WIDGET MÀN HÌNH CHÍNH         │
│ [Slot1][Slot2][Slot3][Slot4]  │ WidgetPinSection 4 _SlotCard h72 r12 + hint 11
│ DANH MỤC                      │
│ [🏷] Danh mục thu chi       ▾ │ _CategoriesExpansionTile header; expand → (Chi (N))(Thu (N)) [+ Thêm] + _CategoryTile ×N [✎][🗑]
│ (32)                          │
└───────────────────────────────┘ bottom nav (bản tab) / không (bản push)
```

## D. Bảng component tree (rút gọn theo section)
| # | Section / Element | Loại | Style | Binding | Tương tác | Source |
|---|---|---|---|---|---|---|
| 0 | `_SectionHeader` ×9 | Text | pad (16,16,8,4); 12 w600 ls.5 onSurfaceVariant | | | `:872-892` |
| 1 | `_ExportTile` ×3 | ListTile | leading 36 r8 primary α.1 `download` 18 primary; title 14; subtitle 12 onSurfaceVariant; trailing `chevronRight` 18 | | → `ExportService.exportCSV(range)` (share sheet); lỗi → SnackBar 'Lỗi xuất file: …' | `:52-66, 894-935` |
| 2 | Backup | `Material(surface) Column[ListTile, Divider(indent 16), ListTile]` | leading 36 r8 `#6C63FF` α.1 icon `#6C63FF` 18 | | Xuất → loading dialog → SnackBar '✅ Đã xuất N giao dịch, N danh mục…'; Khôi phục → file picker → loading → preview → `_RestorePreviewDialog` → loading → SnackBar | `:72-137, 538-690` |
| 2a | `_RestorePreviewDialog` | AlertDialog title Row[hardDriveUpload 20 #6C63FF, 8, 'Xác nhận khôi phục' 16 w600]; content `_PreviewRow`(icon 16 màu + text 13) mỗi loại >0 + skipped + errors; actions Huỷ / FilledButton #6C63FF 'Khôi phục' (disabled nếu không có gì) | | `RestoreResult` | | `:704-868` |
| 3 | `SepayConnectionSection` | Material Column | ListTile dashboard (leading `#1E88E5` α.1 `landmark`; trailing `externalLink` 16); `_AccountTile` ×N (leading `#43A047`/onSurfaceVariant α.1; title `displayName` 14; subtitle 'Đang đồng bộ' xanh / 'Tạm dừng'; trailing `Switch(shrinkWrap)` + `IconButton(trash2 16 red)`); Divider; ListTile `plus` 18 primary 'Thêm tài khoản ngân hàng' 14 primary; text hướng dẫn 11 | `sepayAccountsProvider` (loading/error → shrink) | dashboard → `launchUrl(https://my.sepay.vn)`; switch → `toggleActive`; 🗑 → dialog 'Xoá kết nối?'; Thêm → `_AddMappingSheet` | `sepay_connection_section.dart:13-211` |
| 4 | `GDriveBackupSection` | Material Column | chưa login: ListTile leading `#4285F4` α.1 `cloud` 18; title 'Kết nối Google Drive' 14 w500; subtitle; trailing spinner 20 / chevron. Đã login: ListTile `cloudCheck`, title email 14 w500, subtitle 'Lần cuối: dd/MM/yyyy, HH:mm' / 'Chưa có bản sao lưu nào', trailing `IconButton(logOut 20)` tooltip 'Ngắt kết nối'; Divider indent 68; ListTile L68 'Tự động sao lưu' + `DropdownButton<BackupFrequency>` (Tắt/Hàng ngày/Hàng tuần/Hàng tháng, `chevronDown` 16); Divider; 'Sao lưu ngay' trailing `uploadCloud` 20 `#4285F4` / spinner; Divider; 'Khôi phục từ Drive' `downloadCloud` 20 | `gdriveProvider`; `ref.listen` → SnackBar '❌ error' / '✅ success' | signIn; logout → dialog 'Ngắt kết nối Google Drive!'; backupNow; restore → loading → dialog 'Chọn bản sao lưu' (ListView ListTile date/size) → loading → dialog 'Xác nhận khôi phục' (text nhiều dòng) → loading → SnackBar | `gdrive_backup_section.dart` |
| 5 | Giao diện | `Consumer > Material Column` | 3 `_ThemeTile` (ListTile leading icon 18 primary/onSurfaceVariant; title 14; trailing `check` 16 primary nếu chọn); Divider; ListTile `sparkles` 'Đồ họa' subtitle 'Xịn xò'/'Bình thường' chevron; Divider; ListTile `palette` 'Màu chủ đạo' trailing [swatch 20 circle, 8, chevron] | `themeModeProvider`, `visualModeProvider`, `themeProvider.colorScheme` | tile → `setMode`; Đồ hoạ → `_VisualModeSheet`; Màu → `_ThemeColorSheet` | `:153-271` |
| 6 | Thông báo | Consumer Material Column | ListTile `bell` 18 (primary nếu bật) 'Nhắc nhập chi tiêu' subtitle 'Mỗi ngày lúc HH:mm' trailing `Switch`; nếu bật: ListTile `clock` 'Giờ nhắc nhở' trailing `HH:mm` 14 w500 primary; ListTile `bellRing` 'Gửi thông báo thử' subtitle 'Hiện sau 5 giây' chevron | `notificationEnabled/Hour/MinuteProvider` | switch → `requestPermission` rồi toggle (từ chối → không đổi, không báo); giờ → `showTimePicker`; thử → `sendTestNotification` + SnackBar 'Thông báo sẽ hiện sau 5 giây' | `:276-399` |
| 7 | Nhắc định kỳ | ListTile tileColor surface; leading 36 r8 primary α.1 `bellRing`; 'Quản lý nhắc nhở' / 'Nhắc mua đồ và ghi chi tiêu định kỳ'; chevron | | → push `/reminders` | `:404-433` |
| 8 | `WidgetPinSection` | Container surface pad (16,12,16,12) | Row 4 `_SlotCard` Expanded gap 12 (pad L6/R6): h72 r12 bg cat α.1 / surfaceContainerHighest, border cat α.4 / outlineVariant 1; filled: icon 22 + tên 10 w600 1 dòng + `x` 12 góc (2,2) (tap-target ~12px); empty: `plus` 20 + 'Slot N' 10; hint 11 center | `widgetPinnedIdsProvider`, `expenseCategoriesProvider` | tap → `_CategoryPickerSheet` → `setSlot` + `WidgetSync`; x → `clearSlot` | `widget_pin_section.dart` |
| 9 | `_CategoriesExpansionTile` | InkWell header Container surface pad H16 V14 [leading 36 r8 primary α.1 `tag`, 12, Column['Danh mục thu chi' 14, 'N danh mục · A chi, B thu' 12], `keyboard_arrow_down` 20 AnimatedRotation]; `ClipRect > AnimatedSize` 260ms: Divider; Row pad (16,8,8,4) [`_TabChip` 'Chi (N)' / 'Thu (N)' (InkWell 48 tap-box, pill pad H10 V4 r20), Spacer, `TextButton.icon(add 15, 'Thêm')` compact primary]; `_CategoryTile` ×N (ListTile leading 36 r8 cat α.15 icon 18; title 14; subtitle 'Mặc định' 11 nếu isDefault; trailing [IconButton pencil 16, IconButton trash2 16 red (ẩn nếu default)]); 4 | `categoriesProvider` | expand; tab; Thêm → `CategoryFormSheet(isIncome)`; ✎ → form(existing); 🗑 → dialog 'Xoá danh mục?' → delete (lỗi → SnackBar đỏ) | `:449-457, 1042-1267` |
| 10 | `_VisualModeSheet` | `SafeArea Padding(20,16,20,20) Column` 'Chọn đồ họa' 16 w600; 'Hiệu ứng chỉ thay đổi phần trình bày…' 12; 14; `VisualModePicker` (non-glass: `AnimatedContainer` bg primaryContainer α.5 / surface, r12) | | tile → setMode + pop | `:1269-1310` |
| 11 | `_ThemeColorSheet` | `SafeArea Padding V16 Column` 'Chọn màu chủ đạo' 16 w600 pad H20 V8; 8; 5 ListTile [swatch 24 circle, label 14, check 16 primary] | `AppColorScheme.values` | tap → setColorScheme + pop | `:1312-1366` |

## E. Vùng bố cục
- Header 56; body 1 ListView dài (~2000px với danh mục mở): 9 section, nền scaffold xám với block trắng `Material(color: surface)` không bo góc, không margin → dạng "grouped list" phẳng.
- Footer: bottom nav (tab) / không (push). Fancy: padding đáy safe+16.
- Không có tìm kiếm cài đặt, không anchor.

## F. Trạng thái màn hình
| Khu vực | State | UI |
|---|---|---|
| Categories | loading | `allCats = []` → '0 danh mục · 0 chi, 0 thu' (không skeleton) |
| SePay | loading/error | section chỉ còn 2 ListTile + hướng dẫn (accounts ẩn im lặng) |
| GDrive | isLoading | spinner ở trailing, tile disabled; Dropdown disabled |
| GDrive error/success | `ref.listen` | SnackBar ❌/✅ |
| Notification permission denied | | switch không bật, **không thông báo** |
| Backup/Restore | | loading dialog full-screen (`Center(CircularProgressIndicator)` không nền) ×3 lần trong 1 luồng restore |
| Restore không có gì mới | `!hasAnything` | dialog text 'Tất cả dữ liệu trong backup đã tồn tại…', nút Khôi phục disabled |
| Export | không loading (share sheet mở) | |

## G. Tương tác (tóm tắt số lượng)
28 điểm chạm: 3 export, 2 backup, 2+N SePay (+switch, 🗑), 1–5 GDrive, 3 theme, 2 sheet giao diện, 1–3 thông báo, 1 reminders, 4 slot (+4 x), 1 expand + 2 tab + 1 thêm + N×2 category. Không gesture đặc biệt.

## H. Animation/transition
| Element | Loại | Thời lượng |
|---|---|---|
| Categories expand | AnimatedRotation + AnimatedSize | 260ms / layout curve |
| Tab chip | AnimatedContainer | 140ms |
| VisualModePicker tile | AnimatedContainer | 260ms |
| Còn lại | không | |

## I. Dữ liệu hiển thị
| Field | Nguồn | Format |
|---|---|---|
| Giờ nhắc | providers | `HH:mm` |
| Email / lần backup | `gdriveProvider` | `dd/MM/yyyy, HH:mm` (intl) |
| SePay displayName | `label` hoặc `'<bank> ****<4 số cuối>'` | |
| Đếm danh mục | `allCats` | `'N danh mục · A chi, B thu'` |
| Swatch | `scheme.swatch` | |
| Slot | `cat.name` 10px 1 dòng ellipsis | |
| Kết quả backup | SnackBar liệt kê số lượng từng loại | |

## J. Responsive & edge cases
- Trang rất dài; danh mục mở thêm ~N×56px.
- Slot 4 ô trên màn 360: mỗi ô ~75px, tên 10px ellipsis; nút x 12px khó chạm.
- Dark: ok (dùng cs) trừ màu section cứng (#6C63FF, #4285F4, #1E88E5, #43A047).
- Bản push `/settings` từ AllFeatures: có back, không nav; state expand không share với bản tab.

## K. Text hiển thị (chính)
`Cài đặt` · `Xuất báo cáo` · `Tháng này` · `Xuất giao dịch tháng hiện tại dạng CSV` · `3 tháng gần đây` · `Xuất giao dịch 3 tháng gần nhất dạng CSV` · `Tất cả` · `Toàn bộ lịch sử giao dịch dạng CSV` · `Sao lưu & khôi phục` · `Xuất backup toàn bộ` · `Lưu toàn bộ dữ liệu ra file JSON để khôi phục sau` · `Khôi phục từ backup` · `Nhập file JSON backup để khôi phục dữ liệu` · `Kết nối ngân hàng tự động` · `Quản lý kết nối SePay` · `Mở SePay để kết nối/ngắt kết nối tài khoản ngân hàng` · `Đang đồng bộ` · `Tạm dừng` · `Thêm tài khoản ngân hàng` · `Sau khi kết nối ngân hàng trên SePay, thêm tài khoản ở đây để giao dịch tự động đồng bộ vào Spendo.` · `Không mở được trình duyệt` · `Xoá kết nối?` · `Xoá "X"?\n\nGiao dịch đã nhập sẽ không bị ảnh hưởng. Chỉ dừng tự động đồng bộ từ tài khoản này.` · `Sao lưu Google Drive` · `Kết nối Google Drive` · `Đăng nhập để tự động sao lưu dữ liệu` · `Đã kết nối Google Drive` · `Lần cuối: …` · `Chưa có bản sao lưu nào` · `Ngắt kết nối` · `Ngắt kết nối Google Drive!` · `Dữ liệu trên thiết bị sẽ không bị xóa, nhưng tính năng sao lưu tự động sẽ bị tắt. Bạn chắc chắn chứ?` · `Hủy` · `Tự động sao lưu` · `Tắt` `Hàng ngày` `Hàng tuần` `Hàng tháng` · `Sao lưu ngay` · `Khôi phục từ Drive` · `Không tìm thấy bản sao lưu nào trên Drive.` · `Chọn bản sao lưu` · `Không rõ ngày` · `Đóng` · `Xác nhận khôi phục` · `Bạn sắp khôi phục dữ liệu ngày …\n\nSẽ thêm:\n• N giao dịch…\n\nDữ liệu trùng lặp sẽ tự động bị bỏ qua.` · `Khôi phục` · `✅ Khôi phục thành công …` · `Lỗi khôi phục: …` · `Lỗi tải danh sách: …` · `Giao diện` · `Theo hệ thống` · `Sáng` · `Tối` · `Đồ họa` · `Xịn xò` · `Bình thường` · `Màu chủ đạo` · `Chọn đồ họa` · `Hiệu ứng chỉ thay đổi phần trình bày, không ảnh hưởng dữ liệu.` · `Chọn màu chủ đạo` · `Rose (Mặc định)` `Indigo Midnight` `Emerald Wealth` `Slate Premium` `Amber Warm` · `Thông báo` · `Nhắc nhập chi tiêu` · `Mỗi ngày lúc HH:mm` · `Giờ nhắc nhở` · `Gửi thông báo thử` · `Hiện sau 5 giây` · `Thông báo sẽ hiện sau 5 giây` · `Nhắc chi tiêu định kỳ` · `Quản lý nhắc nhở` · `Nhắc mua đồ và ghi chi tiêu định kỳ` · `Widget màn hình chính` · `Slot N` · `Tap vào ô để chọn danh mục hiển thị trên widget` · `Chọn danh mục cho slot N` · `Đang dùng ở slot khác` · `Danh mục` · `Danh mục thu chi` · `N danh mục · A chi, B thu` · `Chi (N)` · `Thu (N)` · `Thêm` · `Mặc định` · `Xoá danh mục?` · `Xoá "X"?\nDanh mục đang có giao dịch sẽ không thể xoá.` · `Huỷ` · `Xoá` · `Lỗi xuất file: …` · `✅ Đã xuất …` · `❌ Lỗi xuất backup: …` · `✅ Đã khôi phục … · bỏ qua N trùng` · `Xác nhận khôi phục` · `N giao dịch mới sẽ được thêm` (và các dòng tương tự) · `Tất cả dữ liệu trong backup đã tồn tại trên thiết bị này.`

## L. Nhận xét nhanh
- 1366 LOC một màn, 9 nhóm không liên quan (tài chính, kết nối, giao diện, thông báo, danh mục) cùng một list phẳng không có điều hướng cấp 2; quản lý Danh mục — một entity cốt lõi — bị chôn cuối trang trong expansion tile.
- Ba màu nhấn ngoài theme (#6C63FF backup, #4285F4 Google, #1E88E5 SePay) cộng primary → 4 màu icon trong 1 màn.
- Luồng restore dùng 3 dialog loading toàn màn không nền + 2 dialog xác nhận + SnackBar; GDrive restore lặp lại pattern với text thuần trong AlertDialog.
- Hai kiểu viết "Huỷ"/"Hủy" trong cùng màn (`:494` vs `gdrive_backup_section.dart:135`).
