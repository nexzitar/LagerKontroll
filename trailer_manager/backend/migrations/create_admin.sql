-- Create or update first admin user
-- Run this as: sudo -u postgres psql -d trailer_manager -f create_admin.sql
-- Then update with your email: UPDATE users SET role = 'admin' WHERE email = 'your@email.com';

-- Update the existing user to be admin (replace with your email)
UPDATE users SET role = 'admin' WHERE email = 'sukiyo83@gmail.com';

-- Display all users and their roles
SELECT id, email, name, role FROM users;
