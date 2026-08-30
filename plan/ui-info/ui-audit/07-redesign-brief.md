# 07 — Redesign Brief (bản nạp cho công cụ thiết kế)

> Tổng hợp từ 00–06 (AS-IS) và 08–10 (TO-BE). Dùng cùng `09-ui-proposals.md` §T3 làm nguồn token chi tiết. Ngôn ngữ UI: **tiếng Việt** duy nhất.

## 1. Design direction & token cuối

**Direction**: Material 3 tonal làm nền + tinh thần "sổ cái" (ledger): ít màu, bề mặt tonal thay viền, component M3 chuẩn, số tiền tabular là nhân vật chính, danh sách dày và thẳng hàng. Giữ nhận diện: logo tròn `#F06292` + tagline "Your money, clearly." (chỉ ở Splash/Welcome/Về app); 5 màu chủ đạo chọn được; chế độ **Fancy** (aurora + liquid glass) là skin bật/tắt trên cùng bộ token.

| Nhóm | Token cuối (chi tiết 09 §T3) |
|---|---|
| Màu | `ColorScheme.fromSeed` cho 5 seed (**Rose `#F06292`** mặc định — đã chốt đổi từ `#AD6E7F`, Indigo `#5C6BC0`, Emerald `#00897B`, Slate `#78909C`, Amber `#FFB300`), variant `tonalSpot`, **bỏ override surface**; dùng role: `surface / surfaceContainerLow / surfaceContainer / surfaceContainerHigh / surfaceContainerLowest`, `primary / primaryContainer / secondaryContainer / tertiary / error`, `onSurface / onSurfaceVariant / outline / outlineVariant`. Rose light (giá trị thật): primary `#8C4A5E`, primaryContainer `#FFD9E1`, secondaryContainer `#FFD9E1`, surface `#FFF8F8`, surfaceContainerLow `#FFF0F2`, surfaceContainer `#FBEAEC`, onSurface `#22191B`, onSurfaceVariant `#514346`, outlineVariant `#D6C2C5`; dark: primary `#FFB1C5`, surface `#191113`, surfaceContainerLow `#22191B`, surfaceContainer `#261D1F`, onSurface `#EFDFE1`, onSurfaceVariant `#D6C2C5`. **Lưu ý**: fromSeed chuẩn hoá tone nên seed `#F06292` cho primary rose trầm, không phải hồng logo; hồng logo (`brand`) chỉ dùng cho logo/splash và (tuỳ chọn mở #4) FAB/nav indicator với icon `#551D30`. |
| Màu ngữ nghĩa | `income #2E7D32/#81C784`, `expense #C62828/#EF9A9A`, `warning #B26A00/#FFB74D`, `automatic = tertiary`, `brand #F06292`, `googleBlue #4285F4` (chỉ nút Google). Palette 15 màu danh mục/ví giữ, chỉ cho icon/dot. |
| Chữ | Font hệ thống; số `tabularFigures`. displaySmall 36/700 · headlineSmall 24/700 · titleLarge 22/600 · titleMedium 16/600 · titleSmall 14/600 · bodyLarge 16 · bodyMedium 14 · bodySmall 12 · labelLarge 14/600 · labelMedium 12/600 · labelSmall 11/500. Không < 11. |
| Khoảng cách | 4 · 8 · 12 · 16 · 20 · 24 · 32 · 40. Padding ngang màn 16. Row 56/72. Gap section 24. |
| Bo góc | 4 (progress) · 8 (input, chip vuông, numpad) · 12 (card, nút) · 16 (card nổi bật) · 28 (sheet, dialog) · full (FilterChip, FAB, icon tròn). |
| Viền/độ cao | Không viền mảnh; divider 1px `outlineVariant`; elevation 0 (tonal), FAB level 3, sheet/dialog level 1. |
| Icon | Lucide duy nhất: 24 / 20 / 16. Icon danh mục: tròn 40, nền màu α.15. |
| Motion | `MotionSpec` hiện có (100/140/260/360/380/420ms, easeOutCubic); reduce-motion áp mọi nơi kể cả Aurora/nav. |
| Fancy | `FancySurface` bọc card/nav/FAB/sheet-header bằng `GlassContainer` superellipse 28; Aurora chỉ ở Home/Welcome/Settings hub; list & chart luôn đặc. |

## 2. Danh sách màn hình theo ưu tiên

| Ưu tiên | Màn | Quyết định | Khác gì bản cũ (1 dòng) |
|---|---|---|---|
| 1 | **Home** | [REDESIGN] | Header "Còn lại tháng này" + thu/chi 2 cột + card ngân sách; bỏ grid 8 ô → 4 ô; list "Gần đây" lên trên fold; 1 nút mắt lưu prefs. |
| 1 | **AddTransactionSheet** | [REDESIGN] | Huỷ/Chi\|Thu/Lưu trên đầu; grid danh mục có icon; ghi chú + gợi ý inline; chip Ngày/Ví/Lặp lại; numpad phẳng; sửa "₫ ₫"; cuộn được. |
| 2 | **AppShell** | [REDESIGN] — **ĐÃ CHỐT 4 tab** | `NavigationBar` M3 Trang chủ · Giao dịch · Thống kê · Cài đặt; mặc định tab 0; FAB tab 0–2; bỏ route push riêng `/transactions`, `/settings`; Fancy = `GlassTabBar` 4 tab. |
| 3 | **Transactions** | [REDESIGN] | SearchBar M3; SegmentedButton Chi/Thu; sheet Lọc (danh mục/ví/ngày) + badge; swipe xoá + hoàn tác; skeleton loading. |
| 3 | TransactionDetailSheet | [REDESIGN] | Role màu (dark OK); ngày sửa được; note wrap; nút Nhân bản; xoá → undo. |
| 3 | NotePickerScreen | [BỎ] | Gộp gợi ý vào AddTransactionSheet. |
| 4 | **Settings hub** | [REDESIGN] | Hub 3 nhóm card + trang con: Danh mục, Sao lưu & đồng bộ, Ngân hàng, Widget, Giao diện, Thông báo (tuỳ chọn cũ: 1 list card nhóm + anchor). |
| 4 | **Categories page** | [MỚI] | Trang riêng Chi\|Thu, reorder, FAB, swipe xoá. |
| 4 | CategoryFormSheet | [REDESIGN] | Cuộn; ghi loại chi/thu; validate inline; swatch inline (dùng chung với ví). |
| 4 | Appearance page | [MỚI] | Chế độ + 5 swatch + đồ hoạ với preview live (thay 3 tile + 2 sheet). |
| 4 | Backup page | [MỚI] | Gộp JSON + Drive + CSV; 1 progress pattern; 1 preview dialog. |
| 4 | AllFeaturesScreen | [BỎ] — **ĐÃ CHỐT** (4 tab + Home 4 ô + Settings hub phủ mọi đích ≤2 tap) | Các đích cũ: Thêm→FAB; Giao dịch/Thống kê/Cài đặt→tab; Ví/Vay/Nhắc nhở/Hạn mức→4 ô Home; Đang vay/Cho vay→SegmentedButton trong LoanList; Backup/Drive/Ngân hàng/Giao diện/Danh mục/Widget/Xuất báo cáo→trang con Settings. |
| 5 | Wallets | [REDESIGN] | Icon đúng loại; header tổng dùng widget chung; 1 FAB; card tổng không gradient. |
| 5 | WalletDetail | [REDESIGN] | TonalCard header; FAB "Thêm giao dịch"; archive → undo; trạng thái không tồn tại. |
| 5 | WalletFormSheet | [REDESIGN] | Token form chung; validate inline; màu swatch inline; cuộn. |
| 5 | **Budget page `/budget`** | [MỚI] — **ĐÃ CHỐT** | Gộp BudgetType + Budget + CategoryBudget; tiến độ tổng + danh mục; swipe xoá + hoàn tác; card trên Home. |
| 5 | BudgetTypeSheet / BudgetScreen / CategoryBudgetScreen | [BỎ] — **ĐÃ CHỐT** | Thay bằng Budget page. |
| 5 | LoanList | [REDESIGN] | SegmentedButton lọc; header Đang nợ/Được nợ; tile còn lại + progress + nút Trả; route `/loans/:id`. |
| 5 | LoanDetail + AddPayment | [REDESIGN] | Chọn ngày, hiện ghi chú payment, gợi ý tất toán, badge M3 thay emoji. |
| 5 | LoanFormSheet | [REDESIGN] | Token form chung; nút bám tên; date picker an toàn. |
| 5 | Reminders | [REDESIGN] | 1 hàng gợi ý; tile "Lần tới · ~số tiền"; "Ghi ngay"; swipe xoá + undo. |
| 5 | ReminderFormSheet | [REDESIGN] | Numpad cho số tiền; "Nhắc trước"; SegmentedButton tần suất. |
| 6 | Splash | [REDESIGN] | Nền theme thật; logo brand; message tiếng Việt; timeout + "Tiếp tục offline". |
| 6 | Welcome | [REDESIGN] | 2 trang, dots, skip mọi nơi, chạy trong theme thật, giữ glass card. |
| 6 | StartupGate | [BỎ] | Thành GoRouter redirect. |
| 6 | Stats | [REDESIGN] nhẹ | Chi\|Thu toggle; summary titleMedium; legend tap → list; PeriodPicker chung. |
| 6 | MonthPickerSheet + DateRangePickerSheet | [REDESIGN] | Gộp thành PeriodPickerSheet. |
| 6 | SePay section/form | [REDESIGN] | Trang riêng; token form chung; CTA tạo ví. |
| 6 | WidgetPin section | [REDESIGN] | Trang riêng + preview; bỏ ghim trong sheet; fix Kotlin < 4 slot. |
| — | AuthScreen | [BỎ] | Dead code; đăng nhập/đồng bộ là quyết định mở. |
| — | Android widgets | [GIỮ NGUYÊN] layout, [SỬA] logic slot | Ngoài scope Flutter. |
| — | Motion primitives, Numpad, CategoryIconWidget, GroupedTransactionSliver, AnimatedProgressBar | [GIỮ NGUYÊN] (restyle) | |

## 3. Spec từng màn ưu tiên 1–3

**Home** — Mục đích: nhìn tình hình tháng trong 3 giây và vào giao dịch gần đây. Khối bắt buộc: chọn tháng (AppBar), "Còn lại tháng này" + thu/chi, card ngân sách (ẩn → dòng "Đặt hạn mức"), hàng chip ví (+ tạo), 4 ô tắt (Ví, Vay, Nhắc nhở, Hạn mức), "Gần đây" 8 giao dịch + "Xem tất cả". Hành động chính: FAB thêm. States bắt buộc: loading (skeleton list + chip ví), empty (chưa có giao dịch: CTA), error list (retry), ví rỗng (chip "+ Thêm nguồn tiền"), mask số.

**AddTransactionSheet** — Mục đích: ghi 1 giao dịch ≤5 tap. Khối: hàng Huỷ / Chi\|Thu / Lưu; số tiền lớn; grid danh mục (ô "+"); ghi chú + gợi ý; chip Ngày/Ví/Lặp lại; numpad. Hành động chính: Lưu. States: idle, dirty (Huỷ hỏi), submitting, saved (SnackBar + Hoàn tác), failed (SnackBar), không có danh mục (empty trong grid), cảnh báo hạn mức (banner inline), ví âm (dialog), edit mode (tiêu đề "Sửa giao dịch"), prefill từ notification/widget/reminder.

**AppShell** — 4 destination + FAB; Fancy: GlassTabBar. States: tab đang chọn; không badge.

**Transactions** — Mục đích: tìm/duyệt/lọc/xoá. Khối: SearchBar; PeriodSelector; SegmentedButton Tất cả\|Chi\|Thu; nút Lọc + badge; chip filter đang áp; dòng tổng; list nhóm ngày. Hành động chính: FAB thêm; swipe xoá. States: loading skeleton, refresh mảnh, empty không lọc / có lọc, error retry, offline chip.

**Settings hub** — Mục đích: định hướng ≤2 tap tới mọi quản lý. Khối: 3 nhóm card (Dữ liệu: Danh mục/Nguồn tiền/Khoản vay/Nhắc nhở; Kết nối: Sao lưu & đồng bộ/Ngân hàng/Widget; Ứng dụng: Giao diện/Thông báo), số đếm phụ, footer phiên bản + tagline. States: đếm loading = "—".

(Ưu tiên 4–6: theo quy tắc 09 §T3.8.)

## 4. Ràng buộc bất biến

- **Thứ tự luồng lõi giữ nguyên**: mở app → Home → FAB → nhập số → (danh mục) → Lưu. Thêm nhanh không được quá 5 tap.
- **Dữ liệu bắt buộc** mỗi giao dịch: `amount` (int VND), `type` (expense|income), `categoryId`, `createdAt`; tuỳ chọn `note`, `walletId`; `source` không sửa từ UI. Tiền: integer, hiển thị `1.234.567 ₫`.
- **Không đổi vì phụ thuộc logic**: `AmountInputController` (format/giới hạn), `formatVND`, `selectedMonthProvider` là nguồn tháng cho Home/Transactions/Budget; cảnh báo ví âm/hạn mức vẫn phải chạy trước khi lưu (được đổi hình thức); notification payload & deep link `/add?category_id&note&amount`; prefs key hiện có (`theme_mode`, `theme_color_scheme`, `app_visual_mode`, `onboarding_completed_v1`, `widget_pinned_ids`); `MotionSpec` tokens; PowerSync schema (mọi đề xuất cần schema mới — chuyển tiền, budget theo tháng, liên kết payment↔giao dịch, đăng nhập — là roadmap, không trong redesign này).
- **Giới hạn kỹ thuật**: Flutter 3.44 / Material 3; fl_chart cho chart; liquid_glass_widgets cho Fancy; không thêm font asset; Android widget native XML; iOS widget không có.
- **Ngôn ngữ**: tiếng Việt, chuẩn hoá "Huỷ"; tên màu chủ đạo: Hồng / Chàm / Ngọc lục / Xám xanh / Hổ phách (đã chốt).

## 5. Quyết định

### 5a. Đã chốt (checkpoint 2)
| # | Quyết định | Kết quả |
|---|---|---|
| 1 | Shell | **4 tab** Trang chủ · Giao dịch · Thống kê · Cài đặt; AllFeatures [BỎ] |
| 2 | Seed Rose | **`#F06292`** (bảng màu thực tế ≈ seed cũ; brand pink chỉ ở logo/splash, xem mở #4) |
| 3 | Undo thay dialog | **Đồng ý** — áp cho xoá giao dịch/reminder/hạn mức/payment, archive ví, tất toán; dialog giữ cho xoá ví có giao dịch, xoá loan kèm payment, ngắt Drive, restore |
| 5 | Budget | **Gộp** thành `/budget` + card Home; bỏ 3 sheet |
| — | Home grid, AddTransaction sheet 92% | theo khuyến nghị (user uỷ quyền "cứ theo ý bạn" cho các mục còn lại của nhóm này) |

### 5b. Đã chốt (checkpoint 3 — "theo khuyến nghị")
| # | Quyết định | Kết quả |
|---|---|---|
| 6 | Settings | **Hub + trang con**: Cài đặt = menu ngắn 9 dòng (Danh mục · Nguồn tiền · Khoản vay · Nhắc nhở · Sao lưu & đồng bộ · Ngân hàng · Widget · Giao diện · Thông báo), mỗi dòng mở trang riêng có back (09 T2.5 MỚI) |
| 7 | Hồng brand trong app | **FAB + chỉ báo tab đang chọn dùng `brand #F06292`** với icon/label `#551D30` (contrast ≈5.4:1); mọi nút/chữ khác dùng `primary` từ seed. Giữ `tonalSpot` (không `neutral`). Fancy: FAB glass có tint brand |
| 8 | Numpad | Phím `000` thay `00`; long-press ⌫ xoá hết; giới hạn 12 chữ số |
| 9 | Tên màu chủ đạo | Tiếng Việt: **Hồng (mặc định) · Chàm · Ngọc lục · Xám xanh · Hổ phách** (enum `name` giữ nguyên để không phá prefs `theme_color_scheme`) |
| 10 | Đăng nhập/đồng bộ | **Bỏ hẳn** `AuthScreen` + `auth_provider.dart`; không thiết kế màn đăng nhập trong redesign này |
| 11 | Chuyển tiền giữa ví | **Mockup roadmap** (1 sheet "Chuyển tiền" trong bộ thiết kế, gắn nhãn Roadmap), không đưa vào phạm vi code |
| 12 | Fancy | Aurora chỉ ở **Home, Welcome, Settings hub**; các màn khác chỉ glass cho nav/FAB/card header; list & chart luôn đặc |

**Không còn quyết định mở.** Bộ tài liệu 00–10 là đầu vào cuối cho công cụ thiết kế.
