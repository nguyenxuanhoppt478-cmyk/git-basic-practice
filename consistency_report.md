# BÁO CÁO PHÂN TÍCH TÍNH NHẤT QUÁN (GAP ANALYSIS & CONSISTENCY REPORT)
**Dự án:** Hệ Thống Phòng Khám Đa Khoa HealthSync  
**Vai trò:** System Analyst & Database Administrator (SA / DBA)

---

## 1. Ba Điểm Vênh Nghiêm Trọng Nhất Giữa Nghiệp Vụ Và Thiết Kế Cũ

Qua đối chiếu giữa Lưu đồ hoạt động (UML Activity Diagram) do BA cung cấp và mã nguồn cơ sở dữ liệu cũ (Legacy Schema), chúng tôi xác định 3 "lỗ hổng" dữ liệu trí mạng sau:

1. **Anti-Pattern cờ Boolean (`is_active`) cho quy trình đa trạng thái:**  
   Quy trình nghiệp vụ thực tế có 5 trạng thái liên tục: `PENDING` $\to$ `CONFIRMED` $\to$ `CHECKED_IN` $\to$ `COMPLETED` hoặc `CANCELLED`. Việc lập trình viên chỉ dùng 1 cột `is_active BOOLEAN` chỉ biểu diễn được 2 giá trị nhị phân (Đang chạy/Đã hủy), làm mất hoàn toàn khả năng giám sát vòng đời lịch hẹn của bệnh nhân trong thực tế.

2. **Thiếu hoàn toàn các trường dữ liệu tài chính và lý do hủy (`deposit_amount`, `penalty_fee`, `cancel_reason`):**  
   Nghiệp vụ phòng khám bắt buộc thu tiền cọc và phạt hủy lịch nếu hủy sau khi đã xác nhận. Bản thiết kế cũ không có cột nào để lưu tiền cọc, số tiền phạt, hay nguyên nhân hủy. Hậu quả là phòng khám không thể đối soát doanh thu, gây thất thoát tiền bạc và tranh chấp với bệnh nhân.

3. **Bỏ quên hoàn toàn thực thể Đơn thuốc (`Prescriptions`):**  
   Lưu đồ nghiệp vụ kết thúc khi bác sĩ khám xong (`COMPLETED`) và kê đơn thuốc cho bệnh nhân. Thiết kế cũ hoàn toàn không có bảng hay trường nào lưu trữ đơn thuốc, khiến bác sĩ không thể kê toa điện tử và bệnh nhân không thể mua thuốc hay tái khám.

---

## 2. Phần Bảo Vệ Thiết Kế - Trả Lời Vấn Đáp Giảng Viên (100% Tự Tin)

### Câu hỏi 1:
> *"Nếu một lịch hẹn đang ở trạng thái PENDING (chưa khám), nhưng có người cố tình INSERT một đơn thuốc vào bảng Prescriptions, làm thế nào để chặn hành động phi logic này ở tầng CSDL?"*

**Trả lời:**  
Chúng em thiết lập một **Database Trigger** `BEFORE INSERT` trên bảng `Prescriptions`. Trigger sẽ truy vấn trạng thái (`status`) của lịch hẹn tương ứng trong bảng `Appointments`. Nếu `status != 'COMPLETED'`, Trigger sẽ ném ra ngoại lệ `SIGNAL SQLSTATE '45000'` từ chối thao tác ghi dữ liệu. Giải pháp này đảm bảo tính toàn vẹn nghiệp vụ ở tầng lõi dữ liệu, ngay cả khi ứng dụng backend bị lỗi hoặc có người cố tình can thiệp bằng câu lệnh SQL trực tiếp.

### Câu hỏi 2:
> *"Tại sao việc lưu `penalty_fee` lại quan trọng đối với tính toàn vẹn hệ thống? Nếu thiếu cột này, kế toán đối soát cuối tháng sẽ gặp hậu quả gì?"*

**Trả lời:**  
Cột `penalty_fee` ghi nhận nguồn doanh thu phát sinh từ hành vi vi phạm cam kết lịch hẹn. Nếu thiếu cột này:
- Kế toán không thể biết khoản tiền cọc bị trừ đi bao nhiêu và phải hoàn trả bệnh nhân bao nhiêu (`Tiền hoàn = Tiền cọc - Phí phạt`).
- Tổng tiền thu thực tế trên tài khoản ngân hàng sẽ bị chênh lệch (vênh số liệu) so với báo cáo trên phần mềm, vi phạm nguyên tắc kiểm toán và không thể xác định công nợ/doanh thu phòng khám.

### Câu hỏi 3:
> *"Sự nhất quán (Consistency) giữa UML Activity Diagram và ERD đóng vai trò gì trong việc chuyển giao công việc giữa BA và Dev?"*

**Trả lời:**  
- **UML Activity Diagram** định nghĩa **dòng chảy động (Behavior/Process)** của nghiệp vụ.
- **ERD** định nghĩa **cấu trúc tĩnh (Data Structure)** lưu trữ trạng thái của dòng chảy đó.
- Sự nhất quán giữa hai biểu đồ này là chiếc cầu nối kỹ thuật đảm bảo: Mọi hành động, điều kiện rẽ nhánh và kết quả trong luồng nghiệp vụ đều có "nơi lưu trú" hợp lệ trong cơ sở dữ liệu. Nếu bị vênh, phần mềm chắc chắn sẽ sập (Crash) hoặc phát sinh lỗi nghiêm trọng khi triển khai thực tế.
