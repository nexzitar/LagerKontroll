# Trailer Manager App
## Presentation for Management

---

# 1. OVERVIEW

## What is Trailer Manager?

**A mobile application for tracking and managing storage trailers in real-time.**

### The Problem It Solves

- **Before:** Staff had no easy way to know where trailers are located or their current status
- **Before:** Information was scattered, outdated, or simply not recorded
- **Before:** Finding a specific trailer meant physically searching the terminal

### The Solution

- **Now:** Any team member can see ALL trailers on a map in real-time
- **Now:** Every trailer has a photo, GPS location, status, and history
- **Now:** Finding a trailer takes seconds, not minutes

### Key Talking Point

> "Instead of walking around looking for trailers, our team can now locate any trailer instantly from their phone."

---

# 2. KEY FEATURES

## 2.1 Trailer Tracking (Core Feature)

- **Create new entries** with a single photo capture
- **View all trailers** in a sortable, filterable list
- **Edit existing trailers** - update status, location, notes
- **Delete trailers** when no longer needed (admin only)
- **Search and filter** by terminal, status, or date

### Talking Point

> "Every trailer in our system has complete documentation - photo, location, status, and full history."

---

## 2.2 Camera Capture with Photo Documentation

- **Built-in camera** - no switching between apps
- **High-quality photos** for visual identification
- **Flash control** with 4 modes: Auto, On, Torch (continuous light), Off
- **Fullscreen photo viewer** for detailed inspection

### Talking Point

> "One tap to open the camera, one tap to capture. The photo is automatically linked to the trailer record."

---

## 2.3 License Plate OCR (Automatic Detection)

- **Scans photos automatically** for license plate numbers
- **Supports multiple formats:**
  - Norwegian plates (AB 1234)
  - Swedish classic (ABC 123)
  - Swedish new format (ABC 12D)
  - Dutch plates
- **Auto-fills trailer number** - reduces manual typing errors

### Talking Point

> "The app reads the license plate from the photo and fills in the number automatically - fewer typing errors, faster entry."

---

## 2.4 GPS Location Tracking

- **Automatic GPS capture** when creating entries
- **Precise coordinates** stored with each entry
- **Location refresh** button to update position
- **Address display** where available

### Talking Point

> "Every entry captures the exact GPS coordinates, so we always know where the trailer was last seen."

---

## 2.5 Interactive Map View

- **See all trailers on a satellite map**
- **Color-coded markers:**
  - Green = Empty (available)
  - Red/Orange = Loaded
  - Yellow = In Ramp (at dock)
- **Tap markers** to see trailer details
- **Filter by terminal** (LSO, B1-B5, or specific terminal)
- **Zoom to terminal boundaries** automatically

### Talking Point

> "Managers can open the map and instantly see where every trailer is located and its current status."

---

## 2.6 Status Management

### Three Clear Statuses

| Status | Meaning | Color |
|--------|---------|-------|
| **Empty** | Trailer is available | Green |
| **Loaded** | Trailer contains cargo | Orange |
| **In Ramp** | Trailer is at a dock | Blue |

- **Ramp number** can be specified (e.g., "Ramp 3")
- **Quick status updates** without creating new entry
- **Optional GPS update** when changing status remotely

### Talking Point

> "Drivers can update status in seconds - tap Edit Status, select the new status, done."

---

## 2.7 Terminal Filtering

### Supported Terminals

- **LSO** (combined view of B1-B5)
- **B1, B2, B3, B4, B5** (individual terminals)
- **OT** (external terminal)

### Features

- **Quick filter chips** to show only trailers at specific terminals
- **Summary bar** shows count per status (Empty/Loaded/In Ramp/All)
- **Tap summary items** to filter instantly
- **Terminal auto-detection** based on GPS when creating entries

### Talking Point

> "Tap 'LSO' to see all trailers at the main facility, or tap a specific terminal like B3 for a focused view."

---

## 2.8 History Tracking

- **Complete history** for each trailer
- **See all status changes** with timestamps
- **Track who made changes** (user attribution)
- **View historical photos** for each entry
- **Timestamps in local timezone**

### Talking Point

> "Every change is logged. We can see exactly when a trailer changed status and who updated it."

---

# 3. USER MANAGEMENT

## 3.1 Three User Roles

| Role | Can View | Can Create/Edit | Can Delete | Admin Panel |
|------|----------|-----------------|------------|-------------|
| **Guest** | Yes | No | No | No |
| **User** | Yes | Yes | No | No |
| **Admin** | Yes | Yes | Yes | Yes |

---

## 3.2 Admin Capabilities

- **Create new users** with auto-generated secure passwords
- **Delete users** who no longer need access
- **Change user roles** (promote/demote users)
- **View all users** and their creation dates
- **Delete trailers** from the system

### Talking Point

> "Admins have full control over who can access the system and what they can do."

---

## 3.3 Regular User Capabilities

- **View all trailers** and their details
- **Create new trailer entries** with photos
- **Update trailer status** and location
- **Edit trailer information** (terminal, notes)
- **Change their own password**

