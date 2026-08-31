# 09 — NotePickerScreen (Ghi chú & gợi ý)

## A. Metadata
- **Tên**: `NotePickerScreen`
- **Route**: không có; `Navigator.push<NotePickerResult>(MaterialPageRoute)` từ `AddTransactionSheet._openNotePicker` (`add_transaction_sheet.dart:297-306`)
- **File**: `lib/features/transactions/presentation/screens/note_picker_screen.dart` (375 LOC)
- **Vào từ**: icon 🔍 cạnh ô ghi chú trong AddTransactionSheet
- **Thoát đi**: X → `pop()` (null, giữ nguyên); "Xác nhận" → `pop(NotePickerResult(note, categoryId))`

## B. Mục đích
Nhập ghi chú với gợi ý = lịch sử note của danh mục (top 20 theo tần suất, SQL trực tiếp `:82-86`) + note mặc định theo `iconName` (`_kDefaultNotes` `:19-36`); cho phép đổi danh mục ngay tại đây.

## C. Layout skeleton
```
┌───────────────────────────────┐ AppBar
│ [X]        Ghi chú    Xác nhận│ leading LucideIcons.x 20; title theme; TextButton primary w600  :146-164
├───────────────────────────────┤
│ ┌ Nhập ghi chú...        [x] ┐│ TextField OutlineInputBorder r10, pad H12 V10, autofocus, suffix clear khi có text :169-193
│ (16)                          │
│ Danh mục 12 w600              │ pad L16 B8                                            :199-209
│ (🍴 Ăn uống)(🚗 Di chuyển)…→  │ _CategoryChip h36 strip, pad H16, gap 8: icon 13 + tên 12  :210-227
│ (16) ─────────────────────────│ Divider h1
│ Gợi ý | Kết quả tìm kiếm 12 w600│ pad (16,12,16,8)                                    :234-244
│ (Ăn sáng)(Ăn trưa)(Cà phê)    │ Wrap spacing 8 runSpacing 8, _SuggestionChip pad H12 V7 r20 bg surfaceContainerHighest :267-284
│ (Trà sữa)(…)                  │ SingleChildScrollView pad (16,0,16,16)
│                               │
└───────────────────────────────┘ (keyboard mở phía dưới)
```

## D. Bảng component tree
| # | Element | Loại | Vị trí | Kích thước | Spacing | Style | Nội dung/binding | Tương tác | Source |
|---|---|---|---|---|---|---|---|---|---|
| 1 | AppBar leading | `IconButton(LucideIcons.x 20)` | | 48 | | | | pop(null) | `:147-150` |
| 2 | Title | Text 'Ghi chú' | center | | | theme 16 w600 | | | `:151` |
| 3 | Action | `TextButton('Xác nhận')` | phải | | | w600 `cs.primary` | | `_confirm` | `:153-162` |
| 4 | TextField | input | body top | pad (16,12,16,0) | | 15 onSurface; hint 'Nhập ghi chú...'; `OutlineInputBorder(r10)`; contentPadding H12 V10; `suffixIcon IconButton(x 16)` khi text non-empty | `_ctrl`, `autofocus` | onChanged → setState (lọc gợi ý) | `:169-193` |
| 5 | Label 'Danh mục' | Text | | pad L16 B8 | 16 trên | 12 w600 onSurfaceVariant | chỉ khi `categories.isNotEmpty` | | `:199-209` |
| 6 | `_CategoryChip` strip | `SizedBox(36) > ListView.separated` | | pad H16, gap 8 | | `GestureDetector > AnimatedContainer 150ms` pad H10 V6; bg `cat.color` α.12 / transparent; border color / outlineVariant .8; r20; icon `categoryIcon` 13 + tên 12 w600/w400 màu cat / onSurfaceVariant | `widget.categories` (đã lọc theo loại) | tap → `_onCategoryChanged` → reload history | `:210-227, 294-345` |
| 7 | Divider h1 | | | 16 trên | | | | | `:231` |
| 8 | Label gợi ý | Text | | pad (16,12,16,8) | | 12 w600 onSurfaceVariant | 'Gợi ý' nếu text rỗng, else 'Kết quả tìm kiếm' | | `:234-244` |
| 9 | Body | `Expanded` | | | | loading: spinner 20 center; empty: text 13 center; data: `SingleChildScrollView > Wrap` | `_historyLoading`, `_suggestions` | | `:246-285` |
| 9a | `_SuggestionChip` | `GestureDetector > Container` | | pad H12 V7 | Wrap 8/8 | bg `surfaceContainerHighest`, border outlineVariant .5, r20; 13 onSurface | label | tap → set text + cursor cuối (không pop) | `:349-375` |

