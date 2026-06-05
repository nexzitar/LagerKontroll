# Connect Flutter App to Real Backend

This guide shows you how to connect your Flutter app to the Node.js backend you just set up.

## Step 1: Deploy the Backend

First, deploy the backend to your server. See `backend/README.md` for detailed instructions.

### Quick Backend Deployment

```bash
# On your server
cd /var/www/trailer-manager/backend

# Install dependencies
npm install

# Set up database
psql -U postgres -d trailer_manager -f database_schema.sql

# Configure .env
nano .env

# Start with PM2
pm2 start src/server.js --name trailer-manager-api
pm2 save
```

Your API should now be running at: `http://your-server.com:3000/api/v1`

---

## Step 2: Update Flutter App Configuration

### Update Environment Config

Edit: `lib/core/config/environment.dart`

```dart
class EnvironmentConfig {
  final String apiBaseUrl;
  final bool enableLogging;
  final bool isProduction;

  const EnvironmentConfig({
    required this.apiBaseUrl,
    this.enableLogging = false,
    this.isProduction = false,
  });

  // CHANGE THIS to your server URL
  static const EnvironmentConfig production = EnvironmentConfig(
    apiBaseUrl: 'https://api.your-domain.com/api/v1',  // ✅ Update this
    enableLogging: false,
    isProduction: true,
  );

  static const EnvironmentConfig staging = EnvironmentConfig(
    apiBaseUrl: 'https://staging-api.your-domain.com/api/v1',
    enableLogging: true,
    isProduction: false,
  );

  static const EnvironmentConfig development = EnvironmentConfig(
    apiBaseUrl: 'http://your-server-ip:3000/api/v1',  // ✅ Update this
    enableLogging: true,
    isProduction: false,
  );

  // Set current environment
  static EnvironmentConfig current = development;  // Change to production when ready
}
```

