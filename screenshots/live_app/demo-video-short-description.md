## Kết luận tổng quan

Video dài khoảng **2 phút 46 giây**, bao phủ gần như toàn bộ luồng chính của ứng dụng Spendo: trang chủ, thêm giao dịch, danh sách giao dịch, tìm kiếm, cài đặt, giao diện, nhắc nhở, danh mục, hạn mức và thống kê.

**Ấn tượng chung:** ứng dụng có định hướng hình ảnh rõ, nhiều phản hồi tức thời và không xuất hiện tình trạng đứng hình hay chờ dữ liệu kéo dài. Tuy nhiên, chế độ giao diện kính mờ đang ưu tiên “đẹp và nhiều hiệu ứng” hơn khả năng đọc, phân cấp thông tin và độ tin cậy của dữ liệu tài chính.

Điểm cần xử lý mạnh nhất là:

1. Số dư chạy qua các giá trị tiền không có thật sau khi thêm giao dịch.
2. Chữ và dữ liệu bị chìm trên nền kính mờ nhiều màu.
3. Nút `+` che nội dung giao dịch.
4. Trạng thái rỗng không giải thích các bộ lọc đang áp dụng.
5. Animation chuyển màn hình và chuyển theme chưa đồng nhất.

---

# 1. Timeline toàn bộ video

| Thời gian           | Luồng thao tác                                    | Nhận xét chính                                                                                                                                                    |
| ------------------- | ------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **00:00–00:02.4**   | Splash screen                                     | Nhận diện thương hiệu tốt, nhưng thanh tiến trình đã ở trạng thái `Ready` một khoảng ngắn trước khi vào app, tạo cảm giác đang chờ thêm dù đã hoàn tất.           |
| **00:02.4–00:12.3** | Trang chủ, hiện/ẩn số dư                          | Trang chủ giàu thông tin, phản hồi nhanh. Tuy nhiên nền glass nhiều màu làm chữ, divider và số tiền thiếu ổn định về độ tương phản.                               |
| **00:12.3–00:27.6** | Mở form thêm chi tiêu, nhập số tiền và ghi chú    | Bottom sheet vào khá mượt. Numeric keypad tùy biến rõ ràng, CTA thay đổi theo dữ liệu. Việc chuyển giữa keypad số tùy biến và bàn phím hệ thống gây layout shift. |
| **00:27.6–00:34.5** | Lưu giao dịch, quay về trang chủ                  | Danh sách và số dư cập nhật ngay. Tuy nhiên số dư chạy qua hàng loạt giá trị trung gian không có ý nghĩa.                                                         |
| **00:34.5–00:55.8** | Danh sách giao dịch, lọc danh mục, đổi tháng      | Lọc phản hồi nhanh. Khi bộ lọc dẫn đến không có dữ liệu, empty state quá chung chung và không có nút xóa bộ lọc.                                                  |
| **00:55.8–01:05.8** | Tìm kiếm giao dịch                                | Search mở nhanh, focus và keyboard xuất hiện đúng. Header biến đổi hơi đột ngột; vẫn giữ filter cũ nhưng không thể hiện rõ phạm vi tìm kiếm.                      |
| **01:05.8–01:14**   | Mở Cài đặt và cuộn các nhóm chức năng             | Có nhiều tính năng nhưng cấu trúc trang dài, các section dễ hòa lẫn vào nhau vì nền trang và header section cùng dùng hiệu ứng kính.                              |
| **01:14–01:22**     | Liên kết ngân hàng                                | Sheet và form có cấu trúc hợp lý. Danh sách ngân hàng dài và dày chữ; cần search hoặc ưu tiên ngân hàng phổ biến.                                                 |
| **01:24–01:33**     | Chuyển sáng/tối, chế độ đồ họa và màu chủ đạo     | Cập nhật tức thời. Theme switch có giai đoạn toàn màn hình bị xám/trắng, tạo cảm giác flash.                                                                      |
| **01:33–01:42**     | Cấu hình thông báo                                | Toggle mở rộng thêm tùy chọn là pattern tốt. Nội dung mới xuất hiện khá rõ nhưng animation chiều cao chưa thật liền mạch.                                         |
| **01:42–01:57**     | Danh sách và form nhắc nhở định kỳ                | Empty state rõ. Có hai affordance thêm mới cùng lúc: dấu `+` trên app bar và nút `Thêm nhắc nhở`. Form giữ CTA phía trên keyboard tốt.                            |
| **01:57–02:12**     | Widget màn hình chính, mở danh mục, thêm danh mục | Inline expansion tiện lợi. Bộ chọn màu và icon quá dày, icon không có nhãn nên phụ thuộc nhiều vào khả năng đoán của người dùng.                                  |
| **02:12–02:18**     | Thiết lập hạn mức                                 | Chia thành bước chọn loại hạn mức rồi nhập số giúp tránh form quá dài. Phản hồi nhanh nhưng chuyển bước hơi đột ngột.                                             |
| **02:18–02:24**     | Màn hình Tất cả tính năng                         | Nhóm chức năng rõ hơn trang chủ, nhưng số lượng màu và icon lớn làm giảm điểm tập trung thị giác.                                                                 |
| **02:24–02:45**     | Thống kê, chuyển tab và chọn khoảng thời gian     | Biểu đồ mở gần như ngay lập tức. Tab Theo ngày có quá nhiều khoảng trống khi dữ liệu ít; khả năng đọc xu hướng chưa tốt.                                          |
| **02:45–02:46**     | Quay lại trang chủ                                | Phản hồi nhanh, không thấy loading hoặc màn hình trắng.                                                                                                           |

