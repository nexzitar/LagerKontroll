-- Add role column to users table
-- Run this as: sudo -u postgres psql -d trailer_manager -f add_user_roles.sql

-- Add role column (user or admin)
ALTER TABLE users ADD COLUMN IF NOT EXISTS role VARCHAR(20) DEFAULT 'user' NOT NULL;

-- Display current users
SELECT id, email, name, role FROM users;
