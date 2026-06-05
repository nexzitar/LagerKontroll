-- Migration: Add "In Ramp" status support
-- This adds two new columns to support trailers being in a ramp:
-- - is_in_ramp: boolean indicating if trailer is in a ramp
-- - ramp_number: varchar storing the ramp number (e.g., "R1", "R5", "12")

-- Add is_in_ramp column with default false
ALTER TABLE trailer_entries
ADD COLUMN is_in_ramp BOOLEAN DEFAULT FALSE;

-- Add ramp_number column (nullable, as it's only used when is_in_ramp is true)
ALTER TABLE trailer_entries
ADD COLUMN ramp_number VARCHAR(20);

-- Add a check constraint to ensure ramp_number is provided when is_in_ramp is true
-- Note: This constraint ensures data integrity
ALTER TABLE trailer_entries
ADD CONSTRAINT ramp_number_when_in_ramp
CHECK (
  (is_in_ramp = FALSE AND ramp_number IS NULL) OR
  (is_in_ramp = TRUE AND ramp_number IS NOT NULL AND LENGTH(TRIM(ramp_number)) > 0)
);

-- Create index for filtering by ramp status
CREATE INDEX idx_trailer_entries_is_in_ramp ON trailer_entries(is_in_ramp);
