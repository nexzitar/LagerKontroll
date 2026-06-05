# Trailer Manager Backend API

Node.js + Express + PostgreSQL backend for the Trailer Manager mobile app.

## Features

- ✅ RESTful API with Express.js
- ✅ PostgreSQL database with optimized indexes
- ✅ Image upload and processing (compression, thumbnails)
- ✅ Filtering, sorting, and pagination
- ✅ Append-only history tracking
- ✅ CORS and security middleware
- ✅ Rate limiting
- ✅ Error handling

## Prerequisites

- Node.js 18+
- PostgreSQL 13+
- A server (cloud or local)

## Quick Start

### 1. Database Setup

```bash
# Connect to PostgreSQL
psql -U postgres

# Create database
CREATE DATABASE trailer_manager;

# Connect to database
\c trailer_manager

# Run the schema (from the database_schema.sql file)
\i /path/to/database_schema.sql
```

### 2. Backend Setup

```bash
# Navigate to backend directory
cd backend

# Install dependencies
npm install

# Create .env file from example
cp .env.example .env

# Edit .env with your configuration
nano .env
```

### 3. Configure Environment

Edit `.env`:

```env
# Server
PORT=3000
NODE_ENV=production

# Database
DB_HOST=localhost
DB_PORT=5432
DB_NAME=trailer_manager
DB_USER=postgres
DB_PASSWORD=your_secure_password

# JWT Secret
JWT_SECRET=your_random_secret_here

# Uploads
UPLOAD_DIR=./uploads
MAX_FILE_SIZE=10485760

# CORS (set to your Flutter app's domain in production)
CORS_ORIGIN=*
```

### 4. Start the Server

```bash
# Development (with auto-reload)
npm run dev

# Production
npm start
```

The API will be available at: `http://localhost:3000/api/v1`

## API Endpoints

### Health Check
```
GET /health
```

### Create Trailer Entry
```
POST /api/v1/trailers
Content-Type: multipart/form-data

Fields:
- photo: image file (required)
- trailerNumber: string (required)
- terminal: "B1" | "B3" (required)
- isEmpty: boolean (required)
- latitude: number (required)
- longitude: number (required)
- address: string (optional)
- notes: string (optional)
```

### Get All Trailers
```
GET /api/v1/trailers?page=1&limit=20&terminal=B1&isEmpty=true&sortBy=date&sortDirection=desc

Query Parameters:
- page: number (default: 1)
- limit: number (default: 20)
- trailerNumber: string (partial match)
- terminal: "B1" | "B3"
- isEmpty: boolean
- sortBy: "date" | "name"
- sortDirection: "asc" | "desc"
```

### Get Trailer by ID
```
GET /api/v1/trailers/:trailerNumber
```

### Get Trailer History
```
GET /api/v1/trailers/:trailerNumber/entries?limit=10

Query Parameters:
- limit: number (default: 10)
```

## Deployment on Your Server

### Option 1: Direct Deployment

1. **Copy files to server:**
```bash
scp -r backend user@your-server.com:/var/www/trailer-manager/
```

2. **SSH into server:**
```bash
ssh user@your-server.com
cd /var/www/trailer-manager/backend
```

3. **Install dependencies:**
```bash
npm install --production
```

4. **Set up PM2 (process manager):**
```bash
npm install -g pm2
pm2 start src/server.js --name trailer-manager-api
pm2 save
pm2 startup
```

5. **Configure Nginx as reverse proxy:**
```nginx
server {
    listen 80;
    server_name api.your-domain.com;

    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }

    location /uploads {
        alias /var/www/trailer-manager/backend/uploads;
        expires 30d;
        add_header Cache-Control "public, immutable";
    }
}
```

6. **Enable HTTPS with Let's Encrypt:**
```bash
sudo certbot --nginx -d api.your-domain.com
```

### Option 2: Docker Deployment

1. **Create Dockerfile:**
```dockerfile
FROM node:18-alpine
WORKDIR /app
COPY package*.json ./
RUN npm install --production
COPY . .
EXPOSE 3000
CMD ["npm", "start"]
```

2. **Create docker-compose.yml:**
```yaml
version: '3.8'
services:
  api:
    build: .
    ports:
      - "3000:3000"
    environment:
      - DB_HOST=db
      - DB_NAME=trailer_manager
      - DB_USER=postgres
      - DB_PASSWORD=${DB_PASSWORD}
    volumes:
      - ./uploads:/app/uploads
    depends_on:
      - db

  db:
    image: postgres:13-alpine
    environment:
      - POSTGRES_DB=trailer_manager
      - POSTGRES_PASSWORD=${DB_PASSWORD}
    volumes:
      - postgres_data:/var/lib/postgresql/data

volumes:
  postgres_data:
```

3. **Deploy:**
```bash
docker-compose up -d
```

## Database Maintenance

### Backup Database
```bash
pg_dump -U postgres trailer_manager > backup_$(date +%Y%m%d).sql
```

### Restore Database
```bash
psql -U postgres trailer_manager < backup_20231211.sql
```

### View Database Size
```sql
SELECT pg_size_pretty(pg_database_size('trailer_manager'));
```

### Clean Old Images (optional)
```bash
# Find images older than 90 days
find ./uploads -type f -mtime +90

# Delete them (BE CAREFUL!)
find ./uploads -type f -mtime +90 -delete
```

## Monitoring

### PM2 Commands
```bash
pm2 status                 # Check status
pm2 logs trailer-manager-api  # View logs
pm2 restart trailer-manager-api # Restart
pm2 stop trailer-manager-api   # Stop
pm2 delete trailer-manager-api # Remove from PM2
```

### Check API Health
```bash
curl http://localhost:3000/health
```

## Troubleshooting

### Database Connection Issues
```bash
# Check PostgreSQL is running
sudo systemctl status postgresql

# Check PostgreSQL logs
sudo tail -f /var/log/postgresql/postgresql-13-main.log

# Test connection
psql -U postgres -h localhost -d trailer_manager
```

### Permission Issues
```bash
# Ensure uploads directory is writable
chmod 755 ./uploads
chown -R www-data:www-data ./uploads
```

### High Memory Usage
```bash
# Check Node.js memory
pm2 monit

# Restart if needed
pm2 restart trailer-manager-api
```

## Security Checklist

- [ ] Change default database password
- [ ] Set strong JWT_SECRET
- [ ] Configure CORS_ORIGIN to your domain (not *)
- [ ] Enable HTTPS (SSL/TLS)
- [ ] Set up firewall rules
- [ ] Keep Node.js and dependencies updated
- [ ] Enable PostgreSQL SSL connections
- [ ] Set up database backups
- [ ] Monitor logs regularly
- [ ] Implement authentication (JWT)

## Performance Optimization

1. **Enable PostgreSQL query caching**
2. **Add Redis for API caching** (optional)
3. **Use CDN for images** (optional)
4. **Enable gzip compression in Nginx**
5. **Set up connection pooling** (already configured)

## Support

For issues or questions, check:
- Application logs: `pm2 logs trailer-manager-api`
- PostgreSQL logs: `/var/log/postgresql/`
- Nginx logs: `/var/log/nginx/`

---

**Status**: Production Ready ✅
**Last Updated**: December 11, 2025
