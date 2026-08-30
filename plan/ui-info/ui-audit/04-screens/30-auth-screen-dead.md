# 30 — AuthScreen [DEAD CODE]

## A. Metadata
- **Tên**: `AuthScreen`
- **Route**: **không có**. `grep -rn "AuthScreen\|auth_screen" lib` chỉ trả về file định nghĩa → không thể vào từ UI.
- **File**: `lib/features/auth/presentation/screens/auth_screen.dart` (237 LOC)
- **Vào từ**: — · **Thoát đi**: `Navigator.pop` khi `AuthChangeEvent.signedIn` hoặc "Dùng không cần tài khoản"

## B. Mục đích (theo code)
Đăng nhập/đăng ký Supabase email+password; cho phép bỏ qua.

## C. Layout skeleton
```
┌───────────────────────────────┐ bg grey.shade50, SafeArea, pad 24, Column start
│                               │ Spacer
│ 💸 48                         │
│ Spendo 32 w700 ls−1           │
│ Quản lý thu chi cá nhân 14 grey500│
│                               │ Spacer
│ [Đăng nhập][Đăng ký]          │ _TabBtn pad H16 V8 r8 bg #6C63FF khi active; 14 w600
│ ┌ Email ┐                     │ TextField outline r10 pad H14 V12
│ ┌ Mật khẩu ┐                  │ obscure; onSubmitted → submit
│ lỗi 13 #E53935                │ nếu _error
│ [      Đăng nhập      ]       │ FilledButton bg #6C63FF pad V14 r10; spinner 18
│                               │ Spacer
│     Dùng không cần tài khoản  │ TextButton 13 grey500 → pop
└───────────────────────────────┘
```

## D–J
Không áp dụng cho redesign (màn không tiếp cận được). Điểm ghi nhận: `initState` đăng ký `onAuthStateChange.listen` không huỷ (`:21-25`); màu cứng `#6C63FF`, `grey.shade50/500`; không có back.

## K. Text hiển thị
`💸` · `Spendo` · `Quản lý thu chi cá nhân` · `Đăng nhập` · `Đăng ký` · `Email` · `Mật khẩu` · `Đã có lỗi xảy ra. Thử lại.` · `Dùng không cần tài khoản`

## L. Nhận xét nhanh
- Dead code cùng với `auth_provider.dart`; app hiện chạy Supabase anon + PowerSync mà không có UI đăng nhập → đồng bộ đa thiết bị không có lối vào trên UI `[UNKNOWN: trạng thái sync thực tế ngoài scope UI]`.
