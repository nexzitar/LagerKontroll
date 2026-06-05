# In Ramp Status Implementation Summary

## Overview
Successfully implemented support for a third trailer status: "In Ramp" with ramp number tracking.

## Status States
The system now supports three mutually exclusive states:
1. **Empty** (isEmpty = true, isInRamp = false)
2. **Loaded** (isEmpty = false, isInRamp = false)
3. **In Ramp** (isInRamp = true, with ramp_number)

## Files Changed

### Database Migrations
1. **migrations/002_add_ramp_status.sql**
   - Added `is_in_ramp` BOOLEAN column (default: FALSE)
   - Added `ramp_number` VARCHAR(20) column (nullable)
   - Added constraint: `ramp_number` required when `is_in_ramp` is TRUE
   - Added index on `is_in_ramp` for query performance

2. **migrations/003_update_view_with_ramp.sql**
   - Updated `trailers_latest` view to include `is_in_ramp` and `ramp_number` fields

### Backend Code
**src/controllers/trailerController.js** - Updated 6 functions:

1. **createTrailerEntry** (POST /trailers)
   - Accepts `isInRamp` and `rampNumber` in request body
   - Validates ramp_number is provided when isInRamp is true
   - Stores in database and returns in response

2. **updateTrailerStatus** (PUT /trailers/:id/status)
   - Accepts `isInRamp` and `rampNumber` in request body
   - Validates ramp_number requirement
   - Creates new entry with ramp status

3. **getTrailers** (GET /trailers)
   - Returns `isInRamp` and `rampNumber` in all trailer entries
   - Summary now includes `inRampCount` alongside `emptyCount` and `loadedCount`
   - Summary counts are mutually exclusive (trailers in ramp don't count as empty/loaded)

4. **getTrailerById** (GET /trailers/:id)
   - Returns `isInRamp` and `rampNumber` in latest entry

5. **getTrailerHistory** (GET /trailers/:id/history)
   - Returns `isInRamp` and `rampNumber` in all history entries

6. **Summary counting logic**
   - Modified to count trailers in ramp separately
   - Trailers with `is_in_ramp = true` are counted in `inRampCount`
   - Remaining trailers counted as empty/loaded based on `is_empty`

## API Request/Response Examples

### POST /trailers (Create with ramp status)
```json
{
  "trailerNumber": "TR-12345",
  "terminal": "B1",
  "isEmpty": false,
  "isInRamp": true,
  "rampNumber": "R5",
  "latitude": 59.3293,
  "longitude": 18.0686,
  "photo": "<multipart file>"
}
```

### PUT /trailers/:id/status (Update to ramp status)
```json
{
  "isEmpty": false,
  "isInRamp": true,
  "rampNumber": "R3",
  "latitude": 59.3293,
  "longitude": 18.0686
}
```

### GET /trailers (Response with new fields)
```json
{
  "data": [
    {
      "id": "TR-12345",
      "trailerNumber": "TR-12345",
      "latestEntry": {
        "id": "uuid",
        "trailerNumber": "TR-12345",
        "terminal": "B1",
        "isEmpty": false,
        "isInRamp": true,
        "rampNumber": "R5",
        "latitude": 59.3293,
        "longitude": 18.0686,
        ...
      },
      ...
    }
  ],
  "pagination": {...},
  "summary": {
    "emptyCount": 5,
    "loadedCount": 10,
    "inRampCount": 3
  }
}
```

## Validation Rules

1. **isInRamp**: Optional boolean, defaults to false
2. **rampNumber**:
   - Required when `isInRamp` is true
   - Must be non-empty string
   - Max length: 20 characters
   - Format: Any (e.g., "R1", "R5", "12", "Ramp A")
3. **Database enforces**:
   - `ramp_number` must be NULL when `is_in_ramp` is FALSE
   - `ramp_number` must be NOT NULL when `is_in_ramp` is TRUE

## Deployment Steps (Quick Reference)

```bash
# 1. Backup database
ssh deploy@lassi.cloud
pg_dump -U postgres -d trailer_manager > ~/backups/trailer_manager_$(date +%Y%m%d_%H%M%S).sql

# 2. Run migrations
psql -U postgres -d trailer_manager -f migrations/002_add_ramp_status.sql
psql -U postgres -d trailer_manager -f migrations/003_update_view_with_ramp.sql

# 3. Deploy controller file
scp src/controllers/trailerController.js deploy@lassi.cloud:/path/to/backend/src/controllers/

# 4. Restart PM2
ssh deploy@lassi.cloud
pm2 restart trailer-manager-api
pm2 logs trailer-manager-api --lines 50
```

## Testing Checklist

- [ ] Database migrations execute without errors
- [ ] View includes new columns
- [ ] POST /trailers with isInRamp=true works
- [ ] POST /trailers with isInRamp=false works
- [ ] POST /trailers validation fails when isInRamp=true but rampNumber missing
- [ ] PUT /trailers/:id/status with ramp status works
- [ ] GET /trailers includes isInRamp and rampNumber
- [ ] GET /trailers summary shows inRampCount
- [ ] GET /trailers/:id includes new fields
- [ ] GET /trailers/:id/history includes new fields
- [ ] Database constraint blocks invalid data (ramp_number without is_in_ramp)
- [ ] Existing trailers still work (backward compatibility)

## Backward Compatibility

✅ **Fully backward compatible**
- Existing trailers automatically have `is_in_ramp = false` and `ramp_number = null`
- Existing API calls without ramp parameters continue to work
- New fields are optional in requests
- Database migration sets sensible defaults

## Files Created

1. `/Users/mattias/prog/LagerKontroll/trailer_manager/backend/migrations/002_add_ramp_status.sql`
2. `/Users/mattias/prog/LagerKontroll/trailer_manager/backend/migrations/003_update_view_with_ramp.sql`
3. `/Users/mattias/prog/LagerKontroll/trailer_manager/backend/DEPLOYMENT_GUIDE_RAMP_STATUS.md`
4. `/Users/mattias/prog/LagerKontroll/trailer_manager/backend/RAMP_STATUS_IMPLEMENTATION_SUMMARY.md` (this file)

## Files Modified

1. `/Users/mattias/prog/LagerKontroll/trailer_manager/backend/src/controllers/trailerController.js`

## Database Schema Changes

### trailer_entries table - New columns:
```sql
is_in_ramp BOOLEAN DEFAULT FALSE
ramp_number VARCHAR(20)
```

### New constraint:
```sql
CONSTRAINT ramp_number_when_in_ramp
CHECK (
  (is_in_ramp = FALSE AND ramp_number IS NULL) OR
  (is_in_ramp = TRUE AND ramp_number IS NOT NULL AND LENGTH(TRIM(ramp_number)) > 0)
)
```

### New index:
```sql
CREATE INDEX idx_trailer_entries_is_in_ramp ON trailer_entries(is_in_ramp);
```

## Next Steps

1. Deploy database migrations to production server
2. Deploy updated controller code
3. Restart PM2 service
4. Test all endpoints
5. Update frontend Flutter app to support new fields (separate task)
6. Update API documentation if needed

## Notes

- Summary counts are designed to be mutually exclusive: a trailer is either empty, loaded, or in ramp
- The constraint ensures data integrity at the database level
- Ramp numbers are flexible format to accommodate different naming conventions
- All existing functionality remains unchanged
