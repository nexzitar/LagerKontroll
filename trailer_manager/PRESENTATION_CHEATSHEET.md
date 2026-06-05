# Trailer Manager - Cheat Sheet

## THE PITCH (30 seconds)
> "Instead of walking around looking for trailers, our team can now locate any trailer instantly from their phone."

---

## KEY FEATURES AT A GLANCE

| Feature | One-liner |
|---------|-----------|
| **Trailer Tracking** | Create, view, edit, search - all trailers in one place |
| **Camera Capture** | One tap to photo, auto-linked to trailer record |
| **License Plate OCR** | Auto-reads plate from photo, fills number automatically |
| **GPS Location** | Every entry captures exact coordinates |
| **Map View** | See ALL trailers on satellite map with color-coded markers |
| **Status Management** | Empty (green), Loaded (orange), In Ramp (blue) |
| **Terminal Filtering** | LSO combined view, or B1-B5 individually |
| **History Tracking** | Complete audit trail - who changed what, when |

---

## USER ROLES

| Role | View | Create/Edit | Delete | Admin Panel |
|------|:----:|:-----------:|:------:|:-----------:|
| **Guest** | Yes | No | No | No |
| **User** | Yes | Yes | No | No |
| **Admin** | Yes | Yes | Yes | Yes |

**New user onboarding:** Admin enters name + phone -> SMS sent automatically with credentials + app link

---

## TECHNICAL WINS

- **OTA Updates** - Push fixes instantly, no app store wait
- **Direct SMS** - Credentials sent from device, no SMS service cost
- **Pull-to-refresh** - Data always fresh
- **Cross-platform ready** - Android now, iOS possible later

---

## SECURITY

- Phone + password login with JWT tokens
- Role-based access control
- HTTPS encryption
- Server validates all requests

---

## BUSINESS VALUE

1. **Less time** searching for trailers
2. **Better planning** with real-time visibility
3. **Fewer errors** with OCR plate detection
4. **Complete accountability** with history
5. **Instant deployment** via OTA updates

---

## CURRENT STATUS

**Version:** 1.2.1 | **Platform:** Android | **Backend:** lassi.cloud

---

## FUTURE POSSIBILITIES

iOS version | Barcode/QR scanning | Push notifications | Reporting dashboard | Offline mode | ERP integration | Multi-language

---

## DEMO FLOW

1. **List** - Pull to refresh, show summary bar counts
2. **Filter** - Tap "Empty" to filter, then "All"
3. **Map** - Open map, show color-coded markers
4. **Create** - Capture photo, show OCR reading plate
5. **Edit Status** - Quick status update demo
6. **History** - Show audit trail for a trailer
7. **Admin** - User management (if time)

---

*Version 1.2.1 - January 2026*
