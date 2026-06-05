# Trailer Management System - Database Design Documentation

## Table of Contents
1. [Overview](#overview)
2. [Database Recommendation](#database-recommendation)
3. [Schema Design](#schema-design)
4. [Design Decisions](#design-decisions)
5. [Indexing Strategy](#indexing-strategy)
6. [Performance Considerations](#performance-considerations)
7. [Scalability](#scalability)
8. [Photo Storage Strategy](#photo-storage-strategy)
9. [Query Patterns](#query-patterns)
10. [Backup and Maintenance](#backup-and-maintenance)

---

## Overview

This database schema is designed for a trailer management system that tracks trailer locations, status changes, and photos across multiple terminals with multiple concurrent users. The system is designed as **append-only** to maintain a complete historical record of all changes.

### Key Features
- Complete historical tracking (append-only architecture)
- Multi-user support with audit trails
- Efficient querying by date, trailer, status, and terminal
- Photo storage with metadata
- Production-ready with proper constraints and indexes
- Scalable for concurrent access

---

## Database Recommendation

### Primary Recommendation: **PostgreSQL 12+**

#### Why PostgreSQL?

1. **Advanced Data Types**
   - Native support for `DECIMAL` for precise GPS coordinates
   - `JSONB` for flexible metadata storage
   - `TIMESTAMP WITH TIME ZONE` for proper timezone handling
   - Optional `GEOGRAPHY` type via PostGIS for spatial queries

2. **Performance Features**
   - Excellent indexing capabilities (B-tree, GiST, GIN, BRIN)
   - Materialized views for caching complex queries
   - Partial indexes (e.g., `WHERE is_active = true`)
   - Query parallelization for large datasets

3. **ACID Compliance**
   - Full transaction support
   - Perfect for append-only architecture
   - Row-level locking for concurrent access

4. **Scalability**
   - Handles millions of rows efficiently
   - Partitioning support for time-series data
   - Replication for high availability

5. **Ecosystem**
   - Excellent ORMs (SQLAlchemy, Django ORM, TypeORM)
   - Great mobile app libraries (PostgREST, Supabase)
   - Strong community support

#### Alternative Options

**MySQL 8.0+**
- Pros: Simpler setup, good performance, wide hosting availability
- Cons: Less advanced geospatial support, limited partial indexes
- **Use if:** You need simpler deployment or your team is more familiar with MySQL

**SQLite**
- Pros: Zero-configuration, embedded, good for small deployments
- Cons: Limited concurrency, no built-in replication
- **Use only if:** Single-user or very small deployments (not recommended for production)

---

## Schema Design

### Entity Relationship Diagram (Textual)

```
users (1) -----> (*) trailer_status_history
trailers (1) ---> (*) trailer_status_history
terminals (1) --> (*) trailer_status_history
trailer_status_history (1) ---> (*) photos [optional]
```

### Core Tables

#### 1. **users**
Stores user authentication and profile information.

**Key Fields:**
- `user_id`: Primary key (auto-increment)
- `username`: Unique login identifier
- `email`: Unique email address
- `is_active`: Soft delete flag

**Design Notes:**
- Soft deletes preserve referential integrity in history
- Email validation via CHECK constraint
- Indexed on username and email for login queries

#### 2. **terminals**
Reference table for terminal locations (B1, B3, etc.)

**Key Fields:**
- `terminal_id`: Primary key
- `terminal_code`: Unique short code (e.g., 'B1', 'B3')
- `default_latitude/longitude`: Optional default coordinates

**Design Notes:**
- Pre-populated with B1 and B3
- Easily extensible for new terminals
- Terminal code enforced as uppercase

#### 3. **trailers**
Master table for trailer registration (relatively static data)

**Key Fields:**
- `trailer_id`: Primary key
- `trailer_number`: Internal tracking number (unique)
- `license_plate`: Official license plate (unique)

**Design Notes:**
- Separates static trailer info from dynamic status
- Reduces data redundancy
- Supports additional metadata (make, model, year)

#### 4. **trailer_status_history** (CORE TABLE)
Append-only history of all trailer status changes.

**Key Fields:**
- `history_id`: Primary key (BIGSERIAL for large scale)
- `trailer_id`: Foreign key to trailers
- `terminal_id`: Foreign key to terminals
- `user_id`: Foreign key to users (who recorded this)
- `is_empty`: Boolean status
- `latitude/longitude`: GPS coordinates
- `photo_path`: File path or URL to photo
- `recorded_at`: When the status was recorded
- `created_at`: When the record was inserted

**Design Notes:**
- **BIGSERIAL** used for primary key (supports billions of records)
- **Two timestamps**: `recorded_at` (business time) vs `created_at` (system time)
- Photo metadata embedded (path, size, content type)
- GPS coordinate validation via CHECK constraint
- This is the heart of the append-only architecture

#### 5. **photos** (Optional)
Normalized photo storage if you prefer separation.

**Key Fields:**
- `photo_id`: Primary key
- `history_id`: Links back to status entry
- `file_path`: Storage location
- `storage_type`: filesystem, S3, Azure, etc.
- `file_hash`: SHA-256 for deduplication

**Design Notes:**
- Use if you want advanced photo management
- Enables deduplication via hash
- Tracks storage backend
- Can be omitted if you prefer embedded photo data in `trailer_status_history`

#### 6. **audit_log**
System-wide audit trail for compliance.

**Key Fields:**
- `audit_id`: Primary key
- `table_name/record_id`: Which record was affected
- `action`: INSERT, UPDATE, DELETE, SELECT
- `changed_data`: JSONB with before/after values
- `ip_address`: Client IP (INET type)

**Design Notes:**
- Captures all sensitive operations
- JSONB allows flexible metadata
- Can be triggered automatically or manually

---

## Design Decisions

### 1. Append-Only Architecture

**Decision:** All status changes are stored as new rows in `trailer_status_history`.

**Rationale:**
- Complete audit trail of all changes
- No data loss
- Temporal queries (what was the status on date X?)
- Simplifies concurrent access (no UPDATE conflicts)
- Legal/compliance friendly

**Implementation:**
- Never UPDATE or DELETE from `trailer_status_history`
- Only INSERT operations
- Use views (`v_trailer_current_status`) for "current state" queries

### 2. Separation of Static and Dynamic Data

**Decision:** Trailer master data (trailers table) separate from status history.

**Rationale:**
- Reduces redundancy (trailer number not repeated millions of times)
- Clearer data model
- Easier to update static info (make, model) without touching history
- Better query performance (smaller indexes)

### 3. Terminal Reference Table

**Decision:** Terminals stored in separate table with foreign key.

**Rationale:**
- Easy to add new terminals
- Consistent terminal naming
- Can store terminal-specific metadata (default GPS, description)
- Saves space vs storing "B1" string millions of times

### 4. Two Timestamp Columns

**Decision:** Both `recorded_at` and `created_at` in history table.

**Rationale:**
- `recorded_at`: Business timestamp (when user took the photo/reading)
- `created_at`: System timestamp (when inserted to database)
- Supports backfilling data
- Enables detecting sync delays (mobile app offline, then syncs later)

### 5. Photo Storage Strategy

**Decision:** Store file path, not BLOB, with optional normalized photos table.

**Rationale:**
- **File path approach is better for:**
  - Performance (database not bloated)
  - Backup/restore flexibility
  - Serving files (CDN, direct file serving)
  - Cost (storage cheaper than database)
- **BLOB approach only if:**
  - You need ACID guarantees for photos
  - Small images only
  - Simple deployment (no file server)

**Recommended Storage:**
1. **Cloud Storage (Best)**: AWS S3, Azure Blob, Google Cloud Storage
   - Scalable, redundant, cheap
   - CDN integration
   - Store path like: `s3://bucket-name/photos/2025/12/10/trailer-001-1733826000.jpg`

2. **Local Filesystem (Development)**: Store photos in organized directory structure
   - Store path like: `/var/trailers/photos/2025/12/10/trailer-001-1733826000.jpg`

3. **Database BLOB (Not Recommended)**: Only for small deployments
   - Add column: `photo_blob BYTEA`
   - Limit size with CHECK constraint

### 6. GPS Coordinate Storage

**Decision:** Two DECIMAL columns for lat/lon.

**Rationale:**
- `DECIMAL(10, 8)` for latitude: supports 8 decimal places (~1mm precision)
- `DECIMAL(11, 8)` for longitude: accounts for -180 to +180 range
- Alternative: PostGIS `GEOGRAPHY(POINT, 4326)` for advanced spatial queries

**When to use PostGIS:**
- Need radius searches ("find all trailers within 5km")
- Distance calculations
- Complex geospatial analytics
- Adds complexity, so only use if needed

### 7. Soft Deletes

**Decision:** `is_active` flags instead of DELETE operations.

**Rationale:**
- Preserves referential integrity in history
- Allows "undelete" operations
- Maintains audit trail
- Can still query historical data

### 8. User Authentication Storage

**Decision:** Minimal user table (username, email).

**Rationale:**
- Authentication should be handled by external service (Auth0, Keycloak, Firebase Auth)
- This table just stores user references for audit trails
- Don't store passwords here (use dedicated auth service)

---

## Indexing Strategy

### Indexes Explained

#### 1. Primary Key Indexes (Automatic)
```sql
-- Automatically created on PRIMARY KEY columns
trailers(trailer_id)
trailer_status_history(history_id)
users(user_id)
terminals(terminal_id)
```

#### 2. Foreign Key Indexes
```sql
-- Essential for JOIN performance
CREATE INDEX idx_trailer_status_trailer_id ON trailer_status_history(trailer_id);
CREATE INDEX idx_trailer_status_terminal ON trailer_status_history(terminal_id);
CREATE INDEX idx_trailer_status_user ON trailer_status_history(user_id);
```

**Why:** Foreign keys are heavily used in JOINs. Without indexes, JOINs do full table scans.

#### 3. Query-Specific Indexes

**Date Range Queries:**
```sql
CREATE INDEX idx_trailer_status_recorded_at ON trailer_status_history(recorded_at DESC);
```
- DESC ordering optimizes "most recent first" queries
- Essential for time-series queries

**Status Queries:**
```sql
CREATE INDEX idx_trailer_status_empty ON trailer_status_history(is_empty);
```
- Fast filtering by empty/loaded status

**Date-Only Queries:**
```sql
CREATE INDEX idx_trailer_status_date_only ON trailer_status_history(DATE(recorded_at));
```
- Optimizes "all entries on date X" queries
- Extracts just the date portion

#### 4. Composite Indexes

**Trailer + Date:**
```sql
CREATE INDEX idx_trailer_status_trailer_recorded
ON trailer_status_history(trailer_id, recorded_at DESC);
```
- Optimizes: "last N entries for trailer X"
- Most common query pattern
- Single index serves multiple conditions

**Terminal + Date:**
```sql
CREATE INDEX idx_trailer_status_terminal_recorded
ON trailer_status_history(terminal_id, recorded_at DESC);
```
- Optimizes: "recent activity at terminal B1"

**Empty Status + Date:**
```sql
CREATE INDEX idx_trailer_status_empty_recorded
ON trailer_status_history(is_empty, recorded_at DESC);
```
- Optimizes: "all empty trailers, most recent first"

#### 5. Partial Indexes (PostgreSQL Feature)

**Active Users Only:**
```sql
CREATE INDEX idx_users_username ON users(username)
WHERE is_active = true;
```
- Smaller index (only active users)
- Faster queries for common case
- Reduces index maintenance overhead

**Entries with Photos:**
```sql
CREATE INDEX idx_trailer_status_has_photo ON trailer_status_history(trailer_id)
WHERE photo_path IS NOT NULL;
```
- Optimizes: "find all photos for trailer X"
- Much smaller than full index

#### 6. Unique Indexes (Automatic)
```sql
-- Automatically created on UNIQUE columns
trailers(trailer_number)
trailers(license_plate)
users(username)
users(email)
```

### Index Maintenance

**Monitor Index Usage:**
```sql
SELECT
    schemaname,
    tablename,
    indexname,
    idx_scan as times_used,
    pg_size_pretty(pg_relation_size(indexrelid)) as index_size
FROM pg_stat_user_indexes
WHERE schemaname = 'public'
ORDER BY idx_scan ASC;
```

**Remove Unused Indexes:**
- Indexes with `idx_scan = 0` and old enough (1+ months) can be dropped
- Each index slows down INSERT/UPDATE operations
- Balance between read and write performance

**Reindex Periodically:**
```sql
REINDEX TABLE trailer_status_history;
```
- Rebuilds indexes to remove bloat
- Run during maintenance windows (locks table)

---

## Performance Considerations

### 1. Query Optimization

**Use EXPLAIN ANALYZE:**
```sql
EXPLAIN ANALYZE
SELECT * FROM trailer_status_history
WHERE trailer_id = 123
ORDER BY recorded_at DESC
LIMIT 10;
```
- Shows actual execution plan
- Identifies missing indexes
- Reveals sequential scans (bad for large tables)

**Optimize Common Queries:**

```sql
-- GOOD: Uses composite index
SELECT * FROM trailer_status_history
WHERE trailer_id = 123
ORDER BY recorded_at DESC
LIMIT 10;

-- BAD: Forces index scan + sort
SELECT * FROM trailer_status_history
WHERE trailer_id = 123
ORDER BY created_at DESC  -- Different column!
LIMIT 10;
```

### 2. Connection Pooling

**Problem:** Opening/closing database connections is expensive.

**Solution:** Use connection pooling:
- **PgBouncer** (PostgreSQL): Connection pool manager
- **Application-level**: SQLAlchemy pool, HikariCP (Java)
- Recommended pool size: `(number_of_cores * 2) + effective_spindle_count`

Example (Python/SQLAlchemy):
```python
from sqlalchemy import create_engine

engine = create_engine(
    'postgresql://user:pass@localhost/trailers',
    pool_size=10,
    max_overflow=20,
    pool_pre_ping=True  # Verify connections before use
)
```

### 3. Batch Operations

**For Bulk Inserts:**
```sql
-- GOOD: Single transaction, multiple rows
INSERT INTO trailer_status_history (trailer_id, is_empty, recorded_at)
VALUES
    (1, true, NOW()),
    (2, false, NOW()),
    (3, true, NOW());

-- BAD: Multiple transactions
INSERT INTO trailer_status_history (trailer_id, is_empty, recorded_at)
VALUES (1, true, NOW());
INSERT INTO trailer_status_history (trailer_id, is_empty, recorded_at)
VALUES (2, false, NOW());
-- ... etc
```

**Mobile App Sync:**
- Queue entries locally (SQLite on device)
- Sync in batches (e.g., every 10 entries or every 5 minutes)
- Use transactions for atomic batch commits

### 4. Partitioning (For Large Scale)

**When to Partition:**
- Table exceeds 100GB
- Queries typically filter by date
- Want to drop old data easily

**Example (Time-Based Partitioning):**
```sql
-- Convert to partitioned table
CREATE TABLE trailer_status_history_partitioned (
    LIKE trailer_status_history INCLUDING ALL
) PARTITION BY RANGE (recorded_at);

-- Create monthly partitions
CREATE TABLE trailer_status_history_2025_01
    PARTITION OF trailer_status_history_partitioned
    FOR VALUES FROM ('2025-01-01') TO ('2025-02-01');

CREATE TABLE trailer_status_history_2025_02
    PARTITION OF trailer_status_history_partitioned
    FOR VALUES FROM ('2025-02-01') TO ('2025-03-01');
-- ... etc
```

**Benefits:**
- Query only relevant partitions (partition pruning)
- Drop old partitions instead of DELETE (instant, no bloat)
- Better vacuum performance

### 5. Vacuum and Analyze

**PostgreSQL Maintenance:**
```sql
-- Update statistics (run weekly)
ANALYZE trailer_status_history;

-- Reclaim space (run monthly)
VACUUM trailer_status_history;

-- Full vacuum (run yearly, requires downtime)
VACUUM FULL trailer_status_history;
```

**Autovacuum Configuration:**
```ini
# postgresql.conf
autovacuum = on
autovacuum_max_workers = 3
autovacuum_naptime = 1min
```

---

## Scalability

### Horizontal Scaling (Multiple Database Servers)

#### 1. Read Replicas
```
[Mobile App] --write--> [Primary DB]
                            |
                            +-- replicate --> [Read Replica 1] <-- read queries
                            +-- replicate --> [Read Replica 2] <-- read queries
```

**Setup:**
- Primary handles writes
- Replicas handle read queries
- Reduces load on primary
- Near real-time replication (few ms lag)

**Implementation (PostgreSQL):**
- Built-in streaming replication
- Or use managed services (AWS RDS Multi-AZ, Azure Database)

#### 2. Sharding (Advanced)

**By Terminal:**
```
DB1: Terminal B1 data
DB2: Terminal B3 data
```

**By Trailer ID Range:**
```
DB1: trailer_id 1-100000
DB2: trailer_id 100001-200000
```

**Only needed if:**
- Single database can't handle load
- Typically 10M+ rows, 1000+ queries/sec

### Vertical Scaling (Bigger Server)

**Recommended Specs:**

**Small Deployment (< 100 trailers):**
- CPU: 2 cores
- RAM: 4GB
- Storage: 50GB SSD

**Medium Deployment (100-1000 trailers):**
- CPU: 4-8 cores
- RAM: 16-32GB
- Storage: 500GB SSD

**Large Deployment (1000+ trailers):**
- CPU: 16+ cores
- RAM: 64-128GB
- Storage: 1-2TB SSD (NVMe preferred)

### Caching Strategy

**Application-Level Cache (Redis/Memcached):**

```python
# Pseudo-code
def get_trailer_current_status(trailer_id):
    cache_key = f"trailer:{trailer_id}:status"

    # Check cache first
    cached = redis.get(cache_key)
    if cached:
        return cached

    # Query database
    status = db.query(...)

    # Cache for 5 minutes
    redis.setex(cache_key, 300, status)
    return status
```

**What to Cache:**
- Current status for each trailer (invalidate on new insert)
- Terminal list (rarely changes)
- User profiles (rarely change)

**What NOT to Cache:**
- Historical queries (too variable)
- Reports (usually ad-hoc)

### Materialized Views (PostgreSQL)

**For Complex Reports:**
```sql
CREATE MATERIALIZED VIEW mv_daily_terminal_activity AS
SELECT
    DATE(recorded_at) as activity_date,
    terminal_id,
    COUNT(*) as total_entries,
    COUNT(DISTINCT trailer_id) as unique_trailers,
    COUNT(*) FILTER (WHERE is_empty = true) as empty_count,
    COUNT(*) FILTER (WHERE is_empty = false) as loaded_count
FROM trailer_status_history
GROUP BY DATE(recorded_at), terminal_id;

-- Create index on materialized view
CREATE INDEX idx_mv_daily_terminal_date
ON mv_daily_terminal_activity(activity_date DESC);

-- Refresh periodically (e.g., nightly)
REFRESH MATERIALIZED VIEW mv_daily_terminal_activity;
```

**Benefits:**
- Pre-computed results (instant queries)
- No real-time computation overhead
- Great for dashboards and reports

---

## Photo Storage Strategy

### Option 1: Cloud Storage (RECOMMENDED)

**AWS S3 Example:**

**Directory Structure:**
```
s3://trailer-photos-bucket/
    2025/
        01/
            10/
                trailer-ABC123-1704873600-uuid.jpg
                trailer-ABC123-1704877200-uuid.jpg
        02/
            15/
                trailer-XYZ789-1708012800-uuid.jpg
```

**File Naming Convention:**
```
{trailer_number}-{unix_timestamp}-{uuid}.{extension}

Example: trailer-ABC123-1704873600-a1b2c3d4.jpg
```

**Application Flow:**
```
1. Mobile app takes photo
2. Upload to S3 (direct from mobile or via backend)
3. S3 returns URL: https://bucket.s3.amazonaws.com/2025/01/10/trailer-ABC123-1704873600-uuid.jpg
4. Store URL in database (photo_path column)
5. Serve photos via CloudFront CDN (fast worldwide access)
```

**Advantages:**
- Virtually unlimited storage
- CDN integration (fast global access)
- Automatic redundancy (11 9's durability)
- Cheap ($0.023/GB/month)
- No database bloat

**Security:**
- Use pre-signed URLs for access control
- Bucket policy restricts public access
- Photos only accessible via your app

**Code Example (Python/boto3):**
```python
import boto3
from datetime import datetime

s3 = boto3.client('s3')

def upload_trailer_photo(trailer_number, photo_file):
    # Generate unique filename
    timestamp = int(datetime.now().timestamp())
    filename = f"{trailer_number}-{timestamp}.jpg"

    # Organize by date
    date_prefix = datetime.now().strftime('%Y/%m/%d')
    s3_key = f"{date_prefix}/{filename}"

    # Upload to S3
    s3.upload_fileobj(
        photo_file,
        'trailer-photos-bucket',
        s3_key,
        ExtraArgs={'ContentType': 'image/jpeg'}
    )

    # Return S3 URL to store in database
    return f"s3://trailer-photos-bucket/{s3_key}"

def generate_presigned_url(s3_path, expiration=3600):
    """Generate temporary URL for accessing photo"""
    bucket, key = s3_path.replace('s3://', '').split('/', 1)

    url = s3.generate_presigned_url(
        'get_object',
        Params={'Bucket': bucket, 'Key': key},
        ExpiresIn=expiration
    )
    return url
```

### Option 2: Local Filesystem

**Directory Structure:**
```
/var/trailers/photos/
    2025/
        01/
            10/
                trailer-ABC123-1704873600.jpg
        02/
            15/
                trailer-XYZ789-1708012800.jpg
```

**Advantages:**
- Simple setup
- No cloud costs
- Full control

**Disadvantages:**
- Must manage backups
- No built-in redundancy
- Harder to scale (need network storage)
- Manual CDN setup

**Configuration:**
```nginx
# Nginx config for serving photos
location /photos/ {
    alias /var/trailers/photos/;
    expires 1y;
    add_header Cache-Control "public, immutable";

    # Optional: Require authentication
    auth_request /api/auth/verify;
}
```

### Option 3: Database BLOB (NOT RECOMMENDED)

**Only use if:**
- Very small deployment (< 100 trailers)
- Simple deployment requirements
- Photos are small (< 100KB each)

**Implementation:**
```sql
ALTER TABLE trailer_status_history ADD COLUMN photo_blob BYTEA;

-- Add size constraint (e.g., max 5MB)
ALTER TABLE trailer_status_history ADD CONSTRAINT photo_size_limit
CHECK (photo_blob IS NULL OR octet_length(photo_blob) <= 5242880);
```

**Disadvantages:**
- Database size explodes
- Slow backups/restores
- No CDN caching
- Higher database costs
- Slower queries (photo data loaded even when not needed)

### Photo Processing

**Recommended Workflow:**

1. **On Upload:**
   - Validate file type (JPEG, PNG only)
   - Validate file size (< 10MB)
   - Generate thumbnail (200x200)
   - Extract EXIF data (GPS, timestamp)
   - Compress (e.g., 80% JPEG quality)

2. **Store Multiple Versions:**
   ```
   photos/
       original/
           trailer-ABC123-1704873600.jpg  (full size, 3MB)
       large/
           trailer-ABC123-1704873600.jpg  (1920x1080, 500KB)
       thumbnail/
           trailer-ABC123-1704873600.jpg  (200x200, 20KB)
   ```

3. **Update Database:**
   ```sql
   INSERT INTO trailer_status_history (..., photo_path, ...)
   VALUES (..., 's3://bucket/photos/original/trailer-ABC123-1704873600.jpg', ...);
   ```

**Image Processing Libraries:**
- Python: Pillow, ImageMagick
- Node.js: Sharp, Jimp
- Java: ImageIO, Thumbnailator

---

## Query Patterns

### Common Queries with Optimizations

#### 1. Last 10 Entries for a Trailer

**Using Function (Recommended):**
```sql
SELECT * FROM get_trailer_history('TRAILER-001', 10);
```

**Direct Query:**
```sql
SELECT
    tsh.history_id,
    tsh.is_empty,
    term.terminal_code,
    tsh.latitude,
    tsh.longitude,
    tsh.photo_path,
    tsh.recorded_at,
    u.username
FROM trailer_status_history tsh
JOIN trailers t ON tsh.trailer_id = t.trailer_id
LEFT JOIN terminals term ON tsh.terminal_id = term.terminal_id
LEFT JOIN users u ON tsh.user_id = u.user_id
WHERE t.trailer_number = 'TRAILER-001'
ORDER BY tsh.recorded_at DESC
LIMIT 10;
```

**Index Used:** `idx_trailer_status_trailer_recorded` (trailer_id, recorded_at DESC)

#### 2. Current Status for All Trailers

**Using View (Recommended):**
```sql
SELECT * FROM v_trailer_current_status
WHERE is_active = true
ORDER BY trailer_number;
```

**Direct Query (with DISTINCT ON):**
```sql
SELECT DISTINCT ON (t.trailer_id)
    t.trailer_number,
    t.license_plate,
    tsh.is_empty,
    term.terminal_code,
    tsh.recorded_at
FROM trailers t
LEFT JOIN trailer_status_history tsh ON t.trailer_id = tsh.trailer_id
LEFT JOIN terminals term ON tsh.terminal_id = term.terminal_id
WHERE t.is_active = true
ORDER BY t.trailer_id, tsh.recorded_at DESC;
```

**Performance:** `DISTINCT ON` is PostgreSQL-specific but very efficient.

#### 3. Empty Trailers at Terminal B1

```sql
WITH latest_status AS (
    SELECT DISTINCT ON (trailer_id)
        trailer_id,
        is_empty,
        terminal_id,
        recorded_at
    FROM trailer_status_history
    ORDER BY trailer_id, recorded_at DESC
)
SELECT
    t.trailer_number,
    t.license_plate,
    ls.recorded_at as last_seen
FROM latest_status ls
JOIN trailers t ON ls.trailer_id = t.trailer_id
JOIN terminals term ON ls.terminal_id = term.terminal_id
WHERE ls.is_empty = true
  AND term.terminal_code = 'B1'
  AND t.is_active = true
ORDER BY t.trailer_number;
```

**Index Used:** Composite indexes on trailer_status_history

#### 4. Activity for Date Range

```sql
SELECT
    t.trailer_number,
    term.terminal_code,
    tsh.is_empty,
    tsh.latitude,
    tsh.longitude,
    tsh.recorded_at,
    u.username
FROM trailer_status_history tsh
JOIN trailers t ON tsh.trailer_id = t.trailer_id
LEFT JOIN terminals term ON tsh.terminal_id = term.terminal_id
LEFT JOIN users u ON tsh.user_id = u.user_id
WHERE tsh.recorded_at >= '2025-01-01 00:00:00+00'
  AND tsh.recorded_at < '2025-02-01 00:00:00+00'
ORDER BY tsh.recorded_at DESC;
```

**Index Used:** `idx_trailer_status_recorded_at`

**For Single Date:**
```sql
WHERE DATE(tsh.recorded_at) = '2025-01-15'
```
**Index Used:** `idx_trailer_status_date_only`

#### 5. Terminal Activity Summary

```sql
SELECT
    term.terminal_code,
    term.terminal_name,
    COUNT(*) as total_entries,
    COUNT(*) FILTER (WHERE tsh.is_empty = true) as empty_entries,
    COUNT(*) FILTER (WHERE tsh.is_empty = false) as loaded_entries,
    COUNT(DISTINCT tsh.trailer_id) as unique_trailers,
    MIN(tsh.recorded_at) as first_activity,
    MAX(tsh.recorded_at) as last_activity
FROM trailer_status_history tsh
JOIN terminals term ON tsh.terminal_id = term.terminal_id
WHERE tsh.recorded_at >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY term.terminal_id, term.terminal_code, term.terminal_name
ORDER BY total_entries DESC;
```

**Performance:** For frequently run reports, consider materialized view.

#### 6. Trailer Utilization Report

```sql
WITH trailer_stats AS (
    SELECT
        trailer_id,
        COUNT(*) as total_entries,
        MIN(recorded_at) as first_seen,
        MAX(recorded_at) as last_seen,
        COUNT(*) FILTER (WHERE is_empty = true) as empty_count,
        COUNT(*) FILTER (WHERE is_empty = false) as loaded_count
    FROM trailer_status_history
    WHERE recorded_at >= CURRENT_DATE - INTERVAL '90 days'
    GROUP BY trailer_id
)
SELECT
    t.trailer_number,
    t.license_plate,
    ts.total_entries,
    ts.first_seen,
    ts.last_seen,
    ts.empty_count,
    ts.loaded_count,
    ROUND(100.0 * ts.loaded_count / NULLIF(ts.total_entries, 0), 2) as utilization_pct,
    EXTRACT(EPOCH FROM (ts.last_seen - ts.first_seen)) / 86400 as active_days
FROM trailer_stats ts
JOIN trailers t ON ts.trailer_id = t.trailer_id
WHERE t.is_active = true
ORDER BY utilization_pct DESC;
```

#### 7. Photo History for Trailer

```sql
SELECT
    tsh.photo_path,
    tsh.photo_content_type,
    tsh.photo_size_bytes,
    tsh.is_empty,
    term.terminal_code,
    tsh.recorded_at,
    u.username as taken_by
FROM trailer_status_history tsh
JOIN trailers t ON tsh.trailer_id = t.trailer_id
LEFT JOIN terminals term ON tsh.terminal_id = term.terminal_id
LEFT JOIN users u ON tsh.user_id = u.user_id
WHERE t.trailer_number = 'TRAILER-001'
  AND tsh.photo_path IS NOT NULL
ORDER BY tsh.recorded_at DESC;
```

**Index Used:** `idx_trailer_status_has_photo` (partial index)

---

## Backup and Maintenance

### Backup Strategy

#### 1. PostgreSQL Backup Methods

**A. Logical Backup (pg_dump)**
```bash
# Full database backup
pg_dump -h localhost -U postgres -d trailers -F c -f trailers_backup_$(date +%Y%m%d).dump

# Compressed backup
pg_dump -h localhost -U postgres -d trailers | gzip > trailers_backup_$(date +%Y%m%d).sql.gz

# Table-specific backup
pg_dump -h localhost -U postgres -d trailers -t trailer_status_history -F c -f history_backup.dump
```

**Restore:**
```bash
pg_restore -h localhost -U postgres -d trailers -c trailers_backup_20251210.dump
```

**B. Physical Backup (pg_basebackup)**
```bash
# Full cluster backup
pg_basebackup -h localhost -U postgres -D /backup/pg_base -Ft -z -P
```

**C. Continuous Archiving (WAL Archiving)**
```ini
# postgresql.conf
wal_level = replica
archive_mode = on
archive_command = 'cp %p /backup/wal_archive/%f'
```

**Benefits:** Point-in-time recovery (PITR)

#### 2. Backup Schedule

**Recommended:**
- **Full backup:** Daily (automated)
- **Incremental/WAL:** Continuous
- **Long-term retention:** Weekly (keep for 1 year)
- **Test restores:** Monthly

**Automation (cron):**
```bash
# /etc/cron.d/trailers-backup
# Daily full backup at 2 AM
0 2 * * * postgres /usr/local/bin/backup_trailers_db.sh

# Weekly cleanup of old backups
0 3 * * 0 postgres /usr/local/bin/cleanup_old_backups.sh
```

#### 3. Photo Backup

**S3 (Automatic Versioning):**
```bash
aws s3 mb s3://trailer-photos-backup
aws s3 sync s3://trailer-photos-bucket s3://trailer-photos-backup --storage-class GLACIER
```

**Local Filesystem:**
```bash
# Daily rsync to backup server
rsync -avz --delete /var/trailers/photos/ backup-server:/backups/trailer-photos/
```

### Maintenance Tasks

#### Daily
```sql
-- Update query planner statistics
ANALYZE;
```

#### Weekly
```sql
-- Reclaim space from deleted rows (automatic with autovacuum)
VACUUM;

-- Check for bloat
SELECT
    schemaname,
    tablename,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS size,
    n_dead_tup as dead_rows
FROM pg_stat_user_tables
WHERE n_dead_tup > 1000
ORDER BY n_dead_tup DESC;
```

#### Monthly
```sql
-- Rebuild indexes to remove bloat
REINDEX TABLE trailer_status_history;

-- Check index usage
SELECT
    schemaname,
    tablename,
    indexname,
    idx_scan as index_scans
FROM pg_stat_user_indexes
WHERE schemaname = 'public'
  AND idx_scan < 100
ORDER BY idx_scan ASC;
```

#### Quarterly
```sql
-- Check for missing indexes (queries doing sequential scans)
SELECT
    schemaname,
    tablename,
    seq_scan,
    seq_tup_read,
    idx_scan,
    seq_tup_read / NULLIF(seq_scan, 0) as avg_seq_read
FROM pg_stat_user_tables
WHERE seq_scan > 1000
  AND schemaname = 'public'
ORDER BY seq_tup_read DESC;
```

### Data Retention

**Archival Strategy:**

For append-only systems, data grows indefinitely. Consider:

1. **Keep Last N Years in Main Database:**
   ```sql
   -- Example: Archive data older than 5 years to separate table
   CREATE TABLE trailer_status_history_archive (LIKE trailer_status_history INCLUDING ALL);

   INSERT INTO trailer_status_history_archive
   SELECT * FROM trailer_status_history
   WHERE recorded_at < CURRENT_DATE - INTERVAL '5 years';

   -- Verify data integrity
   SELECT COUNT(*) FROM trailer_status_history_archive;

   -- Then delete from main table (or keep if storage allows)
   -- DELETE FROM trailer_status_history
   -- WHERE recorded_at < CURRENT_DATE - INTERVAL '5 years';
   ```

2. **Compress Old Photos:**
   - Move photos older than 1 year to cheaper storage (S3 Glacier)
   - Further compress images (reduce quality to 60%)

3. **Partitioning for Easy Archival:**
   - With time-based partitions, simply detach old partitions
   ```sql
   ALTER TABLE trailer_status_history_partitioned
   DETACH PARTITION trailer_status_history_2020;
   ```

---

## Security Considerations

### 1. Database Access Control

**Create Role-Based Access:**
```sql
-- Read-only role for reporting
CREATE ROLE trailer_readonly;
GRANT CONNECT ON DATABASE trailers TO trailer_readonly;
GRANT USAGE ON SCHEMA public TO trailer_readonly;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO trailer_readonly;

-- Application role (read/write, no DDL)
CREATE ROLE trailer_app;
GRANT CONNECT ON DATABASE trailers TO trailer_app;
GRANT USAGE ON SCHEMA public TO trailer_app;
GRANT SELECT, INSERT ON trailers, trailer_status_history, users TO trailer_app;
GRANT SELECT ON terminals TO trailer_app;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO trailer_app;

-- Create user and assign role
CREATE USER mobile_app WITH PASSWORD 'secure_password_here';
GRANT trailer_app TO mobile_app;
```

### 2. Connection Security

**Enforce SSL:**
```ini
# postgresql.conf
ssl = on
ssl_cert_file = '/path/to/server.crt'
ssl_key_file = '/path/to/server.key'
```

**Connection String:**
```
postgresql://user:pass@host:5432/trailers?sslmode=require
```

### 3. Data Encryption

**At Rest:**
- PostgreSQL: Transparent Data Encryption (TDE) requires enterprise extensions
- Filesystem: LUKS (Linux), FileVault (macOS), BitLocker (Windows)
- Cloud: AWS RDS encryption, Azure Database encryption

**In Transit:**
- Always use SSL/TLS for database connections
- Use HTTPS for API endpoints
- Use S3 pre-signed URLs over HTTPS

### 4. SQL Injection Prevention

**Always use parameterized queries:**

```python
# GOOD (parameterized)
cursor.execute(
    "SELECT * FROM trailers WHERE trailer_number = %s",
    (user_input,)
)

# BAD (vulnerable to SQL injection)
cursor.execute(
    f"SELECT * FROM trailers WHERE trailer_number = '{user_input}'"
)
```

### 5. Photo Access Control

**S3 Bucket Policy:**
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Deny",
      "Principal": "*",
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::trailer-photos-bucket/*",
      "Condition": {
        "StringNotLike": {
          "aws:Referer": [
            "https://your-app-domain.com/*"
          ]
        }
      }
    }
  ]
}
```

**Use Pre-Signed URLs:**
- Generate temporary URLs (expire after 1 hour)
- No direct public access to S3 bucket
- Application controls access

---

## Migration and Deployment

### Initial Setup

**1. Create Database:**
```bash
createdb trailers -O postgres -E UTF8
```

**2. Run Schema:**
```bash
psql -U postgres -d trailers -f database_schema.sql
```

**3. Verify:**
```sql
\dt  -- List tables
\di  -- List indexes
\df  -- List functions
\dv  -- List views
```

### Migration Strategy (Schema Changes)

**Use Migration Tools:**
- **Flyway** (Java): Version-controlled migrations
- **Liquibase** (Java): XML/YAML migrations
- **Alembic** (Python): SQLAlchemy migrations
- **pgmigrate** (Go): Simple migration tool

**Example (manual migrations):**
```
migrations/
    V1__initial_schema.sql
    V2__add_photo_metadata.sql
    V3__create_indexes.sql
```

**Never:**
- Manually edit production database
- Run DDL without testing
- Drop tables without backup

### Zero-Downtime Deployments

**Adding Column:**
```sql
-- Step 1: Add column (nullable)
ALTER TABLE trailer_status_history ADD COLUMN new_field TEXT;

-- Step 2: Backfill data (in batches)
UPDATE trailer_status_history SET new_field = 'default'
WHERE history_id BETWEEN 1 AND 100000;
-- Repeat in batches...

-- Step 3: Add NOT NULL constraint
ALTER TABLE trailer_status_history ALTER COLUMN new_field SET NOT NULL;
```

**Removing Column:**
```sql
-- Step 1: Stop writing to column in application
-- Step 2: Wait for deploy
-- Step 3: Drop column
ALTER TABLE trailer_status_history DROP COLUMN old_field;
```

---

## Monitoring and Alerts

### Key Metrics

**1. Database Performance:**
- Query latency (p50, p95, p99)
- Connections (active, idle, waiting)
- Transaction rate
- Cache hit ratio (should be > 90%)

```sql
-- Cache hit ratio
SELECT
    sum(heap_blks_read) as heap_read,
    sum(heap_blks_hit) as heap_hit,
    sum(heap_blks_hit) / (sum(heap_blks_hit) + sum(heap_blks_read)) as cache_hit_ratio
FROM pg_statio_user_tables;
```

**2. Table Growth:**
```sql
SELECT
    schemaname,
    tablename,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS size,
    pg_total_relation_size(schemaname||'.'||tablename) as bytes
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY bytes DESC;
```

**3. Slow Queries:**
```ini
# postgresql.conf
log_min_duration_statement = 1000  # Log queries > 1 second
log_line_prefix = '%t [%p]: [%l-1] user=%u,db=%d,app=%a,client=%h '
```

**4. Replication Lag (if using replicas):**
```sql
SELECT
    client_addr,
    state,
    sent_lsn,
    write_lsn,
    replay_lsn,
    sync_state,
    pg_wal_lsn_diff(sent_lsn, replay_lsn) as replication_lag_bytes
FROM pg_stat_replication;
```

### Monitoring Tools

**Open Source:**
- **pgAdmin**: GUI for PostgreSQL
- **Grafana + Prometheus**: Metrics dashboards
- **pg_stat_statements**: Query performance analysis
- **pgBadger**: Log analyzer

**Commercial:**
- **Datadog**: Full-stack monitoring
- **New Relic**: APM with database insights
- **AWS CloudWatch**: For RDS deployments

### Alerts to Set Up

1. **Database down** (critical)
2. **Disk space > 80%** (warning), > 90% (critical)
3. **Connection pool exhausted** (critical)
4. **Replication lag > 1 minute** (warning)
5. **Slow queries > 5 seconds** (warning)
6. **Backup failed** (critical)
7. **Cache hit ratio < 90%** (warning)

---

## Summary

### Key Takeaways

1. **PostgreSQL is the recommended database** for its advanced features, scalability, and ACID compliance.

2. **Append-only architecture** via `trailer_status_history` table ensures complete audit trail and simplifies concurrent access.

3. **Indexes are critical** for query performance. The schema includes composite indexes optimized for common query patterns.

4. **Store photos in cloud storage (S3)**, not the database, with file paths in the database.

5. **Use connection pooling** and batch operations for optimal performance with multiple concurrent users.

6. **Implement proper backups** (daily full, continuous WAL archiving) and test restores regularly.

7. **Monitor key metrics** (query performance, disk space, replication lag) and set up alerts.

8. **Consider partitioning** when the history table exceeds 100GB for better query performance and easier archival.

### Next Steps

1. **Deploy PostgreSQL** (local, cloud, or managed service)
2. **Run the schema SQL** to create all tables, indexes, and functions
3. **Test with sample data** to verify query performance
4. **Set up photo storage** (S3 or filesystem)
5. **Configure backups** and test restoration
6. **Implement connection pooling** in your application
7. **Set up monitoring** and alerts
8. **Load test** with expected concurrent user load

---

## Additional Resources

- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [Use The Index, Luke!](https://use-the-index-luke.com/) - SQL indexing guide
- [Explain.depesz.com](https://explain.depesz.com/) - EXPLAIN plan visualizer
- [PgTune](https://pgtune.leopard.in.ua/) - PostgreSQL configuration optimizer
- [PostGIS](https://postgis.net/) - Spatial database extension

---

**Schema Version:** 1.0
**Last Updated:** 2025-12-10
**Author:** Database Design for Trailer Management System
