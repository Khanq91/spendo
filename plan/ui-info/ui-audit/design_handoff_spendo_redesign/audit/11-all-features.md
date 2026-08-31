# 11 — AllFeatures (Tất cả tính năng)

## A. Metadata
- **Tên**: `AllFeaturesScreen`
- **Route**: `/features` (`app_router.dart:22`)
- **File**: `lib/features/home/presentation/screens/all_features_screen.dart` (49 LOC) + `widgets/home_feature_actions.dart:73-204` (`buildAllFeatureSections`)
- **Vào từ**: Home grid ô "Xem thêm"
- **Thoát đi**: back; 18 ô → push/sheet

## B. Mục đích
Danh mục đầy đủ lối tắt, chia 4 nhóm.

## C. Layout skeleton
```
┌───────────────────────────────┐ AppBar: back tự động + 'Tất cả tính năng' 16 w600
├───────────────────────────────┤ ListView.separated pad (16,8,16,24), gap 18
│ Tài chính 13 w700 onSurfaceVariant│ pad L2 B8
│ (⊕)(🧾)(👛)(📅)               │ FeatureGrid 4 cột (tile 102)
│ Thêm  Giao  Ví  Hạn mức       │
│ giao   dịch     tháng         │
│ (🏷)                          │
│ Hạn mức                       │
│ danh mục                      │
│ Vay nợ                        │
│ (🤝)(↙)(↗)                    │
│ Vay nợ Đang vay Cho vay       │
│ Theo dõi                      │
│ (◔)(🔔)(📱)                   │
│ Thống kê Nhắc nhở Widget      │
│ Tiện ích & cài đặt            │
│ (⚙)(💾)(☁)(🏛)                │
│ Cài đặt Backup Google Ngân    │
│                Drive  hàng    │
│ (🎨)(🏷)(📄)                  │
│ Giao diện Danh mục Xuất báo cáo│
└───────────────────────────────┘
```

## D. Bảng component tree
| # | Element | Loại | Vị trí | Kích thước | Spacing | Style | Nội dung/binding | Tương tác | Source |
|---|---|---|---|---|---|---|---|---|---|
| 1 | AppBar | | | 56 | | title Text 16 w600 (trùng theme) | 'Tất cả tính năng' | back | `:15-20` |
| 2 | `ListView.separated` | | body | | pad (16,8,16,24); sep 18 | | 4 `FeatureSection` | | `:21-46` |
| 3 | Section title | Text | | | pad L2 B8 | 13 w700 onSurfaceVariant | | | `:31-41` |
| 4 | `FeatureGrid` | GridView shrinkWrap | | 4 cột, extent 102, spacing 10/6 | | như Home | `section.actions` | tap | `:42` |

Nội dung (`home_feature_actions.dart:73-204`):
| Nhóm | Ô | Icon | Màu | Đích |
|---|---|---|---|---|
| Tài chính | Thêm giao dịch | circlePlus | #16A34A | `/add` |
| | Giao dịch | receiptText | #2563EB | `/transactions` |
| | Ví | wallet | #0EA5E9 | `/wallets` |
| | Hạn mức tháng | calendarDays | #8B5CF6 | sheet `BudgetScreen` |
| | Hạn mức danh mục | tags | #EC4899 | sheet `CategoryBudgetScreen` |
| Vay nợ | Vay nợ | handCoins | #DC2626 | `/loans` |
| | Đang vay | arrowDownLeft | #EA580C | `/loans?type=borrowed` |
| | Cho vay | arrowUpRight | #0891B2 | `/loans?type=lent` |
| Theo dõi | Thống kê | chartPie | #7C3AED | `/stats` |
| | Nhắc nhở | bellRing | #DB2777 | `/reminders` |
| | Widget | smartphone | #475569 | `/settings` (**không scroll tới section**) |
| Tiện ích & cài đặt | Cài đặt | settings | #64748B | `/settings` |
| | Backup | hardDriveDownload | #6C63FF | `/settings` |
| | Google Drive | cloud | #0284C7 | `/settings` |
| | Ngân hàng | landmark | #0F766E | `/settings` |
| | Giao diện | palette | #9333EA | `/settings` |
| | Danh mục | tag | #CA8A04 | `/settings` |
| | Xuất báo cáo | fileDown | #059669 | `/settings` |

## E. Vùng bố cục
Header AppBar; body scroll; không footer/FAB.

## F. Trạng thái màn hình
Chỉ 1 state tĩnh. Không loading/empty/error.

## G. Tương tác
| Trigger | Kết quả | Điều hướng |
|---|---|---|
| Tap ô | PressableScale | push/sheet theo bảng; ô `/add` → sau khi đóng sheet `go('/')` → **mất màn AllFeatures** |
| Back | pop | về Home |

## H. Animation/transition
PressableScale 0.96; route mặc định.

## I. Dữ liệu hiển thị
Tĩnh (label, icon, màu hard-code).

## J. Responsive & edge cases
- Label 2 dòng ("Hạn mức danh mục", "Xuất báo cáo") ellipsis 2 dòng 12px.
- 18 ô, 4 nhóm → ~640px, cuộn trên màn nhỏ.

## K. Text hiển thị
`Tất cả tính năng` · `Tài chính` · `Thêm giao dịch` · `Giao dịch` · `Ví` · `Hạn mức tháng` · `Hạn mức danh mục` · `Vay nợ` · `Đang vay` · `Cho vay` · `Theo dõi` · `Thống kê` · `Nhắc nhở` · `Widget` · `Tiện ích & cài đặt` · `Cài đặt` · `Backup` · `Google Drive` · `Ngân hàng` · `Giao diện` · `Danh mục` · `Xuất báo cáo`

## L. Nhận xét nhanh
- 8/18 ô đều dẫn tới `/settings` không có anchor → 7 ô "khác nhau" hạ cánh cùng vị trí đầu trang Settings.
- Trùng 7/8 ô với Home grid; nhóm "Vay nợ" 3 ô cùng 1 màn chỉ khác filter.
- Ô "Widget" trong "Theo dõi" nhưng thực chất là cài đặt.
