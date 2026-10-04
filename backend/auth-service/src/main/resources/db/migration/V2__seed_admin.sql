INSERT INTO users (phone, name, role)
VALUES ('9999999999', 'City Admin', 'ADMIN')
ON DUPLICATE KEY UPDATE phone = phone;
