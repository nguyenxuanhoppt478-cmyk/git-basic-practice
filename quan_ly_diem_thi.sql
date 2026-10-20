-- ========================================================
-- [Thực hành] Tạo bảng trong CSDL
-- Cơ sở dữ liệu: QuanLyDiemThi
-- ========================================================

-- Bước 1: Tạo cơ sở dữ liệu QuanLyDiemThi
DROP DATABASE IF EXISTS QuanLyDiemThi;
CREATE DATABASE QuanLyDiemThi;

-- Bước 2: Chọn Database QuanLyDiemThi để thao tác
USE QuanLyDiemThi;

-- Bước 3: Tạo bảng HocSinh
CREATE TABLE HocSinh (
    MaHS VARCHAR(20) PRIMARY KEY,
    TenHS VARCHAR(50) NOT NULL,
    NgaySinh DATETIME,
    Lop VARCHAR(20),
    GT VARCHAR(20)
);

-- Bước 4: Tạo bảng MonHoc
CREATE TABLE MonHoc (
    MaMH VARCHAR(50) PRIMARY KEY,
    TenMH VARCHAR(50) NOT NULL,
    MaGV VARCHAR(20)
);

-- Bước 5: Tạo bảng BangDiem (Bảng trung gian giữa HocSinh và MonHoc quan hệ n - n)
CREATE TABLE BangDiem (
    MaHS VARCHAR(20),
    MaMH VARCHAR(50),
    DiemThi INT,
    NgayKT DATETIME,
    PRIMARY KEY (MaHS, MaMH),
    CONSTRAINT FK_BangDiem_HocSinh FOREIGN KEY (MaHS) REFERENCES HocSinh(MaHS),
    CONSTRAINT FK_BangDiem_MonHoc FOREIGN KEY (MaMH) REFERENCES MonHoc(MaMH)
);

-- Bước 6: Tạo bảng GiaoVien
CREATE TABLE GiaoVien (
    MaGV VARCHAR(20) PRIMARY KEY,
    TenGV VARCHAR(50) NOT NULL,
    SDT VARCHAR(10)
);

-- Bước 7: Bổ sung khóa ngoại cho bảng MonHoc tham chiếu đến bảng GiaoVien
ALTER TABLE MonHoc 
    ADD CONSTRAINT FK_MaGV FOREIGN KEY (MaGV) REFERENCES GiaoVien(MaGV);
