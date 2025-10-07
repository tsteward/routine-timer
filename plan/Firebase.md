# Firebase Integration Plan - Step 7 (Multi-User with Authentication)

This document provides a detailed implementation plan for integrating Firebase Authentication and Firestore into the Routine Timer app to enable **multi-user** cloud-based data persistence.

---

## Overview

**Goal:** Connect the app to Firebase with authentication and persist all routine data per user so that:
- Each user has their own private routine data
- Users can sign in with Google or continue as Guest
- User data persists across app restarts and devices
- Data is secure with per-user access control

**Key Features:**
- 🔐 Google Sign-In authentication
- 👤 Guest/Anonymous authentication (no account needed)
- 🔒 Per-user data isolation with security rules
- ☁️ Cloud sync across devices
- 💾 Offline persistence

**Prerequisites:**
- Steps 1-6 completed (all data models, BLoC, and task management UI working)
- Google account for Firebase Console access
- Physical Android device or emulator for testing

---

## Phase 1: Firebase Project Setup

### Task 1.1: Create Firebase Project

**Steps:**
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Add project" or "Create a project"
3. Enter project name: `routine-timer` (or your preference)
4. **Enable Google Analytics** (recommended for auth tracking)
5. Click "Create Project" and wait for provisioning

**Expected Output:** A new Firebase project visible in the console.

---

### Task 1.2: Register Android App

**Steps:**
1. In Firebase Console, click the Android icon to add an Android app
2. Register app with package name: `com.example.routine_timer`
   - To verify: Check `android/app/build.gradle.kts` for `applicationId`
3. (Optional) Add app nickname: "Routine Timer Android"
4. **Get SHA-1 certificate fingerprint** (required for Google Sign-In):
   ```powershell
   # For debug builds (development)
   cd android
   ./gradlew signingReport
   # Look for "SHA1" under "Variant: debug" - copy this value
   ```
5. Paste SHA-1 in Firebase Console
6. Click "Register app"

**Expected Output:** Android app registered in Firebase project with SHA-1 certificate.

**Important:** SHA-1 is required for Google Sign-In to work on Android.

---

### Task 1.3: Download Configuration Files

**Steps:**
1. Download `google-services.json` file from Firebase Console
2. Place it in `android/app/` directory (NOT in `android/` root)
3. Verify file location: `routine_timer/android/app/google-services.json`
4. **Already excluded from Git** (updated in `.gitignore`)

**Expected Output:** `google-services.json` file in correct location.

**Verification:**
```powershell
# Check file exists
Test-Path android/app/google-services.json
# Should return: True
```

---

### Task 1.4: Configure Android Build Files

**Current State:** The `pubspec.yaml` already includes Firebase dependencies:
- `firebase_core: any`
- `cloud_firestore: any`
- `firebase_auth: any`

**Steps:**

1. **Update `android/build.gradle.kts`** (project-level):
   - Add Google services classpath to dependencies block
   - Verify buildscript repositories include `google()`

2. **Update `android/app/build.gradle.kts`** (app-level):
   - Add Google services plugin at the bottom of the file
   - Ensure `minSdk` is at least 21 (required by Firebase)

3. **Run pub get to download Firebase packages:**
   ```powershell
   flutter pub get
   ```

**Expected Changes:**

**`android/build.gradle.kts`** (project-level) - Add to buildscript dependencies:
```kotlin
buildscript {
    dependencies {
        classpath("com.google.gms:google-services:4.4.0")
    }
}
```

**`android/app/build.gradle.kts`** (app-level) - Add at the end:
```kotlin
// Must be at the bottom
apply(plugin = "com.google.gms.google-services")
```

**Verification:**
```powershell
# Clean and rebuild
flutter clean
flutter pub get
flutter build apk --debug
# Should complete without errors
```

---

### Task 1.5: Enable Firebase Authentication

**Steps:**
1. In Firebase Console, navigate to "Authentication" in left sidebar
2. Click "Get started"
3. Go to "Sign-in method" tab
4. Enable **Google** provider:
   - Click "Google"
   - Toggle "Enable"
   - Set support email (your email)
   - Click "Save"
5. Enable **Anonymous** provider:
   - Click "Anonymous"
   - Toggle "Enable"
   - Click "Save"

**Expected Output:** Both Google and Anonymous authentication providers enabled.

**Verification:** Check that both providers show as "Enabled" in the Sign-in method tab.

---

### Task 1.6: Enable Firestore Database

