# 01 — Design tokens

Nguồn trực quan: `mockups/00 - Foundation.dc.html`. Cấu trúc role theo M3; thay `ColorScheme.fromSeed` bằng **ColorScheme khai báo tường minh** + `ThemeExtension` cho token ngoài M3 (brand, income/expense/warning, 5 bậc surface).

## Màu — Light
| Role | Hex | Dùng cho |
|---|---|---|
| brand | #F06292 | FAB, tab indicator (KHÔNG dùng nơi khác) |
| onBrand | #551D30 | icon/chữ trên brand |
| primary | #8C4A5E | nút chính, link, progress, focus |
| onPrimary | #FFFFFF | chữ trên primary |
| primaryContainer | #FFD9E1 | ô/chip đang chọn |
| onPrimaryContainer | #703346 | chữ trên primaryContainer |
| secondaryContainer | #E3E8D0 | sage — icon tile, nút phụ |
| onSecondaryContainer | #48513A | |
| tertiaryContainer | #FFDCBF | badge "tự động" (SePay) |
| income | #5A7230 | số tiền thu (olive ấm) |
| expense | #B23A2E | số tiền chi (terracotta) |
| warning | #B26A00 | sắp vượt hạn mức |
| error | #BA1A1A | lỗi, vượt hạn |
| surface | #FAF1E8 | nền màn |
| surfaceContainerLowest | #FFFDF9 | bottom sheet, row nổi |
| surfaceContainerLow | #F5E9DA | card, numpad key, meta chip |
| surfaceContainer | #EFE0CC | chip lọc, bottom nav, input filled |
| surfaceContainerHighest | #E2CDB1 | progress track, divider trong card |
| onSurface | #221A12 | chữ chính |
| onSurfaceVariant | #57493B | chữ phụ, label, icon phụ |
| outlineVariant | #DCC9AF | divider 1px, chip outline |
| outline dashed | #B7A388 | ô "Thêm" nét đứt |

## Màu — Dark (cùng role, chỉ đổi giá trị — KHÔNG dựng lại màn)
| Role | Hex | Ghi chú |
|---|---|---|
| brand / onBrand | #F06292 / #551D30 | giữ nguyên |
| primary / onPrimary | #E9A4B5 / #4A2231 | nâng tone |
| primaryContainer / on | #703346 / #FFD9E1 | đảo chiều light |
| secondaryContainer / on | #48513A / #E3E8D0 | |
| tertiaryContainer / on | #7A4A24 / #FFDCBF | |
| income · expense | #A9C77C · #E88D7C | |
| warning · error | #E8A94E · #FFB4AB | |
| surface | #1C140C | nâu ấm, không đen thuần |
| surfaceContainerLowest | #251B10 | sheet |
| surfaceContainerLow | #2B2013 | card |
| surfaceContainer | #342718 | chip, nav |
| surfaceContainerHighest | #453421 | track |
| onSurface · onSurfaceVariant | #F0E4D3 · #C9B79F | |
| outlineVariant | #55442F | divider |

Quy tắc dark: FAB/tab giữ brand + icon #551D30; nút chính → primary #E9A4B5 chữ #4A2231; icon tile danh mục giữ màu stroke, nền rgba nâng alpha 0.16→0.24; **bỏ box-shadow**, phân tầng bằng chênh lệch surface.

## Màu danh mục (icon tile: nền = rgba(màu, 0.16–0.18), stroke = màu)
Ăn uống #C67139 · Di chuyển #7A8A5E · Mua sắm #B98A2F · Hoá đơn #5E7E8A · Giải trí #A5668B · Sức khoẻ #C05B4D · Học tập #6B7EA8 · Thu nhập #5A7230.

## 5 màu chủ đạo (Appearance)
Token trên định nghĩa cho seed mặc định "Hồng" (#F06292). 4 seed còn lại: chỉ swap brand + ramp primary tương ứng, **giữ nguyên bộ surface cream/nâu** — không sinh lại toàn scheme bằng fromSeed.

## Chữ
Font: **Figtree** (toàn UI, 400–800; số tiền luôn `tabular figures` — `FontFeature.tabularFigures()`), **Caprasimo** chỉ cho tiêu đề màn + brand moment.
⚠️ Kiểm tra glyph tiếng Việt của Caprasimo trước (subset latin/latin-ext); nếu thiếu dấu → fallback tiêu đề sang Figtree 800.

| Style | Spec | Dùng |
|---|---|---|
| titleLarge | Caprasimo 22–23/400 | tiêu đề màn |
| displaySmall | Figtree 36–38/800, ls −0.5, tnum | số dư, số tiền sheet |
| headlineSmall | 24/700 tnum | số trong sheet/card |
| titleMedium | 16/600 | tiêu đề sheet |
| titleSmall | 14/600 | tên trong row |
| bodyMedium | 14/400 | nội dung |
| labelMedium | 12/600, ls 0.3, UPPERCASE cho section | section, chip, nav |
| labelSmall | 11/600 | tên dưới icon |

## Hình khối & spacing
- Bo góc: card 16 · card nổi bật 20 · sheet 28 (top) · input 12 · numpad key 16 · chip/nút/FAB pill 999.
- Lưới 4px: 4·8·12·16·20·24·32·40. Padding ngang màn 16. Gap section 24. Row 56/72. Icon tile danh mục 40–46.
- Icon: Lucide (`lucide_icons_flutter`) stroke 2.25, cỡ 24/20/16. **Xoá toàn bộ Material `Icons.*`** (≈38 icon) — chỉ Lucide.
- Divider 1px outlineVariant; card không viền (tonal thay viền).
- Hit target ≥ 44px.

## Motion
Giữ nguyên bộ `lib/shared/widgets/motion/` (MotionSpec, PressableScale, AnimatedMoneyText, AnimatedProgressBar, SkeletonBlock, MotionListItem) — chỉ đổi màu theo token. Respect `disableAnimations`.
