# 10 — Đề xuất logic & hành vi (TO-BE)

> Hành vi, không thẩm mỹ. Mỗi mục: **[SỬA]/[MỚI]/[BỎ] | mô tả | vì sao (neo AS-IS) | ảnh hưởng code**.

---

## 1. State machine còn thiếu

| # | Màn | Nhãn | Hành vi đề xuất | Vì sao | Ảnh hưởng code |
|---|---|---|---|---|---|
| S1 | Transactions | [SỬA] | `loading` (chưa có giá trị) → skeleton 4 row; `loading` khi đã có giá trị → giữ list + `LinearProgressIndicator` 2px dưới AppBar; `error` không có giá trị → ErrorState retry; `error` có giá trị → SnackBar + giữ list | 06 A4: đang hiện "Chưa có giao dịch nào" lúc load | `filteredTransactionsProvider` trả `AsyncValue` thay `List` (`transaction_provider.dart:31-43`); `transactions_screen.dart:120-151` |
| S2 | WalletDetail | [SỬA] | `wallet == null` sau khi providers đã có giá trị → màn "Nguồn tiền không tồn tại" + nút Quay lại (pop tự động sau 1.5s nếu vừa xoá) | 06 A5: spinner vĩnh viễn | `wallet_detail_screen.dart:41-46` |
| S3 | AddTransactionSheet | [SỬA] | `idle` → `dirty` (có input) → `submitting` → `saved`/`failed`; `failed` → SnackBar lỗi + giữ sheet; `dirty` + đóng → dialog "Bỏ giao dịch này?"; `cats.isEmpty` → empty state trong grid "Chưa có danh mục chi/thu — Tạo" | 06 D2 | `add_transaction_sheet.dart:96-147` (try/catch), `PopScope`/`onDismiss` |
| S4 | Mọi sheet numpad (Budget, SetCategoryBudget, AddPayment) | [SỬA] | `try/catch/finally` + SnackBar lỗi; `_loading` luôn reset | 06 D9: `_loading` kẹt | 3 file |
| S5 | Wallets / LoanList / Reminders / LoanDetail | [SỬA] | Thay `Text('Lỗi: $e')` bằng `ErrorState(onRetry: invalidate)`; loading spinner → skeleton list | 06 C9/C10/D4 | 4 file |
| S6 | CategoryBudget | [SỬA] | `expenseCategories.isEmpty` → EmptyState "Chưa có danh mục chi"; loading → skeleton | 06 D5 | `category_budget_screen.dart:75-122` |
| S7 | SePay AddMapping | [SỬA] | `wallets` = `AsyncValue`: loading → dropdown disabled + spinner; empty → dòng "Chưa có nguồn tiền — Tạo" mở WalletFormSheet rồi tự chọn | 06 D6 | `sepay_connection_section.dart:243-246, 327-341` |
| S8 | Settings › Thông báo | [SỬA] | Permission denied → SnackBar "Spendo chưa được phép gửi thông báo" + nút "Mở cài đặt" (`openAppSettings`) | 06 D10 | `settings_screen.dart:310-319` |
| S9 | StartupGate | [SỬA] | Gộp vào GoRouter `redirect`; lỗi đọc prefs → coi như đã onboarding | 06 D3, 04-02 §L | `startup_gate.dart` → xoá; `app_router.dart` |
| S10 | Splash | [SỬA] | Timeout tổng 15s cho init → state `error` với "Thử lại" + "Tiếp tục offline" (bỏ qua Supabase, mở DB local) | 04-01 §J: treo vô hạn khi Supabase treo | `main.dart:77-117`, `splash_screen.dart` |
| S11 | Home | [SỬA] | Wallet loading → skeleton 1 hàng chip thay `SizedBox.shrink` (layout nhảy) | 04-05 §F | `wallet_card_home.dart:73` |
| S12 | Toàn app | [MỚI] | `SyncStatusBanner`: nếu PowerSync `connected == false` > 30s → chip nhỏ "Ngoại tuyến · dữ liệu lưu trên máy" ở đầu Home/Transactions | 06 D11; app là local-first nhưng user không biết | provider mới đọc `db.statusStream` (`powersync_db.dart`) |

---

## 2. Tối ưu tương tác