**Steps:**
1. In Firebase Console, navigate to "Firestore Database" in left sidebar
2. Click "Create database"
3. Select "Start in **production mode**" (we'll add rules in Phase 6)
4. Choose a Cloud Firestore location (e.g., `us-central1` or closest to you)
5. Click "Enable"

**Expected Output:** Firestore database created and ready to use.

**Note:** We're starting in production mode (deny all) and will add proper per-user security rules.

---

## Phase 2: Firebase Initialization & Authentication Setup

### Task 2.1: Initialize Firebase in `main.dart`

**Current State:** The `lib/main.dart` file exists with basic app structure.

**Steps:**
1. Import Firebase packages at the top of `main.dart`
2. Make `main()` function `async`
3. Add `WidgetsFlutterBinding.ensureInitialized()` before Firebase init
4. Call `await Firebase.initializeApp()`
5. Enable Firestore offline persistence
6. Add error handling for initialization failures

**Code Changes for `lib/main.dart`:**

```dart
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> main() async {
  // Ensure Flutter binding is initialized before Firebase
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Initialize Firebase
    await Firebase.initializeApp();
    
    // Enable offline persistence for Firestore
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
  } catch (e) {
    // Log error (in production, use proper logging/crash reporting)
    print('Firebase initialization error: $e');
  }
  
  runApp(const MyApp());
}
```

**Verification:**
```powershell
flutter run -d <deviceId>
# Check console logs - should initialize without errors
```

**Troubleshooting:**
- If you see `MissingPluginException`: Run `flutter clean && flutter pub get`
- If you see `google-services.json not found`: Verify file location in Task 1.3
- If build fails: Check Task 1.4 Gradle configuration

---

### Task 2.2: Add Google Sign-In Package

**Update `pubspec.yaml`:**

```yaml
dependencies:
  # ... existing dependencies ...
  
  # Authentication
  firebase_auth: any
  google_sign_in: ^6.2.1
```

**Run:**
```powershell
flutter pub get
```

---

### Task 2.3: Create Authentication Service

**Create new directory and file:**
- Directory: `lib/src/services/`
- File: `lib/src/services/auth_service.dart`

**Implement `AuthService`:**

```dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Service for handling Firebase Authentication operations.
class AuthService {
  AuthService({
    FirebaseAuth? auth,
    GoogleSignIn? googleSignIn,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn();

  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;

  /// Stream of authentication state changes.
  /// Emits null when signed out, User object when signed in.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Current authenticated user (null if not signed in).
  User? get currentUser => _auth.currentUser;

  /// Current user ID (null if not signed in).
  String? get currentUserId => _auth.currentUser?.uid;

  /// Whether user is currently signed in.
  bool get isSignedIn => _auth.currentUser != null;

  /// Whether user is signed in anonymously (guest).
  bool get isAnonymous => _auth.currentUser?.isAnonymous ?? false;

  /// Sign in with Google account.
  /// Returns null on success, error message on failure.
  Future<String?> signInWithGoogle() async {
    try {
      // Trigger Google Sign-In flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        // User cancelled sign-in
        return 'Sign-in cancelled';
      }

      // Obtain auth details
      final GoogleSignInAuthentication googleAuth = 
          await googleUser.authentication;

      // Create Firebase credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with Google credential
      await _auth.signInWithCredential(credential);
      
      return null; // Success
    } catch (e) {
      print('Google Sign-In error: $e');
      return 'Failed to sign in with Google: $e';
    }
  }

  /// Sign in anonymously (as guest).
  /// Returns null on success, error message on failure.
  Future<String?> signInAnonymously() async {
    try {
      await _auth.signInAnonymously();
      return null; // Success
    } catch (e) {
      print('Anonymous sign-in error: $e');
      return 'Failed to sign in as guest: $e';
    }
  }

  /// Link anonymous account to Google account (upgrade guest to full account).
  /// Returns null on success, error message on failure.
  Future<String?> linkAnonymousToGoogle() async {
    try {
      final user = _auth.currentUser;
      if (user == null || !user.isAnonymous) {
        return 'Not signed in as guest';
      }

      // Trigger Google Sign-In flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        return 'Sign-in cancelled';
      }

      // Obtain auth details
      final GoogleSignInAuthentication googleAuth = 
          await googleUser.authentication;

      // Create Firebase credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Link anonymous account to Google account
      await user.linkWithCredential(credential);
      
      return null; // Success
    } catch (e) {
      print('Account linking error: $e');
      return 'Failed to link accounts: $e';
    }
  }

  /// Sign out current user.
  /// Returns null on success, error message on failure.
  Future<String?> signOut() async {
    try {
      await Future.wait([
        _auth.signOut(),
        _googleSignIn.signOut(),
      ]);
      return null; // Success
    } catch (e) {
      print('Sign-out error: $e');
      return 'Failed to sign out: $e';
    }
  }

  /// Delete current user account and all data.
  /// Returns null on success, error message on failure.
  Future<String?> deleteAccount() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return 'Not signed in';
      }

      await user.delete();
      return null; // Success
    } catch (e) {
      print('Account deletion error: $e');
      return 'Failed to delete account: $e';
    }
  }
}
```

**Key Features:**
- Google Sign-In support
- Anonymous/Guest sign-in support
- Account linking (upgrade guest to Google account)
- Auth state stream for reactive UI
- Comprehensive error handling

---

### Task 2.4: Create Authentication BLoC

**Create new files:**
- `lib/src/bloc/auth_bloc.dart`
- `lib/src/bloc/auth_events.dart`
- `lib/src/bloc/auth_state_bloc.dart`

**`lib/src/bloc/auth_events.dart`:**

```dart
import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

/// Triggered when Firebase auth state changes
class AuthStateChanged extends AuthEvent {
  const AuthStateChanged(this.userId);

  final String? userId;

  @override
  List<Object?> get props => [userId];
}

/// User initiates Google Sign-In
class SignInWithGoogle extends AuthEvent {
  const SignInWithGoogle();
}

/// User initiates Guest/Anonymous Sign-In
class SignInAnonymously extends AuthEvent {
  const SignInAnonymously();
}

/// User initiates sign-out
class SignOut extends AuthEvent {
  const SignOut();
}

/// Guest user upgrades to Google account
class LinkAnonymousToGoogle extends AuthEvent {
  const LinkAnonymousToGoogle();
}

/// User deletes their account
class DeleteAccount extends AuthEvent {
  const DeleteAccount();
}
```

**`lib/src/bloc/auth_state_bloc.dart`:**

```dart
import 'package:equatable/equatable.dart';

enum AuthStatus {
  initial,
  authenticated,
  unauthenticated,
  loading,
}

class AuthBlocState extends Equatable {
  const AuthBlocState({
    this.status = AuthStatus.initial,
    this.userId,
    this.isAnonymous = false,
    this.errorMessage,
  });

  final AuthStatus status;
  final String? userId;
  final bool isAnonymous;
  final String? errorMessage;

  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get isLoading => status == AuthStatus.loading;

  AuthBlocState copyWith({
    AuthStatus? status,
    String? userId,
    bool? isAnonymous,
    String? errorMessage,
  }) {
    return AuthBlocState(
      status: status ?? this.status,
      userId: userId ?? this.userId,
      isAnonymous: isAnonymous ?? this.isAnonymous,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, userId, isAnonymous, errorMessage];
}
```

**`lib/src/bloc/auth_bloc.dart`:**

```dart
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../services/auth_service.dart';

part 'auth_events.dart';
part 'auth_state_bloc.dart';

class AuthBloc extends Bloc<AuthEvent, AuthBlocState> {
  AuthBloc({AuthService? authService})
      : _authService = authService ?? AuthService(),
        super(const AuthBlocState()) {
    on<AuthStateChanged>(_onAuthStateChanged);
    on<SignInWithGoogle>(_onSignInWithGoogle);
    on<SignInAnonymously>(_onSignInAnonymously);
    on<SignOut>(_onSignOut);
    on<LinkAnonymousToGoogle>(_onLinkAnonymousToGoogle);
    on<DeleteAccount>(_onDeleteAccount);

    // Listen to Firebase auth state changes
    _authStateSubscription = _authService.authStateChanges.listen((user) {
      add(AuthStateChanged(user?.uid));
    });
  }

  final AuthService _authService;
  StreamSubscription<User?>? _authStateSubscription;

  @override
  Future<void> close() {
    _authStateSubscription?.cancel();
    return super.close();
  }

  void _onAuthStateChanged(
    AuthStateChanged event,
    Emitter<AuthBlocState> emit,
  ) {
    if (event.userId != null) {
      emit(AuthBlocState(
        status: AuthStatus.authenticated,
        userId: event.userId,
        isAnonymous: _authService.isAnonymous,
      ));
    } else {
      emit(const AuthBlocState(status: AuthStatus.unauthenticated));
    }
  }

  Future<void> _onSignInWithGoogle(
    SignInWithGoogle event,
    Emitter<AuthBlocState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading, errorMessage: null));

    final error = await _authService.signInWithGoogle();

    if (error != null) {
      emit(state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: error,
      ));
    }
    // Auth state change will be handled by _onAuthStateChanged
  }

  Future<void> _onSignInAnonymously(
    SignInAnonymously event,
    Emitter<AuthBlocState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading, errorMessage: null));

    final error = await _authService.signInAnonymously();

    if (error != null) {
      emit(state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: error,
      ));
    }
    // Auth state change will be handled by _onAuthStateChanged
  }

  Future<void> _onSignOut(
    SignOut event,
    Emitter<AuthBlocState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading));

    final error = await _authService.signOut();

    if (error != null) {
      emit(state.copyWith(errorMessage: error));
    }
    // Auth state change will be handled by _onAuthStateChanged
  }

  Future<void> _onLinkAnonymousToGoogle(
    LinkAnonymousToGoogle event,
    Emitter<AuthBlocState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading, errorMessage: null));

    final error = await _authService.linkAnonymousToGoogle();

    if (error != null) {
      emit(state.copyWith(
        status: AuthStatus.authenticated,
        errorMessage: error,
      ));
    }
    // Auth state change will be handled by _onAuthStateChanged
  }

  Future<void> _onDeleteAccount(
    DeleteAccount event,
    Emitter<AuthBlocState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading));

    final error = await _authService.deleteAccount();

    if (error != null) {
      emit(state.copyWith(errorMessage: error));
    }
    // Auth state change will be handled by _onAuthStateChanged
  }
}
```

---

### Task 2.5: Create Sign-In Screen

**Create `lib/src/screens/sign_in_screen.dart`:**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/auth_bloc.dart';
import '../app_theme.dart';

class SignInScreen extends StatelessWidget {
  const SignInScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: BlocConsumer<AuthBloc, AuthBlocState>(
        listener: (context, state) {
          if (state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage!),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(
              child: CircularProgressIndicator(
                color: Colors.white,
              ),
            );
          }

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // App Logo/Title
                  const Icon(
                    Icons.timer,
                    size: 100,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Routine Timer',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Manage your morning routine with ease',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 64),

                  // Google Sign-In Button
                  ElevatedButton.icon(
                    onPressed: () {
                      context.read<AuthBloc>().add(const SignInWithGoogle());
                    },
                    icon: const Icon(Icons.login),
                    label: const Text('Sign in with Google'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Guest Sign-In Button
                  OutlinedButton.icon(
                    onPressed: () {
                      context.read<AuthBloc>().add(const SignInAnonymously());
                    },
                    icon: const Icon(Icons.person_outline),
                    label: const Text('Continue as Guest'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Info Text
                  const Text(
                    'Guest accounts can be upgraded to full accounts later',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white60,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
```

---

### Task 2.6: Update App Root with Auth Check

**Update `lib/main.dart` to handle authentication state:**

```dart
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'src/app_theme.dart';
import 'src/bloc/auth_bloc.dart';
import 'src/bloc/routine_bloc.dart';
import 'src/screens/sign_in_screen.dart';
import 'src/screens/pre_start_screen.dart';
import 'src/services/auth_service.dart';
import 'src/repositories/routine_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp();
    
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
  } catch (e) {
    print('Firebase initialization error: $e');
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        // Auth BLoC - available throughout the app
        BlocProvider(
          create: (context) => AuthBloc(),
        ),
        // Routine BLoC - needs auth for user ID
        BlocProvider(
          create: (context) {
            final authService = AuthService();
            final repository = RoutineRepository(
              authService: authService,
            );
            return RoutineBloc(repository: repository);
          },
        ),
      ],
      child: MaterialApp(
        title: 'Routine Timer',
        theme: appTheme,
        home: const AuthGate(),
      ),
    );
  }
}

/// Widget that shows sign-in screen or main app based on auth state
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthBlocState>(
      builder: (context, authState) {
        // Show sign-in screen if not authenticated
        if (!authState.isAuthenticated) {
          return const SignInScreen();
        }

        // User is authenticated, load their routine
        final routineBloc = context.read<RoutineBloc>();
        if (routineBloc.state.model == null && !routineBloc.state.loading) {
          routineBloc.add(const LoadRoutineFromFirebase());
        }

        // Show main app
        return const PreStartScreen();
      },
    );
  }
}
```

---

## Phase 3: Repository Layer with User ID Support

### Task 3.1: Update Repository to Use User ID

**Update `lib/src/repositories/routine_repository.dart`:**

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/routine_state.dart';
import '../services/auth_service.dart';

/// Repository for persisting and loading routine data from Firebase Firestore.
/// Each user's routine is stored in a separate document: routines/{userId}
class RoutineRepository {
  RoutineRepository({
    FirebaseFirestore? firestore,
    AuthService? authService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _authService = authService ?? AuthService();

  final FirebaseFirestore _firestore;
  final AuthService _authService;

  /// Collection name for routines in Firestore
  static const String _routinesCollection = 'routines';

  /// Reference to the current user's routine document
  /// Returns null if user is not signed in
  DocumentReference<Map<String, dynamic>>? get _userRoutineDoc {
    final userId = _authService.currentUserId;
    if (userId == null) return null;
    
    return _firestore.collection(_routinesCollection).doc(userId);
  }

  /// Saves the entire routine state to Firestore for current user.
  /// Returns true if successful, false otherwise.
  Future<bool> saveRoutine(RoutineStateModel routine) async {
    try {
      final doc = _userRoutineDoc;
      if (doc == null) {
        print('Cannot save routine: user not signed in');
        return false;
      }

      await doc.set(
        routine.toMap(),
        SetOptions(merge: true),
      );
      return true;
    } catch (e) {
      print('Error saving routine: $e');
      return false;
    }
  }

  /// Loads the routine state from Firestore for current user.
  /// Returns null if document doesn't exist or on error.
  Future<RoutineStateModel?> loadRoutine() async {
    try {
      final doc = _userRoutineDoc;
      if (doc == null) {
        print('Cannot load routine: user not signed in');
        return null;
      }

      final snapshot = await doc.get();
      
      if (!snapshot.exists) {
        return null;
      }

      final data = snapshot.data();
      if (data == null) {
        return null;
      }

      return RoutineStateModel.fromMap(data);
    } catch (e) {
      print('Error loading routine: $e');
      return null;
    }
  }

  /// Stream of routine updates from Firestore (for real-time sync)
  /// Returns null initially if document doesn't exist.
  Stream<RoutineStateModel?> watchRoutine() {
    final doc = _userRoutineDoc;
    if (doc == null) {
      return Stream.value(null);
    }

    return doc.snapshots().map((snapshot) {
      if (!snapshot.exists) {
        return null;
      }

      final data = snapshot.data();
      if (data == null) {
        return null;
      }

      try {
        return RoutineStateModel.fromMap(data);
      } catch (e) {
        print('Error parsing routine from snapshot: $e');
        return null;
      }
    });
  }

  /// Deletes the current user's routine from Firestore
  Future<bool> deleteRoutine() async {
    try {
      final doc = _userRoutineDoc;
      if (doc == null) {
        print('Cannot delete routine: user not signed in');
        return false;
      }

      await doc.delete();
      return true;
    } catch (e) {
      print('Error deleting routine: $e');
      return false;
    }
  }
}
```

**Key Changes:**
- Repository now requires `AuthService` to get current user ID
- All operations use `routines/{userId}` document path
- Null-safe handling when user not signed in
- Same API, but per-user data storage

---

### Task 3.2: Update RoutineBloc to Handle Auth State

**Update `lib/src/bloc/routine_bloc.dart` event handlers:**

```dart
// Add this event handler to reload when user signs in
on<ReloadRoutineForUser>(_onReloadRoutineForUser);

void _onReloadRoutineForUser(
  ReloadRoutineForUser event,
  Emitter<RoutineBlocState> emit,
) {
  // Clear current state
  emit(const RoutineBlocState());
  
  // Load data for new user
  add(const LoadRoutineFromFirebase());
}
```

**Add event in `routine_events.dart`:**

```dart
/// Reload routine when user changes (sign in/out)
class ReloadRoutineForUser extends RoutineEvent {
  const ReloadRoutineForUser();
}
```

**Update `AuthGate` widget to trigger reload:**

```dart
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthBlocState>(
      listener: (context, authState) {
        // When auth state changes, reload routine for new user
        context.read<RoutineBloc>().add(const ReloadRoutineForUser());
      },
      child: BlocBuilder<AuthBloc, AuthBlocState>(
        builder: (context, authState) {
          if (!authState.isAuthenticated) {
            return const SignInScreen();
          }

          return const PreStartScreen();
        },
      ),
    );
  }
}
```

---

## Phase 4: Testing Authentication

### Task 4.1: Unit Tests for AuthService

**Create `test/src/services/auth_service_test.dart`:**

```dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:routine_timer/src/services/auth_service.dart';

void main() {
  group('AuthService', () {
    late MockFirebaseAuth mockAuth;
    late AuthService authService;

    setUp(() {
      mockAuth = MockFirebaseAuth();
      authService = AuthService(auth: mockAuth);
    });

    test('currentUser returns null when not signed in', () {
      expect(authService.currentUser, isNull);
      expect(authService.isSignedIn, isFalse);
    });

    test('signInAnonymously creates anonymous user', () async {
      final error = await authService.signInAnonymously();

      expect(error, isNull);
      expect(authService.isSignedIn, isTrue);
      expect(authService.isAnonymous, isTrue);
    });

    test('currentUserId returns user ID when signed in', () async {
      await authService.signInAnonymously();

      expect(authService.currentUserId, isNotNull);
      expect(authService.currentUserId, isA<String>());
    });

    test('signOut clears current user', () async {
      await authService.signInAnonymously();
      expect(authService.isSignedIn, isTrue);

      final error = await authService.signOut();

      expect(error, isNull);
      expect(authService.isSignedIn, isFalse);
    });
  });
}
```

**Add dependency to `pubspec.yaml`:**

```yaml
dev_dependencies:
  firebase_auth_mocks: ^0.13.0
```

---

### Task 4.2: Manual Testing - Sign In Flow

**Test Case 1: Guest Sign-In**

**Steps:**
1. Run the app: `flutter run -d <deviceId>`
2. App should show Sign-In screen (black background)
3. Tap "Continue as Guest"
4. Should see loading indicator briefly
5. Should navigate to main app (Pre-Start or Task Management screen)

**Expected Result:**
- Guest user created in Firebase Authentication
- User can access the app
- No data yet (empty routine or sample data)

**Verification:**
- Check Firebase Console → Authentication → Users
- Should see one anonymous user listed

---

**Test Case 2: Google Sign-In**

**Steps:**
1. Force-quit and restart app
2. Tap "Sign in with Google"
3. Choose Google account
4. Grant permissions
5. Should navigate to main app

**Expected Result:**
- Google user created in Firebase Authentication
- User can access the app
- Different user ID than guest account

**Verification:**
- Check Firebase Console → Authentication → Users
- Should see Google account listed with email

---

**Test Case 3: Data Isolation**

**Steps:**
1. Sign in as Guest
2. Add task "Guest Task"
3. Sign out (need to add sign-out button)
4. Sign in with Google
5. Check tasks list

**Expected Result:**
- "Guest Task" should NOT appear for Google user
- Each user has separate data
- Guest data still exists if you sign back in as guest

---

### Task 4.3: Add Sign-Out Button

**Update Task Management screen or add to app bar:**

```dart
IconButton(
  icon: const Icon(Icons.logout),
  onPressed: () {
    context.read<AuthBloc>().add(const SignOut());
  },
  tooltip: 'Sign Out',
)
```

**Add user info display:**

```dart
BlocBuilder<AuthBloc, AuthBlocState>(
  builder: (context, authState) {
    if (!authState.isAuthenticated) return const SizedBox();

    return ListTile(
      leading: Icon(
        authState.isAnonymous ? Icons.person_outline : Icons.person,
      ),
      title: Text(authState.isAnonymous ? 'Guest User' : 'Google Account'),
      subtitle: Text(authState.userId ?? ''),
      trailing: IconButton(
        icon: const Icon(Icons.logout),
        onPressed: () {
          context.read<AuthBloc>().add(const SignOut());
        },
      ),
    );
  },
)
```

---

## Phase 5: Security Rules (Production Ready)

### Task 5.1: Update Firestore Security Rules

**Current State:** Production mode (deny all).

**Per-User Security Rules:**

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Helper function: user is authenticated
    function isSignedIn() {
      return request.auth != null;
    }
    
    // Helper function: user owns the document
    function isOwner(userId) {
      return isSignedIn() && request.auth.uid == userId;
    }
    
    // Routines collection: users can only access their own routine
    match /routines/{userId} {
      // Allow read/write only if authenticated and accessing own document
      allow read, write: if isOwner(userId);
    }
    
    // Deny all other access
    match /{document=**} {
      allow read, write: if false;
    }
  }
}
```

**Steps to Apply:**
1. In Firebase Console, go to Firestore Database
2. Click "Rules" tab
3. Replace existing rules with the above
4. Click "Publish"

**Security Features:**
✅ Users must be authenticated (logged in or guest)  
✅ Users can only read/write their own data  
✅ Guest accounts have same access as Google accounts  
✅ No cross-user data access possible  

**Verification:**
```powershell
# Run the app and test:
# 1. Sign in as user A, add tasks
# 2. Sign out, sign in as user B
# 3. User B should NOT see user A's tasks
# 4. Check Firebase Console for separate documents
```

---

## Phase 6: Advanced Features

### Task 6.1: Account Linking (Upgrade Guest to Google)

**Add "Upgrade Account" button for guest users:**

**In Task Management screen settings section:**

```dart
BlocBuilder<AuthBloc, AuthBlocState>(
  builder: (context, authState) {
    if (!authState.isAnonymous) return const SizedBox();

    return Card(
      margin: const EdgeInsets.all(16),
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.info_outline, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'Guest Account',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'You\'re signed in as a guest. Upgrade to a Google account to access your routine from other devices.',
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () async {
                // Show confirmation dialog
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Upgrade Account'),
                    content: const Text(
                      'Link your guest account to Google? Your routine data will be preserved.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Upgrade'),
                      ),
                    ],
                  ),
                );

                if (confirm == true && context.mounted) {
                  context.read<AuthBloc>().add(const LinkAnonymousToGoogle());
                }
              },
              icon: const Icon(Icons.upgrade),
              label: const Text('Upgrade to Google Account'),
            ),
          ],
        ),
      ),
    );
  },
)
```

**What Happens:**
1. Guest user taps "Upgrade"
2. Google Sign-In flow starts
3. Firebase links accounts
4. **User ID remains the same** - data is preserved!
5. User now has full Google account with same data

---

### Task 6.2: Real-Time Multi-Device Sync

**Update RoutineBloc to listen to Firestore stream:**

```dart
StreamSubscription<RoutineStateModel?>? _routineSubscription;

