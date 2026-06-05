# Trailer Manager - Claude Code Guide

This document provides essential information for Claude Code to effectively work with the Trailer Manager Flutter application.

## Project Overview

**Trailer Manager** is a Flutter mobile application for tracking and managing storage trailers. It features camera capture, GPS tracking, real-time updates, and phone-based authentication. The app connects to a backend API (documented in the parent directory `/Users/mattias/prog/LagerKontroll/`) and uses SMS for user onboarding.

## IMPORTANT: Agent-Centric Workflow

**To avoid context bloat and session compression, ALWAYS prefer using agents over doing work directly.**

**FULL PERMISSION GRANTED**: You have explicit permission to create and deploy any general or specialist agents required to complete tasks in the best way possible. Do not ask for permission - just deploy agents proactively whenever they would be beneficial.

## IMPORTANT: Auto-Deploy After Fixes

After fixing a bug or implementing a feature, **automatically deploy it** via Shorebird OTA patch. Do not ask for permission - just run the patch command:

```bash
~/.shorebird/bin/shorebird patch android
```

If the fix involves native code changes (Kotlin, AndroidManifest, etc.), use a full release instead:

```bash
~/.shorebird/bin/shorebird release android --artifact apk
```

### When to Use Agents (Prefer This)

1. **Exploring the Codebase** - Use Explore agents instead of reading files directly
   - "Map out the authentication system"
   - "Find all files related to trailer deletion"
   - "Understand how Shorebird OTA updates are configured"

2. **Implementing Features** - Use general-purpose agents for multi-step tasks
   - "Add sorting functionality to trailer list"
   - "Implement export to CSV feature"
   - Agent reads files, makes changes, tests, and reports back

3. **Investigating Issues** - Deploy agents to research problems
   - "Find why OTA updates aren't applying"
   - "Investigate backend API error handling"

4. **Parallel Work** - Launch multiple agents simultaneously
   - One exploring backend structure
   - One implementing frontend feature
   - One updating documentation

### When to Work Directly (Less Preferred)

- Single-file edits where you already know the exact location
- Trivial changes (fixing typos, updating a single value)
- Configuration updates to known files

### Benefits of Agent-Centric Approach

✅ **Prevents context bloat** - Agents work in their own context windows
✅ **Avoids session compression** - Less information kept in working memory
✅ **Enables parallel work** - Multiple agents working simultaneously
✅ **Better knowledge retention** - No information lost in compression
✅ **Faster execution** - Agents can explore/implement while you plan next steps

### Agent Usage Pattern

```
❌ BAD: Read 10 files yourself to understand auth flow
✅ GOOD: Deploy Explore agent to map auth system and report summary

❌ BAD: Manually implement feature across multiple files
✅ GOOD: Deploy general-purpose agent with clear specs

❌ BAD: Keep entire codebase structure in memory
✅ GOOD: Deploy agents when you need to refresh knowledge about specific areas
```

### Persistent Knowledge Base

This CLAUDE.md file serves as persistent memory. Agents can reference it, and you should update it with important findings to reduce what needs to be kept in active context.

## Key Technologies

- **Flutter**: 3.10.1+
- **Dart**: 3.10.1+
- **State Management**: Riverpod 2.5.1
- **Networking**: Dio 5.7.0 with custom DioClient
- **Local Storage**: Hive 2.2.3 for credentials, SharedPreferences for settings
- **Navigation**: go_router 14.2.7
- **Maps**: Google Maps Flutter 2.9.0
- **Location**: Geolocator 13.0.1
- **Camera**: camera 0.11.0+2
- **OCR**: Google ML Kit Text Recognition 0.13.0 (license plate detection)
- **Authentication**: JWT-based phone number authentication
- **OTA Updates**: Shorebird Code Push

## Architecture

### Clean Architecture Pattern

The app follows Clean Architecture with feature-based organization:

