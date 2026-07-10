Bạn là một Senior Product Designer + Motion Designer + Frontend/UI Engineer. Hãy thiết kế hoặc refactor giao diện app của tôi theo phong cách “smooth premium finance UI”: tối giản, sạch, nhiều khoảng thở, motion tinh tế, chuyển động mềm, không giật layout.

Mục tiêu chính:

* UI phải có cảm giác cao cấp, hiện đại, mượt như các app tài chính/fintech.
* Không dùng quá nhiều màu hoặc hiệu ứng rối mắt.
* Motion phải phục vụ trải nghiệm người dùng, không chỉ để trang trí.
* Các thay đổi dữ liệu như số dư, giao dịch, trạng thái, thống kê phải chuyển động tự nhiên thay vì thay đổi đột ngột.

Áp dụng các kỹ thuật UI/motion sau:

1. Odometer / Rolling Number Animation
   Khi hiển thị số tiền, số dư, điểm, thống kê hoặc phần trăm, không đổi text ngay lập tức. Hãy animate từng chữ số theo kiểu odometer: digit lăn dọc lên/xuống.
   Yêu cầu:

* Mỗi digit có animation riêng.
* Các digit có thể chạy lệch nhau nhẹ bằng staggered delay.
* Chỉ digit thay đổi mới animate, digit không đổi giữ nguyên.
* Dùng vertical clipping/masking để chữ số lăn bên trong một vùng cố định.
* Giữ baseline và width ổn định để tránh layout shift.
* Easing gợi ý: easeOutCubic, easeInOutCubic hoặc spring nhẹ.

2. Smooth Value Transition
   Khi giá trị thay đổi, dùng animated transition thay vì set text trực tiếp.
   Yêu cầu:

* Amount chính có thể scale nhẹ 0.98 → 1.0 khi cập nhật.
* Opacity có thể fade nhẹ trong 120–200ms.
* Không làm toàn bộ màn hình nhảy lại.
* Số, ký hiệu tiền tệ, dấu phẩy và decimal nên được xử lý riêng để motion tự nhiên.

3. Animated List Reorder / Transaction Morphing
   Danh sách giao dịch, lịch sử, notification hoặc item card phải animate khi thêm/xóa/sắp xếp lại.
   Áp dụng kỹ thuật:

* FLIP animation: First, Last, Invert, Play.
* Shared-axis transition khi item di chuyển theo trục dọc.
* Slide + fade khi item xuất hiện hoặc biến mất.
* Reorder animation khi danh sách thay đổi vị trí.
* Giữ item key ổn định để framework hiểu item nào đang di chuyển.
* Không render lại toàn bộ list nếu chỉ một vài item thay đổi.

4. Micro-interactions
   Thêm micro-interaction cho các hành động nhỏ như nút “+”, filter, tab, card, icon, button.
   Gợi ý:

* Button press: scale 1.0 → 0.96 → 1.0.
* Icon transition: rotate nhẹ hoặc crossfade khi đổi trạng thái.
* Card tap: slight scale down + shadow soften.
* Selected tab: animated underline hoặc pill indicator trượt mượt.
* Duration gợi ý: 120–220ms.

5. Depth, Blur và Layering
   Tạo cảm giác chiều sâu bằng layering nhẹ, không lạm dụng.
   Có thể dùng:

* Subtle blur khi item đang chuyển động nhanh.
* Background blur cho floating panel/bottom sheet.
* Shadow mềm, spread thấp, opacity nhẹ.
* Scale hoặc opacity giảm nhẹ cho item ít quan trọng.
* Parallax rất nhẹ giữa foreground và background nếu có scroll.

6. Easing và Timing
   Không dùng linear animation cho UI chính.
   Quy tắc:

* Motion ngắn: 120–180ms cho tap/click feedback.
* Motion trung bình: 220–350ms cho card/list/value transition.
* Motion lớn: 400–600ms cho screen transition hoặc layout morphing.
* Easing nên dùng: easeOutCubic, easeInOutCubic, fastOutSlowIn.
* Với animation dạng vật lý, dùng spring nhẹ, damping cao, không bounce quá nhiều.
* Dùng stagger 20–60ms giữa các digit/item để motion có nhịp.

7. Layout Stability
   Ưu tiên giữ layout ổn định.
   Yêu cầu:

* Tránh layout shift khi số tiền thay đổi độ dài.
* Dùng fixed width hoặc tabular numbers cho digit.
* Card/list item cần giữ chiều cao nhất quán.
* Khi loading dữ liệu, dùng skeleton hoặc shimmer nhẹ thay vì nhảy nội dung.
* Khi empty/error state xuất hiện, dùng fade + slide nhẹ.

8. Visual Style
   Phong cách thiết kế:

* Minimal, clean, premium.
* Background sáng hoặc tối đều được, nhưng phải có contrast rõ.
* Typography lớn, rõ, dùng font weight hợp lý.
* Card bo góc mềm, spacing rộng.
* Ít màu, ưu tiên grayscale + 1 accent color.
* Không dùng gradient quá gắt.
* Không dùng shadow nặng hoặc animation quá lố.

9. Performance Requirements
   Motion phải mượt 60fps.
   Yêu cầu kỹ thuật:

* Chỉ animate transform, opacity, clip hoặc position khi cần.
* Tránh animate layout quá nặng.
* Tách component nhỏ để tránh rebuild toàn màn hình.
* Dùng memoization/caching nếu cần.
* Với list dài, dùng lazy rendering.
* Với blur, chỉ dùng ở vùng nhỏ vì blur rất tốn GPU.
* Kiểm tra jank, dropped frames và memory usage.

10. Output mong muốn từ bạn
    Hãy trả về:

* Đề xuất UI layout mới hoặc cách refactor UI hiện có.
* Danh sách component cần tạo.
* Motion specification cho từng component.
* Duration, easing, delay/stagger cụ thể.
* Pseudo-code hoặc code mẫu nếu phù hợp.
* Lưu ý performance.
* Những phần nào nên animate và phần nào không nên animate.
* Nếu UI hiện tại có vấn đề, hãy chỉ ra vấn đề và cách sửa.

Context app của tôi:

* Loại app: [mô tả app của bạn]
* Màn hình cần thiết kế/refactor: [mô tả màn hình]
* Dữ liệu chính cần hiển thị: [số dư / giao dịch / thống kê / danh sách / notification / v.v.]
* Style mong muốn: premium, smooth, minimal, modern.
* Framework đang dùng: [Flutter / React / Vue / Native / khác]
* UI hiện tại nếu có: [dán code, ảnh, mô tả hoặc file liên quan]

Nếu áp dụng trong Flutter, hãy triển khai motion theo hướng component hóa, tối ưu rebuild và giữ 60fps.

Các kỹ thuật Flutter nên dùng:

1. Rolling Number / Odometer Effect
   Tạo widget riêng, ví dụ:

* AnimatedMoneyText
* RollingDigit
* OdometerNumber
* AnimatedBalance

Cách triển khai:

* Tách số tiền thành từng ký tự: currency symbol, digit, separator, decimal.
* Với từng digit, dùng ClipRect để giới hạn vùng hiển thị.
* Dùng AnimatedSwitcher, SlideTransition hoặc AnimatedBuilder để digit trượt dọc.
* Mỗi digit có AnimationController hoặc TweenAnimationBuilder riêng.
* Dùng stagger delay nhẹ giữa các digit bằng Interval hoặc Future delay có kiểm soát.
* Giữ width cố định cho từng digit để tránh text bị giật.
* Có thể dùng FontFeature.tabularFigures() nếu font hỗ trợ để các số có cùng chiều rộng.

Widget/API gợi ý:

* AnimatedSwitcher
* TweenAnimationBuilder
* AnimationController
* AnimatedBuilder
* SlideTransition
* FadeTransition
* ScaleTransition
* ClipRect
* Transform.translate
* TextStyle(fontFeatures: [FontFeature.tabularFigures()])

2. Animated Transaction List
   Với danh sách giao dịch hoặc item động:

* Dùng AnimatedList nếu thêm/xóa item.
* Dùng SliverAnimatedList nếu màn hình dùng CustomScrollView.
* Dùng key ổn định cho từng item, ví dụ ValueKey(transaction.id).
* Khi reorder hoặc data thay đổi vị trí, dùng FLIP-like animation hoặc package hỗ trợ animated reorder.
* Có thể dùng implicitly_animated_reorderable_list nếu cần reorder mượt.

Animation cho item:

* Item xuất hiện: fade in + slide up 12–24px.
* Item biến mất: fade out + slide down nhẹ.
* Item đổi vị trí: animate position thay vì rebuild nhảy.
* Card tap: scale 0.98 trong 100–150ms rồi về 1.0.

3. Micro-interactions
   Dùng:

* AnimatedScale cho press feedback.
* AnimatedOpacity cho trạng thái mờ/rõ.
* AnimatedContainer cho background, border radius, padding, color.
* AnimatedPositioned nếu item nằm trong Stack.
* Hero cho shared element transition giữa màn hình list và detail.
* animations package nếu cần SharedAxisTransition, FadeThroughTransition hoặc OpenContainer.

4. Blur, Depth, Layering
   Dùng cẩn thận:

* BackdropFilter cho glassmorphism/bottom sheet blur.
* ImageFiltered cho blur một layer cụ thể.
* PhysicalModel hoặc BoxShadow nhẹ cho card.
* RepaintBoundary bọc vùng blur hoặc animation phức tạp.
* Không blur toàn màn hình nếu không cần.

5. Easing và Duration trong Flutter
   Nên dùng:

* Curves.easeOutCubic cho số tiền/list item.
* Curves.easeInOutCubic cho layout morphing.
* Curves.fastOutSlowIn cho Material-like transition.
* SpringSimulation hoặc package flutter_animate nếu muốn motion dạng spring.

Duration gợi ý:

* Button press: 100–150ms.
* Digit rolling: 280–450ms.
* List item enter/exit: 220–320ms.
* Screen transition: 350–500ms.
* Stagger giữa digit/item: 20–60ms.

6. Performance Rules
   Bắt buộc:

* Không gọi setState cho cả màn hình khi chỉ số tiền thay đổi.
* Tách widget số tiền, list item, header, action button thành widget riêng.
* Dùng const constructor nhiều nhất có thể.
* Dùng Selector hoặc Consumer nhỏ nếu dùng Provider.
* Với Riverpod/Bloc, chỉ listen đúng state cần thiết.
* Dùng ListView.builder hoặc SliverList cho list dài.
* Dùng RepaintBoundary cho component animate nặng.
* Tránh BackdropFilter lớn vì dễ gây jank.
* Không animate height phức tạp trong list dài nếu không cần.
* Luôn dùng key ổn định cho animated list item.

7. Package có thể cân nhắc

* flutter_animate: viết animation nhanh, dễ chain effect.
* animations: có SharedAxisTransition, FadeThroughTransition, OpenContainer.
* implicitly_animated_reorderable_list: list reorder mượt.
* animated_flip_counter: nếu cần animated number nhanh, nhưng nên custom nếu muốn odometer premium hơn.
* auto_size_text: nếu số tiền có thể dài, nhưng cần kiểm soát layout kỹ.

Hãy viết code Flutter theo hướng clean architecture ở UI layer:

* Widget nhỏ, dễ tái sử dụng.
* Animation spec rõ ràng.
* Không trộn business logic vào animation widget.
* Có fallback khi user bật reduce motion/accessibility.
* Có comment giải thích motion: duration, curve, purpose.
