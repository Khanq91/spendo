# 03 — Welcome (Onboarding 3 trang)

## A. Metadata
- **Tên**: `WelcomeScreen`
- **Route**: không có (child của `StartupGate` khi chưa onboarding, `startup_gate.dart:35`)
- **File**: `lib/features/onboarding/presentation/welcome_screen.dart` (320 LOC)
- **Vào từ**: StartupGate (lần đầu cài app)
- **Thoát đi**: `_finish` → `setBool('onboarding_completed_v1', true)` → `Navigator.pushReplacement(MaterialPageRoute → SpendoApp)` (`:59-66`)
- **Theme context**: MaterialApp#1 (`main.dart:68`, seed `#F06292`, light only) — **không** phải theme user

## B. Mục đích
Giới thiệu app (trang 0), chọn chế độ đồ hoạ Normal/Fancy (trang 1), tuỳ chọn đăng nhập Google Drive để backup (trang 2).

## C. Layout skeleton (chung 3 trang)
```
┌─────────────────────────┐ Scaffold bg cs.surface; Positioned.fill AuroraThemeBackground (luôn bật)
│ SafeArea                │
│  pad L28 T56 R28 B96    │  _WelcomeStep :154-155
│ ╭─────────────────────╮ │  GlassContainer superellipse 28, pad H24 V22, quality premium :159-163
│ │      ◉ 92×92        │ │  _BrandHeader: logo ClipOval             :199-206
│ │        (18)         │ │
│ │       Spendo 40     │ │  40 w700 onSurface h1                    :208-216
│ │        (18)         │ │
│ │  description 16     │ │  center, onSurfaceVariant, h1.35         :169-177
│ ╰─────────────────────╯ │
│          (36)           │
│ ┌ Expanded Center ─────┐│  trang0: rỗng | trang1: VisualModePicker(glass) | trang2: _GoogleDriveOptIn
│ │                      ││
│ └──────────────────────┘│
│ [Bỏ qua]*     [Tiếp theo]│  Positioned L24 R24 B24; *chỉ trang 2, trang 0-1 là SizedBox(88) :124-134, 295-298
└─────────────────────────┘
```

