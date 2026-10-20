# [BÀI TẬP] CHUYỂN ĐỔI ERD SANG MÔ HÌNH QUAN HỆ

**Mục tiêu:** Chuyển đổi mô hình thực thể kết hợp (ERD Quản lý cung ứng vật tư & kho) sang mô hình dữ liệu quan hệ (Relational Model / Database Schema).

---

## 🖼️ SƠ ĐỒ MÔ HÌNH BẢNG QUAN HỆ SAU CHUYỂN ĐỔI

![Mô hình Quan Hệ](erd_chuyen_doi_mo_hinh_quan_he.svg)

---

## 📝 CHI TIẾT 4 BƯỚC PHÂN TÍCH CHUYỂN ĐỔI CHUẨN

### Bước 1: Xác định các thực thể có trong mô hình ERD
Từ sơ đồ ERD, ta xác định được **5 thực thể mạnh** (Strong Entities):
1. **PHIEUXUAT** (Phiếu xuất): Lưu thông tin các phiếu xuất kho.
   - Thuộc tính: `SoPX` (Khóa chính), `NgayXuat`.
2. **VATTU** (Vật tư): Lưu danh mục các loại vật tư hàng hóa.
   - Thuộc tính: `MaVT` (Khóa chính), `TenVT`.
3. **PHIEUNHAP** (Phiếu nhập): Lưu thông tin các phiếu nhập kho.
   - Thuộc tính: `SoPN` (Khóa chính), `NgayNhap`.
4. **DONDH** (Đơn đặt hàng): Lưu thông tin đơn đặt hàng gửi nhà cung cấp.
   - Thuộc tính: `SoDH` (Khóa chính), `NgayDH`.
5. **NHACC** (Nhà cung cấp): Lưu thông tin đối tác cung cấp hàng.
   - Thuộc tính: `MaNCC` (Khóa chính), `TenNCC`, `DiaChi`.

---

### Bước 2: Xác định các mối quan hệ (1-1, 1-n, n-m) để sinh trường và bảng

1. **Mối quan hệ 1 - n (CUNG_CAP giữa NHACC và DONDH):**
   - *Quy tắc:* Một nhà cung cấp có thể cung cấp nhiều đơn đặt hàng (1 - n).
   - *Chuyển đổi:* Lấy khóa chính `MaNCC` từ bảng phía 1 (`NHACC`) đưa sang làm khóa ngoại (FK) trong bảng phía n (`DONDH`).
   - $\rightarrow$ Bảng `DonDatHang` có thêm cột `MaNCC (FK)`.

2. **Mối quan hệ n - m (XUAT giữa PHIEUXUAT và VATTU):**
   - *Quy tắc:* Một phiếu xuất có nhiều vật tư và một vật tư có thể xuất trong nhiều phiếu. Mối quan hệ có 2 thuộc tính riêng là đơn giá xuất (`DGXuat`) và số lượng xuất (`SLXuat`).
   - *Chuyển đổi:* Sinh ra bảng trung gian **ChiTietPhieuXuat**.
   - Khóa chính kết hợp: `(SoPX, MaVT)`, đồng thời là 2 khóa ngoại.
   - Các cột: `SoPX (PK, FK)`, `MaVT (PK, FK)`, `DGXuat`, `SLXuat`.

3. **Mối quan hệ n - m (NHAP giữa PHIEUNHAP và VATTU):**
   - *Quy tắc:* Một phiếu nhập có nhiều vật tư và một vật tư có thể nhập ở nhiều phiếu. Mối quan hệ có 2 thuộc tính riêng là đơn giá nhập (`DGNhap`) và số lượng nhập (`SLNhap`).
   - *Chuyển đổi:* Sinh ra bảng trung gian **ChiTietPhieuNhap**.
   - Khóa chính kết hợp: `(SoPN, MaVT)`, đồng thời là 2 khóa ngoại.
   - Các cột: `SoPN (PK, FK)`, `MaVT (PK, FK)`, `DGNhap`, `SLNhap`.

4. **Mối quan hệ n - m (DAT_HANG giữa DONDH và VATTU):**
   - *Quy tắc:* Một đơn đặt hàng có nhiều vật tư và một vật tư có thể nằm trong nhiều đơn đặt.
   - *Chuyển đổi:* Sinh ra bảng trung gian **ChiTietDonDatHang**.
   - Khóa chính kết hợp: `(SoDH, MaVT)`, đồng thời là 2 khóa ngoại.
   - Các cột: `SoDH (PK, FK)`, `MaVT (PK, FK)`.

---

### Bước 3: Xác định thuộc tính đa trị và tạo thành 1 bảng mới
- Trong sơ đồ ERD, thực thể **NHACC** có thuộc tính **SDT** (Số điện thoại) là thuộc tính đa trị (được biểu diễn bằng hình oval nét đôi - một nhà cung cấp có thể có nhiều số điện thoại liên hệ).
- Theo chuẩn hóa 1NF (dạng chuẩn 1), bảng không được chứa thuộc tính đa trị.
- *Quy tắc chuyển đổi:* Tách thuộc tính đa trị thành một bảng mới: **NhaCungCap_SDT**.
  - Đưa khóa chính `MaNCC` của bảng `NhaCungCap` sang làm khóa ngoại.
  - Khóa chính của bảng mới là cặp kết hợp: `(MaNCC, SDT)`.

---

### Bước 4: Liệt kê lại danh sách các bảng sau khi chuyển đổi xong

Sau khi hoàn thành 4 bước trên, hệ thống thu được **9 bảng quan hệ** chuẩn hóa hoàn chỉnh:

1. **PhieuXuat** (<u>SoPX</u>, NgayXuat)
2. **ChiTietPhieuXuat** (<u>#SoPX</u>, <u>#MaVT</u>, DGXuat, SLXuat)
3. **VatTu** (<u>MaVT</u>, TenVT)
4. **ChiTietPhieuNhap** (<u>#SoPN</u>, <u>#MaVT</u>, DGNhap, SLNhap)
5. **PhieuNhap** (<u>SoPN</u>, NgayNhap)
6. **ChiTietDonDatHang** (<u>#SoDH</u>, <u>#MaVT</u>)
7. **DonDatHang** (<u>SoDH</u>, NgayDH, #MaNCC)
8. **NhaCungCap** (<u>MaNCC</u>, TenNCC, DiaChi)
9. **NhaCungCap_SDT** (<u>#MaNCC</u>, <u>SDT</u>)

*(Ghi chú: Ký hiệu gạch chân `<u>...</u>` là Khóa chính - PK, ký hiệu `#` là Khóa ngoại - FK).*
