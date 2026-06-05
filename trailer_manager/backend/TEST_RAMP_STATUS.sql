-- Test Script for Ramp Status Feature
-- Run this after deploying migrations to verify everything works

-- 1. Verify columns exist
\echo '=========================================='
\echo 'Test 1: Verify new columns exist'
\echo '=========================================='
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns
WHERE table_name = 'trailer_entries'
  AND column_name IN ('is_in_ramp', 'ramp_number')
ORDER BY column_name;

-- 2. Verify constraint exists
\echo ''
\echo '=========================================='
\echo 'Test 2: Verify constraint exists'
\echo '=========================================='
SELECT constraint_name, constraint_type
FROM information_schema.table_constraints
WHERE table_name = 'trailer_entries'
  AND constraint_name = 'ramp_number_when_in_ramp';

-- 3. Verify index exists
\echo ''
\echo '=========================================='
\echo 'Test 3: Verify index exists'
\echo '=========================================='
SELECT indexname, indexdef
FROM pg_indexes
WHERE tablename = 'trailer_entries'
  AND indexname = 'idx_trailer_entries_is_in_ramp';

-- 4. Verify view includes new columns
\echo ''
\echo '=========================================='
\echo 'Test 4: Verify view includes new columns'
\echo '=========================================='
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'trailers_latest'
  AND column_name IN ('is_in_ramp', 'ramp_number')
ORDER BY column_name;

-- 5. Check existing data (should all have is_in_ramp = false)
\echo ''
\echo '=========================================='
\echo 'Test 5: Check existing data defaults'
\echo '=========================================='
SELECT
    COUNT(*) as total_entries,
    COUNT(CASE WHEN is_in_ramp = true THEN 1 END) as in_ramp_count,
    COUNT(CASE WHEN is_in_ramp = false THEN 1 END) as not_in_ramp_count,
    COUNT(CASE WHEN ramp_number IS NOT NULL THEN 1 END) as with_ramp_number
FROM trailer_entries;

-- 6. Test constraint: should FAIL (is_in_ramp true but no ramp_number)
\echo ''
\echo '=========================================='
\echo 'Test 6: Constraint validation (should fail)'
\echo '=========================================='
-- This should fail with constraint violation
INSERT INTO trailer_entries
    (trailer_number, terminal, is_empty, is_in_ramp, ramp_number, latitude, longitude, photo_url)
VALUES
    ('TEST-FAIL', 'B1', false, true, NULL, 59.0, 18.0, 'http://test.jpg');
-- Expected: ERROR: new row violates check constraint "ramp_number_when_in_ramp"

-- 7. Test constraint: should FAIL (ramp_number but is_in_ramp false)
\echo ''
\echo '=========================================='
\echo 'Test 7: Constraint validation (should fail)'
\echo '=========================================='
-- This should fail with constraint violation
INSERT INTO trailer_entries
    (trailer_number, terminal, is_empty, is_in_ramp, ramp_number, latitude, longitude, photo_url)
VALUES
    ('TEST-FAIL2', 'B1', false, false, 'R1', 59.0, 18.0, 'http://test.jpg');
-- Expected: ERROR: new row violates check constraint "ramp_number_when_in_ramp"

-- 8. Test valid insert: trailer in ramp
\echo ''
\echo '=========================================='
\echo 'Test 8: Valid insert - in ramp (should succeed)'
\echo '=========================================='
BEGIN;
INSERT INTO trailer_entries
    (trailer_number, terminal, is_empty, is_in_ramp, ramp_number, latitude, longitude, photo_url)
VALUES
    ('TEST-RAMP-001', 'B1', false, true, 'R5', 59.3293, 18.0686, 'http://test.jpg');
SELECT 'Success: Inserted trailer in ramp R5' as result;
ROLLBACK;

-- 9. Test valid insert: trailer not in ramp
\echo ''
\echo '=========================================='
\echo 'Test 9: Valid insert - not in ramp (should succeed)'
\echo '=========================================='
BEGIN;
INSERT INTO trailer_entries
    (trailer_number, terminal, is_empty, is_in_ramp, ramp_number, latitude, longitude, photo_url)
VALUES
    ('TEST-EMPTY-001', 'B1', true, false, NULL, 59.3293, 18.0686, 'http://test.jpg');
SELECT 'Success: Inserted empty trailer not in ramp' as result;
ROLLBACK;

-- 10. Test view with different statuses
\echo ''
\echo '=========================================='
\echo 'Test 10: View query test'
\echo '=========================================='
BEGIN;
-- Insert test data
INSERT INTO trailer_entries
    (trailer_number, terminal, is_empty, is_in_ramp, ramp_number, latitude, longitude, photo_url)
VALUES
    ('TEST-VIEW-1', 'B1', false, true, 'R3', 59.0, 18.0, 'http://test.jpg'),
    ('TEST-VIEW-2', 'B1', true, false, NULL, 59.0, 18.0, 'http://test.jpg'),
    ('TEST-VIEW-3', 'B1', false, false, NULL, 59.0, 18.0, 'http://test.jpg');

-- Query the view
SELECT
    trailer_number,
    is_empty,
    is_in_ramp,
    ramp_number,
    CASE
        WHEN is_in_ramp THEN 'In Ramp'
        WHEN is_empty THEN 'Empty'
        ELSE 'Loaded'
    END as status
FROM trailers_latest
WHERE trailer_number LIKE 'TEST-VIEW-%'
ORDER BY trailer_number;

ROLLBACK;

-- 11. Test summary counts
\echo ''
\echo '=========================================='
\echo 'Test 11: Summary counts (with test data)'
\echo '=========================================='
BEGIN;
-- Insert test data
INSERT INTO trailer_entries
    (trailer_number, terminal, is_empty, is_in_ramp, ramp_number, latitude, longitude, photo_url)
VALUES
    ('TEST-SUM-1', 'B1', false, true, 'R1', 59.0, 18.0, 'http://test.jpg'),
    ('TEST-SUM-2', 'B1', false, true, 'R2', 59.0, 18.0, 'http://test.jpg'),
    ('TEST-SUM-3', 'B1', true, false, NULL, 59.0, 18.0, 'http://test.jpg'),
    ('TEST-SUM-4', 'B1', true, false, NULL, 59.0, 18.0, 'http://test.jpg'),
    ('TEST-SUM-5', 'B1', true, false, NULL, 59.0, 18.0, 'http://test.jpg'),
    ('TEST-SUM-6', 'B1', false, false, NULL, 59.0, 18.0, 'http://test.jpg');

-- Get counts
SELECT
    is_empty,
    is_in_ramp,
    COUNT(*) as count,
    CASE
        WHEN is_in_ramp THEN 'In Ramp'
        WHEN is_empty THEN 'Empty'
        ELSE 'Loaded'
    END as category
FROM trailers_latest
WHERE trailer_number LIKE 'TEST-SUM-%'
GROUP BY is_empty, is_in_ramp
ORDER BY category;

-- Expected:
-- In Ramp: 2
-- Empty: 3
-- Loaded: 1

ROLLBACK;

\echo ''
\echo '=========================================='
\echo 'All tests complete!'
\echo '=========================================='
\echo ''
\echo 'Summary of expected results:'
\echo '  - Tests 1-5: Should all show the new columns/constraints exist'
\echo '  - Tests 6-7: Should FAIL with constraint violations (expected)'
\echo '  - Tests 8-9: Should succeed with rollback'
\echo '  - Test 10: Should show 3 trailers with different statuses'
\echo '  - Test 11: Should show In Ramp: 2, Empty: 3, Loaded: 1'
\echo ''
