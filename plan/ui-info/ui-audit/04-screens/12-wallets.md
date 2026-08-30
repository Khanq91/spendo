# 12 — Wallets (Nguồn tiền)

## A. Metadata
- **Tên**: `WalletsScreen`
- **Route**: `/wallets` (`app_router.dart:44`)
- **File**: `lib/features/wallets/presentation/screens/wallets_screen.dart` (509 LOC)
- **Vào từ**: Home grid "Ví", WalletCardHome tap, AllFeatures "Ví"
- **Thoát đi**: `/wallets/:id`; sheet `WalletFormSheet`; back

## B. Mục đích
Xem tổng số dư mọi ví, danh sách ví active (với số dư từng ví), ví lưu trữ (khôi phục), thêm ví.

## C. Layout skeleton
```
┌───────────────────────────────┐ AppBar: back · 'Nguồn tiền' 16 w600 · [+]
├───────────────────────────────┤ ListView
│ ╔═══════════════════════════╗ │ _NetWorthCard margin (16,16,16,0) pad H20 V16 gradient [primary,primary] r16
│ ║ Tổng số dư 12 white70     ║ │
│ ║ 30.000.000 ₫ 24 w700      ║ │ AnimatedMoneyText (đỏ redAccent nếu âm)
│ ║ ▬▬▬▬▬▬▬▬▬ 5px             ║ │ _DarkProgressBar + 'Đã dùng X' / '/ Y' 10 white60 (luôn hiện)
│ ╚═══════════════════════════╝ │
│ (8)                           │
│ [▢] Ngân hàng      30.000.000 ₫│ _WalletTile ListTile: leading 40 r10 bg color α.15 icon(circleEllipsis!) 20; title 14 w500; subtitle type.label 12; trailing balance 14 w600 (+ '⚠️ Âm' 10 nếu <0)
│     Ngân hàng                 │
│ [▢] Tiền mặt         500.000 ₫│
│ Đã lưu trữ (1) ▾              │ _ArchivedSection header 12 w600 ls.5 + AnimatedRotation; expand → _ArchivedTile + 'Khôi phục'
│ ┌───────────────────────────┐ │
│ │     + Thêm nguồn tiền     │ │ OutlinedButton.icon pad V12 r10, pad (16,16,16,32)
│ └───────────────────────────┘ │
└───────────────────────────────┘ (không FAB)
```

## D. Bảng component tree
| # | Element | Loại | Vị trí | Kích thước | Spacing | Style | Nội dung/binding | Tương tác | Source |
|---|---|---|---|---|---|---|---|---|---|
| 1 | AppBar | | | | | title 16 w600; action `IconButton(Icons.add)` | | + → `WalletFormSheet` | `:25-36` |
| 2 | `_NetWorthCard` | Container | list #1 | | margin (16,16,16,0); pad H20 V16 | gradient `[cs.primary, cs.primary]` (đồng màu), r16 | | — | `:150-235` |
| 2a | 'Tổng số dư' | Text | | | | 12 white70 | | | `:183-186` |
| 2b | Tổng | `AnimatedMoneyText` / `'...'` | | | 4 | 24 w700 ls−.5 white (redAccent nếu <0) | `totalNetWorthProvider`; loading `'...'`; error shrink | | `:188-212` |
| 2c | `_DarkProgressBar` | Column | | h5 + labels | 12 trên | track white α.2 / redAccent α.3; bar white70 / redAccent; labels 10 white60 | `totalWalletBreakdownProvider` (x1,x2); ẩn nếu 0/0 | | `:220-230, 238-291` |
| 3 | `_WalletTile` ×N | ListTile | list #2 | mặc định (~64) | 8 trên list | leading Container 40 r10 bg `wallet.color` α.15, icon `categoryIcon(type.iconName)` 20 → **luôn `circleEllipsis`**; title `name` 14 w500; subtitle `type.label` 12 onSurfaceVariant; trailing Column end: `AnimatedMoneyText(abs)` 14 w600 onSurface/expenseAlt + `'⚠️ Âm'` 10 nếu âm; loading spinner 16; error shrink | `walletsProvider`, `walletBalanceProvider(id)` | tap → push `/wallets/:id` | `:295-361` |
| 4 | `_EmptyState` | Padding V48 H32 Column | thay #3 | | | `wallet` 48 outlineVariant; 'Chưa có nguồn tiền nào'; 'Thêm ví, tài khoản ngân hàng để theo dõi số dư' 12 center; 24; `FilledButton.icon(add 18, 'Thêm nguồn tiền')` | `wallets.isEmpty` | | `:475-509` |
| 5 | `_ArchivedSection` | Column | list #4 | | | InkWell header pad (16,12,16,8): `'Đã lưu trữ (N)'` 12 w600 ls.5 onSurfaceVariant + `keyboard_arrow_down` 16 AnimatedRotation 260ms; `AnimatedCrossFade` 260ms → `_ArchivedTile` (leading α.08 icon α.5; title 14 onSurfaceVariant; subtitle 'Đã lưu trữ' 12 outlineVariant; trailing `TextButton('Khôi phục')` 12 compact) | `archivedWalletsProvider`; ẩn nếu rỗng/loading/error | expand; Khôi phục → `unarchive` | `:365-471` |
| 6 | `OutlinedButton.icon` | button | list cuối | pad V12 r10 | pad (16,16,16,32) | `add` 16 + 'Thêm nguồn tiền' | | → `WalletFormSheet` | `:61-74` |
| 7 | `_WalletsSkeleton` | ListView | loading | pad (16,16,16,32) | | SkeletonBlock 126 r16; 20; 112×14; 10; 3× `_WalletTileSkeleton` (42 r12, 132×14/88×12, 76×14) gap 8 | | | `:90-146` |
| 8 | Error | `Center(Text('Lỗi: $e'))` | | | | mặc định, **không nút retry** | | | `:39` |

