-- Grant permissions to trailer_app user
-- Run this ONCE as: sudo -u postgres psql -d trailer_manager -f grant_permissions.sql

-- Change owner of users table to trailer_app so it can alter it
ALTER TABLE users OWNER TO trailer_app;

-- Change owner of all sequences to trailer_app
ALTER TABLE trailer_entries OWNER TO trailer_app;

-- Show granted permissions
\dt users