### Talking Point

> "Standard users can do everything needed for daily operations - just not delete data or manage other users."

---

## 3.4 Guest Capabilities

- **View-only access** to all trailers
- **See map, list, and details**
- **Cannot create, edit, or delete** anything

### Talking Point

> "Guest accounts are perfect for managers or partners who need visibility but shouldn't modify data."

---

## 3.5 SMS-Based Onboarding

### How New Users Get Started

1. Admin enters user's name and phone number
2. System generates a secure password automatically
3. **SMS is sent directly** with login credentials + app download link
4. User downloads app and logs in
5. User is prompted to change password on first login

### The SMS Contains

- Welcome message
- Phone number (username)
- Generated password
- Direct download link for the app

### Talking Point

> "Adding a new user takes 30 seconds. They receive everything they need via SMS to start immediately."

---

# 4. TECHNICAL HIGHLIGHTS

## 4.1 Over-The-Air Updates (OTA)

**No App Store needed for updates!**

- **Shorebird Code Push** technology
- Updates download automatically when app launches
- Users don't need to do anything
- Bug fixes and improvements deploy instantly

### Talking Point

> "We can push updates to all users instantly - no waiting for app store approval, no asking users to update manually."

---

## 4.2 Direct SMS Sending

- **SMS sent from the device** - no third-party SMS service costs
- Works on Android devices automatically
- No user interaction needed (doesn't open SMS app)
- Handles long messages automatically

### Talking Point

> "New user credentials are sent instantly via SMS from the admin's phone."

---

## 4.3 Real-Time Updates

- **Pull-to-refresh** on all screens
- **Instant sync** with backend server
- **Automatic data reload** when returning to screens

### Talking Point

> "Data is always fresh - just pull down to refresh and see the latest information."

---

## 4.4 Cross-Platform Ready

- Built with **Flutter** (Google's framework)
- Currently deployed on **Android**
- **iOS version** possible with minimal additional work

### Talking Point

> "Currently on Android, but the codebase is ready for iOS if needed in the future."

---

## 4.5 Professional Architecture

- **Clean Architecture** pattern
- **Riverpod** state management
- **JWT authentication** for security
- **Dio** HTTP client with retry logic
- **Hive** secure local storage

### Talking Point (if asked about technical details)

> "Built with industry best practices - maintainable, scalable, and secure."

---

# 5. SECURITY

## Authentication

- **Phone number + password** login
- **JWT tokens** for secure API access
- **Remember Me** option for convenience
- **Token expiration** for security

## Authorization

- **Role-based access control** (Guest/User/Admin)
- **Admin-only operations** properly restricted
- **API validates permissions** on every request

## Data Protection

- **Secure password generation** for new users
- **HTTPS encryption** for all data in transit
- **Server-side validation** of all inputs

### Talking Point

> "Security is built in at every level - from login to data transmission to role-based access control."

---

# 6. CURRENT STATUS

## Version Information

- **Current Version:** 1.2.1
- **Platform:** Android (API 21+)
- **Backend:** Hosted on lassi.cloud

## Recent Improvements

- License plate OCR with flash control
- In-Ramp status with ramp numbers
- Interactive map view
- SMS-based user onboarding
- OTA updates (Shorebird)
- Terminal geofencing (auto-detect location)

---

# 7. FUTURE POSSIBILITIES

## Potential Enhancements

- **iOS version** deployment
- **Barcode/QR scanning** for trailer IDs
- **Push notifications** for status changes
- **Reporting dashboard** with statistics
- **Offline mode** with sync when back online
- **Integration with other systems** (ERP, logistics platforms)
- **Multi-language support** (Norwegian, Swedish, English)

### Talking Point

> "The foundation is solid. We can add these features as business needs evolve."

---

# SUMMARY

## Key Benefits

1. **Visibility** - Know where every trailer is, instantly
2. **Efficiency** - Update status in seconds, not minutes
3. **Accuracy** - OCR reduces manual entry errors
4. **History** - Complete audit trail of all changes
5. **Access Control** - Right people have right permissions
6. **Easy Deployment** - OTA updates, SMS onboarding

## Business Value

- **Less time** spent searching for trailers
- **Better planning** with real-time visibility
- **Fewer errors** with automated plate detection
- **Complete accountability** with history tracking
- **Instant updates** to all users via OTA

---

# DEMO NOTES

## Suggested Demo Flow

1. **Show the list** - Pull to refresh, show summary bar
2. **Filter by status** - Tap "Empty" to filter, then "All"
3. **Open map view** - Show all trailers on satellite map
4. **Create new entry** - Demonstrate camera and OCR
5. **Edit status** - Show how quick status updates work
6. **Show history** - Demonstrate audit trail
7. **Admin panel** - Show user management (if time permits)

---

# CONTACT & SUPPORT

For questions about this presentation or the Trailer Manager app:
- Backend API: lassi.cloud
- Current Version: 1.2.1+11
- OTA Updates: Enabled

---

*Document generated for management presentation - January 2026*