```
lib/
├── core/                           # Shared functionality
│   ├── config/                     # app_config.dart (terminals, LSO list)
│   ├── constants/                  # app_constants.dart
│   ├── network/                    # dio_client.dart
│   ├── providers/                  # theme_provider.dart
│   ├── services/                   # sms_service.dart, update_service.dart, license_plate_service.dart
│   ├── theme/                      # app_theme.dart
│   └── utils/                      # logger.dart
│
├── features/
│   ├── auth/                       # Phone-based authentication
│   │   ├── data/
│   │   │   ├── models/            # user_model.dart
│   │   │   ├── services/          # auth_storage_service.dart
│   │   │   └── repositories/      # auth_repository.dart
│   │   ├── domain/
│   │   │   └── entities/          # user.dart
│   │   └── presentation/
│   │       ├── providers/         # auth_provider.dart, user_management_provider.dart
│   │       └── screens/           # login_screen.dart, admin_panel_screen.dart, change_password_screen.dart
│   │
│   ├── browse/                     # Trailer list/browse
│   │   ├── presentation/
│   │   │   ├── providers/         # trailer_list_provider.dart
│   │   │   └── screens/           # home_screen.dart, trailer_list_screen.dart
│   │
│   ├── capture/                    # Trailer capture with camera
│   │   ├── presentation/
│   │   │   ├── providers/         # capture_provider.dart
│   │   │   └── screens/           # capture_screen.dart
│   │
│   ├── detail/                     # Trailer detail view
│   │   ├── presentation/
│   │   │   ├── providers/         # detail_provider.dart, history_provider.dart
│   │   │   ├── screens/           # trailer_detail_screen.dart, trailer_history_screen.dart
│   │   │   └── widgets/           # fullscreen_photo_viewer.dart
│   │
│   ├── map/                        # Map view with trailer locations
│   │   └── presentation/
│   │       └── screens/           # map_view_screen.dart
│   │
│   └── settings/                   # App settings
│       └── presentation/
│           └── screens/            # settings_screen.dart
│
└── main.dart                       # App entry point
```

### Key Architectural Decisions

1. **Feature-First Structure**: Code organized by feature (auth, browse, capture, detail, map, settings) rather than layer
2. **Riverpod for State**: All state management uses Riverpod providers with proper dependency injection
3. **Custom MethodChannel**: Direct SMS sending and APK installation on Android uses native Kotlin code via MethodChannel
4. **Phone Numbers as Primary ID**: Users authenticate with phone numbers (no email)
5. **JWT Authentication**: Backend uses JWT tokens stored in Hive for persistence
6. **Navigation**: Uses go_router for declarative routing
7. **Three User Roles**: Admin (full access), User (create/edit), Guest (read-only)
8. **Three Trailer Statuses**: Empty, Loaded, In Ramp (with optional ramp number)

## Essential Commands

### Development

```bash
# Run the app in debug mode
flutter run

# Run with hot reload enabled (default)
flutter run

# Build debug APK for testing
flutter build apk --debug

# Build release APK
flutter build apk --release

# Install dependencies
flutter pub get

# Clean build artifacts
flutter clean

# Analyze code
flutter analyze
```

### Backend Deployment

The backend is deployed on `lassi.cloud` using PM2. To deploy backend changes:

```bash
# SSH to server
ssh deploy@lassi.cloud

# Navigate to backend directory
cd /path/to/backend

# Pull latest changes
git pull

# Install dependencies
npm install

# Restart PM2 process
pm2 restart trailer-manager-api
```

## Authentication Flow

### Phone-Based Login

1. User enters phone number with country code (e.g., +47 12345678)
2. User enters password
3. Optional "Remember Me" checkbox (stores credentials in Hive)
4. Backend validates and returns JWT token
5. Token stored in memory and optionally in Hive for persistence
6. DioClient automatically attaches token to all API requests

### User Creation (Admin Only)

1. Admin accesses Admin Panel screen (lib/features/auth/presentation/screens/admin_panel_screen.dart:11)
2. Admin fills form: name, phone number with country code, role (user/admin)
3. Backend auto-generates password and creates user
4. **SMS is sent automatically** with login credentials and APK download link
5. User receives SMS with phone number, password, and download link

## Direct SMS Implementation

### IMPORTANT: SMS Architecture

The app uses **custom native code** to send SMS directly on Android without opening the SMS app. This is different from url_launcher which only opens the SMS app.

### Files Involved

1. **lib/core/services/sms_service.dart:18** - SmsService with MethodChannel
2. **android/app/src/main/kotlin/com/lagerkontroll/trailer_manager/MainActivity.kt:12** - Native Kotlin SMS implementation
3. **android/app/src/main/AndroidManifest.xml:9** - SEND_SMS permission declaration

### How It Works

**Android:**
- Uses Android SmsManager API via MethodChannel
- Requests SEND_SMS permission on first use
- Sends SMS in background without user interaction
- Automatically handles multipart messages (>160 characters)

