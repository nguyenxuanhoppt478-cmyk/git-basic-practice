-- ========================================================
-- [Bài tập] Chuyển đổi ERD sang mô hình quan hệ
-- Cơ sở dữ liệu: QuanLyVatTu (Quản lý kho và cung ứng vật tư)
-- ========================================================

DROP DATABASE IF EXISTS QuanLyVatTu;
CREATE DATABASE QuanLyVatTu CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE QuanLyVatTu;

-- 1. Bảng Nhà Cung Cấp (NHACC)
-- Tách thuộc tính đa trị SDT sang bảng riêng
CREATE TABLE NhaCungCap (
    MaNCC VARCHAR(20) PRIMARY KEY,
    TenNCC VARCHAR(100) NOT NULL,
    DiaChi VARCHAR(255)
);

-- 2. Bảng Thuộc tính đa trị: Số Điện Thoại của Nhà Cung Cấp (SDT_NHACC)
CREATE TABLE NhaCungCap_SDT (
    MaNCC VARCHAR(20) NOT NULL,
    SDT VARCHAR(15) NOT NULL,
    PRIMARY KEY (MaNCC, SDT),
    CONSTRAINT FK_SDT_NhaCungCap FOREIGN KEY (MaNCC) REFERENCES NhaCungCap(MaNCC) ON DELETE CASCADE
);

-- 3. Bảng Đơn Đặt Hàng (DONDH)
-- Nhận khóa ngoại MaNCC từ quan hệ 1 - n với NhaCungCap
CREATE TABLE DonDatHang (
    SoDH VARCHAR(20) PRIMARY KEY,
    NgayDH DATETIME NOT NULL,
    MaNCC VARCHAR(20) NOT NULL,
    CONSTRAINT FK_DonDatHang_NhaCungCap FOREIGN KEY (MaNCC) REFERENCES NhaCungCap(MaNCC)
);

-- 4. Bảng Vật Tư (VATTU)
CREATE TABLE VatTu (
    MaVT VARCHAR(20) PRIMARY KEY,
    TenVT VARCHAR(100) NOT NULL
);

-- 5. Bảng Chi Tiết Đơn Đặt Hàng (CT_DONDH)
-- Giải quyết quan hệ nhiều - nhiều (n - m) giữa DonDatHang và VatTu
CREATE TABLE ChiTietDonDatHang (
    SoDH VARCHAR(20) NOT NULL,
    MaVT VARCHAR(20) NOT NULL,
    PRIMARY KEY (SoDH, MaVT),
    CONSTRAINT FK_CTDH_DonDatHang FOREIGN KEY (SoDH) REFERENCES DonDatHang(SoDH) ON DELETE CASCADE,
    CONSTRAINT FK_CTDH_VatTu FOREIGN KEY (MaVT) REFERENCES VatTu(MaVT)
);

-- 6. Bảng Phiếu Xuất (PHIEUXUAT)
CREATE TABLE PhieuXuat (
    SoPX VARCHAR(20) PRIMARY KEY,
    NgayXuat DATETIME NOT NULL
);

-- 7. Bảng Chi Tiết Phiếu Xuất (CT_PHIEUXUAT)
-- Giải quyết quan hệ n - m giữa PhieuXuat và VatTu kèm thuộc tính DGXuat, SLXuat
CREATE TABLE ChiTietPhieuXuat (
    SoPX VARCHAR(20) NOT NULL,
    MaVT VARCHAR(20) NOT NULL,
    DGXuat DECIMAL(12, 2) NOT NULL,
    SLXuat INT NOT NULL,
    PRIMARY KEY (SoPX, MaVT),
    CONSTRAINT FK_CTPX_PhieuXuat FOREIGN KEY (SoPX) REFERENCES PhieuXuat(SoPX) ON DELETE CASCADE,
    CONSTRAINT FK_CTPX_VatTu FOREIGN KEY (MaVT) REFERENCES VatTu(MaVT)
);

-- 8. Bảng Phiếu Nhập (PHIEUNHAP)
CREATE TABLE PhieuNhap (
    SoPN VARCHAR(20) PRIMARY KEY,
    NgayNhap DATETIME NOT NULL
);

-- 9. Bảng Chi Tiết Phiếu Nhập (CT_PHIEUNHAP)
-- Giải quyết quan hệ n - m giữa PhieuNhap và VatTu kèm thuộc tính DGNhap, SLNhap
CREATE TABLE ChiTietPhieuNhap (
    SoPN VARCHAR(20) NOT NULL,
    MaVT VARCHAR(20) NOT NULL,
    DGNhap DECIMAL(12, 2) NOT NULL,
    SLNhap INT NOT NULL,
    PRIMARY KEY (SoPN, MaVT),
    CONSTRAINT FK_CTPN_PhieuNhap FOREIGN KEY (SoPN) REFERENCES PhieuNhap(SoPN) ON DELETE CASCADE,
    CONSTRAINT FK_CTPN_VatTu FOREIGN KEY (MaVT) REFERENCES VatTu(MaVT)
);
