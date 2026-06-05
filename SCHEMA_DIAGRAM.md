# Database Schema Visual Diagram

## Entity Relationship Diagram

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                        TRAILER MANAGEMENT SYSTEM                             │
│                         Database Schema Diagram                              │
└─────────────────────────────────────────────────────────────────────────────┘


┌──────────────────────┐
│       users          │
├──────────────────────┤
│ PK  user_id          │◄────────┐
│     username  (UQ)   │         │
│     email  (UQ)      │         │
│     phone_number     │         │
│     full_name        │         │
│     is_active        │         │
│     created_at       │         │
│     updated_at       │         │
└──────────────────────┘         │
                                 │
                                 │
┌──────────────────────┐         │
│     terminals        │         │
├──────────────────────┤         │
│ PK  terminal_id      │◄────┐   │
│     terminal_code(UQ)│     │   │
│     terminal_name    │     │   │
│     description      │     │   │
│     default_latitude │     │   │
│     default_longitude│     │   │
│     is_active        │     │   │
│     created_at       │     │   │
│     updated_at       │     │   │
└──────────────────────┘     │   │
                             │   │
                             │   │
┌──────────────────────┐     │   │
│      trailers        │     │   │
├──────────────────────┤     │   │
│ PK  trailer_id       │◄─┐  │   │
│     trailer_number(UQ│  │  │   │
│     license_plate(UQ)│  │  │   │
│     description      │  │  │   │
│     make             │  │  │   │
│     model            │  │  │   │
│     year             │  │  │   │
│     is_active        │  │  │   │
│     created_at       │  │  │   │
│     updated_at       │  │  │   │
└──────────────────────┘  │  │   │
                          │  │   │
                          │  │   │
┌─────────────────────────────────────────────────────────────┐
│           trailer_status_history (CORE TABLE)               │
│                      APPEND-ONLY                            │
├─────────────────────────────────────────────────────────────┤
│ PK  history_id                                              │
│ FK  trailer_id  ──────────────────────────────────────┘     │
│ FK  terminal_id ────────────────────────────────┘           │
│ FK  user_id  ───────────────────────────────────────────────┘
│                                                             │
│     is_empty           (boolean - required)                │
│     latitude           (decimal 10,8)                      │
│     longitude          (decimal 11,8)                      │
│                                                             │
│     photo_path         (varchar 500)                       │
│     photo_content_type (varchar 50)                        │
│     photo_size_bytes   (bigint)                            │
│     photo_original_filename (varchar 255)                  │
│                                                             │
│     notes              (text)                              │
│     recorded_at        (timestamp - business time)         │
│     created_at         (timestamp - system time)           │
└─────────────────────────────────────────────────────────────┘
                          │
                          │
                          │
┌─────────────────────────────────────────────────────────────┐
│                    photos (OPTIONAL)                        │
│          Alternative normalized photo storage               │
├─────────────────────────────────────────────────────────────┤
│ PK  photo_id                                                │
│ FK  history_id  ────────────────────────────────────────────┘
│ FK  trailer_id                                              │
│ FK  uploaded_by → users.user_id                             │
│                                                             │
│     file_path          (varchar 500)                       │
│     storage_type       (varchar 20)                        │
│     content_type       (varchar 50)                        │
│     file_size_bytes    (bigint)                            │
│     original_filename  (varchar 255)                       │
│     width_pixels       (integer)                           │
│     height_pixels      (integer)                           │
│     file_hash          (varchar 64)                        │
│     uploaded_at        (timestamp)                         │
└─────────────────────────────────────────────────────────────┘


┌─────────────────────────────────────────────────────────────┐
│                     audit_log                               │
│              System-wide audit trail                        │
├─────────────────────────────────────────────────────────────┤
│ PK  audit_id                                                │
│ FK  user_id  → users.user_id                                │
│                                                             │
│     table_name         (varchar 50)                        │
│     record_id          (bigint)                            │
│     action             (varchar 20)                        │
│     changed_data       (jsonb)                             │
│     ip_address         (inet)                              │
│     user_agent         (text)                              │
│     created_at         (timestamp)                         │
└─────────────────────────────────────────────────────────────┘
```

---

## Table Relationships

### One-to-Many Relationships

```
users (1) ──────────► (*) trailer_status_history
  "One user can record many status entries"

trailers (1) ────────► (*) trailer_status_history
  "One trailer can have many status history entries"

terminals (1) ───────► (*) trailer_status_history
  "One terminal can have many trailer status entries"

trailer_status_history (1) ──► (*) photos [optional]
  "One status entry can have multiple photos"
```

---

## Key Indexes

### Primary Key Indexes (Automatic)
```
users:                    user_id
trailers:                 trailer_id
terminals:                terminal_id
trailer_status_history:   history_id  (BIGSERIAL)
photos:                   photo_id    (BIGSERIAL)
audit_log:                audit_id    (BIGSERIAL)
```

### Unique Indexes (Automatic)
```
users:        username, email
trailers:     trailer_number, license_plate
terminals:    terminal_code
```

### Foreign Key Indexes (Explicit)
```
trailer_status_history:
  ├─ idx_trailer_status_trailer_id    ON (trailer_id)
  ├─ idx_trailer_status_terminal      ON (terminal_id)
  └─ idx_trailer_status_user          ON (user_id)

photos:
  ├─ idx_photos_history               ON (history_id)
  └─ idx_photos_trailer               ON (trailer_id)

audit_log:
  └─ idx_audit_user                   ON (user_id)
```

### Query Optimization Indexes
```
trailer_status_history:
  ├─ idx_trailer_status_recorded_at            ON (recorded_at DESC)
  ├─ idx_trailer_status_empty                  ON (is_empty)
  ├─ idx_trailer_status_date_only              ON (DATE(recorded_at))
  ├─ idx_trailer_status_trailer_recorded       ON (trailer_id, recorded_at DESC)
  ├─ idx_trailer_status_terminal_recorded      ON (terminal_id, recorded_at DESC)
  ├─ idx_trailer_status_empty_recorded         ON (is_empty, recorded_at DESC)
  └─ idx_trailer_status_has_photo              ON (trailer_id) WHERE photo_path IS NOT NULL
```

---

## Data Flow Diagram

### 1. Add New Trailer Status (Mobile App)

```
┌──────────────┐
│  Mobile App  │
└──────┬───────┘
       │
       │ 1. User takes photo & fills form
       ▼
┌──────────────────┐
│  Take Photo      │
│  Get GPS coords  │
│  Enter details   │
└──────┬───────────┘
       │
       │ 2. Upload to API
       ▼
┌──────────────────┐
│   REST API       │
│  (Node.js/       │
│   FastAPI)       │
└──────┬───────────┘
       │
       │ 3. Upload photo to S3
       ▼
┌──────────────────┐
│   AWS S3         │
│  (Photo Storage) │
└──────┬───────────┘
       │
       │ 4. Returns S3 path
       ▼
┌──────────────────────────────────────┐
│   PostgreSQL Database                │
│                                      │
│   INSERT INTO                        │
│   trailer_status_history             │
│   (trailer_id, terminal_id,          │
│    user_id, is_empty, lat, lon,      │
│    photo_path, recorded_at)          │
│   VALUES (...)                       │
│                                      │
│   RETURNS history_id                 │
└──────────────────────────────────────┘
       │
       │ 5. Returns success
       ▼
┌──────────────────┐
│  Mobile App      │
│  Shows success   │
└──────────────────┘
```

### 2. Query Trailer History

```
┌──────────────┐
│  Client      │
│  (Web/Mobile)│
└──────┬───────┘
       │
       │ GET /api/trailers/TRL-001/history?limit=10
       ▼
┌──────────────────┐
│   REST API       │
└──────┬───────────┘
       │
       │ SELECT * FROM get_trailer_history('TRL-001', 10)
       ▼
┌──────────────────────────────────────────────────────┐
│   PostgreSQL Database                                │
│                                                      │
│   SELECT                                             │
│     tsh.history_id,                                  │
│     tsh.is_empty,                                    │
│     term.terminal_code,                              │
│     tsh.photo_path,                                  │
│     tsh.recorded_at                                  │
│   FROM trailer_status_history tsh                    │
│   JOIN trailers t ON tsh.trailer_id = t.trailer_id   │
│   WHERE t.trailer_number = 'TRL-001'                 │
│   ORDER BY tsh.recorded_at DESC                      │
│   LIMIT 10                                           │
│                                                      │
│   Uses index: idx_trailer_status_trailer_recorded    │
└──────────────────┬───────────────────────────────────┘
                   │
                   │ Returns 10 most recent entries
                   ▼
┌──────────────────────────────────────┐
│   REST API                           │
│                                      │
│   For each entry with photo_path:   │
│   - Generate S3 pre-signed URL       │
│   - Attach to response               │
└──────────┬───────────────────────────┘
           │
           │ JSON response with photo URLs
           ▼
┌──────────────────┐
│  Client          │
│  Displays history│
│  with photos     │
└──────────────────┘
```

### 3. Get Current Status (All Trailers)

```
┌──────────────┐
│  Dashboard   │
└──────┬───────┘
       │
       │ GET /api/status/current
       ▼
┌──────────────────┐
│   REST API       │
└──────┬───────────┘
       │
       │ SELECT * FROM v_trailer_current_status
       ▼
┌────────────────────────────────────────────────────────┐
│   PostgreSQL - Materialized View                       │
│                                                        │
│   SELECT DISTINCT ON (t.trailer_id)                    │
│     t.trailer_number,                                  │
│     tsh.is_empty,                                      │
│     term.terminal_code,                                │
│     tsh.recorded_at                                    │
│   FROM trailers t                                      │
│   LEFT JOIN trailer_status_history tsh                 │
│     ON t.trailer_id = tsh.trailer_id                   │
│   ORDER BY t.trailer_id, tsh.recorded_at DESC          │
│                                                        │
│   Very fast - uses index                               │
└────────────────┬───────────────────────────────────────┘
                 │
                 │ Returns current status for all trailers
                 ▼
┌────────────────────────────────┐
│  Dashboard                     │
│  Shows real-time status grid   │
│                                │
│  TRL-001 │ B1 │ Empty   │ 10m │
│  TRL-002 │ B3 │ Loaded  │ 2h  │
│  TRL-003 │ B1 │ Empty   │ 5h  │
└────────────────────────────────┘
```

---

## Storage Architecture

### Photo Storage Flow

```
                                   ┌─────────────────┐
                                   │   Mobile App    │
                                   └────────┬────────┘
                                            │
                                            │ 1. Capture photo
                                            ▼
                                   ┌────────────────────┐
                                   │  Compress/Resize   │
                                   │  (max 10MB)        │
                                   └────────┬───────────┘
                                            │
                                            │ 2. Upload
                                            ▼
┌───────────────────────────────────────────────────────────────────┐
│                        Backend API                                │
│                                                                   │
│  ┌──────────────┐     ┌──────────────┐     ┌──────────────┐     │
│  │ Validate     │────►│ Upload to    │────►│ Save path    │     │
│  │ (type, size) │     │ S3/Storage   │     │ to database  │     │
│  └──────────────┘     └──────┬───────┘     └──────────────┘     │
│                              │                                   │
└──────────────────────────────┼───────────────────────────────────┘
                               │
                   ┌───────────┴───────────┐
                   │                       │
                   ▼                       ▼
        ┌──────────────────┐   ┌──────────────────────┐
        │   AWS S3         │   │   PostgreSQL         │
        │   Cloud Storage  │   │   Database           │
        │                  │   │                      │
        │ /2025/12/10/     │   │ photo_path:          │
        │  trl001.jpg      │   │ s3://bucket/2025/... │
        │                  │   │                      │
        │ Stores: Photo    │   │ Stores: Metadata     │
        │ (binary data)    │   │ (path, size, type)   │
        └──────────────────┘   └──────────────────────┘
                   │                       │
                   │                       │
                   │   3. Retrieve         │
                   │                       │
                   ▼                       ▼
        ┌──────────────────────────────────────────┐
        │         Backend API                      │
        │                                          │
        │  1. Get photo_path from database         │
        │  2. Generate pre-signed URL (1hr exp)    │
        │  3. Return URL to client                 │
        └──────────────────┬───────────────────────┘
                           │
                           │ 4. Photo URL
                           ▼
                  ┌────────────────┐
                  │   Mobile App   │
                  │   Displays     │
                  │   photo        │
                  └────────────────┘
```

---

## Scalability Architecture

### Horizontal Scaling with Read Replicas

```
                    ┌───────────────┐
                    │  Mobile Apps  │
                    │  (hundreds)   │
                    └───────┬───────┘
                            │
                            │ All requests
                            ▼
                    ┌───────────────┐
                    │  Load Balancer│
                    └───────┬───────┘
                            │
                ┌───────────┼───────────┐
                │           │           │
                ▼           ▼           ▼
        ┌───────────┐ ┌───────────┐ ┌───────────┐
        │ API       │ │ API       │ │ API       │
        │ Server 1  │ │ Server 2  │ │ Server 3  │
        └─────┬─────┘ └─────┬─────┘ └─────┬─────┘
              │             │             │
        ┌─────┴─────────────┴─────────────┴─────┐
        │                                        │
        │  Write operations        Read operations
        ▼                                        ▼
┌───────────────────┐              ┌────────────────────┐
│  Primary DB       │              │ Read Replica 1     │
│  (PostgreSQL)     │──replicates─►│ (PostgreSQL)       │
│                   │    ┌─────────┤                    │
│  Handles:         │    │         │ Handles:           │
│  - INSERT         │    │         │ - SELECT           │
│  - UPDATE         │    │         │ - Reports          │
│  - DELETE         │    │         │ - Dashboards       │
└───────────────────┘    │         └────────────────────┘
                         │
                         │         ┌────────────────────┐
                         └────────►│ Read Replica 2     │
                                   │ (PostgreSQL)       │
                                   │                    │
                                   │ Handles:           │
                                   │ - SELECT           │
                                   │ - Analytics        │
                                   └────────────────────┘

```

### Caching Layer (Optional)

```
┌───────────────┐
│  API Server   │
└───────┬───────┘
        │
        │ 1. Check cache first
        ▼
┌───────────────────────┐
│   Redis Cache         │
│                       │
│ Key: trailer:TRL-001  │
│ Value: {status...}    │
│ TTL: 5 minutes        │
└───────┬───────────────┘
        │
        │ 2. Cache miss
        ▼
┌───────────────────────┐
│   PostgreSQL          │
│   Query database      │
└───────┬───────────────┘
        │
        │ 3. Return data + cache
        ▼
┌───────────────────────┐
│   API Server          │
│   Returns to client   │
└───────────────────────┘
```

---

## Query Performance Visualization

### Without Index (Sequential Scan)
```
SELECT * FROM trailer_status_history
WHERE trailer_id = 123
ORDER BY recorded_at DESC
LIMIT 10;

┌─────────────────────────────────────────────┐
│  trailer_status_history                     │
│  (10,000,000 rows)                          │
├─────────────────────────────────────────────┤
│  Must scan ALL rows to find trailer_id=123 │
│  ████████████████████████████████████       │
│  Seq Scan: 10,000,000 rows                  │
│  Time: ~10 seconds ❌                        │
└─────────────────────────────────────────────┘
```

### With Index (Index Scan)
```
SELECT * FROM trailer_status_history
WHERE trailer_id = 123
ORDER BY recorded_at DESC
LIMIT 10;

Using: idx_trailer_status_trailer_recorded (trailer_id, recorded_at DESC)

┌─────────────────────────────────────────────┐
│  Index: trailer_id + recorded_at            │
├─────────────────────────────────────────────┤
│  123 ─► [sorted by date DESC]               │
│      ├─ history_id: 9999999                 │
│      ├─ history_id: 9999995                 │
│      ├─ history_id: 9999990                 │
│      └─ ... (only 10 rows)                  │
│                                             │
│  Index Scan: ~10 rows                       │
│  Time: ~1 millisecond ✅                     │
└─────────────────────────────────────────────┘
```

---

## Backup Strategy Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                    Production Database                       │
│                      (PostgreSQL)                            │
└───────────────┬──────────────────────┬──────────────────────┘
                │                      │
    Continuous  │                      │  Daily Full Backup
    WAL Archive │                      │  (2:00 AM)
                │                      │
                ▼                      ▼
    ┌───────────────────┐  ┌───────────────────────────┐
    │  WAL Archive      │  │  Full Database Dump       │
    │  /backup/wal/     │  │  /backup/daily/           │
    │                   │  │                           │
    │  Point-in-time    │  │  trailers_20251210.dump   │
    │  recovery         │  │  trailers_20251209.dump   │
    │  (every 5 min)    │  │  trailers_20251208.dump   │
    └───────┬───────────┘  └────────┬──────────────────┘
            │                       │
            │  Weekly               │  Monthly
            │  to cold storage      │  to long-term
            │                       │
            ▼                       ▼
    ┌───────────────────┐  ┌───────────────────────────┐
    │  AWS S3 Glacier   │  │  AWS S3 Deep Archive      │
    │  (Cheap storage)  │  │  (Cheapest, 1 year)       │
    │  (Keep 3 months)  │  │                           │
    └───────────────────┘  └───────────────────────────┘
```

---

## Security Layers

```
┌─────────────────────────────────────────────────────────────┐
│                     Mobile App / Client                      │
│                                                             │
│  ▼ HTTPS only (TLS 1.2+)                                    │
│  ▼ API Key authentication                                   │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       │ Encrypted connection
                       ▼
┌─────────────────────────────────────────────────────────────┐
│                      API Server                             │
│                                                             │
│  ▼ Rate limiting (100 req/min per user)                     │
│  ▼ Input validation (SQL injection prevention)             │
│  ▼ File upload validation (type, size)                     │
│  ▼ Authentication & authorization                           │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       │ SSL connection
                       ▼
┌─────────────────────────────────────────────────────────────┐
│                   PostgreSQL Database                        │
│                                                             │
│  ▼ SSL required for connections                             │
│  ▼ Role-based access control (RBAC)                         │
│  ▼ Row-level security (RLS) - optional                      │
│  ▼ Audit logging enabled                                    │
│  ▼ Encrypted at rest (filesystem encryption)                │
└─────────────────────────────────────────────────────────────┘


┌─────────────────────────────────────────────────────────────┐
│                    AWS S3 (Photos)                           │
│                                                             │
│  ▼ Private bucket (no public access)                        │
│  ▼ Pre-signed URLs only (1 hour expiration)                 │
│  ▼ Bucket policy restricts access                           │
│  ▼ Encrypted at rest (AES-256)                              │
│  ▼ Versioning enabled (accidental delete protection)        │
└─────────────────────────────────────────────────────────────┘
```

---

## Legend

```
┌─────────┐
│  Box    │  = Entity, Component, or System
└─────────┘

───►  = Data flow or relationship direction

PK    = Primary Key
FK    = Foreign Key
UQ    = Unique constraint

(1)   = One (cardinality)
(*)   = Many (cardinality)

█████ = Processing or scanning

✅    = Good performance
❌    = Poor performance
```

---

This visual diagram complements the SQL schema and documentation, providing a clear overview of:
- Table relationships
- Data flow through the system
- Index usage and performance
- Backup and security architecture
- Scalability patterns
