# Firebase Configuration Setup

This document explains how to set up Firebase configuration files for local development.

## 🔐 Required Secret Files

The following files are **required** to run the app but are **excluded from Git** for security:

### 1. `android/app/google-services.json`
- **Required for:** Android builds
- **How to get:** See instructions below

---

## 📥 Getting Configuration Files (First Time Setup)

### Option A: Download from Firebase Console (Recommended)

1. **Go to Firebase Console:**
   - Visit: https://console.firebase.google.com/
   - Navigate to the `routine-timer` project (or ask project owner for access)

2. **Download Android Configuration:**
   - Click the ⚙️ gear icon → "Project settings"
   - Scroll to "Your apps" section
   - Find the Android app (`com.example.routine_timer`)
   - Click the `google-services.json` download button
   - Place the file in: `android/app/google-services.json`

### Option B: Request from Team Member

If you don't have Firebase Console access, request the file from:
- Project owner
- Tech lead
- Via secure channel (Slack DM, encrypted email, password manager)

**⚠️ NEVER commit these files to Git or share publicly!**

---

## ✅ Verification

After placing the configuration files, verify they're in the correct location:

```powershell
# Check Android config exists
Test-Path android/app/google-services.json
# Should return: True

# Verify file is ignored by Git
git status
# Should NOT show google-services.json in changes
```

---

## 🔨 Building the App

Once configuration files are in place:

```powershell
# Get dependencies
flutter pub get

# Run on device
flutter run -d <deviceId>
```

---

## 🎯 Project Configuration Values

For reference, here's what Firebase Console needs when setting up:

- **Android Package Name:** `com.example.routine_timer`
- **Firebase Project Name:** `routine-timer` (or check with team)
- **Firestore Database:** Enabled in test mode
- **Database Location:** `us-central1` (or check with team)

---

## 🚨 Troubleshooting

### Issue: "google-services.json not found" error

**Solution:**
1. Verify file is in `android/app/` directory (NOT `android/`)
2. Check filename is exactly `google-services.json` (lowercase)
3. Run: `flutter clean && flutter pub get`

### Issue: "No matching client found for package name"

**Solution:**
- The package name in `google-services.json` must match `com.example.routine_timer`
- Re-download the correct configuration file from Firebase Console

### Issue: Build fails after adding Firebase

**Solution:**
```powershell
flutter clean
flutter pub get
flutter run
```

### Issue: Google Sign-In not working (PlatformException: sign_in_failed)

**Solution:**
The SHA-1 certificate fingerprint must be added to Firebase Console:

```powershell
# Get your SHA-1 fingerprint
cd android
./gradlew signingReport
# Look for "SHA1" under "Variant: debug"
```

Then:
1. Go to Firebase Console → Project Settings
2. Select your Android app
3. Click "Add fingerprint"
4. Paste the SHA-1 value
5. Re-download `google-services.json` (may not be necessary)
6. Run `flutter clean && flutter run`

---

## 📝 For Project Maintainers

### When creating a new Firebase project:

1. Create project in Firebase Console
2. Get SHA-1 certificate fingerprint:
   ```powershell
   cd android
   ./gradlew signingReport
   # Copy SHA1 value from "Variant: debug" section
   ```
3. Register Android app with:
   - Package name: `com.example.routine_timer`
   - SHA-1 certificate fingerprint (from step 2)
4. Download `google-services.json`
5. Enable Authentication providers (Google, Anonymous)
6. Set up Firestore security rules
7. Share configuration securely with team members
8. Update this document with project name/location if different

### When adding new team members:

1. Grant them Firebase Console access (or)
2. Share configuration files via secure channel
3. Point them to this document

---

## 🔒 Security Notes

- **API keys in these files are safe for client apps** - they're protected by Firebase Security Rules
- **Still shouldn't be public** - avoid committing to public repos
- **Security Rules in Firestore** are what actually protect your data
- **For production:** Consider using Firebase App Check for additional security

