-- =============================================================================
-- HỆ THỐNG PHÒNG KHÁM HEALTHSYNC (HEALTHSYNC DATABASE OPTIMIZED)
-- Bài thực hành: Khủng Hoảng Tại Phòng Khám HealthSync
-- =============================================================================

-- Bước 1: Khởi tạo cơ sở dữ liệu
DROP DATABASE IF EXISTS healthsync_db;
CREATE DATABASE healthsync_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE healthsync_db;

-- 1. Bảng Bệnh nhân (Patients)
CREATE TABLE Patients (
    patient_id INT AUTO_INCREMENT PRIMARY KEY,
    full_name VARCHAR(100) NOT NULL,
    phone VARCHAR(15) NOT NULL
);

-- 2. Bảng Bác sĩ (Doctors)
CREATE TABLE Doctors (
    doctor_id INT AUTO_INCREMENT PRIMARY KEY,
    full_name VARCHAR(100) NOT NULL,
    specialty VARCHAR(50)
);

-- 3. Bảng Lịch hẹn (Appointments) - TÁI CẤU TRÚC CHUẨN HÓA
-- Thay thế cột is_active bằng ENUM đa trạng thái
-- Bổ sung tiền cọc (deposit_amount), phí phạt (penalty_fee) dạng DECIMAL tránh lỗi sai số tài chính
-- Bổ sung lý do hủy (cancel_reason)
CREATE TABLE Appointments (
    appointment_id INT AUTO_INCREMENT PRIMARY KEY,
    patient_id INT NOT NULL,
    doctor_id INT NOT NULL,
    appointment_date DATETIME NOT NULL,
    status ENUM('PENDING', 'CONFIRMED', 'CHECKED_IN', 'COMPLETED', 'CANCELLED') 
        DEFAULT 'PENDING' NOT NULL,
    deposit_amount DECIMAL(12, 2) DEFAULT 0.00 NOT NULL,
    penalty_fee DECIMAL(12, 2) DEFAULT 0.00 NOT NULL,
    cancel_reason VARCHAR(255) DEFAULT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_appointments_patient FOREIGN KEY (patient_id) REFERENCES Patients(patient_id) ON DELETE RESTRICT,
    CONSTRAINT fk_appointments_doctor FOREIGN KEY (doctor_id) REFERENCES Doctors(doctor_id) ON DELETE RESTRICT
);

-- 4. Bảng Đơn thuốc (Prescriptions) - THỰC THỂ MỚI BỊ LẬP TRÌNH VIÊN CŨ BỎ QUÊN
-- Mỗi lịch hẹn sau khi hoàn tất (COMPLETED) sẽ có 1 đơn thuốc tương ứng
CREATE TABLE Prescriptions (
    prescription_id INT AUTO_INCREMENT PRIMARY KEY,
    appointment_id INT NOT NULL UNIQUE,
    medication_details TEXT NOT NULL,
    issued_date DATETIME DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_prescriptions_appointment FOREIGN KEY (appointment_id) REFERENCES Appointments(appointment_id) ON DELETE CASCADE
);

-- =============================================================================
-- TRIGGER BẢO VỆ TÍNH TOÀN VẸN NGHIỆP VỤ (VẤN ĐÁP 1)
-- Ngăn chặn kê đơn thuốc khi lịch hẹn chưa đạt trạng thái COMPLETED
-- =============================================================================
DELIMITER $$
CREATE TRIGGER trg_check_prescription_status
BEFORE INSERT ON Prescriptions
FOR EACH ROW
BEGIN
    DECLARE v_status VARCHAR(20);
    SELECT status INTO v_status FROM Appointments WHERE appointment_id = NEW.appointment_id;
    
    IF v_status IS NULL OR v_status != 'COMPLETED' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Lỗi nghiệp vụ: Chỉ được phép kê đơn thuốc cho lịch hẹn đã hoàn thành (COMPLETED)!';
    END IF;
END$$
DELIMITER ;

-- =============================================================================
-- BƯỚC 4: VẬN HÀNH VÀ MÔ PHỎNG DỮ LIỆU THỰC TẾ (DML)
-- =============================================================================

