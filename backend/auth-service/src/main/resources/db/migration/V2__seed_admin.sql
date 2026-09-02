-- Dev convenience: a pre-seeded admin account so admin flows can be tested
-- with the normal OTP login (dev-echo shows the code in the response).
-- Replace with a proper admin-management flow before production.
INSERT INTO users (phone, name, role)
VALUES ('9999999999', 'City Admin', 'ADMIN')
ON CONFLICT (phone) DO NOTHING;
