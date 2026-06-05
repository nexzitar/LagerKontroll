-- ============================================================================
-- TRAILER MANAGEMENT SYSTEM - DATABASE SCHEMA
-- ============================================================================
-- Database: PostgreSQL (recommended)
-- Version: 12+
-- Character Set: UTF8
-- ============================================================================

-- ============================================================================
-- EXTENSIONS
-- ============================================================================
-- Enable UUID generation (optional, if you want to use UUIDs instead of serial)
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Enable PostGIS for advanced GPS/geospatial queries (optional but recommended)
-- Uncomment if you need radius searches, distance calculations, etc.
-- CREATE EXTENSION IF NOT EXISTS postgis;


-- ============================================================================
-- TABLE: users
-- Stores user information for authentication and audit trails
-- ============================================================================
CREATE TABLE users (
    user_id SERIAL PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    phone_number VARCHAR(20),
    full_name VARCHAR(100),
    is_active BOOLEAN DEFAULT true NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,

    CONSTRAINT email_format CHECK (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$')
);

-- Index for active user lookups
CREATE INDEX idx_users_username ON users(username) WHERE is_active = true;
CREATE INDEX idx_users_email ON users(email) WHERE is_active = true;

COMMENT ON TABLE users IS 'Stores user accounts for the trailer management system';
COMMENT ON COLUMN users.user_id IS 'Primary key - unique identifier for each user';
COMMENT ON COLUMN users.is_active IS 'Soft delete flag - false means user is deactivated';


-- ============================================================================
-- TABLE: terminals
-- Reference table for terminal locations (B1, B3, etc.)
-- ============================================================================
CREATE TABLE terminals (
    terminal_id SERIAL PRIMARY KEY,
    terminal_code VARCHAR(10) UNIQUE NOT NULL,
    terminal_name VARCHAR(100) NOT NULL,
    description TEXT,
    default_latitude DECIMAL(10, 8),
    default_longitude DECIMAL(11, 8),
    is_active BOOLEAN DEFAULT true NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,

    CONSTRAINT terminal_code_uppercase CHECK (terminal_code = UPPER(terminal_code))
);

-- Index for active terminal lookups
CREATE INDEX idx_terminals_code ON terminals(terminal_code) WHERE is_active = true;

COMMENT ON TABLE terminals IS 'Reference table for terminal locations';
COMMENT ON COLUMN terminals.terminal_code IS 'Short code identifier (e.g., B1, B3)';

-- Insert default terminals
INSERT INTO terminals (terminal_code, terminal_name, description) VALUES
    ('B1', 'Terminal B1', 'Terminal B1 location'),
    ('B3', 'Terminal B3', 'Terminal B3 location');


-- ============================================================================
-- TABLE: trailers
-- Master table for trailer information (relatively static data)
-- ============================================================================
CREATE TABLE trailers (
    trailer_id SERIAL PRIMARY KEY,
    trailer_number VARCHAR(20) UNIQUE NOT NULL,
    license_plate VARCHAR(20) UNIQUE NOT NULL,
    description TEXT,
    make VARCHAR(50),
    model VARCHAR(50),
    year INTEGER,
    is_active BOOLEAN DEFAULT true NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,

    CONSTRAINT license_plate_format CHECK (LENGTH(TRIM(license_plate)) >= 3),
    CONSTRAINT year_valid CHECK (year IS NULL OR (year >= 1900 AND year <= EXTRACT(YEAR FROM CURRENT_DATE) + 1))
);

-- Indexes for trailer lookups
CREATE INDEX idx_trailers_number ON trailers(trailer_number) WHERE is_active = true;
CREATE INDEX idx_trailers_license_plate ON trailers(license_plate) WHERE is_active = true;

COMMENT ON TABLE trailers IS 'Master table for trailer registration and static information';
COMMENT ON COLUMN trailers.trailer_number IS 'Internal tracking number for the trailer';
COMMENT ON COLUMN trailers.license_plate IS 'Official license plate number';


-- ============================================================================
-- TABLE: trailer_status_history
-- APPEND-ONLY history of all trailer status changes and locations
-- This is the core table for your append-only requirements
-- ============================================================================
CREATE TABLE trailer_status_history (
    history_id BIGSERIAL PRIMARY KEY,
    trailer_id INTEGER NOT NULL REFERENCES trailers(trailer_id),
    terminal_id INTEGER REFERENCES terminals(terminal_id),
    user_id INTEGER REFERENCES users(user_id),

    -- Status information
    is_empty BOOLEAN NOT NULL,

    -- Location data
    latitude DECIMAL(10, 8),
    longitude DECIMAL(11, 8),
    -- For PostGIS (optional): location GEOGRAPHY(POINT, 4326),

    -- Photo storage
    photo_path VARCHAR(500),
    photo_content_type VARCHAR(50),
    photo_size_bytes BIGINT,
    photo_original_filename VARCHAR(255),

    -- Metadata
    notes TEXT,
    recorded_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,

    -- Constraints
    CONSTRAINT valid_coordinates CHECK (
        (latitude IS NULL AND longitude IS NULL) OR
        (latitude IS NOT NULL AND longitude IS NOT NULL AND
         latitude BETWEEN -90 AND 90 AND
         longitude BETWEEN -180 AND 180)
    ),
    CONSTRAINT photo_data_consistency CHECK (
        (photo_path IS NULL AND photo_content_type IS NULL AND photo_size_bytes IS NULL) OR
        (photo_path IS NOT NULL)
    )
);

-- Indexes for common query patterns
CREATE INDEX idx_trailer_status_trailer_id ON trailer_status_history(trailer_id);
CREATE INDEX idx_trailer_status_recorded_at ON trailer_status_history(recorded_at DESC);
CREATE INDEX idx_trailer_status_terminal ON trailer_status_history(terminal_id);
CREATE INDEX idx_trailer_status_empty ON trailer_status_history(is_empty);
CREATE INDEX idx_trailer_status_user ON trailer_status_history(user_id);

-- Composite indexes for common queries
CREATE INDEX idx_trailer_status_trailer_recorded ON trailer_status_history(trailer_id, recorded_at DESC);
CREATE INDEX idx_trailer_status_terminal_recorded ON trailer_status_history(terminal_id, recorded_at DESC);
CREATE INDEX idx_trailer_status_empty_recorded ON trailer_status_history(is_empty, recorded_at DESC);
CREATE INDEX idx_trailer_status_date_only ON trailer_status_history(DATE(recorded_at));

-- For photo queries
CREATE INDEX idx_trailer_status_has_photo ON trailer_status_history(trailer_id)
    WHERE photo_path IS NOT NULL;

COMMENT ON TABLE trailer_status_history IS 'Append-only history of all trailer status changes, locations, and photos';
COMMENT ON COLUMN trailer_status_history.recorded_at IS 'When the status was recorded (can be backfilled)';
COMMENT ON COLUMN trailer_status_history.created_at IS 'When the record was inserted into the database';
COMMENT ON COLUMN trailer_status_history.photo_path IS 'File system path or cloud storage URL for the photo';


-- ============================================================================
-- TABLE: photos
-- Optional separate table for photo storage if you prefer normalized approach
-- Use this if you want better photo management and metadata
-- ============================================================================
CREATE TABLE photos (
    photo_id BIGSERIAL PRIMARY KEY,
    history_id BIGINT REFERENCES trailer_status_history(history_id),
    trailer_id INTEGER NOT NULL REFERENCES trailers(trailer_id),

    -- File information
    file_path VARCHAR(500) NOT NULL,
    storage_type VARCHAR(20) DEFAULT 'filesystem' NOT NULL, -- 'filesystem', 's3', 'azure', etc.
    content_type VARCHAR(50) NOT NULL,
    file_size_bytes BIGINT NOT NULL,
    original_filename VARCHAR(255),

    -- Image metadata
    width_pixels INTEGER,
    height_pixels INTEGER,

    -- Hash for deduplication
    file_hash VARCHAR(64), -- SHA-256 hash

    -- Metadata
    uploaded_by INTEGER REFERENCES users(user_id),
    uploaded_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,

    CONSTRAINT valid_storage_type CHECK (storage_type IN ('filesystem', 's3', 'azure', 'gcs', 'blob')),
    CONSTRAINT valid_file_size CHECK (file_size_bytes > 0)
);

CREATE INDEX idx_photos_history ON photos(history_id);
CREATE INDEX idx_photos_trailer ON photos(trailer_id);
CREATE INDEX idx_photos_hash ON photos(file_hash);
CREATE INDEX idx_photos_uploaded ON photos(uploaded_at DESC);

COMMENT ON TABLE photos IS 'Normalized photo storage with metadata (optional alternative to storing in trailer_status_history)';


-- ============================================================================
-- TABLE: audit_log
-- System-wide audit trail for security and compliance
-- ============================================================================
CREATE TABLE audit_log (
    audit_id BIGSERIAL PRIMARY KEY,
    table_name VARCHAR(50) NOT NULL,
    record_id BIGINT NOT NULL,
    action VARCHAR(20) NOT NULL,
    user_id INTEGER REFERENCES users(user_id),
    changed_data JSONB,
    ip_address INET,
    user_agent TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,

    CONSTRAINT valid_action CHECK (action IN ('INSERT', 'UPDATE', 'DELETE', 'SELECT'))
);

CREATE INDEX idx_audit_table_record ON audit_log(table_name, record_id);
CREATE INDEX idx_audit_user ON audit_log(user_id);
CREATE INDEX idx_audit_created ON audit_log(created_at DESC);
CREATE INDEX idx_audit_action ON audit_log(action);

COMMENT ON TABLE audit_log IS 'System-wide audit trail for all important operations';


-- ============================================================================
-- VIEWS
-- Convenient views for common queries
-- ============================================================================

-- View: Latest status for each trailer
CREATE VIEW v_trailer_current_status AS
SELECT DISTINCT ON (t.trailer_id)
    t.trailer_id,
    t.trailer_number,
    t.license_plate,
    tsh.history_id,
    tsh.is_empty,
    term.terminal_code,
    term.terminal_name,
    tsh.latitude,
    tsh.longitude,
    tsh.photo_path,
    tsh.recorded_at,
    u.username as recorded_by,
    u.full_name as recorded_by_name
FROM trailers t
LEFT JOIN trailer_status_history tsh ON t.trailer_id = tsh.trailer_id
LEFT JOIN terminals term ON tsh.terminal_id = term.terminal_id
LEFT JOIN users u ON tsh.user_id = u.user_id
WHERE t.is_active = true
ORDER BY t.trailer_id, tsh.recorded_at DESC;

COMMENT ON VIEW v_trailer_current_status IS 'Shows the most recent status for each active trailer';


-- View: Trailer summary with statistics
CREATE VIEW v_trailer_summary AS
SELECT
    t.trailer_id,
    t.trailer_number,
    t.license_plate,
    t.description,
    t.is_active,
    COUNT(tsh.history_id) as total_status_changes,
    MAX(tsh.recorded_at) as last_updated,
    (SELECT is_empty FROM trailer_status_history
     WHERE trailer_id = t.trailer_id
     ORDER BY recorded_at DESC LIMIT 1) as current_empty_status,
    (SELECT terminal_code FROM trailer_status_history tsh2
     JOIN terminals term ON tsh2.terminal_id = term.terminal_id
     WHERE tsh2.trailer_id = t.trailer_id
     ORDER BY tsh2.recorded_at DESC LIMIT 1) as current_terminal
FROM trailers t
LEFT JOIN trailer_status_history tsh ON t.trailer_id = tsh.trailer_id
GROUP BY t.trailer_id;

COMMENT ON VIEW v_trailer_summary IS 'Summary statistics and current status for all trailers';


-- ============================================================================
-- FUNCTIONS
-- Useful stored procedures for common operations
-- ============================================================================

-- Function: Get last N entries for a trailer
CREATE OR REPLACE FUNCTION get_trailer_history(
    p_trailer_number VARCHAR,
    p_limit INTEGER DEFAULT 10
)
RETURNS TABLE (
    history_id BIGINT,
    trailer_number VARCHAR,
    terminal_code VARCHAR,
    is_empty BOOLEAN,
    latitude DECIMAL,
    longitude DECIMAL,
    photo_path VARCHAR,
    recorded_at TIMESTAMP WITH TIME ZONE,
    recorded_by VARCHAR
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        tsh.history_id,
        t.trailer_number,
        term.terminal_code,
        tsh.is_empty,
        tsh.latitude,
        tsh.longitude,
        tsh.photo_path,
        tsh.recorded_at,
        u.username as recorded_by
    FROM trailer_status_history tsh
    JOIN trailers t ON tsh.trailer_id = t.trailer_id
    LEFT JOIN terminals term ON tsh.terminal_id = term.terminal_id
    LEFT JOIN users u ON tsh.user_id = u.user_id
    WHERE t.trailer_number = p_trailer_number
    ORDER BY tsh.recorded_at DESC
    LIMIT p_limit;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION get_trailer_history IS 'Retrieves the last N status entries for a specific trailer';


-- Function: Insert trailer status (with automatic trailer creation if needed)
CREATE OR REPLACE FUNCTION insert_trailer_status(
    p_trailer_number VARCHAR,
    p_license_plate VARCHAR,
    p_terminal_code VARCHAR,
    p_is_empty BOOLEAN,
    p_latitude DECIMAL DEFAULT NULL,
    p_longitude DECIMAL DEFAULT NULL,
    p_photo_path VARCHAR DEFAULT NULL,
    p_photo_content_type VARCHAR DEFAULT NULL,
    p_photo_size_bytes BIGINT DEFAULT NULL,
    p_user_id INTEGER DEFAULT NULL,
    p_notes TEXT DEFAULT NULL
)
RETURNS BIGINT AS $$
DECLARE
    v_trailer_id INTEGER;
    v_terminal_id INTEGER;
    v_history_id BIGINT;
BEGIN
    -- Get or create trailer
    SELECT trailer_id INTO v_trailer_id
    FROM trailers
    WHERE trailer_number = p_trailer_number;

    IF v_trailer_id IS NULL THEN
        INSERT INTO trailers (trailer_number, license_plate)
        VALUES (p_trailer_number, p_license_plate)
        RETURNING trailer_id INTO v_trailer_id;
    END IF;

    -- Get terminal ID
    SELECT terminal_id INTO v_terminal_id
    FROM terminals
    WHERE terminal_code = p_terminal_code AND is_active = true;

    -- Insert status history
    INSERT INTO trailer_status_history (
        trailer_id,
        terminal_id,
        user_id,
        is_empty,
        latitude,
        longitude,
        photo_path,
        photo_content_type,
        photo_size_bytes,
        notes
    ) VALUES (
        v_trailer_id,
        v_terminal_id,
        p_user_id,
        p_is_empty,
        p_latitude,
        p_longitude,
        p_photo_path,
        p_photo_content_type,
        p_photo_size_bytes,
        p_notes
    )
    RETURNING history_id INTO v_history_id;

    RETURN v_history_id;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION insert_trailer_status IS 'Inserts a new trailer status entry, creating the trailer if it does not exist';


-- Function: Update timestamp trigger
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;


-- ============================================================================
-- TRIGGERS
-- Automatic timestamp updates
-- ============================================================================

CREATE TRIGGER trigger_users_updated_at
    BEFORE UPDATE ON users
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trigger_terminals_updated_at
    BEFORE UPDATE ON terminals
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trigger_trailers_updated_at
    BEFORE UPDATE ON trailers
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();


-- ============================================================================
-- SAMPLE QUERIES
-- ============================================================================

/*
-- Query 1: Get last 10 entries for a specific trailer
SELECT * FROM get_trailer_history('TRAILER-001', 10);

-- Query 2: Find all empty trailers at terminal B1
SELECT
    t.trailer_number,
    tsh.recorded_at,
    term.terminal_code
FROM trailer_status_history tsh
JOIN trailers t ON tsh.trailer_id = t.trailer_id
JOIN terminals term ON tsh.terminal_id = term.terminal_id
WHERE tsh.history_id IN (
    SELECT DISTINCT ON (trailer_id) history_id
    FROM trailer_status_history
    ORDER BY trailer_id, recorded_at DESC
)
AND tsh.is_empty = true
AND term.terminal_code = 'B1';

-- Query 3: Get all status changes for a date range
SELECT
    t.trailer_number,
    term.terminal_code,
    tsh.is_empty,
    tsh.recorded_at,
    u.username
FROM trailer_status_history tsh
JOIN trailers t ON tsh.trailer_id = t.trailer_id
LEFT JOIN terminals term ON tsh.terminal_id = term.terminal_id
LEFT JOIN users u ON tsh.user_id = u.user_id
WHERE tsh.recorded_at >= '2025-01-01'
  AND tsh.recorded_at < '2025-02-01'
ORDER BY tsh.recorded_at DESC;

-- Query 4: Get trailer activity summary by terminal
SELECT
    term.terminal_code,
    COUNT(*) as total_entries,
    COUNT(*) FILTER (WHERE tsh.is_empty = true) as empty_entries,
    COUNT(*) FILTER (WHERE tsh.is_empty = false) as loaded_entries,
    COUNT(DISTINCT tsh.trailer_id) as unique_trailers,
    MAX(tsh.recorded_at) as last_activity
FROM trailer_status_history tsh
JOIN terminals term ON tsh.terminal_id = term.terminal_id
WHERE tsh.recorded_at >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY term.terminal_code
ORDER BY total_entries DESC;

-- Query 5: Insert a new status entry
SELECT insert_trailer_status(
    'TRAILER-001',
    'ABC-123',
    'B1',
    false,
    59.329323,
    18.068581,
    '/photos/2025/12/10/trailer-001-1733826000.jpg',
    'image/jpeg',
    2457600,
    1,
    'Loaded with pallets'
);
*/


-- ============================================================================
-- GRANTS (adjust based on your user roles)
-- ============================================================================

/*
-- Example: Create application user with appropriate permissions
CREATE USER trailer_app WITH PASSWORD 'your_secure_password';

GRANT CONNECT ON DATABASE your_database TO trailer_app;
GRANT USAGE ON SCHEMA public TO trailer_app;

-- Read/write access to main tables
GRANT SELECT, INSERT ON users, trailers, trailer_status_history, photos TO trailer_app;
GRANT SELECT ON terminals TO trailer_app;
GRANT SELECT, INSERT ON audit_log TO trailer_app;

-- Sequence access
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO trailer_app;

-- Function access
GRANT EXECUTE ON FUNCTION get_trailer_history TO trailer_app;
GRANT EXECUTE ON FUNCTION insert_trailer_status TO trailer_app;

-- View access
GRANT SELECT ON v_trailer_current_status, v_trailer_summary TO trailer_app;
*/


-- ============================================================================
-- MAINTENANCE QUERIES
-- ============================================================================

/*
-- Analyze table statistics for query optimization
ANALYZE users;
ANALYZE trailers;
ANALYZE trailer_status_history;
ANALYZE terminals;
ANALYZE photos;

-- Check index usage
SELECT
    schemaname,
    tablename,
    indexname,
    idx_scan as index_scans,
    idx_tup_read as tuples_read,
    idx_tup_fetch as tuples_fetched
FROM pg_stat_user_indexes
WHERE schemaname = 'public'
ORDER BY idx_scan DESC;

-- Check table sizes
SELECT
    schemaname,
    tablename,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS size
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;
*/
