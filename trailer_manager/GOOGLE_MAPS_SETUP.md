# Google Maps API Key Setup

## Issue Fixed

The app was crashing when clicking on a trailer because the Google Maps API key was missing from AndroidManifest.xml.

**Error**: `java.lang.IllegalStateException: API key not found`

## What Was Done

1. ✅ Added Google Maps API key configuration to `android/app/src/main/AndroidManifest.xml`
2. ✅ Added required permissions (INTERNET, ACCESS_FINE_LOCATION, ACCESS_COARSE_LOCATION, CAMERA)

## What You Need To Do

### Get a Google Maps API Key

1. **Go to Google Cloud Console**:
   https://console.cloud.google.com/

2. **Create a new project** (or select existing):
   - Click "Select a project" at the top
   - Click "New Project"
   - Name it something like "Trailer Manager"
   - Click "Create"

3. **Enable Google Maps SDK for Android**:
   - In the search bar, type "Maps SDK for Android"
   - Click on "Maps SDK for Android"
   - Click "Enable"

4. **Create API Credentials**:
   - Go to "Credentials" in the left menu
   - Click "Create Credentials" → "API Key"
   - Copy the API key that's generated
   - **Important**: Click "Restrict Key" for security
     - Under "Application restrictions", select "Android apps"
     - Click "Add an item"
     - Package name: `com.lagerkontroll.trailer_manager`
     - SHA-1 certificate fingerprint: Get it by running:
       ```bash
       keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
       ```
     - Copy the SHA-1 fingerprint
   - Under "API restrictions", select "Restrict key"
   - Select "Maps SDK for Android"
   - Click "Save"

5. **Add the API Key to Your App**:
   - Open: `android/app/src/main/AndroidManifest.xml`
   - Find this line:
     ```xml
     android:value="YOUR_GOOGLE_MAPS_API_KEY_HERE"
     ```
   - Replace `YOUR_GOOGLE_MAPS_API_KEY_HERE` with your actual API key:
     ```xml
     android:value="YOUR_ACTUAL_GOOGLE_MAPS_API_KEY"
     ```

6. **Save and Rebuild**:
   ```bash
   flutter clean
   flutter run
   ```

## Security Best Practices

### ⚠️ IMPORTANT: Never Commit API Keys to Git!

1. **Add API Key to .gitignore**:

   Create a separate file for the API key:

   **Step 1**: Create `android/local.properties` (if not exists):
   ```properties
   GOOGLE_MAPS_API_KEY=AIzaSyYourActualAPIKeyHere
   ```

   **Step 2**: Make sure `android/local.properties` is in `.gitignore`:
   ```
   # In .gitignore
   android/local.properties
   **/android/local.properties
   ```

   **Step 3**: Update `android/app/build.gradle` to read from local.properties:
   ```gradle
   // Add this at the top after "apply plugin"
   def localProperties = new Properties()
   def localPropertiesFile = rootProject.file('local.properties')
   if (localPropertiesFile.exists()) {
       localPropertiesFile.withReader('UTF-8') { reader ->
           localProperties.load(reader)
       }
   }

   // Then in android {} section:
   defaultConfig {
       // ... existing config

       // Add this:
       manifestPlaceholders = [
           googleMapsApiKey: localProperties.getProperty('GOOGLE_MAPS_API_KEY', 'YOUR_GOOGLE_MAPS_API_KEY_HERE')
       ]
   }
   ```

   **Step 4**: Update `AndroidManifest.xml`:
   ```xml
   <meta-data
       android:name="com.google.android.geo.API_KEY"
       android:value="${googleMapsApiKey}" />
   ```

2. **For Production**:
   - Create a separate production API key
   - Restrict it to your production app's SHA-1 certificate
   - Store it securely in your CI/CD environment variables
   - Never hardcode it in source code

## Quick Start (For Development)

If you just want to test quickly and aren't concerned about security yet:

1. Get an API key from Google Cloud Console (steps above)
2. Open `android/app/src/main/AndroidManifest.xml`
3. Replace `YOUR_GOOGLE_MAPS_API_KEY_HERE` with your key
4. Run: `flutter run`

**BUT**: Remember to move it to `local.properties` before committing to Git!

## Troubleshooting

### "API key not found" error
- Make sure the API key is in AndroidManifest.xml
- Check that there are no spaces or special characters
- Rebuild the app: `flutter clean && flutter run`

### Map shows gray screen
- API key is invalid or not enabled
- Maps SDK for Android not enabled in Google Cloud Console
- Check the Android app package name matches in API restrictions

### "This API project is not authorized to use this API"
- Maps SDK for Android not enabled
- Go to Google Cloud Console → Enable "Maps SDK for Android"

### Permission denied errors
- Make sure permissions are in AndroidManifest.xml (already added)
- Grant location permission when app asks

## Cost

Google Maps offers a **free tier**:
- $200 free credit per month
- First 28,500 map loads are free
- After that: $7 per 1,000 loads

For this trailer management app with limited users, you'll likely stay within the free tier.

## Current Status

✅ **AndroidManifest.xml updated** with:
- API key placeholder
- Required permissions
- Proper configuration structure

🔴 **You need to**:
1. Get a Google Maps API key
2. Add it to `android/app/src/main/AndroidManifest.xml`
3. Run `flutter run` again

---

**After adding the API key, the app will work perfectly!** 🚀