RoutineBloc({RoutineRepository? repository})
    : _repository = repository ?? RoutineRepository(),
      super(RoutineBlocState.initial()) {
  // ... existing event handlers ...
  
  on<StartWatchingRoutine>(_onStartWatching);
  on<StopWatchingRoutine>(_onStopWatching);
  on<RoutineUpdatedFromFirebase>(_onRoutineUpdatedFromFirebase);
}

@override
Future<void> close() {
  _routineSubscription?.cancel();
  _saveDebouncer.dispose();
  return super.close();
}

void _onStartWatching(
  StartWatchingRoutine event,
  Emitter<RoutineBlocState> emit,
) {
  _routineSubscription?.cancel();
  
  _routineSubscription = _repository.watchRoutine().listen((routine) {
    if (routine != null) {
      add(RoutineUpdatedFromFirebase(routine));
    }
  });
}

void _onStopWatching(
  StopWatchingRoutine event,
  Emitter<RoutineBlocState> emit,
) {
  _routineSubscription?.cancel();
}

void _onRoutineUpdatedFromFirebase(
  RoutineUpdatedFromFirebase event,
  Emitter<RoutineBlocState> emit,
) {
  // Only update if data actually changed (avoid infinite loops)
  if (state.model != event.routine) {
    emit(state.copyWith(model: event.routine));
  }
}
```

**Add events:**

```dart
class StartWatchingRoutine extends RoutineEvent {
  const StartWatchingRoutine();
}