## E. Vùng bố cục
Header 56; body ListView cuộn cả card; không footer/FAB (nút thêm ở cuối list + AppBar +).

## F. Trạng thái màn hình
| State | UI |
|---|---|
| Loading | skeleton (card 126 + 3 tile) |
| Error | `Lỗi: <exception>` thô, không retry |
| Empty | card tổng (0 ₫, progress ẩn) + empty block + nút thêm (2 CTA "Thêm nguồn tiền" + AppBar + = 3 lối) |
| Data | tiles |
| Có archived | section collapsed mặc định |
| Ví âm | số đỏ + '⚠️ Âm'; tổng đỏ nếu tổng âm |
| Overflow tổng (x2>x1) | bar đỏ |

## G. Tương tác
| Trigger | Hành động | Kết quả | Điều hướng |
|---|---|---|---|
| + (AppBar) / nút cuối / CTA empty | sheet WalletForm | | modal |
| Tap tile | | | push `/wallets/:id` |
| Tap header archived | toggle | rotate + crossfade | |
| Khôi phục | `unarchive(id)` không xác nhận | ví chuyển lên list active (stream) | |
| Swipe tile / long-press / reorder | **không có** (có `sortOrder` trong model nhưng không UI) | | |
| Tap card tổng | không có | | |

## H. Animation/transition
| Element | Loại | Thời lượng |
|---|---|---|
| Số tổng / balance tile | AnimatedMoneyText | 360ms |
| Archived expand | AnimatedRotation + AnimatedCrossFade | 260ms |
| Skeleton | pulse | 1100ms |

## I. Dữ liệu hiển thị
| Field | Nguồn | Format | Null |
|---|---|---|---|
| Tổng | `totalNetWorthProvider` (Σ initial+income−expense ví active) | `formatVND` | `'...'` loading |
| Đã dùng / tổng | x2 / x1 | `'Đã dùng ' + formatVND` | ẩn 0/0 |
| Tên / loại | `wallet.name`, `WalletType.label` (Tiền mặt/Ngân hàng/Ví điện tử/Thẻ tín dụng/Đầu tư/Khác) | | |
| Balance | `walletBalanceProvider` | `formatVND(abs)` + cảnh báo | |
| Icon | **lỗi map** → circleEllipsis | | |

## J. Responsive & edge cases
- Tên ví dài: ListTile title 1 dòng wrap → tile cao hơn (không ellipsis).
- Nhiều ví: ListView OK.
- Balance 10 chữ số ở trailing 14px + title: ListTile trailing không giới hạn → có thể chèn title.
- Ví "Thẻ tín dụng" âm là bình thường nhưng vẫn cảnh báo '⚠️ Âm'.

## K. Text hiển thị
`Nguồn tiền` · `Tổng số dư` · `...` · `Đã dùng X ₫` · `/ Y ₫` · `<tên ví>` · `Tiền mặt` `Ngân hàng` `Ví điện tử` `Thẻ tín dụng` `Đầu tư` `Khác` · `⚠️ Âm` · `Đã lưu trữ (N)` · `Đã lưu trữ` · `Khôi phục` · `Thêm nguồn tiền` · `Chưa có nguồn tiền nào` · `Thêm ví, tài khoản ngân hàng để theo dõi số dư` · `Lỗi: …`

## L. Nhận xét nhanh
- Icon loại ví không bao giờ hiển thị đúng (bug ánh xạ) → mọi ví cùng icon "…".
- Card tổng dùng gradient đồng màu (không phải gradient) khác card Home (darken→primary) dù cùng ý nghĩa.
- Lỗi hiển thị exception thô, không retry — khác Home (có retry).
- 3 lối "Thêm nguồn tiền" trên 1 màn; không sắp xếp/kéo thả dù model có `sortOrder`.
