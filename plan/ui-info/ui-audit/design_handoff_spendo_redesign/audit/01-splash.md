# 01 — Splash

## A. Metadata
- **Tên**: `SplashScreen`
- **Route**: không có (là `MaterialApp#1.home`, `lib/main.dart:69-72`)
- **File**: `lib/shared/widgets/splash_screen.dart` (595 LOC)
- **Vào từ**: khởi động app (cold start)
- **Thoát đi**: `Navigator.pushReplacement(PageRouteBuilder fade 350ms)` → `StartupGate` (`:209-216`)

## B. Mục đích
Hiển thị brand trong lúc `_initServices` chạy tuần tự 5 bước (Supabase, DB, notifications, reminders, widget sync — `main.dart:77-117`), báo tiến độ; cho phép thử lại nếu init ném exception.

## C. Layout skeleton
```
┌─────────────────────────┐  bg: #FAF5FF (light) / #0F0A12 (dark)  :233
│  ○ orb tím 65%w (0.75,0.1)│  _MeshPainter: 2 orb radial + vignette :535-591
│                         │
│                         │
│        ◉ 96×96          │  logo tròn, glow hồng pulse          :415-446
│          (28)           │
│        Spendo           │  serif 44 w700 ls-1.5                :285-296
│          (8)            │
│  Your money, clearly.   │  15 w400 ls0.3 taglineColor          :306-316
│                         │
│                         │
│                         │
│    Connecting to cloud… │  12 ls0.4 statusColor  (AnimatedSwitcher) :332-376
│          (14)           │
│  ━━━━━━━━━━━━───────── │  progress 3px, gradient hồng→tím + shimmer 24px :378-382
│          (24)           │
│        v1.7.26          │  11 ls0.5 versionColor               :384-391
│  ○ orb hồng 55%w (0.1,0.88)                                     padding L32 R32 B52
└─────────────────────────┘
```

## D. Bảng component tree
| # | Element | Loại | Vị trí | Kích thước | Spacing | Style | Nội dung/binding | Tương tác | Source |
|---|---|---|---|---|---|---|---|---|---|
| 1 | `FadeTransition(_exitOpacity)` | wrapper | root | full | — | fade 1→0 easeInCubic 450ms khi thoát | — | — | `:244, 153-160` |
| 2 | `Scaffold` | container | root | full | — | `backgroundColor: bgColor` | isDark theo `_resolveBrightness` | — | `:246-247` |
| 3 | `_BackgroundMesh` | CustomPaint | Positioned.fill | full | — | orb `#7B1FA2` α .18/.35 tại (0.75w, 0.1h) r 0.65w; orb `#F06292` α .12/.18 tại (0.1w, 0.88h) r 0.55w; vignette radial α .25/.55 | static | — | `:250, 540-591` |
| 4 | `_LogoMark` | Container circle | center trên | 96×96 | — | RadialGradient `#F48FB1→#F06292` center(−0.3,−0.3); 2 BoxShadow hồng blur 24+20·g / 60, spread 2+4·g / 10; `ClipOval(Image.asset app_logo.jpg cover)` | `glowIntensity = _initDone ? 0 : _pulse` | — | `:271-274, 415-446` |
| 5 | Text "Spendo" | Text | dưới logo +28 | auto | 28 trên | `fontFamily 'serif'`, 44, w700, ls −1.5, h1, `appNameColor` (white / `#1A0A2E`) | hằng | — | `:279-296` |
| 6 | Text tagline | Text | +8 | auto | 8 trên | 15 w400 ls0.3 `#B89AB0`/`#7B5F8A` | "Your money, clearly." | — | `:306-316` |
| 7 | `AnimatedSwitcher` status | Text / Column | đáy, trên progress | auto | padding L32 R32 B52 | 12 ls0.4 `#8A7090`/`#9E7DB0`; fade+slide 0.3 300ms | `_statusMsg`; khi lỗi: msg center + `OutlinedButton('Thử lại')` cách 10 | Thử lại → `_startInit` | `:332-376` |
| 8 | `_ProgressBar` | Container 3px | +14 | full width × 3 | 14 trên | track `#E8D8F5`/`#2A1A2E` r2; fill gradient `#F06292→#CE93D8` + shadow α.6 blur 6; shimmer trắng 24px α .8/.5 chỉ khi 0<p<1; AnimatedContainer 380ms easeOutCubic | `_progress` 0…1 | — | `:378-382, 451-521` |
| 9 | Text version | Text | +24 | auto | 24 trên | 11 ls0.5 `#B09ABF`/`#5A4560` | `'v${packageInfo.version}'`, rỗng đến khi load | — | `:384-391, 77-84` |

