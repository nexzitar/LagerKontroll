# Deployment Guide: In Ramp Status Feature

This guide covers the deployment of the "In Ramp" status feature for the Trailer Manager application.

## Overview

This update adds support for a third trailer status: "In Ramp" with a ramp number, in addition to the existing "Empty" and "Loaded" states.

## Changes Summary

### Database Changes
- Added `is_in_ramp` (boolean) column to `trailer_entries` table
- Added `ramp_number` (varchar(20)) column to `trailer_entries` table
- Added constraint to ensure `ramp_number` is provided when `is_in_ramp` is true
- Updated `trailers_latest` view to include new fields
- Added index on `is_in_ramp` for performance

### API Changes
- **POST /trailers**: Now accepts `isInRamp` and `rampNumber` in request body
- **PUT /trailers/:id/status**: Now accepts `isInRamp` and `rampNumber` in request body
- **GET /trailers**: Response includes `isInRamp` and `rampNumber` in trailer entries, plus `inRampCount` in summary
- **GET /trailers/:id**: Response includes `isInRamp` and `rampNumber` in latest entry
- **GET /trailers/:id/history**: Response includes `isInRamp` and `rampNumber` in all history entries

### Files Modified
- `/Users/mattias/prog/LagerKontroll/trailer_manager/backend/src/controllers/trailerController.js`

### Files Created
- `/Users/mattias/prog/LagerKontroll/trailer_manager/backend/migrations/002_add_ramp_status.sql`
- `/Users/mattias/prog/LagerKontroll/trailer_manager/backend/migrations/003_update_view_with_ramp.sql`

## Deployment Steps

### Step 1: Backup Database
```bash
ssh deploy@lassi.cloud
pg_dump -U postgres -d trailer_manager > ~/backups/trailer_manager_$(date +%Y%m%d_%H%M%S).sql
```

### Step 2: Run Database Migrations
```bash
# Connect to PostgreSQL
psql -U postgres -d trailer_manager

# Run migration 002 (add columns)
\i /path/to/backend/migrations/002_add_ramp_status.sql

# Run migration 003 (update view)
\i /path/to/backend/migrations/003_update_view_with_ramp.sql

# Verify changes
\d trailer_entries
\d+ trailers_latest

# Exit psql
\q
```

**Or run SQL directly:**
```bash
ssh deploy@lassi.cloud

# Navigate to backend directory
cd /path/to/trailer_manager/backend

# Run migrations
psql -U postgres -d trailer_manager -f migrations/002_add_ramp_status.sql
psql -U postgres -d trailer_manager -f migrations/003_update_view_with_ramp.sql
```

### Step 3: Deploy Backend Code
```bash
# From local machine, copy updated controller to server
scp /Users/mattias/prog/LagerKontroll/trailer_manager/backend/src/controllers/trailerController.js deploy@lassi.cloud:/path/to/backend/src/controllers/

# Or if using git
ssh deploy@lassi.cloud
cd /path/to/backend
git pull origin main
```

### Step 4: Restart PM2
```bash
ssh deploy@lassi.cloud
pm2 restart trailer-manager-api

# Check logs for any errors
pm2 logs trailer-manager-api --lines 50
```

### Step 5: Verify Deployment
```bash
# Test the API endpoint
curl -X GET https://lassi.cloud/api/trailers

# Check that the response includes the new fields:
# - isInRamp in trailer entries
# - rampNumber in trailer entries
# - inRampCount in summary
```

## API Usage Examples

### Creating a Trailer in Ramp
```bash
curl -X POST https://lassi.cloud/api/trailers \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: multipart/form-data" \
  -F "trailerNumber=TR-12345" \
  -F "terminal=B1" \
  -F "isEmpty=false" \
  -F "isInRamp=true" \
  -F "rampNumber=R5" \
  -F "latitude=59.3293" \
  -F "longitude=18.0686" \
  -F "photo=@/path/to/photo.jpg"
```

### Updating Trailer to In Ramp Status
```bash
curl -X PUT https://lassi.cloud/api/trailers/TR-12345/status \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "isEmpty": false,
    "isInRamp": true,
    "rampNumber": "R3",
    "latitude": 59.3293,
    "longitude": 18.0686
  }'
```

### Getting Trailers with Summary
```bash
curl -X GET https://lassi.cloud/api/trailers \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"

# Response will include:
# {
#   "data": [...],
#   "pagination": {...},
#   "summary": {
#     "emptyCount": 5,
#     "loadedCount": 10,
#     "inRampCount": 3
#   }
# }
```

## Validation Rules

1. **isInRamp**: Boolean (optional, defaults to false)
2. **rampNumber**: String (required when isInRamp is true, max 20 characters)
3. **Constraint**: If isInRamp is true, rampNumber must be provided and non-empty
4. **Database Constraint**: Enforces that ramp_number is NULL when is_in_ramp is FALSE, and NOT NULL when is_in_ramp is TRUE

## Rollback Procedure

If issues occur, you can rollback:

```bash
# Restore database from backup
psql -U postgres -d trailer_manager < ~/backups/trailer_manager_TIMESTAMP.sql

# Revert backend code
ssh deploy@lassi.cloud
cd /path/to/backend
git revert HEAD  # or git reset --hard PREVIOUS_COMMIT

# Restart PM2
pm2 restart trailer-manager-api
```

## Testing Checklist

- [ ] Database migrations run successfully
- [ ] View includes new fields (is_in_ramp, ramp_number)
- [ ] POST /trailers accepts isInRamp and rampNumber
- [ ] PUT /trailers/:id/status accepts isInRamp and rampNumber
- [ ] GET /trailers returns isInRamp and rampNumber in entries
- [ ] GET /trailers summary includes inRampCount
- [ ] GET /trailers/:id includes new fields
- [ ] GET /trailers/:id/history includes new fields
- [ ] Validation works: rampNumber required when isInRamp is true
- [ ] Database constraint enforced: ramp_number NULL when not in ramp
- [ ] PM2 restart successful
- [ ] No errors in PM2 logs

## Notes

- The feature is backward compatible. Existing trailers will have `is_in_ramp = false` and `ramp_number = null`.
- The summary counts (emptyCount, loadedCount, inRampCount) are mutually exclusive:
  - A trailer in ramp (is_in_ramp = true) is counted in inRampCount
  - A trailer not in ramp is counted as either empty or loaded based on is_empty
- Ramp numbers can be any format (e.g., "R1", "R5", "12", "Ramp A") up to 20 characters.

## Support

If you encounter issues during deployment, check:
1. PM2 logs: `pm2 logs trailer-manager-api`
2. PostgreSQL logs: `/var/log/postgresql/postgresql-*.log`
3. Database constraints: `\d trailer_entries` in psql
4. View definition: `\d+ trailers_latest` in psql