**iOS:**
- Falls back to url_launcher (opens Messages app)
- User must manually tap Send
- No special permissions required

### Usage Example

```dart
import 'package:trailer_manager/core/services/sms_service.dart';

final smsService = SmsService();
final success = await smsService.sendSms(
  phoneNumber: '+4712345678',
  message: 'Your message here',
);
```

### Important Note About SMS Packages

**DO NOT** use these packages - they are outdated:
- `flutter_sms` (namespace build errors)
- `telephony` (discontinued)

The custom MethodChannel implementation is the working solution.

## Backend API Integration

### Base URL

Production: `https://lassi.cloud/api` (configured in lib/core/config/app_config.dart:5)

### Key Endpoints

```
POST   /auth/login              # Phone-based login
POST   /auth/register           # Create new user (admin only)
GET    /auth/users              # List all users (admin only)
DELETE /auth/users/:id          # Delete user (admin only)
POST   /auth/change-password    # Change own password
GET    /trailers                # List trailers
POST   /trailers                # Create trailer
GET    /trailers/:id            # Get trailer details
PUT    /trailers/:id            # Update trailer
GET    /trailers/:id/history    # Get trailer history
```

### Authentication Header

All authenticated requests automatically include:
```
Authorization: Bearer <jwt_token>
```

This is handled by DioClient interceptor (lib/core/network/dio_client.dart).

## Common Development Tasks

### Adding a New Screen

1. Create screen file in `lib/features/<feature>/presentation/screens/`
2. If state needed, create provider in `lib/features/<feature>/presentation/providers/`
3. Add route in `lib/main.dart` routes map
4. Navigate using `Navigator.pushNamed(context, '/route-name')`

### Adding API Integration

1. Update DioClient if needed (lib/core/network/dio_client.dart)
2. Create repository in `lib/features/<feature>/data/repositories/`
3. Create Riverpod provider for the repository
4. Use in presentation layer

### Modifying SMS Message

The welcome SMS template is in `lib/features/auth/presentation/screens/admin_panel_screen.dart:49-58`:

```dart
final message = '''Welcome to Trailer Manager, $userName!

Your Login:
Phone: $phoneNumber
Password: $password

Download the app:
$appDownloadUrl

Please change your password after first login.''';
```

### Adding New Country Code

Edit the dropdown in `lib/features/auth/presentation/screens/admin_panel_screen.dart:341-362`.

### Changing App Configuration

Edit `lib/core/config/app_config.dart` for settings like:
- API base URL
- Padding constants
- Timeout values

### Accessing Google Maps API Key

The Google Maps API key is **not** committed. It's supplied via git-ignored files:
- Android: `MAPS_API_KEY` in `trailer_manager/.env`, read by Gradle and injected into
  `AndroidManifest.xml` as `${MAPS_API_KEY}`.
- iOS: `MAPS_API_KEY` in `ios/Flutter/Secrets.xcconfig`, fed into `Info.plist` (`GMSApiKey`)
  and read in `AppDelegate.swift`.

See `GOOGLE_MAPS_SETUP.md`. Copy `.env.example` / `Secrets.example.xcconfig` to create them.

## State Management with Riverpod

### Provider Types Used

1. **StateNotifierProvider** - For complex state (auth, user management, capture)
2. **Provider** - For read-only services (DioClient, AuthStorage)
3. **StateProvider** - For simple state (theme mode)

### Example Provider Pattern

```dart
// Provider definition
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref);
});

// Usage in widget
class MyScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    // Use authState...
  }
}
```

### Key Providers

- **authProvider** (lib/features/auth/presentation/providers/auth_provider.dart) - Authentication state
- **userManagementProvider** - User CRUD operations (admin)
- **dioClientProvider** (lib/core/network/dio_client.dart) - HTTP client
- **authStorageProvider** - Credential persistence

## Important Implementation Details

### 1. Remember Me Feature

Located in login_screen.dart, uses Hive to store:
- Phone number
- Password (encrypted in production)
- JWT token

Files:
- lib/features/auth/data/services/auth_storage_service.dart - Storage logic
- lib/features/auth/presentation/screens/login_screen.dart - UI

### 2. Admin Check

Admin-only features check: `authState.user?.isAdmin == true`

Example in admin_panel_screen.dart:230:
```dart
if (authState.user?.isAdmin != true) {
  return Scaffold(
    body: const Center(
      child: Text('Access Denied: Admin privileges required'),
    ),
  );
}
```