## D. Bảng component tree
| # | Element | Loại | Vị trí | Kích thước | Spacing | Style | Nội dung/binding | Tương tác | Source |
|---|---|---|---|---|---|---|---|---|---|
| 1 | `AuroraThemeBackground` | CustomPaint | Positioned.fill | full | — | 4 blob radial màu `cs.primary/secondary/tertiary` (MaterialApp#1 → hồng/xám-hồng), loop 24s, parallax theo accelerometer/pointer | — | pointer move → parallax | `:94`, `aurora_theme_background.dart` |
| 2 | `PageView` | pager | SafeArea | full | — | `NeverScrollableScrollPhysics`, không indicator | 3 `_WelcomeStep` | `onPageChanged` → `_page` | `:98-123` |
| 3 | `GlassContainer` (card brand) | glass | trên mỗi trang | width = màn − 56, height theo nội dung | pad H24 V22 | `LiquidRoundedSuperellipse(28)`, `useOwnLayer`, `focalQuality` (premium) | — | — | `:158-180` |
| 4 | Logo | `ClipOval(Image.asset)` | trong card | 92×92 | 18 dưới | cover | `app_logo.jpg` | — | `:199-206` |
| 5 | "Spendo" | Text | | auto | 18 dưới | 40 w700 `cs.onSurface` h1 | hằng | — | `:208-216` |
| 6 | Description | Text | | auto | — | 16 `cs.onSurfaceVariant` h1.35 center | trang0: "Quản lý thu chi cá nhân gọn gàng và rõ ràng." / trang1: "Chọn mức đồ họa" / trang2: "Kết nối Google Drive để sao lưu dữ liệu Spendo khi cần." | — | `:104-120, 169-177` |
| 7 | Khoảng trống | SizedBox | | 36 | | | | | `:182` |
| 8a | (trang 0) `SizedBox.shrink` | — | Expanded center | 0 | | | vùng dưới **trống hoàn toàn** | | `:106` |
| 8b | (trang 1) `VisualModePicker(useGlass: true)` | 2 tile | Expanded center | full width, mỗi tile pad H16 V14, gap 12 | | `GlassContainer` superellipse 22; icon 22; title 15 w700 (primary nếu chọn); subtitle 12 onSurfaceVariant h1.25; trailing `circleCheck`/`circle` 20 AnimatedSwitcher | tile "Bình thường"/"Xịn xò" | tap → `_selectedMode` | `:110-116`, `visual_mode_picker.dart` |
| 8c | (trang 2) `_GoogleDriveOptIn` | Column | Expanded center | button 220×52 | email +12 | `GlassButton.custom` superellipse 18; `cloud_outlined` 20 hoặc spinner 18; "Đăng nhập Google" 14 w700; email text màu primary | `gdriveProvider.isLoading/email` | tap → `_signInGoogle` | `:222-270` |
| 9 | `_OnboardingActions` | Row spaceBetween | Positioned L24 R24 B24 | — | — | trái: `TextButton('Bỏ qua')` chỉ trang 2, ngược lại `SizedBox(width 88)`; phải: `GlassButton.custom` 132×48 superellipse 18 "Tiếp theo" 14 w700, FadeTransition + SlideTransition Offset(0.25,0)→0 | `page`, `_nextController` | Bỏ qua → `_finish`; Tiếp theo → `_goNext` (trang 2: `_finish`) | `:124-134, 272-320` |

## E. Vùng bố cục
- Nền: Aurora full-bleed (dưới cả status bar).
- Body: `SafeArea` → `Stack[PageView, Positioned actions]`. Mỗi trang là `Column[card, 36, Expanded(Center(child))]` với padding `(28,56,28,96)` → card cách top 56 (+safe area), vùng dưới chừa 96 cho hàng nút.
- Footer: hàng nút tuyệt đối cách đáy 24 (không phụ thuộc keyboard; không có input nên OK).

## F. Trạng thái màn hình
| State | UI |
|---|---|
| Initial (trang 0) | card + vùng dưới trống; nút "Tiếp theo" **ẩn 1 giây** rồi trượt vào 420ms (`:36-38`) |
| Trang 1 | 2 tile glass, "Bình thường" chọn sẵn (`_selectedMode = normal` `:25`) |
| Trang 2 default | nút "Đăng nhập Google" + "Bỏ qua" + "Tiếp theo" (label vẫn "Tiếp theo" dù là bước cuối) |
| Trang 2 loading | nút Google `enabled: false`, icon → spinner 18 |
| Trang 2 signed in | thêm dòng email màu primary dưới nút; SnackBar "Đã kết nối Google Drive." |
| Trang 2 lỗi | SnackBar `state.error ?? 'Đăng nhập Google thất bại.'` |
| Empty/Error/Offline khác | không có |

## G. Tương tác
| Trigger | Hành động | Kết quả UI | Điều hướng |
|---|---|---|---|
| Tap "Tiếp theo" trang 0 | `_pageController.nextPage(360ms easeOutCubic)` | sang trang 1 | — |
| Tap tile Bình thường/Xịn xò | `setState(_selectedMode)` | tick đổi (scale+fade 140ms) | — |
| Tap "Tiếp theo" trang 1 | lưu `visualModeProvider.setMode` rồi nextPage | sang trang 2 | — |
| Tap "Đăng nhập Google" | `gdriveProvider.signIn()` | spinner → snackbar | mở Google Sign-In hệ thống |
| Tap "Bỏ qua" (trang 2) | `_finish` | — | replace → SpendoApp |
| Tap "Tiếp theo" trang 2 | `_finish` | — | replace → SpendoApp |
| Swipe ngang | **bị chặn** (`NeverScrollableScrollPhysics`) | — | — |
| Back hệ thống | không chặn (`PopScope` không có) → pop MaterialApp#1 route → thoát app `[UNKNOWN: chưa kiểm chứng trên thiết bị]` | | |

## H. Animation/transition
| Element | Loại | Thời lượng | Curve |
|---|---|---|---|
| Nút "Tiếp theo" xuất hiện | fade + slide x0.25→0, delay 1s | 420ms | `easeOutCubic` |
| Chuyển trang | PageView animateTo | 360ms | `easeOutCubic` |
| Tick tile visual mode | AnimatedSwitcher scale+fade | 140ms (`tapUpDuration`) | mặc định |
| Tile press | `PressableScale` 0.96 | 100/140ms | `easeOutCubic` |
| Aurora | 4 blob quỹ đạo | 24s loop | linear |
| Route ra | `MaterialPageRoute` mặc định | platform | |

## I. Dữ liệu hiển thị
| Field | Nguồn | Null |
|---|---|---|
| email | `gdriveProvider.email` | ẩn dòng |
| isLoading | `gdriveProvider.isLoading` | false |
| Logo | asset | — |

## J. Responsive & edge cases
- Trang 0: hơn nửa màn dưới card trống; trang 1 với màn thấp: 2 tile + hàng nút có thể chạm nhau (Expanded center không scroll).
- Text mô tả dài không tràn (center wrap).
- Không có page indicator → user không biết còn mấy bước.
- Dark mode: MaterialApp#1 chỉ có `theme` (không `darkTheme`) → luôn nền sáng dù hệ thống tối.

## K. Text hiển thị
`Spendo` · `Quản lý thu chi cá nhân gọn gàng và rõ ràng.` · `Chọn mức đồ họa` · `Bình thường` · `Giao diện nhẹ, ổn định và tiết kiệm tài nguyên.` · `Xịn xò` · `Nền aurora, điều hướng liquid glass và hiệu ứng mềm hơn.` · `Kết nối Google Drive để sao lưu dữ liệu Spendo khi cần.` · `Đăng nhập Google` · `Đã kết nối Google Drive.` · `Đăng nhập Google thất bại.` · `Bỏ qua` · `Tiếp theo`

## L. Nhận xét nhanh
- Trang 0 chỉ có 1 câu mô tả, không có giá trị/feature nào được giới thiệu; nửa dưới trống.
- Không page indicator, không back, không swipe; nút cuối vẫn ghi "Tiếp theo" thay vì "Bắt đầu".
- Chạy glass premium + aurora + sensor ngay cả khi user sẽ chọn "Bình thường".
- Không có nút bỏ qua ở trang 0–1 (chỉ trang 2).
