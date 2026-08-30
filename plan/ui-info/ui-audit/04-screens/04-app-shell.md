# 04 — AppShell (Bottom nav + FAB)

## A. Metadata
- **Tên**: `AppShell`
- **Route**: `/` (`lib/core/router/app_router.dart:21`); cũng được render bởi `_AddTransactionPage` cho `/add` (`:105`)
- **File**: `lib/shared/widgets/app_bottom_nav.dart` (368 LOC)
- **Vào từ**: `SpendoApp` initialLocation; mọi `context.go('/')`
- **Thoát đi**: không pop (root); các tab push route con lên trên

## B. Mục đích
Khung 3 tab giữ state (`IndexedStack`) + FAB thêm giao dịch; đổi diện mạo theo `visualModeProvider`.

## C. Layout skeleton
```
Normal                                   Fancy (extendBody: true)
┌─────────────────────────┐              ┌─────────────────────────┐
│                         │              │ AuroraThemeBackground   │
│   IndexedStack[_index]  │              │ (Positioned.fill)       │
│   Transactions|Home|Set │              │ scaffold/canvas trong suốt
│                         │              │                         │
│                    (+)  │ FAB 56 tab0/1│                    (+)  │ GlassButton 56
│                         │              │                         │
├─────────────────────────┤ border top .5│ ╭───────────────────────╮ GlassTabBar.bottom
│ [receipt] [▐home▌] [gear]│ h=80+safe   │ │ receipt   home   gear │ barHeight 64, pad H18 V16
│          Trang chủ      │ pill 90×62   │ ╰───────────────────────╯
└─────────────────────────┘              └─────────────────────────┘
```

## D. Bảng component tree
| # | Element | Loại | Vị trí | Kích thước | Spacing | Style | Nội dung/binding | Tương tác | Source |
|---|---|---|---|---|---|---|---|---|---|
| 1 | `Scaffold` | root | | | | `extendBody: isFancy` | | | `:38-39` |
| 2 | `AuroraThemeBackground` | bg | Positioned.fill (chỉ fancy) | full | | blob `cs.primary/secondary/tertiary`, α .38 light / .55 dark (`BlendMode.plus` dark) + overlay trắng .10/.03 | `visualModeProvider` | parallax | `:42`, `aurora_theme_background.dart:190-216` |
| 3 | `Theme` override | wrapper | | | | fancy: `scaffoldBackgroundColor/canvasColor = transparent` | | | `:43-51` |
| 4 | `IndexedStack` | | body | full | | mỗi child bọc `TickerMode(enabled: _index==i)` | `_screens = [Transactions, Home, Settings]` | | `:52-60` |
| 5 | `_SpendoNavBar` (normal) | Container | bottomNavigationBar | h 80 + SafeArea bottom | | bg `cs.surface`, border top `cs.outlineVariant` 0.5 | 3 `_NavButton` Expanded | tap | `:114-167` |
| 5a | `_NavButton` | GestureDetector opaque | mỗi 1/3 | pill 90 × (44→62) | | `AnimatedContainer` 280ms easeOutCubic; bg `cs.primaryContainer` khi chọn, r20; icon 26 scale 1→1.22 easeOutBack; label 11 w600 h1 fade-in từ 30% + slide 6→0, chỉ hiện khi chọn; màu lerp `onSurfaceVariant→primary` | `_items[i]` | `onTap(i)` | `:213-356` |
| 6 | `_FancySpendoNavBar` | `GlassTabBar.bottom` | bottomNavigationBar | barHeight 64, H pad 18, V pad 16 | | `focalQuality` premium; selected `cs.primary`, unselected `cs.onSurfaceVariant` | 3 `GlassTab` cùng icon/label | `onTabSelected` | `:169-211` |
| 7 | FAB normal | `FloatingActionButton` | endFloat (mặc định) | 56 (theme) | | `CircleBorder`, bg `cs.primary`, fg `onPrimary`, elevation 2 (theme); `Icons.add` 28; bọc `PressableScale(deferTapToChild)` | chỉ khi `_index ∈ {0,1}` | → `showModalBottomSheet(AddTransactionSheet)` | `:68-97` |
| 8 | FAB fancy | `GlassButton` | | 56×56 | | `useOwnLayer`, `interactiveQuality`, `RepaintBoundary` | | cùng | `:71-86` |