class StopWatchingRoutine extends RoutineEvent {
  const StopWatchingRoutine();
}

class RoutineUpdatedFromFirebase extends RoutineEvent {
  const RoutineUpdatedFromFirebase(this.routine);
  
  final RoutineStateModel routine;
  
  @override
  List<Object> get props => [routine];
}
```

**Start watching after login:**

```dart
void _onLoadFromFirebase(
  LoadRoutineFromFirebase event,
  Emitter<RoutineBlocState> emit,
) async {
  emit(state.copyWith(loading: true));

  final routine = await _repository.loadRoutine();

  if (routine != null) {
    emit(state.copyWith(loading: false, model: routine));
  } else {
    emit(state.copyWith(loading: false));
    add(const LoadSampleRoutine());
  }
  
  // Start watching for real-time updates
  add(const StartWatchingRoutine());
}
```

**Benefits:**
- Changes on Device A instantly appear on Device B
- Multiple family members can share routine (future feature)
- Always see latest data across devices

---

## Phase 7: Quality Gate & Completion

### Task 7.1: Complete Test Suite

**Run all tests:**
```powershell
flutter test
```

**Create integration test for full auth flow:**

**`test/integration/auth_flow_test.dart`:**

```dart
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:routine_timer/src/services/auth_service.dart';
import 'package:routine_timer/src/repositories/routine_repository.dart';
import 'package:routine_timer/src/models/routine_state.dart';
import 'package:routine_timer/src/models/routine_settings.dart';
import 'package:routine_timer/src/models/task.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  group('Auth + Repository Integration', () {
    test('different users have separate routine data', () async {
      // Create two mock auth instances for two users
      final auth1 = MockFirebaseAuth(signedIn: true, mockUser: MockUser(
        uid: 'user1',
        email: 'user1@test.com',
      ));
      
      final auth2 = MockFirebaseAuth(signedIn: true, mockUser: MockUser(
        uid: 'user2',
        email: 'user2@test.com',
      ));
      
      // Create services for each user
      final authService1 = AuthService(auth: auth1);
      final authService2 = AuthService(auth: auth2);
      
      // Note: This is a simplified test. In reality, you'd need to mock
      // Firestore as well using fake_cloud_firestore
      
      expect(authService1.currentUserId, 'user1');
      expect(authService2.currentUserId, 'user2');
      expect(authService1.currentUserId, isNot(authService2.currentUserId));
    });
  });
}
```

---

### Task 7.2: Manual Test Checklist

Go through this comprehensive checklist:

#### Authentication Tests
- [ ] Can sign in with Google
- [ ] Can sign in as Guest
- [ ] Can sign out from Google account
- [ ] Can sign out from Guest account
- [ ] Guest account can upgrade to Google
- [ ] After upgrade, data is preserved
- [ ] Sign-in errors show user-friendly messages
- [ ] App shows correct user status (Guest vs Google)

#### Data Persistence Tests
- [ ] Tasks persist after sign-out and sign-in
- [ ] Settings persist after sign-out and sign-in
- [ ] Breaks persist after sign-out and sign-in
- [ ] Different users have separate data
- [ ] Switching users loads correct data

#### Multi-Device Tests (if available)
- [ ] Changes on Device A appear on Device B
- [ ] Offline changes sync when back online
- [ ] No data conflicts or corruption

#### Security Tests
- [ ] Cannot access other users' data
- [ ] Unauthenticated requests fail
- [ ] Security rules enforce per-user access

#### Edge Cases
- [ ] App works offline after initial load
- [ ] Sign-in works on poor network
- [ ] Error handling for network failures
- [ ] Graceful handling of auth errors
- [ ] Account deletion works (if implemented)

---

### Task 7.3: Static Analysis & Formatting

```powershell
# Run analyzer
dart analyze
# Expected: No issues found!

