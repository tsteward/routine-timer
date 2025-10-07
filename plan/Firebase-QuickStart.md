# Firebase Setup Quick Start (Multi-User with Auth)

This is a simplified guide to get Firebase + Authentication working quickly. See `Firebase.md` for the complete detailed plan.

---

## 🚀 Quick Setup (30 Minutes)

### 1. Create Firebase Project (5 min)

1. Go to https://console.firebase.google.com/
2. Click "Add project"
3. Name it: `routine-timer`
4. **Enable Google Analytics** (recommended)
5. Click "Create Project"

---

### 2. Get SHA-1 Certificate (2 min)

This is **required** for Google Sign-In to work:

```powershell
cd android
./gradlew signingReport
```

Look for output like this:
```
Variant: debug
Config: debug
Store: C:\Users\YourName\.android\debug.keystore
Alias: AndroidDebugKey
MD5: XX:XX:XX...
SHA1: A1:B2:C3:D4:E5:F6:G7:H8:I9:J0:K1:L2:M3:N4:O5:P6:Q7:R8:S9:T0  <-- Copy this!
SHA-256: XX:XX:XX...
```

**Copy the SHA1 value** - you'll need it in the next step.

---

### 3. Register Android App (5 min)

1. In Firebase Console, click Android icon
2. Enter package name: `com.example.routine_timer`
3. **Paste the SHA-1 certificate** from step 2
4. Click "Register app"
5. **Download `google-services.json`**
6. Place it in: `android/app/google-services.json`

---

### 4. Enable Authentication (3 min)

1. In Firebase Console sidebar, click "Authentication"
2. Click "Get started"
3. Go to "Sign-in method" tab
4. Enable **Google**:
   - Toggle "Enable"
   - Set support email (your email)
   - Click "Save"
5. Enable **Anonymous**:
   - Toggle "Enable"
   - Click "Save"

---

### 5. Enable Firestore (2 min)

1. In Firebase Console sidebar, click "Firestore Database"
2. Click "Create database"
3. Choose **"Start in production mode"**
4. Select location: `us-central1` (or closest)
5. Click "Enable"

---

### 6. Set Security Rules (2 min)

1. In Firestore, click "Rules" tab
2. Replace with this:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    function isSignedIn() {
      return request.auth != null;
    }
    
    function isOwner(userId) {
      return isSignedIn() && request.auth.uid == userId;
    }
    
    match /routines/{userId} {
      allow read, write: if isOwner(userId);
    }
    
    match /{document=**} {
      allow read, write: if false;
    }
  }
}
```

3. Click "Publish"

---

### 7. Update Code (5 min)

Run these commands:

```powershell
# Install dependencies
flutter pub get

# Clean build
flutter clean

# Run app
flutter run -d <your-device-id>
```

---

## ✅ Verify It Works

You should see:

1. **Sign-In Screen** (black background)
   - "Sign in with Google" button
   - "Continue as Guest" button

2. **Try Guest Sign-In:**
   - Tap "Continue as Guest"
   - Should navigate to main app
   - Check Firebase Console → Authentication → Users
   - Should see 1 anonymous user

3. **Try Google Sign-In:**
   - Sign out (need to implement sign-out button first!)
   - Tap "Sign in with Google"
   - Choose account
   - Should navigate to main app
   - Check Firebase Console → Authentication → Users
   - Should see Google account

4. **Verify Data Isolation:**
   - Add tasks as one user
   - Sign out
   - Sign in as different user
   - Should NOT see first user's tasks

---

## 🎯 What You Get

✅ **Google Sign-In**: Users can sign in with Google account  
✅ **Guest Mode**: Users can try the app without account  
✅ **Per-User Data**: Each user has private routine data  
✅ **Account Linking**: Guests can upgrade to Google account  
✅ **Security**: Firestore rules enforce per-user access  
✅ **Offline Support**: App works without internet  
✅ **Multi-Device**: Access data from multiple devices  

---

## 📋 Files Created/Modified

### New Files to Create:
- `lib/src/services/auth_service.dart` - Authentication service
- `lib/src/bloc/auth_bloc.dart` - Authentication state management
- `lib/src/bloc/auth_events.dart` - Auth events
- `lib/src/bloc/auth_state_bloc.dart` - Auth state
- `lib/src/screens/sign_in_screen.dart` - Sign-in UI
- `lib/src/repositories/routine_repository.dart` - Updated for user ID

### Files to Modify:
- `lib/main.dart` - Add Firebase init, auth providers
- `lib/src/bloc/routine_bloc.dart` - Add auth integration
- `pubspec.yaml` - Add `google_sign_in` package

### Configuration Files:
- `android/app/google-services.json` - Downloaded from Firebase
- `android/build.gradle.kts` - Add Google services plugin
- `android/app/build.gradle.kts` - Apply Google services

---

## 🐛 Common Issues

### Google Sign-In doesn't work

**Problem:** PlatformException: sign_in_failed

**Solution:**
1. Verify SHA-1 is added in Firebase Console
2. Package name matches exactly: `com.example.routine_timer`
3. `google-services.json` is in `android/app/`
4. Run `flutter clean && flutter run`

### Can't access Firestore

**Problem:** Permission denied

**Solution:**
1. Check security rules are published
2. User is signed in (not null)
3. Wait 1-2 minutes for rules to propagate

### Build fails

**Solution:**
```powershell
flutter clean
flutter pub get
cd android
./gradlew clean
cd ..
flutter run
```

---

## 📚 Next Steps

After Firebase + Auth is working:

1. **Add Sign-Out Button** to Task Management screen
2. **Add User Profile Section** showing current user
3. **Implement Account Linking UI** for guest users
4. **Test Multi-Device Sync** (if you have 2 devices)
5. **Move to Step 8** - Pre-Start countdown screen

---

## 🔗 Resources

- Full Plan: `plan/Firebase.md`
- Setup Guide: `FIREBASE_SETUP.md`
- Firebase Console: https://console.firebase.google.com/

---

## ⏱️ Time Estimate

- **Firebase Setup**: 15 minutes
- **Code Implementation**: 2-3 hours
- **Testing**: 30 minutes
- **Total**: 3-4 hours

Good luck! 🚀