---

# 2. Các vấn đề theo P0–P3

## P0 — Blocker hoặc nguy cơ dữ liệu nghiêm trọng

**Không quan sát thấy P0 từ video.**

Không có bằng chứng về crash, mất dữ liệu, lưu trùng giao dịch, sai kết quả cuối cùng hoặc không thể hoàn thành tác vụ.

Video không đủ để xác minh tính toàn vẹn dữ liệu ở tầng lưu trữ.

---

## P1 — Ảnh hưởng trực tiếp đến tác vụ chính, độ tin cậy hoặc accessibility

### P1.1 — Animation số dư hiển thị các số tiền không có thật

**Mốc:** khoảng `00:27.45–00:27.80`.

Sau khi thêm khoản chi `1.000.000 đ`, số dư từ `91.079.990 đ` được chạy qua các giá trị:

* `90.510.438 đ`
* `90.341.147 đ`
* `90.248.385 đ`
* `90.150.459 đ`
* `90.111.459 đ`
* `90.080.241 đ`
* rồi mới đến `90.079.990 đ`

Đây có vẻ là animation nội suy số, không phải bằng chứng tính toán sai. Tuy nhiên trong ứng dụng tài chính, mỗi con số tiền hiển thị đều có ý nghĩa. Người dùng có thể tưởng ứng dụng đang tính toán hoặc đồng bộ nhiều lần.

**Đề xuất:**

* Cập nhật số dư cuối cùng ngay lập tức.
* Animate opacity, scale, highlight hoặc background của card.
* Có thể hiển thị riêng delta `−1.000.000 đ` bay lên hoặc fade out.
* Không tween trực tiếp giá trị tiền qua các số trung gian.

---

### P1.2 — Độ tương phản không ổn định trong chế độ glass

Xuất hiện xuyên suốt, rõ nhất tại:

* Danh sách giao dịch.
* Empty state.
* Các section trong Cài đặt.
* Inactive item ở bottom navigation.
* Text phụ trên balance card.
* Các divider và metadata nhỏ.

Nền blur nhiều vùng sáng/tối khác nhau khiến cùng một màu chữ lúc dễ đọc, lúc bị chìm. Đây là vấn đề quan sát trực tiếp về khả năng đọc; chưa thể kết luận blur gây vấn đề hiệu năng kỹ thuật.

**Đề xuất:**

* Thêm scrim tối hoặc sáng ổn định phía sau khu vực chứa chữ.
* Card chứa dữ liệu tài chính nên có màu surface gần đặc, không phụ thuộc hoàn toàn vào wallpaper.
* Tăng contrast cho secondary text, divider và inactive navigation.
* Chế độ `Bình thường` nên là mặc định; `Xịn xò` là tùy chọn trang trí.
* Kiểm tra contrast theo từng trạng thái theme, không chỉ theo mã màu cố định.

---

### P1.3 — Floating action button che dữ liệu giao dịch

Nút `+` nằm đè lên vùng danh sách ở cạnh phải, có thời điểm che hoặc nằm sát phần số tiền của giao dịch cuối màn hình.

Đây là nội dung cốt lõi của ứng dụng, không nên bị control nổi che khuất.

**Đề xuất:**

* Thêm bottom padding cho danh sách bằng chiều cao FAB cộng safe area.
* Hoặc đặt hành động thêm vào bottom bar.
* Ẩn hoặc thu nhỏ FAB khi keyboard mở, khi đang search hoặc khi người dùng cuộn xuống.
* Không để row cuối cùng dừng dưới vùng tương tác của FAB.

