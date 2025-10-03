-- JobBoard Database Setup Script
-- This script creates the necessary database and tables for the Job Board application

-- Create database (if it doesn't exist)
CREATE DATABASE IF NOT EXISTS jobboard;
USE jobboard;

-- Create jobs table
CREATE TABLE IF NOT EXISTS jobs (
    id INT AUTO_INCREMENT PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    employer VARCHAR(255) NOT NULL,
    location VARCHAR(100) NOT NULL,
    salary DECIMAL(10,2) NOT NULL,
    description TEXT,
    posted_date DATE NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_posted_date (posted_date),
    INDEX idx_location (location),
    INDEX idx_salary (salary)
);

-- Insert sample data for testing
INSERT INTO jobs (title, employer, location, salary, description, posted_date) VALUES
('Cashier', 'Local Grocery Store', 'Downtown', 15.00, 'Part-time cashier position with flexible hours', CURDATE()),
('Cook', 'Fast Food Restaurant', 'Mall Area', 16.50, 'Line cook position, experience preferred but not required', CURDATE()),
('Barista', 'Coffee Shop Chain', 'City Center', 14.50, 'Morning and afternoon shifts available', CURDATE()),
('Sales Associate', 'Retail Store', 'Shopping District', 15.50, 'Customer service and merchandising position', CURDATE()),
('Delivery Driver', 'Pizza Restaurant', 'Various Locations', 18.00, 'Must have valid driver\'s license and reliable vehicle', CURDATE()),
('Waiter/Waitress', 'Family Restaurant', 'Residential Area', 12.00, 'Plus tips, part-time and full-time positions', CURDATE()),
('Janitor', 'Office Building', 'Business District', 16.00, 'Evening shift, cleaning and maintenance', CURDATE()),
('Tutor', 'Learning Center', 'Educational District', 20.00, 'Math and English tutoring for K-12 students', CURDATE()),
('Receptionist', 'Dental Clinic', 'Medical District', 17.00, 'Front desk position, some experience preferred', CURDATE()),
('Warehouse Worker', 'Distribution Center', 'Industrial Area', 16.50, 'Loading and unloading trucks, physical work', CURDATE())
ON DUPLICATE KEY UPDATE
    title = VALUES(title),
    employer = VALUES(employer),
    location = VALUES(location),
    salary = VALUES(salary),
    description = VALUES(description),
    posted_date = VALUES(posted_date);

-- Create user table (for future authentication features)
CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    user_type ENUM('employer', 'job_seeker') NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_email (email),
    INDEX idx_user_type (user_type)
);

-- Create applications table (for job applications)
CREATE TABLE IF NOT EXISTS applications (
    id INT AUTO_INCREMENT PRIMARY KEY,
    job_id INT NOT NULL,
    applicant_name VARCHAR(100) NOT NULL,
    applicant_email VARCHAR(100) NOT NULL,
    applicant_phone VARCHAR(20),
    resume_url VARCHAR(500),
    cover_letter TEXT,
    status ENUM('pending', 'reviewing', 'accepted', 'rejected') DEFAULT 'pending',
    applied_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (job_id) REFERENCES jobs(id) ON DELETE CASCADE,
    INDEX idx_job_id (job_id),
    INDEX idx_status (status),
    INDEX idx_applied_date (applied_date)
);

-- Show created tables
SHOW TABLES;

-- Show table structures
DESCRIBE jobs;
DESCRIBE users;
DESCRIBE applications;

-- Show sample data count
SELECT 'Jobs' as Table_Name, COUNT(*) as Record_Count FROM jobs
UNION ALL
SELECT 'Users' as Table_Name, COUNT(*) as Record_Count FROM users
UNION ALL
SELECT 'Applications' as Table_Name, COUNT(*) as Record_Count FROM applications;