## E. Vùng bố cục
- **Nền**: `Stack` → `Positioned.fill(_BackgroundMesh)` (vẽ toàn màn kể cả dưới status bar).
- **Body**: `SafeArea → Column[Expanded(Center(Column min: logo/name/tagline)), bottom block]` — khối brand căn giữa theo cả 2 trục phần còn lại; khối tiến độ cố định đáy với padding `fromLTRB(32,0,32,52)`.
- Không AppBar, không bottom nav. Status bar: `SystemChrome.setSystemUIOverlayStyle` trong suốt, icon sáng/tối theo `isDark` (`:60-67`).

## F. Trạng thái màn hình
| State | Điều kiện | UI |
|---|---|---|
| Entry | 0–1100ms sau mount | logo scale 0.6→1 elasticOut (0–65%), opacity 0→1 (0–40%), slide y0.15→0 (0–60%); tagline fade+slide 12→0 (45–85%); khối đáy fade (65–100%). Status text "Starting up…" | 
| Initializing | sau entry | `_progress` nhảy 0 → .05 → .35 → .65 → .80 → .90 → 1.0 với message tương ứng; logo glow pulse 1800ms lặp (0.6↔1.0) |
| Error | `onInit` throw | `_hasInitError=true`, status = "Không thể khởi động ứng dụng.", hiện `OutlinedButton 'Thử lại'`; progress giữ giá trị lúc lỗi; pulse vẫn chạy |
| Success | init xong | status "Ready!", progress 1.0, pulse dừng, glow 0; chờ 500ms rồi fade-out 450ms → pushReplacement |
| Loading / Empty / Offline | không áp dụng riêng; offline → Supabase.initialize có thể throw → state Error `[UNKNOWN: hành vi Supabase.initialize khi offline không đọc trong scope UI]` |

## G. Tương tác
| Trigger | Hành động | Kết quả UI | Điều hướng |
|---|---|---|---|
| Tap "Thử lại" (chỉ khi lỗi) | `_startInit()` | reset progress 0, msg "Starting up…", ẩn nút | — |
| Hết init | tự động | fade out | → StartupGate (replace) |
| Gesture khác | không có (không skip, không tap-to-continue) | — | — |

## H. Animation/transition
| Element | Loại | Thời lượng | Curve |
|---|---|---|---|
| Logo | scale 0.6→1 | Interval 0–0.65 của 1100ms | `elasticOut` |
| Logo | opacity | 0–0.4 của 1100ms | `easeOut` |
| Logo | slide Offset(0,0.15)→0 | 0–0.6 | `easeOutCubic` |
| Tagline | opacity + translate 12→0 | 0.45–0.85 | `easeOut` / `easeOutCubic` |
| Khối đáy | opacity | 0.65–1.0 | `easeOut` |
| Glow | 0.6↔1.0 repeat reverse | 1800ms | `easeInOut` |
| Progress fill | width | 380ms | `easeOutCubic` |
| Status text | AnimatedSwitcher fade + slide y0.3 | 300ms | mặc định |
| Exit | opacity 1→0 | 450ms | `easeInCubic` |
| Route | FadeTransition | 350ms | linear |
| `_progressCtrl` 400ms | **khai báo nhưng không dùng** | — | `:139-142` |

## I. Dữ liệu hiển thị
| Field | Nguồn | Format | Null/rỗng |
|---|---|---|---|
| Status message | callback `report(progress, message)` từ `main._initServices` | chuỗi thô (tiếng Anh) | mặc định "Starting up…" |
| Progress | cùng callback | 0..1 clamp | 0 |
| Version | `PackageInfo.fromPlatform().version` | `'v' + version` | `''` cho đến khi async xong |
| Logo | `assets/icons/app_logo.jpg` | BoxFit.cover trong ClipOval | asset bắt buộc tồn tại |

## J. Responsive & edge cases
- Toàn bộ khoảng cách cố định; trên màn thấp (<600px) khối brand + khối đáy không chồng vì `Expanded`.
- Không xử lý landscape đặc biệt (Column vẫn hoạt động).
- Text status tiếng Anh, lỗi tiếng Việt — trộn ngôn ngữ.
- Không có timeout tổng cho init (chỉ reminders 5s+5s `main.dart:101-106`) → nếu Supabase treo, splash treo vô hạn không có nút thoát.

## K. Text hiển thị
`Starting up…` · `Initializing…` · `Connecting to cloud…` · `Opening database…` · `Setting up notifications…` · `Scheduling reminders…` · `Syncing widgets…` · `All done!` · `Ready!` · `Không thể khởi động ứng dụng.` · `Thử lại` · `Spendo` · `Your money, clearly.` · `v<version>`

## L. Nhận xét nhanh
- Palette riêng (tím-hồng `#F06292`) không liên quan 5 scheme user chọn; user đổi màu chủ đạo vẫn thấy splash hồng.
- Message tiến độ tiếng Anh trong app hoàn toàn tiếng Việt.
- Không có timeout/skip khi init treo; nút "Thử lại" chỉ xuất hiện khi có exception.
- Delay cứng 100ms + 200ms + 500ms + 450ms + 350ms ≈ 1.6s ngoài thời gian init thực.
