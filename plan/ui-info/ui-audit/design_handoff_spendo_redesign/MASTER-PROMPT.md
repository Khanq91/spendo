# MASTER PROMPT — dán vào Claude Code để bắt đầu

```
Bạn sẽ redesign UI app Flutter "Spendo" (quản lý thu chi, offline-first, tiếng
Việt hard-code, Material 3 + Riverpod + go_router) theo một design direction đã
chốt. KHÔNG tự sáng tác style mới.

NGUỒN SỰ THẬT, đọc theo thứ tự:
1. design_handoff_spendo_redesign/README.md   — phạm vi + quyết định đã chốt
2. .../01-tokens.md                            — màu light+dark, chữ, hình khối
3. .../02-components.md                        — widget dùng chung phải dựng
4. .../03-screens.md                           — 26 màn: mockup ↔ audit ↔ thay đổi
5. .../04-phases.md                            — kế hoạch 8 phase + nghiệm thu
6. Bộ audit AS-IS (00-overview.md → 31-*.md)   — hiện trạng code, ref file:line
7. mockups/*.dc.html                           — thiết kế hi-fi: mở đọc source,
   mọi style nằm inline; đây là REFERENCE, không copy HTML vào app

QUY TẮC:
- Mọi màu/chữ/bo góc/spacing lấy từ 01-tokens.md qua ColorScheme +
  ThemeExtension; cấm hex rải trong widget.
- Icon chỉ dùng Lucide, stroke 2.25. Số tiền luôn tabular figures.
- Giữ nguyên logic nghiệp vụ, provider, database; đây là redesign UI.
- Giữ bộ motion lib/shared/widgets/motion/, chỉ đổi màu.
- Làm đúng 1 phase mỗi lượt, theo thứ tự 0→7; xong phase thì build, tự kiểm
  tra mục "Nghiệm thu" của phase đó, liệt kê file đã sửa, rồi dừng chờ duyệt.
- Gặp mâu thuẫn giữa audit và mockup: mockup (TO-BE) thắng; mâu thuẫn giữa
  mockup và tokens: tokens thắng. Điều gì không rõ → hỏi, kèm phương án đề xuất.

Bắt đầu: Phase 0.
```