---

### P1.4 — Empty state không giải thích bộ lọc đang áp dụng

**Mốc:** khoảng `00:42–00:52`.

Người dùng vẫn đang chọn danh mục như `Di chuyển` và thay đổi tháng, nhưng màn hình chỉ hiển thị:

> Không tìm thấy giao dịch nào

Không rõ là:

* Tháng đó thực sự chưa có giao dịch.
* Không có giao dịch thuộc danh mục đang chọn.
* Search hoặc filter khác còn đang hoạt động.

**Đề xuất:**

Hiển thị ngữ cảnh trực tiếp:

> Không có giao dịch “Di chuyển” trong tháng 6/2026.

Kèm hai hành động:

* `Xóa bộ lọc`
* `Thêm giao dịch`

Active filter cũng nên được thể hiện rõ hơn ở vùng summary.

---

## P2 — Ma sát đáng kể nhưng không chặn tác vụ

### P2.1 — Splash báo `Ready` nhưng chưa chuyển màn hình ngay

Khoảng cuối splash, progress bar đã đầy và hiện `Ready` trước khi trang chủ xuất hiện. Điều này làm tăng perceived waiting time.

**Nên làm:** khi đã `Ready`, chuyển màn hình ngay; hoặc bỏ chữ `Ready` và để progress phản ánh đúng quá trình.

---

### P2.2 — Form giao dịch dùng hai hệ nhập liệu khác nhau

Số tiền dùng keypad tùy biến, còn ghi chú dùng bàn phím hệ thống. Khi chuyển focus, toàn bộ bố cục thay đổi khá mạnh.

Điểm tốt là CTA vẫn giữ được khả năng tiếp cận. Vấn đề chính là mất tính liên tục.

**Nên làm:**

* Tách ghi chú thành vùng nhập mở rộng có animation rõ.
* Giữ header số tiền cố định.
* Tránh để sheet đổi chiều cao đột ngột.
* Có nút `Xong` hoặc `Tiếp tục` rõ khi thoát chế độ nhập text.

---

### P2.3 — Chuyển màn hình thiếu spatial continuity

Bottom navigation có active indicator tương đối nổi bật, nhưng phần nội dung thường đổi gần như ngay lập tức:

* Trang chủ → Giao dịch.
* Trang chủ → Cài đặt.
* Trang chủ → Thống kê.
* Các tab trong Thống kê.

Indicator có chuyển động nhưng destination content không đi cùng chuyển động đó, tạo cảm giác hai layer không liên quan.

**Nên làm:**

* Các destination ngang hàng dùng shared-axis hoặc fade-through khoảng 180–250 ms.
* Không cần slide toàn màn hình mạnh.
* Tab `Danh mục` ↔ `Theo ngày` có thể dùng crossfade kết hợp dịch ngang nhẹ.
* Back từ màn hình con nên có hướng chuyển động ngược lại.

---

### P2.4 — Chuyển sáng/tối tạo flash toàn màn hình

**Mốc:** khoảng `01:25–01:27`.

Có các frame trung gian bị xám hoặc sáng toàn màn hình. Đây không giống loading kéo dài, nhưng tạo cảm giác chớp và có thể khó chịu khi đổi theme ban đêm.

**Nên làm:**

* Không fade toàn bộ màn hình qua lớp màu xám sáng.
* Crossfade trực tiếp giữa hai bộ màu trong 150–250 ms.
* Giữ status bar, navigation bar và app content đồng bộ cùng một thời điểm.
* Tôn trọng thiết lập reduce motion của hệ thống.

---

### P2.5 — Trang Cài đặt quá dài và hierarchy yếu

Cùng một trang chứa:

* Xuất và khôi phục.
* Ngân hàng.
* Google Drive.
* Giao diện.
* Thông báo.
* Nhắc nhở.
* Widget.
* Danh mục.

Section header dùng nền trang trí khá giống các card khác, khiến người dùng phải đọc nhiều mới biết mình đang ở đâu.

**Nên làm:**

Chia thành nhóm hoặc màn hình con:

* Dữ liệu và đồng bộ.
* Tài khoản và ngân hàng.
* Giao diện.
* Thông báo và nhắc nhở.
* Danh mục và widget.

Các hành động ít dùng không nên cạnh tranh thị giác với theme và notification.

---

### P2.6 — Quá nhiều màu cạnh tranh trên trang chủ và Tất cả tính năng