-- Dữ liệu ban đầu: Bệnh nhân & Bác sĩ
INSERT INTO Patients (full_name, phone) VALUES 
('Nguyễn Văn An', '0901234567'),
('Trần Thị Bình', '0912345678');

INSERT INTO Doctors (full_name, specialty) VALUES 
('BS. Lê Hoàng Nam', 'Nội tổng quát'),
('BS. Phạm Minh Trang', 'Tim mạch');

-- -----------------------------------------------------------------------------
-- KỊCH BẢN 1 (Thành công trọn vẹn):
-- 1. Tạo lịch hẹn trạng thái PENDING với tiền cọc 500.000 VNĐ
-- 2. Bệnh nhân đến khám -> update CHECKED_IN
-- 3. Khám xong -> update COMPLETED
-- 4. Bác sĩ kê đơn thuốc
-- -----------------------------------------------------------------------------
-- 1. Tạo lịch hẹn PENDING
INSERT INTO Appointments (patient_id, doctor_id, appointment_date, status, deposit_amount)
VALUES (1, 1, '2026-10-25 08:30:00', 'PENDING', 500000.00);
SET @app_success_id = LAST_INSERT_ID();

-- 2. Chuyển sang CHECKED_IN khi bệnh nhân tới phòng khám
UPDATE Appointments 
SET status = 'CHECKED_IN' 
WHERE appointment_id = @app_success_id;

-- 3. Chuyển sang COMPLETED khi khám xong
UPDATE Appointments 
SET status = 'COMPLETED' 
WHERE appointment_id = @app_success_id;

-- 4. Bác sĩ tạo Đơn thuốc đi kèm
INSERT INTO Prescriptions (appointment_id, medication_details, issued_date)
VALUES (@app_success_id, '1. Paracetamol 500mg: 2 viên/ngày sau ăn\n2. Vitamin C 500mg: 1 viên/ngày sáng', NOW());

-- -----------------------------------------------------------------------------
-- KỊCH BẢN 2 (Hủy lịch và Phạt tiền cọc):
-- 1. Tạo lịch hẹn CONFIRMED với tiền cọc 300.000 VNĐ
-- 2. Bệnh nhân báo hủy -> Update CANCELLED, lý do hủy, và phạt 150.000 VNĐ
-- -----------------------------------------------------------------------------
-- 1. Tạo lịch hẹn CONFIRMED
INSERT INTO Appointments (patient_id, doctor_id, appointment_date, status, deposit_amount)
VALUES (2, 2, '2026-10-26 14:00:00', 'CONFIRMED', 300000.00);
SET @app_cancelled_id = LAST_INSERT_ID();

-- 2. Cập nhật hủy lịch và áp dụng phạt
UPDATE Appointments 
SET status = 'CANCELLED',
    cancel_reason = 'Bận việc đột xuất',
    penalty_fee = 150000.00
WHERE appointment_id = @app_cancelled_id;

-- =============================================================================
-- CÂU LỆNH TRUY VẤN KIỂM TRA ĐỐI SOÁT (TESTING)
-- =============================================================================

-- Truy vấn 1: Danh sách bệnh nhân đã hoàn tất khám và chi tiết đơn thuốc
SELECT 
    a.appointment_id,
    p.full_name AS ten_benh_nhan,
    p.phone AS sdt,
    d.full_name AS bac_si_kham,
    a.appointment_date AS ngay_kham,
    a.status AS trang_thai,
    pr.medication_details AS chi_tiet_don_thuoc
FROM Appointments a
JOIN Patients p ON a.patient_id = p.patient_id
JOIN Doctors d ON a.doctor_id = d.doctor_id
JOIN Prescriptions pr ON a.appointment_id = pr.appointment_id
WHERE a.status = 'COMPLETED';

-- Truy vấn 2: Báo cáo tài chính tiền cọc và phí phạt (Hỗ trợ Kế toán đối soát)
SELECT 
    a.appointment_id,
    p.full_name AS ten_benh_nhan,
    a.status AS trang_thai,
    a.deposit_amount AS tien_coc,
    a.penalty_fee AS phi_phat,
    (a.deposit_amount - a.penalty_fee) AS tien_hoan_lai,
    a.cancel_reason AS ly_do_huy
FROM Appointments a
JOIN Patients p ON a.patient_id = p.patient_id;