### 2.1 Undo thay confirm dialog
| # | Nhãn | Ở đâu | Đề xuất | Vì sao | Ảnh hưởng code |
|---|---|---|---|---|---|
| U1 | [MỚI] | Cơ chế chung | `UndoController`: hành động huỷ được → thực thi ngay (optimistic) + SnackBar 5s "Đã xoá · Hoàn tác"; hoàn tác = gọi `restore()` (insert lại với **id cũ**) | 06 E9: 6 dialog vs 5 xoá tức thì | `shared/undo_controller.dart`; các repo cần `insert(entity)` giữ id (kiểm tra `TransactionRepository.add` sinh uuid mới) |
| U2 | [SỬA] | Xoá giao dịch, reminder, hạn mức danh mục, hạn mức tháng, payment | dùng U1, bỏ AlertDialog | | 5 file |
| U3 | [SỬA] | Lưu trữ ví, tất toán/mở lại loan, dismiss habit | dùng U1 (không pop màn ngay khi archive) | 04-13 §L, 04-18 §G | 3 file |
| U4 | [GIỮ] dialog | Xoá ví có giao dịch (chặn), xoá loan kèm payments, ngắt Google Drive, restore backup | thao tác lan rộng / không idempotent | |

### 2.2 Optimistic update
| # | Nhãn | Ở đâu | Đề xuất | Vì sao |
|---|---|---|---|---|
| O1 | [SỬA] | Switch reminder, Switch SePay, Đồ hoạ/Theme | đổi state UI trước, ghi sau; lỗi → revert + SnackBar | hiện `await` rồi stream mới đổi → switch trễ |
| O2 | [SỬA] | Toggle mắt số dư | lưu `SharedPreferences` `home_balance_visible`; **1 toggle** cho cả 3 số | 04-05 §L: 3 toggle không lưu |
| O3 | [SỬA] | Thêm giao dịch | đóng sheet ngay khi bấm Lưu (không chờ `await repo.add`), SnackBar "Đã thêm"; lỗi → SnackBar đỏ "Không lưu được · Thử lại" mở lại sheet với dữ liệu | sheet hiện chờ spinner |

### 2.3 Auto-save thay nút Lưu
| # | Nhãn | Ở đâu | Đề xuất | Vì sao |
|---|---|---|---|---|
| A1 | [SỬA] | Giờ nhắc nhở (Settings), tần suất backup, màu/mode theme, ghim widget | đã là auto-save — [GIỮ] |
| A2 | [SỬA] | Hạn mức tháng / danh mục | numpad sheet: lưu khi bấm "Xong" (giữ nút) nhưng **không** nút Xoá riêng — xoá bằng swipe trên list (U1) | 04-23 §L |
| A3 | [GIỮ] | Form entity (ví, loan, danh mục, reminder, giao dịch) | giữ nút Lưu tường minh — form nhiều field, auto-save tạo bản ghi rác |

### 2.4 Validate realtime
| # | Nhãn | Ở đâu | Đề xuất | Vì sao | Ảnh hưởng |
|---|---|---|---|---|---|
| V1 | [SỬA] | WalletForm, LoanForm, CategoryForm, ReminderForm, SePay | Nút Lưu `enabled` bám `ValueListenable` của mọi field bắt buộc; `errorText` inline khi blur ("Tên không được trống", "Tên đã tồn tại" — check trùng async 300ms) | 06 D8/A11 | `TextEditingController` listeners; `CategoryRepository` có `DuplicateCategoryException` sẵn |
| V2 | [SỬA] | AddTransaction | Số > 0 && category ≠ null → Lưu enabled (đã có); thêm cảnh báo inline dưới số khi vượt hạn mức ("Vượt 150.000 ₫ hạn mức Ăn uống") thay dialog chặn; dialog chỉ còn cho ví âm | 04-07: 2 dialog liên tiếp | `_checkCategoryBudget` → banner |
| V3 | [SỬA] | LoanForm date picker | `firstDate = min(now, dueDate ?? now)`; `initialDate` clamp | 06 A12 | 1 dòng |
| V4 | [SỬA — đã chốt] | AmountInputController | giới hạn 12 chữ số (999 tỷ) thay 10; `000` thay `00`; long-press ⌫ xoá hết | VND lớn | `amount_input_controller.dart:26-33`, `numpad.dart:19` |

---

## 3. Dữ liệu nên hiển thị thêm / bớt

