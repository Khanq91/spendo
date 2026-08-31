# 02 — Component dùng chung

Mục tiêu kép: (a) skin mới theo token, (b) **hợp nhất các bản private trùng lặp** (audit `06-inconsistencies.md`: pill-chip ×7, drag-handle ×15, section header ×3, empty state ×6, progress bar ×5). Mỗi component dưới đây là 1 widget công khai trong `lib/shared/widgets/`, thay thế toàn bộ bản inline.

## SpendoButton
- **primary**: pill h48, nền primary, chữ onPrimary 14/600, padding ngang 28. Pressed: PressableScale + đậm hơn 1 bậc.
- **secondary**: pill h48, nền secondaryContainer, chữ onSecondaryContainer.
- **outline**: pill h40, viền 1.5 outlineVariant, chữ primary 13/600, padding 20.
- Disabled: opacity 0.45.

## SpendoChip
- **filter selected**: h34, nền primaryContainer, chữ onPrimaryContainer 12.5/600 (+ ✓ khi cần).
- **filter unselected**: h34, nền surfaceContainer, chữ onSurfaceVariant.
- **suggestion**: h32–36, viền 1px outlineVariant HOẶC nền surfaceContainer (màn 02b), chữ 12–13/600.
- **meta** (ngày/ví/lặp lại trong Add sheet): h36, nền surfaceContainerLow, icon 15 + chữ 12.5/600.
- **segmented Chi|Thu**: track pill nền surfaceContainer padding 3; opt h32 padding 18; selected nền primaryContainer chữ onPrimaryContainer 13/700.

## CategoryTile (grid chọn danh mục — màn 02, 02b, 15)
Cột: circle 46 + label 11 bên dưới, gap 5. Nền rgba(màu danh mục, 0.16–0.18), icon Lucide 20 stroke màu danh mục. **Selected**: nền primaryContainer, icon onPrimaryContainer, ring `box-shadow 0 0 0 2px primary`, label 11/700. Ô "Thêm": circle nét đứt 1.5 #B7A388, icon plus #86735F.

## TransactionRow
Row min-56, padding 8×16: icon tile 40 (như CategoryTile không label) + (tên 14/600, phụ 12 onSurfaceVariant) + số tiền 14/700 tnum (expense đỏ "−", income olive "+"). Header nhóm ngày: 12/600 onSurfaceVariant + tổng ngày bên phải cùng cỡ, màu theo dấu.

## SpendoCard / SettingsGroupCard
Card: nền surfaceContainerLow, r16 (nổi bật r20), padding 14–16, không viền không bóng (light). SettingsGroupCard: nền surfaceContainerLow r20, các row min-49 icon tile 38 nền secondaryContainer + chevron Lucide 17; divider 1px surfaceContainerHighest, margin-left 66.

## SectionHeader
Label 12/600 onSurfaceVariant, letter-spacing 0.4, UPPERCASE ("DỮ LIỆU", "GỢI Ý"…), margin trên 12–20.

## SpendoProgressBar
h8 (splash h4), track surfaceContainerHighest, fill pill: primary / warning (≥85%) / error (vượt). Dùng AnimatedProgressBar hiện có, đổi màu.

## SpendoFab
56, nền brand, icon plus 26 stroke 2.5 onBrand, bóng `0 6px 18px rgba(85,29,48,0.35)` (light; dark bỏ bóng). Đặt trên bottom nav 16px.

## SpendoBottomNav (shell 4 tab)
h80, nền surfaceContainer, mỗi tab: indicator pill 56×32 (active nền brand, icon onBrand) + label 11 (active /700 onSurface, inactive /600 onSurfaceVariant). Icon Lucide 20: house, notebook-text, chart-pie, settings.

## SpendoSheet
Bottom sheet: nền surfaceContainerLowest, bo 28 top, drag-handle 36×4 pill outlineVariant margin 10 auto (MỘT widget, thay 15 bản inline), bóng `0 -8px 32px rgba(43,30,19,0.25)` (light). Sheet form cao ~92%.

## Numpad
Grid 3 cột gap 8, key h54 r16 nền surfaceContainerLow, số 23/500 tnum, "000" 17/600, delete icon Lucide. Layout 1-9 / 000 / 0 / ⌫.

## SearchBar (màn 03)
h46 r999 nền surfaceContainer, icon search 19 onSurfaceVariant, placeholder 14 onSurfaceVariant.

## FormField
Input filled: h46–50 r12 nền surfaceContainer, chữ 15. Focus: nền surfaceContainerLowest, viền 1.5 primary + glow `0 0 0 3px rgba(140,74,94,0.10)`. Validate lỗi: viền error + helper 12 error, inline (không dialog).

## EmptyState
1 widget chung: icon Lucide 40 onSurfaceVariant, tiêu đề 14/600, mô tả 13 onSurfaceVariant, nút outline tùy chọn — thay 6 bản inline.