# Format code
dart format .

# Run tests
flutter test

# Generate coverage
flutter test --coverage
```

---

## Success Criteria

Step 7 is complete when:

✅ **Authentication works**: Google and Guest sign-in functional  
✅ **Per-user data**: Each user has separate routine data  
✅ **Data persistence**: All data persists across restarts  
✅ **Security rules**: Proper per-user access control implemented  
✅ **Offline support**: App works offline with cached data  
✅ **Account linking**: Guest can upgrade to Google account  
✅ **All tests pass**: Unit tests and integration tests green  
✅ **Static analysis clean**: 0 errors, 0 warnings  
✅ **Code formatted**: All files properly formatted  
✅ **Manual testing complete**: All checklist items verified  

**Ready for Step 8:** Pre-Start countdown screen implementation.

---

## Estimated Time

- **Phase 1 (Firebase Setup):** 45-60 minutes
- **Phase 2 (Auth Setup):** 90-120 minutes
- **Phase 3 (Repository):** 45 minutes
- **Phase 4 (Testing Auth):** 45 minutes
- **Phase 5 (Security Rules):** 15 minutes
- **Phase 6 (Advanced Features):** 60 minutes (optional)
- **Phase 7 (Quality Gate):** 45 minutes

**Total: 5-7 hours** for core functionality (6-9 hours with advanced features)

---

## Troubleshooting

### Issue: "PlatformException: sign_in_failed"

**Cause:** SHA-1 certificate not configured or doesn't match.

**Solution:**
```powershell
cd android
./gradlew signingReport
# Copy SHA1 for debug variant
# Add to Firebase Console: Project Settings > Your apps > Android > Add fingerprint
```

### Issue: Google Sign-In cancelled immediately

**Cause:** `google-services.json` doesn't match package name or SHA-1 missing.

**Solution:**
1. Verify package name in `google-services.json` matches `com.example.routine_timer`
2. Add SHA-1 certificate fingerprint in Firebase Console
3. Re-download `google-services.json`
4. Run `flutter clean && flutter run`

### Issue: "Permission denied" when accessing Firestore

**Cause:** Security rules not configured correctly.

**Solution:**
1. Check Firebase Console → Firestore → Rules
2. Verify rules match Task 5.1
3. Click "Publish" to apply rules
4. Wait 1-2 minutes for rules to propagate

### Issue: Guest account data lost after linking to Google

**Cause:** Account linking failed or done incorrectly.

**Solution:**
- Use `linkWithCredential()` not `signInWithCredential()`
- The AuthService implementation in Task 2.3 handles this correctly
- Test thoroughly before production

---

## References

- [Firebase Authentication Documentation](https://firebase.google.com/docs/auth)
- [Google Sign-In for Flutter](https://pub.dev/packages/google_sign_in)
- [Anonymous Authentication](https://firebase.google.com/docs/auth/web/anonymous-auth)
- [Firestore Security Rules](https://firebase.google.com/docs/firestore/security/get-started)
- [Account Linking](https://firebase.google.com/docs/auth/flutter/account-linking)
