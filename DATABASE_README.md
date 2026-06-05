# Trailer Management System - Database Design

A production-ready, scalable relational database schema for tracking trailers across multiple terminals with complete historical tracking, photo storage, and multi-user support.

## Overview

This database design provides a complete solution for a trailer management system with the following key features:

- **Append-only history** - Never delete data, maintain complete audit trail
- **Multi-user support** - Track which user made each status change
- **Photo storage** - Store photos with metadata (S3 or filesystem)
- **GPS tracking** - Record precise latitude/longitude coordinates
- **Terminal management** - Track trailers across multiple locations (B1, B3, etc.)
- **Efficient querying** - Optimized indexes for common query patterns
- **Scalable architecture** - Designed for concurrent access and growth

## Quick Start

### 1. Install PostgreSQL

```bash
# macOS
brew install postgresql@15
brew services start postgresql@15

# Ubuntu/Debian
sudo apt install postgresql postgresql-contrib
sudo systemctl start postgresql

# Docker
docker run --name trailer-postgres \
  -e POSTGRES_PASSWORD=mypassword \
  -e POSTGRES_DB=trailers \
  -p 5432:5432 \
  -d postgres:15
```

### 2. Create Database and Run Schema

```bash
# Create database
createdb trailers -O postgres

# Apply schema
psql -U postgres -d trailers -f database_schema.sql
```

### 3. Verify Installation

```bash
psql -U postgres -d trailers
```

```sql
-- Check tables
\dt

-- Verify sample data
SELECT * FROM terminals;
```

## Documentation Files

This repository contains comprehensive documentation:

| File | Description |
|------|-------------|
| **database_schema.sql** | Complete SQL schema with tables, indexes, views, and functions |
| **DATABASE_DESIGN_DOCUMENTATION.md** | In-depth design decisions, recommendations, and best practices |
| **QUICK_START_GUIDE.md** | Quick reference with sample queries and API integration examples |
| **APPLICATION_EXAMPLES.md** | Production-ready code examples (Node.js, Python, React Native) |
| **SCHEMA_DIAGRAM.md** | Visual diagrams of database structure and data flow |
| **DATABASE_README.md** | This file - overview and getting started |

## Core Tables

### 1. users
Stores user information for authentication and audit trails.

```sql
SELECT user_id, username, email, full_name FROM users;
```

### 2. terminals
Reference table for terminal locations (B1, B3, etc.).

```sql
SELECT terminal_id, terminal_code, terminal_name FROM terminals;
```

### 3. trailers
Master table for trailer registration (static data).

```sql
SELECT trailer_id, trailer_number, license_plate, make, model FROM trailers;
```

### 4. trailer_status_history (CORE TABLE)
**Append-only** history of all trailer status changes, locations, and photos.

```sql
SELECT
    history_id,
    trailer_id,
    terminal_id,
    is_empty,
    latitude,
    longitude,
    photo_path,
    recorded_at
FROM trailer_status_history
ORDER BY recorded_at DESC
LIMIT 10;
```

## Key Features

### Append-Only Architecture

The `trailer_status_history` table is designed as append-only:
- **Never UPDATE or DELETE** - Only INSERT operations
- Complete audit trail of all changes
- Temporal queries supported (what was the status on date X?)
- Simplifies concurrent access (no UPDATE conflicts)

### Efficient Querying

Optimized indexes for common query patterns:
- Last N entries for a specific trailer
- Current status of all trailers
- Activity by date range
- Trailers at specific terminal
- Empty/loaded status filtering

### Photo Storage

Two approaches supported:

**1. Cloud Storage (Recommended)**
- Store photos in AWS S3, Azure Blob, or Google Cloud Storage
- Database stores file path/URL only
- Scalable, cost-effective, CDN integration

**2. Embedded Metadata**
- Photo path, content type, and size stored in `trailer_status_history`
- Optional normalized `photos` table for advanced management

## Common Queries

### Get Last 10 Entries for a Trailer

```sql
SELECT * FROM get_trailer_history('TRL-001', 10);
```

### Get Current Status of All Trailers

```sql
SELECT * FROM v_trailer_current_status
ORDER BY trailer_number;
```

### Find Empty Trailers at Terminal B1

```sql
WITH latest_status AS (
    SELECT DISTINCT ON (trailer_id)
        trailer_id, is_empty, terminal_id, recorded_at
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
  AND t.is_active = true;
```

### Add New Status Entry