### 3. Country Code Handling

Country codes are stored separately from phone number:
- `_countryCode` variable stores: '+47', '+46', etc.
- `_phoneController` stores: '12345678' (without country code)
- Combined before sending: `'$_countryCode${_phoneController.text.trim()}'`

### 4. Error Handling

Use ScaffoldMessenger for user feedback:
```dart
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: Text('Error message'),
    backgroundColor: Colors.red,
  ),
);
```

### 5. Loading States

Use boolean flags and disable buttons during async operations:
```dart
ElevatedButton(
  onPressed: _isCreating ? null : _createUser,
  child: _isCreating
      ? CircularProgressIndicator()
      : Text('Create User'),
)
```

## Testing & Debugging

### Running on Physical Device

```bash
# List connected devices
flutter devices

# Run on specific device
flutter run -d <device-id>
```

### Common Issues

1. **SMS Not Sending**: Check SEND_SMS permission in AndroidManifest.xml:9
2. **Build Failures**: Run `flutter clean && flutter pub get`
3. **Map Not Showing**: Verify API key in AndroidManifest.xml:46
4. **Auth Errors**: Check token in DioClient interceptor

### Logs

The app uses a custom logger (lib/core/utils/logger.dart):
```dart
import 'package:trailer_manager/core/utils/logger.dart';

logger.info('Info message');
logger.error('Error message');
logger.debug('Debug message');
```

## Backend Documentation

For backend-specific documentation, see parent directory:
- `/Users/mattias/prog/LagerKontroll/README.md` - Main documentation
- `/Users/mattias/prog/LagerKontroll/API_INTEGRATION_GUIDE.md` - API reference
- `/Users/mattias/prog/LagerKontroll/DATABASE_DESIGN_DOCUMENTATION.md` - Database schema
- `/Users/mattias/prog/LagerKontroll/QUICK_START_GUIDE.md` - Setup instructions

## Deployment

### Building Release APK

```bash
# Build release APK
flutter build apk --release

# Output location
build/app/outputs/flutter-apk/app-release.apk
```

### Deploying to lassi.cloud

The APK download link in SMS messages points to:
`https://lassi.cloud/downloads/trailer-manager.apk`

Upload the built APK to this location on the server.

### SSH Access

```bash
ssh deploy@lassi.cloud
```

## Related Projects

**TaskDispatcher** (`/Users/mattias/prog/TaskDispatcher/`)
- Sibling project with similar SMS implementation
- Reference implementation for MethodChannel SMS
- Uses same pattern for native Android integration

## Code Style & Conventions

1. **File naming**: snake_case (e.g., `admin_panel_screen.dart`)
2. **Class naming**: PascalCase (e.g., `AdminPanelScreen`)
3. **Variable naming**: camelCase (e.g., `_phoneController`)
4. **Private members**: Prefix with underscore (e.g., `_sendWelcomeSMS`)
5. **Constants**: camelCase or SCREAMING_SNAKE_CASE
6. **Line length**: Prefer < 80 characters, max 120
7. **Comments**: Use `///` for public API documentation

## Security Considerations

1. **SEND_SMS Permission**: Only requested when needed (first SMS send)
2. **JWT Storage**: Tokens stored in Hive (encrypted in production recommended)
3. **API Keys**: Google Maps key is exposed in AndroidManifest (consider environment variables)
4. **Password Generation**: Backend generates secure random passwords
5. **Admin Check**: Always verify `isAdmin` before admin operations

## Performance Notes

1. **Images**: Optimized before upload
2. **Lists**: Use ListView.builder for efficient rendering
3. **State**: Riverpod providers properly scoped to avoid unnecessary rebuilds
4. **Network**: Dio client includes timeout and retry logic

## Version Information

- **App Version**: 1.2.1+11 (pubspec.yaml:5)
- **Min SDK**: Android API 21+
- **Target SDK**: Latest
- **iOS**: 11.0+

## Quick Reference Links

- Flutter Docs: https://docs.flutter.dev
- Riverpod Docs: https://riverpod.dev
- Google Maps: https://pub.dev/packages/google_maps_flutter
- Dio: https://pub.dev/packages/dio

## Getting Help

When working in this codebase:

1. **Check existing code** for patterns (especially in auth feature)
2. **Review providers** to understand state management flow
3. **Check app_config.dart** for configuration values
4. **Look at admin_panel_screen.dart** for complete SMS implementation example
5. **Reference TaskDispatcher** project for native Android patterns

