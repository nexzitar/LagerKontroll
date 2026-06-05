-- Migration: Allow custom terminal/location values
-- This removes the CHECK constraint that limited terminal to only 'B1' and 'B3'
-- and increases the field size to accommodate longer location names

-- Drop the existing CHECK constraint
ALTER TABLE trailer_entries
DROP CONSTRAINT IF EXISTS trailer_entries_terminal_check;

-- Increase the varchar size from 10 to 50 to accommodate longer location names
ALTER TABLE trailer_entries
ALTER COLUMN terminal TYPE VARCHAR(50);

-- Add a simple validation that terminal is not empty
ALTER TABLE trailer_entries
ADD CONSTRAINT trailer_entries_terminal_not_empty CHECK (LENGTH(TRIM(terminal)) > 0);