```sql
SELECT insert_trailer_status(
    'TRL-001',              -- trailer_number
    'ABC123',               -- license_plate
    'B1',                   -- terminal_code
    false,                  -- is_empty
    59.329323,              -- latitude
    18.068581,              -- longitude
    's3://bucket/photo.jpg', -- photo_path
    'image/jpeg',           -- photo_content_type
    2457600,                -- photo_size_bytes
    1,                      -- user_id
    'Loaded with cargo'     -- notes
);
```

## Database Recommendations

### Primary Recommendation: PostgreSQL 12+

**Why PostgreSQL?**
- Advanced indexing (partial indexes, composite indexes, BRIN)
- Native JSON support (JSONB)
- PostGIS for spatial queries (optional)
- Excellent performance for time-series data
- Strong ACID compliance
- Great scalability (replication, partitioning)

### Alternative: MySQL 8.0+
Use if your team is more familiar with MySQL or you need simpler deployment.

### NOT Recommended: SQLite
Only for development/testing. Not suitable for production with multiple concurrent users.

## Performance Considerations

### Connection Pooling

Always use connection pooling for production deployments:

```javascript
// Node.js example
const pool = new Pool({
  max: 20,  // Maximum connections
  idleTimeoutMillis: 30000
});
```

### Indexing Strategy

The schema includes comprehensive indexes:
- Primary key indexes (automatic)
- Foreign key indexes (for JOINs)
- Query-specific indexes (date, status, terminal)
- Composite indexes (trailer_id + recorded_at)
- Partial indexes (active records only)

### Query Optimization

```sql
-- Always use EXPLAIN ANALYZE to verify index usage
EXPLAIN ANALYZE
SELECT * FROM trailer_status_history
WHERE trailer_id = 123
ORDER BY recorded_at DESC
LIMIT 10;
```

Look for "Index Scan" (good) vs "Seq Scan" (bad for large tables).

## Scalability

### Vertical Scaling (Bigger Server)

**Small Deployment** (< 100 trailers)
- CPU: 2 cores
- RAM: 4GB
- Storage: 50GB SSD

**Medium Deployment** (100-1000 trailers)
- CPU: 4-8 cores
- RAM: 16-32GB
- Storage: 500GB SSD

**Large Deployment** (1000+ trailers)
- CPU: 16+ cores
- RAM: 64-128GB
- Storage: 1-2TB NVMe SSD

### Horizontal Scaling (Multiple Servers)

**Read Replicas:**
```
[Mobile Apps] ──writes──► [Primary DB]
                             │
                             ├──replicate──► [Read Replica 1] ◄──reads──
                             └──replicate──► [Read Replica 2] ◄──reads──
```

### Partitioning (For Large Scale)

When `trailer_status_history` exceeds 100GB, consider time-based partitioning:

```sql
CREATE TABLE trailer_status_history_partitioned (
    LIKE trailer_status_history INCLUDING ALL
) PARTITION BY RANGE (recorded_at);

CREATE TABLE trailer_status_history_2025_01
    PARTITION OF trailer_status_history_partitioned
    FOR VALUES FROM ('2025-01-01') TO ('2025-02-01');
```

## Backup Strategy

### Daily Full Backup

```bash
# Automated backup script
pg_dump -h localhost -U postgres -d trailers \
  -F c -f /backup/trailers_$(date +%Y%m%d).dump
```

### Continuous WAL Archiving

```ini
# postgresql.conf
wal_level = replica
archive_mode = on
archive_command = 'cp %p /backup/wal_archive/%f'
```

Enables point-in-time recovery (PITR).

### Photo Backup

```bash
# S3 to S3 replication
aws s3 sync s3://trailer-photos s3://trailer-photos-backup \
  --storage-class GLACIER
```

## Security Checklist

