# 31 — Android Home Widgets (native)

## A. Metadata
- **Tên**: `SpendoWidgetSmall` (2×1), `SpendoWidgetMedium` (2×2)
- **File**: `android/app/src/main/res/layout/widget_layout_small.xml`, `widget_layout_medium.xml`, `xml/widget_info_{small,medium}.xml`, `kotlin/com/kg/spendo/spendo/SpendoWidget{Small,Medium}.kt`
- **Dữ liệu**: SharedPreferences `widget_categories` (JSON id/name/emoji) + `widget_pinned_ids`, ghi bởi `lib/core/utils/widget_sync.dart:23-66` (gọi lúc khởi động và khi đổi slot)
- **Thoát đi**: tap → deep link `spendo:///add` hoặc `spendo:///add?category_id=<id>` (`SpendoWidgetMedium.kt:85-87`) → GoRouter `/add`
- iOS: `[UNKNOWN: không có widget extension trong repo]`

## B. Mục đích
Lối tắt thêm chi tiêu từ màn hình chính; medium cho phép chọn sẵn 1 trong 4 danh mục đã ghim.

## C. Layout skeleton
```
Small (minW110 minH40, 2×1)          Medium (110×110, 2×2)
┌─────────────────────────┐          ┌─────────────────────────┐ bg @drawable/widget_background, pad 12dp
│ Spendo 12sp #F06292 bold│          │ Spendo 12sp #F06292 bold│ marginBottom 8 / 10
│ ┌─────────────────────┐ │          │ ┌────────┐ ┌────────┐   │ GridLayout 2×2, ô margin 4 pad 8 bg widget_cat_bg
│ │  + Thêm chi tiêu    │ │ Button   │ │  🍜    │ │  🚗    │   │ emoji 20sp
│ └─────────────────────┘ │ 13sp white│ │Ăn uống │ │Di chuyển│   │ tên 10sp #666666
└─────────────────────────┘          │ └────────┘ └────────┘   │
                                     │ ┌────────┐ ┌────────┐   │
                                     │ │  🛍️    │ │  📚    │   │
                                     │ │Mua sắm │ │Học tập │   │
                                     │ └────────┘ └────────┘   │
                                     └─────────────────────────┘
```

## D. Bảng component tree
| # | Element | Style | Binding | Tương tác | Source |
|---|---|---|---|---|---|
| S1 | `tv_title` | 12sp bold `#F06292` | hằng "Spendo" | | `widget_layout_small.xml:9-16` |
| S2 | `btn_add` | Button match_parent, 13sp white, bg `widget_button_bg`, pad 8 | "+ Thêm chi tiêu" | → `spendo:///add` (`SpendoWidgetSmall.kt:30`) | `:18-26` |
| M1 | title | như S1 | | | `widget_layout_medium.xml:9-16` |
| M2 | `btn_cat_0..3` | LinearLayout vertical center pad 8 margin 4 bg `widget_cat_bg`; `tv_cat_N_icon` 20sp emoji; `tv_cat_N_name` 10sp `#666666` marginTop 2 | `cat.emoji`, `cat.name` từ prefs (`SpendoWidgetMedium.kt:81-82`); mặc định XML: 🍜 Ăn uống / 🚗 Di chuyển / 🛍️ Mua sắm / 📚 Học tập | tap → `spendo:///add?category_id=` | `:18-125` |

Emoji map (`widget_sync.dart:9-13`): restaurant 🍜, directions_car 🚗, school 📚, sports_esports 🎮, favorite 💊, shopping_bag 🛍️, work 💼, laptop 💻, storefront 🏪, card_giftcard 🎁, home 🏠, flight ✈️, movie 🎬, fitness_center 💪, pets 🐾, more_horiz 📦, fallback 💰.

## E–H
Widget tĩnh; `updatePeriodMillis 0` (chỉ cập nhật khi app gọi `HomeWidget.updateWidget`); resizable ngang/dọc. Không animation.

## F. Trạng thái
| State | UI |
|---|---|
| Ghim < 4 slot | Kotlin chỉ dùng danh sách ghim khi **đủ 4** (`displayCats = if (cats.size >= 4) cats else defaults`, `SpendoWidgetMedium.kt:76`) → ghim 1–3 danh mục **không có tác dụng**, widget vẫn hiện 4 ô mặc định (Ăn uống/Di chuyển/Mua sắm/Học tập) với `cat.id` rỗng → tap mở `/add` không prefill (`:85-87`) |
| App chưa mở lần nào | prefs rỗng → mặc định XML |

## I. Dữ liệu hiển thị
Emoji (không phải Lucide như trong app), tên danh mục 10sp.

## J. Responsive & edge cases
Tên dài 10sp trong ô ~50dp: XML không có `maxLines`/`ellipsize` (grep rỗng) → TextView wrap nhiều dòng, ô cao lên. Màu `#666666`/`#F06292` cứng, không theo dark mode hệ thống.

## K. Text hiển thị
`Spendo` · `+ Thêm chi tiêu` · tên 4 danh mục ghim

## L. Nhận xét nhanh
- Ngôn ngữ hình ảnh khác app (emoji vs Lucide; màu hồng `#F06292` cũ vs seed theme).
- Không hiển thị số liệu (chi tháng này, số dư) — chỉ là launcher.
- Không dark mode.
- Ghim dưới 4 slot trong Settings không có tác dụng — UI Settings cho phép ghim từng ô nhưng widget yêu cầu đủ 4.
