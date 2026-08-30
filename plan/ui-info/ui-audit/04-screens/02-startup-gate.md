# 02 — StartupGate

## A. Metadata
- **Tên**: `StartupGate`
- **Route**: không có (đích của `SplashScreen.nextScreen`, `lib/main.dart:71`)
- **File**: `lib/features/onboarding/presentation/startup_gate.dart` (39 LOC)
- **Vào từ**: Splash (pushReplacement)
- **Thoát đi**: render trực tiếp `SpendoApp` hoặc `WelcomeScreen` làm child (không push)

## B. Mục đích
Đọc cờ `onboarding_completed_v1` từ SharedPreferences để rẽ nhánh onboarding / app chính.

## C. Layout skeleton
```
┌─────────────────────────┐
│                         │
│                         │
│           ◌             │  CircularProgressIndicator mặc định, center
│                         │
│                         │
└─────────────────────────┘
```

## D. Bảng component tree
| # | Element | Loại | Vị trí | Kích thước | Spacing | Style | Nội dung/binding | Tương tác | Source |
|---|---|---|---|---|---|---|---|---|---|
| 1 | `FutureBuilder<bool>` | logic | root | — | — | — | `_completedFuture` | — | `:26-28` |
| 2 | `Scaffold(body: Center(CircularProgressIndicator()))` | loading | root | full | — | theme MaterialApp#1 (seed `#F06292`) | khi `!snapshot.hasData` | — | `:29-33` |
| 3 | `SpendoApp` / `WelcomeScreen` | child | root | full | — | — | `snapshot.data!` | — | `:35` |

## E. Vùng bố cục
Toàn màn là 1 trong 3 widget trên; không header/footer.

## F. Trạng thái màn hình
| State | UI |
|---|---|
| Loading (đọc prefs, thường <1 frame) | Scaffold trắng + spinner hồng ở giữa — **nhấp nháy** sau khi splash vừa fade |
| `true` | `SpendoApp` |
| `false` / null | `WelcomeScreen` |
| Error | **không xử lý** — `snapshot.hasError` sẽ rơi vào `!hasData` → spinner vĩnh viễn |

## G. Tương tác
Không có.

## H. Animation/transition
Không có (thay child tức thì, không AnimatedSwitcher).

## I. Dữ liệu hiển thị
`prefs.getBool('onboarding_completed_v1') ?? false` (`:20-21`).

## J. Responsive & edge cases
- Khung trung gian dùng theme của MaterialApp#1 → nền trắng ngay cả khi user chọn dark → chớp trắng giữa splash tối và app tối.

## K. Text hiển thị
Không có text.

## L. Nhận xét nhanh
- Một frame trung gian không cần thiết (spinner trắng) giữa 2 màn có nền riêng.
- Không có nhánh lỗi.