| Màn | Nhãn | Thêm / bớt | Vì sao | Nguồn dữ liệu (có sẵn?) |
|---|---|---|---|---|
| Home | [SỬA] | Đổi nhãn "Số dư" → "Còn lại tháng này"; **bớt** progress ví khỏi header | 06 A3 | có |
| Home | [MỚI] | Card ngân sách tháng (spent/budget/%) | 06 A6 | `budgetProgressProvider` có |
| Home | [MỚI] | Dòng "So với tháng trước: −12%" dưới số chi | ngữ cảnh 1 số đơn lẻ vô nghĩa | query tháng trước — `watchByMonth` có |
| Home | [BỎ] | 4 ô grid trùng (Thêm, Giao dịch, Thống kê, Xem thêm) | 04-05 §L | |
| Transactions | [MỚI] | Lọc Chi/Thu, ví, khoảng ngày; badge số filter | 04-06 §L | model có `type`, `walletId`, `createdAt` |
| Transactions row | [MỚI] | Tên ví (nếu có) dạng dot màu ví cạnh giờ | ví là thông tin phân biệt khi có SePay | `walletId` có |
| AddTransaction | [MỚI] | Ngày/giờ; gợi ý ghi chú inline; "Ví gần nhất" mặc định | 04-07 §L | `createdAt`; query note; prefs |
| AddTransaction | [BỎ] | Text '₫' thừa; dialog vượt hạn mức (→ banner) | 06 A2 | |
| TransactionDetail | [MỚI] | Ví archived vẫn hiện tên (+ nhãn "đã lưu trữ") | 06 A10 | `archivedWalletsProvider` có |
| Stats | [MỚI] | Toggle Chi/Thu; Δ so tháng trước; tap legend → list | 06 A9 | có |
| Wallets | [MỚI] | Header "Tổng tài sản" + "Trong tháng: +thu −chi" | card tổng hiện chỉ 1 số + bar khó hiểu | có |
| Wallets tile | [SỬA] | Icon đúng loại; bớt '⚠️ Âm' cho thẻ tín dụng (âm là bình thường) | 06 A1, 04-12 §J | `WalletType.credit` |
| WalletDetail | [MỚI] | FAB "Thêm giao dịch" prefill ví; "Ban đầu" → dòng phụ | 04-13 §L | |
| LoanList | [SỬA] | Số **còn lại** thay gốc; header Đang nợ/Được nợ; progress | 04-15 §L | `watchSummaryWithRemaining` có |
| LoanDetail | [MỚI] | Ghi chú thanh toán; ngày thanh toán chọn được | 06 A7 | `LoanPayment.note/paidAt` có |
| Reminders tile | [MỚI] | "Lần tới: …", số tiền gợi ý, nút "Ghi ngay" | 04-18 §L | `nextTrigger`, `amountHint` có |
| ReminderForm | [MỚI] | "Nhắc trước" (0/6h/24h) | 06 A8 | `warnBeforeHours` có |
| Budget page | [MỚI] | Tháng đang tính; "Còn lại / ngày" (= còn lại ÷ số ngày còn lại) | 04-24 §L | tính client |
| Settings hub | [MỚI] | Số đếm phụ (12 danh mục, 3 ví, Drive 2h trước) | định hướng nhanh | providers có |
| Settings | [BỎ] | 3 tile CSV riêng → 1 mục "Xuất CSV" chọn khoảng trong sheet | 3 tile cho 1 tham số | `ExportRange` có |
| Splash | [BỎ] | Message kỹ thuật tiếng Anh ("Connecting to cloud…") → 1 dòng "Đang chuẩn bị…" | 04-01 §L | |
| Widget Android | [MỚI] | "Chi tháng này: X ₫" | 04-31 §L | `WidgetSync` ghi thêm key |

---

## 4. Tính năng nhỏ nên thêm (khoảng trống thấy được)