- [ ] Change default PostgreSQL password
- [ ] Create dedicated application user (don't use 'postgres')
- [ ] Enable SSL/TLS for database connections
- [ ] Use environment variables for credentials (never hardcode)
- [ ] Implement rate limiting on API endpoints
- [ ] Validate all user inputs (prevent SQL injection)
- [ ] Use parameterized queries only
- [ ] Restrict S3 bucket public access
- [ ] Use pre-signed URLs for photo access
- [ ] Enable database audit logging
- [ ] Configure regular backups
- [ ] Monitor for suspicious activity

## Application Integration

### REST API Endpoints

```
POST   /api/status              - Add new trailer status
GET    /api/status/trailer/:id  - Get trailer history
GET    /api/status/current      - Get all current statuses
GET    /api/status/terminal/:id - Get trailers at terminal
GET    /api/status/date/:date   - Get activity for date
GET    /api/trailers            - List all trailers
POST   /api/trailers            - Register new trailer
```

See **APPLICATION_EXAMPLES.md** for complete code examples in:
- Node.js/Express with S3 photo upload
- Python FastAPI
- React Native mobile app
- Offline-first architecture

## Monitoring

### Key Metrics to Monitor

1. **Query Performance**
   - Average query time
   - Slow queries (> 1 second)

2. **Database Health**
   - Connection pool usage
   - Cache hit ratio (should be > 90%)
   - Disk space usage

3. **Replication Lag** (if using replicas)
   - Should be < 1 second

4. **Backup Status**
   - Last successful backup
   - Backup size

### Monitoring Tools

- **pgAdmin** - GUI for PostgreSQL
- **Grafana + Prometheus** - Metrics dashboards
- **pg_stat_statements** - Query performance analysis
- **Datadog/New Relic** - Full-stack monitoring (commercial)

## Maintenance

### Daily
```sql
ANALYZE;  -- Update query planner statistics
```

### Weekly
```sql
VACUUM;  -- Reclaim space from deleted rows
```

### Monthly
```sql
REINDEX TABLE trailer_status_history;  -- Rebuild indexes
```

### Quarterly
- Review index usage (drop unused indexes)
- Check for table bloat
- Test backup restoration
- Review slow query log

## Troubleshooting

### Slow Queries

```sql
-- Enable slow query logging
ALTER SYSTEM SET log_min_duration_statement = 1000;  -- 1 second
SELECT pg_reload_conf();

-- Check index usage
EXPLAIN ANALYZE <your_query>;
```

### Connection Pool Exhausted

```sql
-- Check active connections
SELECT count(*) FROM pg_stat_activity;

-- Check max connections
SHOW max_connections;

-- Increase pool size or max_connections
ALTER SYSTEM SET max_connections = 200;
```

### Disk Space Issues

```sql
-- Check table sizes
SELECT
    tablename,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS size
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;

-- Reclaim space
VACUUM FULL trailer_status_history;
```

## Migration from Existing System

If you have an existing trailer tracking system:

1. **Analyze Current Data**
   - Identify all data fields
   - Map to new schema

2. **Create Migration Script**
   ```sql
   -- Example migration from old_trailers table
   INSERT INTO trailers (trailer_number, license_plate)
   SELECT old_trailer_id, old_license FROM old_trailers;

   INSERT INTO trailer_status_history (trailer_id, is_empty, recorded_at)
   SELECT t.trailer_id, old.is_empty, old.timestamp
   FROM old_status old
   JOIN trailers t ON t.trailer_number = old.old_trailer_id;
   ```

3. **Test Migration**
   - Run on copy of production data
   - Verify data integrity
   - Test all queries

4. **Execute Migration**
   - Schedule downtime
   - Backup existing system
   - Run migration
   - Verify success
   - Switch to new system

## Support and Resources

### Documentation
- [PostgreSQL Official Docs](https://www.postgresql.org/docs/)
- [SQL Tutorial](https://www.postgresql.org/docs/current/tutorial.html)
- [Performance Tuning](https://wiki.postgresql.org/wiki/Performance_Optimization)

### Tools
- **psql** - Command-line interface
- **pgAdmin** - GUI tool
- **DBeaver** - Universal database tool
- **Postico** - macOS native PostgreSQL client

### Community
- [PostgreSQL Mailing Lists](https://www.postgresql.org/list/)
- [Stack Overflow](https://stackoverflow.com/questions/tagged/postgresql)
- [PostgreSQL Slack](https://postgres-slack.herokuapp.com/)

## License

This database schema and documentation are provided as-is for use in your trailer management system.

## Version History

- **v1.0.0** (2025-12-10) - Initial release
  - Core tables (users, trailers, terminals, trailer_status_history)
  - Comprehensive indexes for common queries
  - Helper functions and views
  - Complete documentation and examples

## Contributors

Designed for production use in trailer/logistics management systems.

---

**Need Help?**

1. Read the **QUICK_START_GUIDE.md** for common queries
2. Check **DATABASE_DESIGN_DOCUMENTATION.md** for detailed explanations
3. Review **APPLICATION_EXAMPLES.md** for integration code
4. See **SCHEMA_DIAGRAM.md** for visual representations

---

**Ready to Deploy?**

1. ✅ Install PostgreSQL
2. ✅ Run database_schema.sql
3. ✅ Configure backups
4. ✅ Set up monitoring
5. ✅ Deploy API (see APPLICATION_EXAMPLES.md)
6. ✅ Test with sample data
7. ✅ Go live!
