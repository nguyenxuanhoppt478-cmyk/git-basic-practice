# NHẬT KÝ SỬ DỤNG AI TRONG THIẾT KẾ HỆ THỐNG (AI PROMPT LOG)
**Học viên:** Nguyễn Xuân Hợp  
**Bài tập:** [Thực hành] Khủng Hoảng Tại Phòng Khám HealthSync  
**Vai trò AI:** Data Modeling Assistant & Database Mentor

---

### 💬 Phiên thảo luận 1: Anti-Pattern cờ Boolean cho vòng đời lịch hẹn
* **Prompt của học viên:**  
  > *"Trong thiết kế cơ sở dữ liệu quan hệ, tại sao việc dùng một cột `is_active` (kiểu TINYINT/BOOLEAN) để theo dõi vòng đời của một Đơn hàng/Lịch hẹn lại là một thiết kế tồi (Anti-pattern)? Tôi nên thay thế bằng cấu trúc nào trong MySQL?"*
* **Tóm tắt phản hồi của AI:**  
  - Cột Boolean chỉ biểu diễn được 2 trạng thái phân cực (Đúng/Sai hoặc 0/1). Trong khi đó, quy trình thực tế trải qua nhiều trạng thái trung gian (`PENDING`, `CONFIRMED`, `CHECKED_IN`, `COMPLETED`, `CANCELLED`).
  - Dùng Boolean sẽ dẫn đến hiện tượng "trôi trạng thái" (Status drift) hoặc buộc lập trình viên phải tạo thêm nhiều cờ rời rạc (`is_confirmed`, `is_cancelled`), gây rối loạn logic kiểm tra.
  - **Khuyến nghị:** Sử dụng kiểu dữ liệu `ENUM` trong MySQL hoặc tạo bảng danh mục `appointment_statuses` liên kết khóa ngoại. `ENUM` giúp kiểm tra hợp lệ dữ liệu ngay ở tầng database và tối ưu hóa bộ nhớ.

---

### 💬 Phiên thảo luận 2: Rủi ro sai số tài chính (Float Precision Error)
* **Prompt của học viên:**  
  > *"Khi thiết kế cột `deposit_amount` và `penalty_fee` trong MySQL phục vụ tính toán tài chính phòng khám, tôi nên dùng kiểu dữ liệu FLOAT, DOUBLE hay DECIMAL? Tại sao?"*
* **Tóm tắt phản hồi của AI:**  
  - `FLOAT` và `DOUBLE` sử dụng cách biểu diễn số thực dấu phẩy động theo chuẩn IEEE 754 (nhị phân xấp xỉ). Điều này gây ra sai số làm tròn tích lũy khi thực hiện các phép cộng trừ tiền tệ (ví dụ: `0.1 + 0.2 = 0.30000000000000004`).
  - Trong kế toán và tài chính, sai số dù chỉ 1 đồng cũng vi phạm tính toàn vẹn và không thể đối soát.
  - **Khuyến nghị:** Luôn sử dụng kiểu dữ liệu số cố định `DECIMAL(12, 2)`. Kiểu này lưu trữ dữ liệu dưới dạng chuỗi byte chính xác tuyệt đối từng con số sau dấu phẩy.

---

### 💬 Phiên thảo luận 3: Ràng buộc Khóa ngoại (ON DELETE CASCADE vs RESTRICT)
* **Prompt của học viên:**  
  > *"Đối với quan hệ giữa `Patients` - `Appointments` và giữa `Appointments` - `Prescriptions`, tôi nên đặt hành vi xóa khóa ngoại là `ON DELETE RESTRICT` hay `ON DELETE CASCADE`?"*
* **Tóm tắt phản hồi của AI:**  
  - Giữa `Patients` và `Appointments`: Phải dùng `ON DELETE RESTRICT` để ngăn chặn việc lỡ tay xóa một bệnh nhân khi họ đang có lịch sử khám bệnh. Dữ liệu y khoa là hồ sơ pháp lý không được phép xóa tùy tiện.
  - Giữa `Appointments` và `Prescriptions`: Nếu một bản ghi lịch hẹn bị xóa (ở môi trường hủy thử nghiệm), đơn thuốc đi kèm có thể đặt `ON DELETE CASCADE` vì đơn thuốc không thể tồn tại độc lập mà không gắn với một ca khám. Tuy nhiên trên môi trường thực tế sản xuất (Production), nên dùng kỹ thuật Soft Delete (xóa mềm).

---

### 💬 Phiên thảo luận 4: Chặn kê đơn thuốc khi chưa khám bằng Database Trigger
* **Prompt của học viên:**  
  > *"Làm thế nào để viết một Trigger trong MySQL kiểm tra trạng thái của lịch hẹn trước khi cho phép INSERT một đơn thuốc vào bảng Prescriptions?"*
* **Tóm tắt phản hồi của AI:**  
  - Sử dụng trigger `BEFORE INSERT ON Prescriptions`.
  - Dùng câu lệnh `SELECT status INTO v_status FROM Appointments WHERE appointment_id = NEW.appointment_id`.
  - Nếu `v_status != 'COMPLETED'`, kích hoạt `SIGNAL SQLSTATE '45000'` với thông báo lỗi rõ ràng để hủy ngay giao dịch.