Mỗi shortcut có một màu neon riêng, trong khi:

* Accent color cũng có màu riêng.
* Thu nhập xanh, chi tiêu đỏ.
* Balance card là gradient.
* Background tiếp tục có nhiều màu.

Hậu quả là màu không còn cho biết rõ đâu là primary action, đâu là category và đâu là trạng thái.

**Nên làm:**

* Primary accent chỉ dùng cho trạng thái chọn và CTA.
* Màu category sử dụng trong icon nhỏ hoặc dữ liệu liên quan.
* Shortcut mặc định dùng surface trung tính, chỉ icon có tint nhẹ.
* Red/green dành cho semantics thu–chi, không dùng làm decoration tùy ý.

---

### P2.7 — Bộ lọc dạng chip thiếu dấu hiệu có thể cuộn ngang

Các danh mục nằm trên một hàng, một số item sát hoặc vượt mép màn hình. Không có gradient edge hay item lộ một phần đủ rõ để người dùng hiểu còn nội dung phía sau.

**Nên làm:**

* Cho item tiếp theo lộ ra có chủ ý.
* Thêm edge fade.
* Giữ chip đang chọn tự động scroll vào giữa.
* Có nút `Tất cả bộ lọc` khi số danh mục tăng.

---

### P2.8 — Bộ chọn icon và màu danh mục quá dày

Danh sách chấm màu và icon được đặt sát nhau, không có tên hoặc preview danh mục hoàn chỉnh.

Người dùng khó phân biệt những icon gần giống nhau và khó biết màu sẽ xuất hiện như thế nào trên trang chủ.

**Nên làm:**

* Tăng khoảng cách và touch target.
* Chia icon thành nhóm.
* Hiển thị preview: icon + màu + tên danh mục.
* Có search hoặc danh sách icon phổ biến trước.
* Selected state cần rõ hơn ngoài đường viền mảnh.

---

### P2.9 — Biểu đồ Theo ngày sử dụng không gian chưa hiệu quả

Khi chỉ có một ngày có dữ liệu, màn hình gần như trống với một cột rất nhỏ. Người dùng khó đọc giá trị và không thấy insight.

**Nên làm:**

* Hiển thị tooltip/value label trực tiếp.
* Với dữ liệu thưa, dùng danh sách ngày có giao dịch hoặc bar chart co giãn theo số điểm.
* Có empty/sparse-data explanation.
* Không bắt buộc giữ trục đủ cả tháng khi chỉ có một vài ngày dữ liệu.

---

## P3 — Tinh chỉnh và hoàn thiện

### P3.1 — Hai nút thêm nhắc nhở trên cùng empty state

Màn hình có cả dấu `+` trên app bar và nút `Thêm nhắc nhở` ở giữa. Không gây lỗi nhưng tạo dư thừa.

Giữ nút ở empty state; dấu `+` chỉ cần xuất hiện khi danh sách đã có dữ liệu.

---

### P3.2 — Bottom sheet thiếu affordance đóng rõ

Phần lớn sheet có drag handle nhưng không có `X` hoặc `Hủy`. Người dùng quen gesture vẫn hiểu, nhưng discoverability chưa tối ưu.

Với sheet chứa form hoặc có nhiều bước, nên có `Đóng/Hủy` rõ.

---

### P3.3 — Expand/collapse danh mục làm nội dung dịch chuyển hơi gấp

Việc mở danh sách danh mục inline là đúng pattern, nhưng chiều cao thay đổi khá nhanh và che khuất vị trí trước đó.

Nên animate size 180–250 ms, xoay chevron và giữ header section trong viewport.

---

### P3.4 — Iconography chưa hoàn toàn đồng nhất

Một số icon dạng outline mảnh, một số có nét dày hoặc chi tiết nhiều hơn. Khi đặt trong cùng grid, cảm giác kích thước thị giác khác nhau dù bounding box có thể bằng nhau.

Nên chuẩn hóa stroke, optical size và icon container.

---

### P3.5 — Microcopy có thể rõ ngữ cảnh hơn

Ví dụ:

* `Đồ họa`: nên thể hiện rõ đây là mức hiệu ứng hình ảnh.
* `Bình thường` và `Xịn xò`: phù hợp app cá nhân, nhưng chưa mô tả khác biệt.
* `Gửi thông báo thử`: có thể ghi thêm kết quả mong đợi.
* `Theo hệ thống`: nên hiển thị theme đang được hệ thống chọn hiện tại.

---

