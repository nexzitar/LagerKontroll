-- Trailer Manager Database Schema
-- PostgreSQL 13+

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Users table (for authentication)
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    name VARCHAR(255) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Trailer entries table (append-only history)
CREATE TABLE trailer_entries (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    trailer_number VARCHAR(50) NOT NULL,
    terminal VARCHAR(10) NOT NULL CHECK (terminal IN ('B1', 'B3')),
    is_empty BOOLEAN NOT NULL DEFAULT false,
    latitude DECIMAL(10, 8) NOT NULL,
    longitude DECIMAL(11, 8) NOT NULL,
    address TEXT,
    photo_url TEXT NOT NULL,
    thumbnail_url TEXT,
    notes TEXT,
    created_by UUID REFERENCES users(id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,

    -- Indexes for common queries
    CONSTRAINT valid_latitude CHECK (latitude >= -90 AND latitude <= 90),
    CONSTRAINT valid_longitude CHECK (longitude >= -180 AND longitude <= 180)
);

-- Create indexes for performance
CREATE INDEX idx_trailer_entries_number ON trailer_entries(trailer_number);
CREATE INDEX idx_trailer_entries_created_at ON trailer_entries(created_at DESC);
CREATE INDEX idx_trailer_entries_terminal ON trailer_entries(terminal);
CREATE INDEX idx_trailer_entries_is_empty ON trailer_entries(is_empty);
CREATE INDEX idx_trailer_entries_composite ON trailer_entries(trailer_number, created_at DESC);

-- View for latest trailer status (most recent entry per trailer)
CREATE OR REPLACE VIEW trailers_latest AS
SELECT DISTINCT ON (trailer_number)
    trailer_number,
    id AS latest_entry_id,
    terminal,
    is_empty,
    latitude,
    longitude,
    address,
    photo_url,
    thumbnail_url,
    notes,
    created_by,
    created_at,
    (SELECT COUNT(*) FROM trailer_entries te2 WHERE te2.trailer_number = trailer_entries.trailer_number) AS entry_count
FROM trailer_entries
ORDER BY trailer_number, created_at DESC;

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Trigger for users table
CREATE TRIGGER update_users_updated_at
    BEFORE UPDATE ON users
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Insert a default user for testing (password: 'password123')
-- IMPORTANT: Change this password in production!
INSERT INTO users (email, password_hash, name) VALUES
('test@example.com', '$2b$10$rKvVLZ5FZHqZ5xK5Y5YZZ.YxYZYZYZYZYZYZYZYZYZYZYZYZYZY', 'Test User')
ON CONFLICT (email) DO NOTHING;

-- Sample data for testing (optional)
-- Uncomment if you want to start with sample data
/*
INSERT INTO trailer_entries (
    trailer_number,
    terminal,
    is_empty,
    latitude,
    longitude,
    address,
    photo_url,
    thumbnail_url,
    notes,
    created_by
) VALUES
    ('TR-12345', 'B1', false, 59.3293, 18.0686, 'Stockholm, Sweden', 'https://picsum.photos/800/600?random=1', 'https://picsum.photos/200/150?random=1', 'Test entry 1', (SELECT id FROM users LIMIT 1)),
    ('TR-12345', 'B1', true, 59.3293, 18.0686, 'Stockholm, Sweden', 'https://picsum.photos/800/600?random=2', 'https://picsum.photos/200/150?random=2', 'Marked as empty', (SELECT id FROM users LIMIT 1)),
    ('TR-67890', 'B3', false, 59.3251, 18.0710, 'Stockholm, Sweden', 'https://picsum.photos/800/600?random=3', 'https://picsum.photos/200/150?random=3', 'Test entry 2', (SELECT id FROM users LIMIT 1));
*/
