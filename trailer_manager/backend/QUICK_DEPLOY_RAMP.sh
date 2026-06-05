#!/bin/bash
# Quick Deploy Script for Ramp Status Feature
# Run this on lassi.cloud server after uploading files

set -e  # Exit on error

echo "=========================================="
echo "Deploying Ramp Status Feature"
echo "=========================================="

# Configuration
DB_NAME="trailer_manager"
DB_USER="postgres"
BACKEND_DIR="/path/to/trailer_manager/backend"
PM2_APP_NAME="trailer-manager-api"

echo ""
echo "Step 1: Backing up database..."
BACKUP_FILE="$HOME/backups/trailer_manager_$(date +%Y%m%d_%H%M%S).sql"
mkdir -p "$HOME/backups"
pg_dump -U "$DB_USER" -d "$DB_NAME" > "$BACKUP_FILE"
echo "✓ Database backed up to: $BACKUP_FILE"

echo ""
echo "Step 2: Running migration 002 (add columns)..."
psql -U "$DB_USER" -d "$DB_NAME" -f "$BACKEND_DIR/migrations/002_add_ramp_status.sql"
echo "✓ Migration 002 completed"

echo ""
echo "Step 3: Running migration 003 (update view)..."
psql -U "$DB_USER" -d "$DB_NAME" -f "$BACKEND_DIR/migrations/003_update_view_with_ramp.sql"
echo "✓ Migration 003 completed"

echo ""
echo "Step 4: Verifying database changes..."
psql -U "$DB_USER" -d "$DB_NAME" -c "\d trailer_entries" | grep -E "is_in_ramp|ramp_number"
echo "✓ Database schema verified"

echo ""
echo "Step 5: Restarting PM2 application..."
pm2 restart "$PM2_APP_NAME"
echo "✓ PM2 restarted"

echo ""
echo "Step 6: Checking application status..."
sleep 2
pm2 status "$PM2_APP_NAME"

echo ""
echo "=========================================="
echo "Deployment Complete!"
echo "=========================================="
echo ""
echo "Backup location: $BACKUP_FILE"
echo ""
echo "Check logs with: pm2 logs $PM2_APP_NAME --lines 50"
echo ""
echo "Test the API with:"
echo "  curl -X GET https://lassi.cloud/api/trailers"
echo ""
echo "Look for 'inRampCount' in the summary section"
echo ""