### Example URLs:
- **Local testing**: `http://192.168.1.100:3000/api/v1` (replace with your server's local IP)
- **Production**: `https://api.your-domain.com/api/v1`

---

## Step 3: Switch from Mock to Real Backend

### Enable Real Backend

Edit: `lib/core/providers/providers.dart`

Find this section (around line 44):

```dart
// Repository Providers
// TODO: Switch to TrailerRepositoryImpl when backend is ready
// For now, using mock to avoid network connectivity issues
final trailerRepositoryProvider = Provider<TrailerRepository>((ref) {
  // Mock mode - no network required
  return TrailerRepositoryMock();

  // Real mode - uncomment when backend is ready:
  // return TrailerRepositoryImpl(
  //   remoteDataSource: ref.watch(trailerRemoteDataSourceProvider),
  //   networkInfo: ref.watch(networkInfoProvider),
  // );
});
```

**Change it to:**

```dart
// Repository Providers
final trailerRepositoryProvider = Provider<TrailerRepository>((ref) {
  // Real mode - backend connected! ✅
  return TrailerRepositoryImpl(
    remoteDataSource: ref.watch(trailerRemoteDataSourceProvider),
    networkInfo: ref.watch(networkInfoProvider),
  );
});
```

### Re-enable the Import

At the top of `lib/core/providers/providers.dart`, add back:

```dart
import '../../features/capture/data/repositories/trailer_repository_impl.dart';
```

---

## Step 4: Test the Connection

### 1. Test Backend API

First, verify your backend is accessible:

```bash
# Test health endpoint
curl http://your-server-ip:3000/health

# Should return:
# {"status":"ok","timestamp":"...","uptime":...}
```

### 2. Rebuild Flutter App

```bash
flutter clean
flutter pub get
flutter run
```

### 3. Create a Test Entry

1. Open app
2. Tap "New Entry"
3. Take a photo
4. Fill in details
5. Tap "Save"
6. ✅ Should save successfully!
7. ✅ Entry should appear in list
8. ✅ After app restart, data should still be there (persistent!)

### 4. Test Action Buttons

1. Open a trailer detail screen
2. Tap "Mark as Empty"
3. ✅ Should update and persist
4. Tap "Update Location"
5. ✅ Should get real GPS and save

---

## Step 5: Verify Data Persistence

### Check Database

On your server:

```bash
psql -U postgres -d trailer_manager
```

```sql
-- View all trailers
SELECT trailer_number, COUNT(*) as entry_count
FROM trailer_entries
GROUP BY trailer_number;

-- View latest entries
SELECT trailer_number, terminal, is_empty, created_at
FROM trailer_entries
ORDER BY created_at DESC
LIMIT 10;

-- View specific trailer history
SELECT * FROM trailer_entries
WHERE trailer_number = 'TR-12345'
ORDER BY created_at DESC;
```

---

## Troubleshooting

### "No internet connection" Error

**Problem**: App can't reach the backend

**Solutions**:
1. ✅ Check backend is running: `pm2 status`
2. ✅ Test API directly: `curl http://your-server-ip:3000/health`
3. ✅ Check firewall allows port 3000
4. ✅ Verify `apiBaseUrl` in `environment.dart` is correct
5. ✅ Make sure phone/emulator can reach the server
   - For local testing, use server's IP address (not localhost)
   - For production, use domain name

### "Connection refused" Error

**Problem**: Backend not accessible

**Solutions**:
```bash
# Check if backend is running
pm2 list

# Check port is open
sudo netstat -tlnp | grep 3000

# Restart backend
pm2 restart trailer-manager-api

# Check logs
pm2 logs trailer-manager-api
```

### "API key not found" (Google Maps)

**Problem**: Google Maps API key issue

**Solution**: Already fixed! Key is in `AndroidManifest.xml`

### Photos Not Uploading

**Problem**: Image upload fails

**Solutions**:
1. ✅ Check uploads directory exists and is writable:
   ```bash
   ls -la backend/uploads
   chmod 755 backend/uploads
   ```
2. ✅ Check image file size (must be < 10MB)
3. ✅ Check backend logs: `pm2 logs trailer-manager-api`

### Database Connection Issues

**Problem**: Backend can't connect to database

**Solutions**:
```bash
# Check PostgreSQL is running
sudo systemctl status postgresql

# Test connection
psql -U postgres -d trailer_manager

# Check .env file has correct credentials
cat backend/.env
```

---

## Network Configuration

### For Local Testing (Same WiFi)

1. Find your server's IP:
   ```bash
   # On server
   ifconfig | grep inet
   # or
   ip addr show
   ```

2. Update `environment.dart`:
   ```dart
   apiBaseUrl: 'http://192.168.1.100:3000/api/v1'  // Use your server's IP
   ```

3. Make sure both phone and server are on same network

### For Production (Internet)

1. **Set up domain**: `api.your-domain.com`

2. **Configure Nginx** (see backend/README.md)

3. **Enable HTTPS**: `sudo certbot --nginx -d api.your-domain.com`

4. **Update Flutter app**:
   ```dart
   apiBaseUrl: 'https://api.your-domain.com/api/v1'
   ```

---

## Verification Checklist

- [ ] Backend is deployed and running
- [ ] Database schema is loaded
- [ ] Health endpoint returns 200: `curl http://your-server:3000/health`
- [ ] `environment.dart` has correct API URL
- [ ] `providers.dart` is using `TrailerRepositoryImpl` (not mock)
- [ ] Flutter app rebuilt: `flutter clean && flutter run`
- [ ] Can create new trailer entry
- [ ] Can view trailers list
- [ ] Can view trailer details
- [ ] Mark Empty button works and persists
- [ ] Update Location button works and persists
- [ ] Data survives app restart
- [ ] Photos are uploaded and displayed
- [ ] Database contains the data

---

## Success! 🎉

Once all checks pass, your app is fully connected to the backend!

**Benefits of Real Backend**:
- ✅ Data persists permanently
- ✅ Accessible from multiple devices
- ✅ Real photo storage
- ✅ Action buttons actually save changes
- ✅ Full history tracking
- ✅ Production-ready!

---

## Optional: Add Authentication

Currently, the API is open. To add authentication:

1. **Uncomment JWT code** in controllers
2. **Create login endpoint**
3. **Add token to Flutter requests**
4. **See backend/README.md** for details

---

**Questions?** Check the logs:
- Backend: `pm2 logs trailer-manager-api`
- Database: `sudo tail -f /var/log/postgresql/postgresql-13-main.log`
- Flutter: Check console in Android Studio / VS Code

Good luck! 🚀
