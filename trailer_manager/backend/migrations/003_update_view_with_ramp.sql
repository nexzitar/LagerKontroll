-- Migration: Update trailers_latest view to include ramp fields

-- Drop the existing view
DROP VIEW IF EXISTS trailers_latest;

-- Recreate the view with new fields
CREATE OR REPLACE VIEW trailers_latest AS
SELECT DISTINCT ON (trailer_number)
    trailer_number,
    id AS latest_entry_id,
    terminal,
    is_empty,
    is_in_ramp,
    ramp_number,
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