## E. Vùng bố cục
- Header AppBar 56.
- Body `Column[field, 16, label, chip strip 36, 16, divider, label, Expanded scroll]`; phần cố định ≈ 150px; gợi ý scroll dọc.
- Keyboard: `autofocus` → keyboard mở ngay; `Scaffold` mặc định `resizeToAvoidBottomInset` → body co, gợi ý vẫn scroll được.

## F. Trạng thái màn hình
| State | UI |
|---|---|
| Initial | field có `initialNote`, danh mục `initialCategoryId` chọn, đang load history (spinner) |
| Loading history | spinner 20 (mỗi lần đổi danh mục) |
| Có gợi ý | Wrap chips (history trước, default sau, dedupe case-insensitive) |
| Gõ text | label → "Kết quả tìm kiếm", lọc `contains` |
| Rỗng (không gõ) | "Chưa có gợi ý cho danh mục này" |
| Rỗng (có gõ) | "Không tìm thấy gợi ý phù hợp" |
| `_categoryId == null` | không load history (`:77-80`), chỉ default rỗng → "Chưa có gợi ý…" |
| DB error | catch → `_historyLoading=false`, coi như rỗng (không báo) |

## G. Tương tác
| Trigger | Hành động | Kết quả | Điều hướng |
|---|---|---|---|
| X | pop(null) | AddTransaction giữ nguyên | back |
| Xác nhận | pop(result) | AddTransaction set note + category (đánh dấu user picked) | back |
| Back hệ thống | pop(null) | | |
| Tap chip danh mục | đổi `_categoryId`, reload | history đổi | |
| Tap gợi ý | điền vào field (không pop) | phải bấm Xác nhận thêm 1 tap | |
| Tap suffix x | clear | | |
| Submit keyboard (enter) | **không xử lý** (`onSubmitted` không có) | | |

## H. Animation/transition
| Element | Loại | Thời lượng |
|---|---|---|
| Category chip | AnimatedContainer | 150ms |
| Route | MaterialPageRoute mặc định | platform |
| Gợi ý xuất hiện | không | |

## I. Dữ liệu hiển thị
| Field | Nguồn | Format |
|---|---|---|
| History | `SELECT note, COUNT(*) … WHERE category_id=? GROUP BY note ORDER BY cnt DESC LIMIT 20` | thô |
| Default | `_kDefaultNotes[cat.iconName]` — 16 nhóm, ví dụ restaurant: Ăn sáng, Ăn trưa, Ăn tối, Cà phê, Trà sữa, Đi ăn, Bia, Đặt đồ ăn | thô |
| Chip danh mục | icon + tên | |

## J. Responsive & edge cases
- Nhiều gợi ý: Wrap xuống dòng, scroll dọc OK.
- Note rất dài: chip Wrap có thể rộng hết dòng; text không ellipsis (`_SuggestionChip` Text không maxLines) → chip cao nhiều dòng.
- Category strip trộn không có "Tất cả".
- Màn nhỏ + keyboard: chỉ còn ~100px cho gợi ý.

## K. Text hiển thị
`Ghi chú` · `Xác nhận` · `Nhập ghi chú...` · `Danh mục` · `Gợi ý` · `Kết quả tìm kiếm` · `Chưa có gợi ý cho danh mục này` · `Không tìm thấy gợi ý phù hợp` · 60+ note mặc định (`_kDefaultNotes`) · tên danh mục

## L. Nhận xét nhanh
- Cần 3 tap để dùng gợi ý (🔍 → chip → Xác nhận) trong khi ô ghi chú ở sheet cha đã cho gõ trực tiếp.
- Là màn full-page push từ một bottom sheet → chuyển ngữ cảnh mạnh (sheet vẫn mở phía sau).
- Chip danh mục ở đây có icon + màu riêng, còn chip ở AddTransactionSheet không có → 2 phong cách cho cùng entity trong cùng luồng.
- Không có nút submit bàn phím; gợi ý không tự áp dụng.