# 3. Đánh giá animation

## Điểm tốt

* Bottom sheet có scrim, hướng chuyển động và tầng thị giác rõ.
* CTA disabled/active phản hồi theo số tiền nhập.
* Tap feedback trên keypad và control khá rõ.
* Accent color được áp dụng gần như tức thì.
* Toggle notification mở thêm nội dung đúng theo progressive disclosure.
* Lưu giao dịch xong, danh sách và balance card cập nhật ngay, không xuất hiện màn hình loading trung gian.
* Mở thống kê không có khoảng trắng chờ biểu đồ.

## Điểm chưa tốt

* Tween số tiền gây sai nghĩa dữ liệu.
* Chuyển destination chủ yếu là thay nội dung đột ngột.
* Global theme transition tạo flash.
* Một số expand/collapse thiên về layout jump hơn motion có chủ ý.
* Animation đang tập trung nhiều vào decoration, nhưng ít hỗ trợ giải thích quan hệ giữa màn hình nguồn và màn hình đích.

## Hướng motion nên thống nhất

* **Tap feedback:** 80–120 ms.
* **Chip/toggle/selection:** 120–180 ms.
* **Expand/collapse:** 180–250 ms.
* **Bottom sheet:** 250–350 ms.
* **Destination transition:** 180–250 ms.
* **Không animate số tiền bằng nội suy giá trị.**
* Dùng cùng một easing cho các surface chính, tránh mỗi component có cảm giác chuyển động khác nhau.

---

# 4. Perceived performance

## Những gì quan sát được

* Không có đoạn đứng hình nhiều giây.
* Mở màn hình Giao dịch, Cài đặt và Thống kê đều cho kết quả gần như ngay lập tức.
* Filter và đổi accent phản hồi trong vài frame của bản ghi.
* Bottom sheet thường ổn định trong khoảng vài trăm mili giây.
* Keyboard xuất hiện bình thường, CTA không bị đẩy mất khỏi màn hình.
* Chart không có loading placeholder nhưng dữ liệu cũng không xuất hiện trễ trong video.

## Những điểm tạo cảm giác chậm dù chưa chắc chậm kỹ thuật

* Splash đã báo `Ready` nhưng chưa đóng.
* Theme switch đi qua nhiều trạng thái màu trung gian.
* Animation số dư kéo dài thời điểm người dùng nhìn thấy kết quả cuối cùng.
* Glass background làm màn hình “mềm” và thiếu điểm neo, đôi khi bị cảm nhận là thiếu sắc nét hoặc phản hồi không dứt khoát.
* Layout shift khi đổi loại bàn phím.

## Những điều không thể kết luận từ video

Bản ghi có tốc độ khoảng **24 fps**, nên không đủ để khẳng định:

* App có giữ được 60/90/120 fps hay không.
* Có jank trên UI thread hoặc raster thread.
* Blur có gây GPU overload.
* Có shader compilation.
* Có rebuild quá rộng.
* Search hoặc thống kê đang đọc local database hay gọi API.
* Thời gian CPU, memory, overdraw hoặc battery usage.

Muốn xác minh kỹ thuật trong Flutter cần chạy **profile mode** và xem Flutter DevTools Performance, frame chart, raster/UI time và frame vượt ngân sách `16,7 ms` hoặc `8,3 ms`.

---

# 5. Thứ tự xử lý đề xuất

### Vòng 1 — Core trust và readability

1. Bỏ tween giá trị tiền.
2. Tăng contrast cho glass surfaces.
3. Không để FAB che danh sách.
4. Làm empty state nhận biết filter và có `Xóa bộ lọc`.

### Vòng 2 — Luồng thao tác

1. Thống nhất transition giữa bottom navigation destinations.
2. Giảm layout shift của form giao dịch.
3. Chia lại Information Architecture của Cài đặt.
4. Cải thiện filter chip và form danh mục.

### Vòng 3 — Motion và polish

1. Sửa theme transition.
2. Chuẩn hóa animation duration/easing.
3. Cải thiện màn hình thống kê khi dữ liệu thưa.
4. Chuẩn hóa icon, spacing và microcopy.

**Đánh giá tổng thể từ video:** UI có bản sắc và độ hoàn thiện thị giác khá cao, perceived performance nhìn chung tốt. Điểm yếu không nằm ở “app có vẻ chậm”, mà nằm ở việc hiệu ứng trang trí đôi khi làm giảm độ rõ ràng, độ tin cậy và khả năng đọc của một ứng dụng quản lý tiền.