Nav items (`:120-136`): 0 `receipt_long_outlined/receipt_long` "Giao dịch"; 1 `home_outlined/home` "Trang chủ"; 2 `settings_outlined/settings` "Cài đặt". Key test: `spendo_tab_$i`, `spendo_fab_add_transaction`.

## E. Vùng bố cục
- Body: full (fancy: kéo dưới nav).
- Footer: nav bar 80 (normal) — cao hơn chuẩn Material 80 = NavigationBar M3 mặc định, nhưng tự vẽ; safe area bottom thêm vào.
- Floating: FAB endFloat, không dịch theo nav (Scaffold xử lý); các màn con chừa `SizedBox(height 80)` cuối list.
- Overlay: sheet mở từ FAB **không** truyền `backgroundColor/shape` → dùng `bottomSheetTheme` (white/`#1E1E1E`, r20 top).

## F. Trạng thái màn hình
| State | UI |
|---|---|
| Initial | `_index = 1` (Home, tab giữa) `:23` |
| Tab đổi | pill mở rộng 44→62, label trượt vào, icon phóng 1.22 |
| Fancy | nền aurora + glass nav + glass FAB; `Settings` thêm padding đáy (`settings_screen.dart:36-37`); Home/Transactions **không** thêm padding → 80px spacer cuối list che bởi nav trong suốt `[cần kiểm tra trực quan]` |
| Reduce motion | Aurora vẫn chạy (không check reduce motion trong `aurora_theme_background.dart`); nav animation vẫn chạy (không dùng `MotionSpec`) |
| Loading/Error/Empty | không có ở cấp shell |

## G. Tương tác
| Trigger | Hành động | Kết quả UI | Điều hướng |
|---|---|---|---|
| Tap tab i | `HapticFeedback.lightImpact(); setState(_index=i)` | đổi IndexedStack, pill anim | không đổi URL |
| Tap FAB | `showModalBottomSheet(isScrollControlled)` | sheet AddTransaction | modal |
| Tap tab đang chọn | không có xử lý (không scroll-to-top) | — | — |
| Long-press / swipe tab | không có | — | — |

## H. Animation/transition
| Element | Loại | Thời lượng | Curve |
|---|---|---|---|
| Pill height 44→62 & màu | AnimatedContainer | 280ms | `easeOutCubic` |
| Icon scale 1→1.22 | Tween | 280ms | `easeOutBack` |
| Label opacity/slide | Interval 0.3–1.0 | 280ms | `easeOut`/`easeOutCubic` |
| FAB press | PressableScale 0.96 | 100/140ms | `easeOutCubic` |
| Aurora | loop | 24s | — |
| Đổi tab | **không** có transition nội dung (IndexedStack tức thì) | | |

## I. Dữ liệu hiển thị
Chỉ label tĩnh; không badge/số.

## J. Responsive & edge cases
- Pill rộng cố định 90 → 3 pill = 270; màn hẹp <300 vẫn OK vì `Expanded`.
- Label chỉ hiện khi chọn → 2 tab còn lại chỉ icon (không có tooltip/semantics label — `Icon` không có `semanticLabel`).
- Landscape: nav 80 + safe area chiếm nhiều chiều cao; không có rail.

## K. Text hiển thị
`Giao dịch` · `Trang chủ` · `Cài đặt`

## L. Nhận xét nhanh
- Tab mặc định ở **giữa** (Home) nhưng tab trái là Transactions — thứ tự không theo tần suất dùng hay quy ước (Home thường ở trái).
- FAB "+" và ô "Thêm" trong Home grid và route `/add` là 3 lối vào cùng 1 sheet trên cùng màn.
- Nav tự vẽ thay vì `NavigationBar` M3 → `navigationBarTheme` trong theme là dead config; không semantics.
- Chỉ 3 tab nhưng app có ≥7 khu vực chức năng (Stats, Wallets, Loans, Reminders, Budget… phải qua Home grid).