| # | Nhãn | Tính năng | Vì sao | Ảnh hưởng code | Backend |
|---|---|---|---|---|---|
| N1 | [MỚI] | Chọn ngày/giờ khi thêm/sửa giao dịch | 05 "Luồng thiếu" | `add_transaction_sheet.dart` truyền `createdAt` — `TransactionRepository.add(createdAt:)` đã hỗ trợ (`:45`) | không |
| N2 | [MỚI] | Swipe xoá + Hoàn tác (U1) | 06 E9 | `Dismissible` + UndoController | nhẹ |
| N3 | [MỚI] | Thêm danh mục từ AddTransaction (ô "＋") | 06 E4 | mở `CategoryFormSheet` rồi chọn id trả về | không |
| N4 | [MỚI] | "Ghi ngay" từ Reminders → AddTransaction prefill | reminder chỉ hữu ích qua notification | tái dùng `preselectedCategoryId/prefillNote/prefillAmount` | không |
| N5 | [MỚI] | "Lặp lại" trong AddTransaction → tạo reminder từ giao dịch | nối 2 tính năng đang rời | `ReminderFormSheet(preset)` | không |
| N6 | [MỚI] | Drill-down Stats legend/ngày → Transactions filter | 04-10 §L | truyền filter qua provider/route query | không |
| N7 | [MỚI] | Ví mặc định (prefs) và tự bật "Ghi vào nguồn tiền" khi có ví | checkbox mặc định tắt → số dư ví không bao giờ đúng nếu quên | prefs + `_trackWallet` init | không |
| N8 | [MỚI] | Nhân bản giao dịch (từ detail sheet) | ghi chép lặp (cà phê mỗi sáng) | `AddTransactionSheet(prefill từ tx)` | không |
| N9 | [MỚI] | Sắp xếp danh mục & ví (drag) | model có `sortOrder` không UI | `ReorderableListView` + `update sortOrder` | nhẹ |
| N10 | [MỚI] | Widget: dùng đúng số slot ghim; slot trống = "+" | 06 A16 | Kotlin `SpendoWidgetMedium.kt:76` | không |
| N11 | [MỚI — roadmap, chỉ mockup] | Chuyển tiền giữa ví | 05 "Luồng thiếu"; đã chốt: vẽ 1 sheet mockup, không code trong redesign | schema `transfer_id`/type; loại khỏi tổng thu/chi; UI sheet | **lớn** |
| N12 | [MỚI] | Tự tất toán khi trả đủ (hỏi 1 lần) | 04-16 §F | `LoanDetail` sau addPayment | không |
| N13 | [MỚI] | Sao lưu cục bộ tự động (giữ 7 bản) | 08 F12 PA2 | Workmanager task có sẵn pattern | không |
| N14 | [MỚI] | Tìm kiếm khớp tên danh mục & tên ví | 04-06: chỉ note/amount | `filteredTransactionsProvider` | không |
| N15 | [BỎ] | `AuthScreen`, `auth_provider.dart`, `GlobalFab`, `LoanMiniCard`, `LoanSettingsTile`, `QuickActionsBar`, `WalletProgressBar`, `NotePickerScreen` (sau N-inline), `BudgetTypeSheet` (sau gộp), `AllFeaturesScreen` (nếu chọn T2.1 A + hub) | 06 C15 | xoá file | không |
| N16 | [BỎ — đã chốt] | Đăng nhập Supabase để đồng bộ đa thiết bị | Bỏ `AuthScreen` + `auth_provider.dart` khỏi redesign; backend RLS/sync rules chưa có (`plan/memory/PROGRESS.md`) nên không thiết kế màn đăng nhập | xoá 2 file | — |

---

## 5. Chính sách hành vi thống nhất (áp toàn app)

| Chủ đề | Quy tắc |
|---|---|
| Xoá | Optimistic + Hoàn tác 5s. Dialog chỉ khi thao tác lan rộng (U4). |
| Lưu form | Nút Lưu tường minh, disabled tới khi hợp lệ, lỗi inline; lưu → đóng ngay + SnackBar. |
| Loading | Lần đầu: skeleton đúng hình dạng nội dung; refresh: giữ nội dung + progress mảnh. Không dialog loading trần. |
| Lỗi | ErrorState có retry khi không có dữ liệu; SnackBar khi đã có dữ liệu. Không `Text('Lỗi: $e')`. |
| Rỗng | Icon + 1 câu + CTA đúng hành động chính. |
| Thời gian | 1 nguồn `selectedPeriodProvider` cho Home/Transactions/Budget/Stats(mode month); WalletDetail và Stats custom range là state cục bộ có nhãn rõ. |
| Điều hướng | Tab ↔ tab không push; màn con luôn có route (`/loans/:id`, `/settings/*`); sheet không mở sheet (đóng rồi mở → dùng `pushReplacement`-style hoặc gộp). |
| Modal | Bottom sheet cho form ≤1 màn; trang cho danh sách/quản lý; dialog cho quyết định. |
| Motion | Mọi duration từ `MotionSpec`; respect reduce-motion kể cả Aurora/nav. |