## Shorebird Code Push (OTA Updates)

### Overview

Shorebird provides over-the-air (OTA) updates for the Trailer Manager app, allowing you to push code changes to users without requiring them to download a new APK from the server.

### Configuration

- **App ID**: `4999168b-07e4-4000-820f-392dbc14b1ca`
- **Auto Update**: Enabled by default (updates check on app launch)
- **Config File**: `shorebird.yaml` (tracked in version control)

### Key Commands

```bash
# Create a new release (do this when incrementing app version)
~/.shorebird/bin/shorebird release android

# Create a release APK for distribution
~/.shorebird/bin/shorebird release android --artifact apk

# Push an OTA patch (for code-only changes, no version bump needed)
~/.shorebird/bin/shorebird patch android

# Push an OTA patch without confirmation prompt (for CI/CD)
~/.shorebird/bin/shorebird patch android --no-confirm

# Preview a release before deploying
~/.shorebird/bin/shorebird preview
```

### Release vs Patch Workflow

**Creating a New Release** (when version changes):
1. Update version in `pubspec.yaml` (e.g., `1.0.0+1` → `1.0.1+2`)
2. Run: `~/.shorebird/bin/shorebird release android --artifact apk`
3. Copy APK from `build/app/outputs/apk/release/app-release.apk` to server
4. Upload to `/var/www/trailer-manager/downloads/trailer-manager.apk`
5. Users download new APK via SMS link

**Pushing an OTA Patch** (for code-only updates):
1. Make code changes (no version bump needed)
2. Run: `~/.shorebird/bin/shorebird patch android`
3. Existing users will automatically receive the update on next app launch
4. No need to redistribute APK

### Limitations

Shorebird can patch:
- Dart code changes
- UI updates
- Business logic modifications

Shorebird CANNOT patch:
- Native code changes (Kotlin/Java in android/)
- AndroidManifest.xml changes
- Gradle configuration changes
- New permissions
- Plugin additions or updates
- Asset changes (including new icons that change font tree-shaking)

**Important**: When adding UI elements that use Material Icons, use icons that already exist in your app to avoid font asset changes. New icons will trigger tree-shaking and create asset diffs, which cannot be patched.

For these changes, you must create a new release and redistribute the APK.

### Deployment Workflow

1. **Initial Release**: Created via `shorebird release android --artifact apk`
   - Current version: 1.2.1+11
   - APK location: `build/app/outputs/apk/release/app-release.apk`
   - Server location: `https://lassi.cloud/downloads/trailer-manager.apk`

2. **Subsequent Updates**:
   - Minor fixes: Use `shorebird patch android --no-confirm`
   - Version changes or native updates: Use `shorebird release android --artifact apk` and redeploy APK

### Checking Update Status

Users can check for updates programmatically, but auto-update is enabled so updates apply automatically on app restart.

The Settings screen (lib/features/settings/presentation/screens/settings_screen.dart:86-89) displays an "OTA Updates" section showing that Shorebird is enabled and auto-updates are active. This serves as a visual indicator to users that the app will automatically receive updates.

### Important Notes

- The `shorebird.yaml` file is NOT sensitive and should be committed to version control
- App ID is public and used to identify your app with Shorebird's servers
- Patches are downloaded and applied automatically when users open the app
- Users don't need to download a new APK for patches, only for new releases

### Shorebird Dashboard

View releases and patches at: https://console.shorebird.dev

### Troubleshooting

**"Your app contains asset changes" error when patching:**
This occurs when Flutter's tree-shaking produces different MaterialIcons font files between the release and the patch. Common causes:
- Adding new Material Icons that weren't in the original release
- Using different icon variants (outlined, filled, rounded, etc.)

**Solution:** Use icons that already exist in your codebase. Check existing screens to find icons you can reuse, or create a new release instead of a patch if you need new icons.

## Recent Changes

