-- Add phone_number column to users table
ALTER TABLE users ADD COLUMN IF NOT EXISTS phone_number VARCHAR(20) UNIQUE;

-- Make email optional (for future phone-only users)
ALTER TABLE users ALTER COLUMN email DROP NOT NULL;

-- Add index on phone_number for faster lookups
CREATE INDEX IF NOT EXISTS idx_users_phone_number ON users(phone_number);