### Edit Status Feature (2025-12-20)
- Replaced "Mark Empty" and "Update Location" buttons with single "Edit Status" button
- New dialog allows changing status (Empty/Loaded/In Ramp) with optional ramp number
- Added "Update location" toggle switch (default ON) to control whether GPS is updated
- When toggle is OFF, keeps existing location (useful for editing trailers you're not near)
- Files: `lib/features/detail/presentation/screens/trailer_detail_screen.dart`, `lib/features/detail/presentation/providers/detail_provider.dart`

### License Plate OCR Improvements (2025-12-20)
- Added flash toggle button with 4 modes: Auto → On → Torch → Off
- Torch mode keeps light on continuously for previewing in dark conditions
- Added Swedish new plate format support: ABC 12D (3 letters + 2 digits + 1 letter)
- Improved pattern matching with `_extractPlateFromText()` for finding plates in noisy OCR text
- Added debug logging to show all OCR-detected text blocks
- File: `lib/core/services/license_plate_service.dart`

### Trailer List Limit Increase (2025-12-20)
- Increased default limit from 20 to 1000 trailers
- Fixes issue where only 20 trailers were displayed
- Updated in backend (`trailerController.js`) and frontend (`trailer_list_provider.dart`, `get_trailers.dart`)

### Timezone Fix (2025-12-20)
- All timestamps now display in user's local timezone
- Added `.toLocal()` conversion before formatting dates
- Fixed in: trailer list, history screen, detail screen, admin panel

### Summary Bar Bug Fixes (2025-12-18)
- Fixed summary bar disappearing when filter results in empty list
- Fixed summary counts showing filtered counts instead of true totals
- Summary bar now always shows actual counts (Empty/Loaded/In Ramp/All) regardless of active filter

### In-App Update System (2025-12-18)
- Added in-app APK download with progress indicator
- Native APK installation via FileProvider (Android 7+)
- Update notifications on app launch when new version available
- Files: `lib/core/services/update_service.dart`, `MainActivity.kt`
- Backend version config: `backend/src/config/appVersion.js`

### Tappable Summary Bar (2025-12-18)
- Summary bar items (Empty/Loaded/In Ramp/All) are now tappable to filter
- Visual feedback with border and background when filter is active
- Tap same filter again to clear it

### In Ramp Status (2025-12-18)
- Added third trailer status: "In Ramp" (alongside Empty/Loaded)
- Optional ramp number field (e.g., "Ramp 3")
- Database migration: `is_in_ramp` boolean, `ramp_number` text columns
- Blue color coding for In Ramp status throughout UI

### Map View Feature (2025-12-17)
- New map screen showing all trailers with GPS locations
- Color-coded markers: Green (Empty), Orange (Loaded), Blue (In Ramp)
- Tappable markers showing trailer info
- File: `lib/features/map/presentation/screens/map_view_screen.dart`

### Guest Role (2025-12-17)
- Read-only role that can view trailers but not create/edit/delete
- FAB hidden for guest users
- Edit/delete buttons hidden in detail screen

### Admin Role Management (2025-12-17)
- Admins can change other users' roles (user/admin/guest)
- Role selector in admin panel user list

### Summary Bar & Terminal Filters (2025-12-17)
- Added summary card showing Empty/Loaded/In Ramp/Total counts
- Terminal filter options: All, LSO (B1-B5 combined), B1, B2, B3, B4, B5, ØT
- LSO filter groups terminals B1-B5 together

### License Plate OCR (2025-12-16)
- Auto-detect license plates using Google ML Kit text recognition
- Supports Norwegian (AB 1234), Swedish classic (ABC 123), Swedish new (ABC 12D), and Dutch plate formats
- Pre-fills trailer number field after photo capture
- File: `lib/core/services/license_plate_service.dart`

### Edit Trailer Number (2025-12-16)
- Ability to edit trailer number from detail screen (admin only)
- Auto-merges entries if new number matches existing trailer

### Custom App Icon (2025-12-16)
- Posten Norge red background (#e32d22)
- Truck with location pin design
- Adaptive icon configuration in pubspec.yaml

### OTA Testing and Validation (2025-12-14)
- Successfully tested Shorebird OTA updates
- Confirmed automatic patch download and application works
- Added OTA Updates indicator in Settings screen

### Admin Delete Functionality (2025-12-14)
- Implemented trailer deletion (admin only)
- Added backend DELETE endpoint with authentication
- Delete button visible to admin users in trailer detail screen

### Shorebird Integration (2025-12-14)
- Initialized Shorebird for OTA updates
- Configured automatic update checking on app launch
- Added APK distribution via HTTPS

### SMS Implementation (2025-12-12)
- Custom MethodChannel for direct SMS sending on Android
- Native Kotlin implementation in MainActivity.kt

### Authentication
- Phone-based login with JWT
- Remember Me functionality with Hive storage
- Admin panel for user management
