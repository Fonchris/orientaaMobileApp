# Orientaa Mobile App

A Flutter mobile application with Firebase Authentication and a Django REST backend.

## Architecture Overview

```
┌─────────────────────────────────────────────────────────┐
│                    FLUTTER APP                           │
│                                                          │
│  LoginPage / SignupPage / ResetPasswordPage              │
│       │                                                  │
│       ▼                                                  │
│  AuthService (lib/widgets/auth_service.dart)             │
│       │                                                  │
│       ├──► Firebase Authentication (cloud)               │
│       │      ├── Email/Password signup & login           │
│       │      ├── Passwordless email link sign-in         │
│       │      ├── Google OAuth sign-in                    │
│       │      └── Password reset email                    │
│       │                                                  │
│       └──► HTTP GET → Django Backend (after login)       │
│              http://10.0.2.2:8000/api/profile/           │
│              Header: Authorization: Bearer <Firebase ID> │
│                                                          │
└─────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────┐
│                  DJANGO BACKEND                          │
│                                                          │
│  ProfileView (backend/authapp/views.py)                  │
│       │                                                  │
│       ▼                                                  │
│  FirebaseAuthentication (backend/authapp/authentication) │
│       │                                                  │
│       ▼                                                  │
│  Firebase Admin SDK verifies ID token                    │
│       │                                                  │
│       ▼                                                  │
│  Returns user profile JSON                               │
└─────────────────────────────────────────────────────────┘
```

## Tech Stack

| Layer | Technology |
|-------|-----------|
| **Frontend** | Flutter (Dart) |
| **Authentication** | Firebase Authentication |
| **Backend API** | Django + Django REST Framework |
| **Database (planned)** | Firebase Firestore (NoSQL) |

---

## Authentication Flows

### 1. App Startup (`lib/main.dart`)

```
main()
  → WidgetsFlutterBinding.ensureInitialized()
  → Firebase.initializeApp()        // Connects to Firebase project
  → runApp(OrientaaApp())
      → MaterialApp with routes:
          '/login'         → LoginPage
          '/signup'        → SignupPage
          '/reset-password' → ResetPasswordPage
      → initialRoute: '/login'      // App opens to login screen
```

Firebase is initialized once at startup. The app uses named routes for navigation.

### 2. Sign Up (`lib/widgets/signup_page.dart`)

```
User fills form (name, email, password, confirm password)
  → Validates: all fields filled, email has @, password ≥ 6 chars, passwords match
  → Clicks "Create Account"
  → _signup() called
      → AuthService.signUp(email, password)
          → FirebaseAuth.instance.createUserWithEmailAndPassword()
              → Firebase creates the user account
          → user.sendEmailVerification()
              → Firebase sends a verification email to the user's inbox
          → _auth.signOut()
              → User is signed out so they must verify before logging in
      → Shows "Verification email sent to your@email.com" snackbar
      → Navigates back to login page
```

**Note:** The `name` field is collected but not sent to Firebase Auth (Firebase only stores email/password). The name would need to be saved separately to Firestore.

**Email Verification:** After sign up, the user MUST click the verification link in their email before they can log in. Attempting to log in with an unverified email will show an error message.

### 3. Login (`lib/widgets/login_page.dart`)

#### 3a. Email/Password Login

```
User fills email + password
  → Validates: email not empty, password ≥ 6 chars
  → Clicks "Log In"
  → _login() called
      → AuthService.signIn(email, password)
          → FirebaseAuth.instance.signInWithEmailAndPassword()
              → Firebase verifies credentials
              → Returns UserCredential (user authenticated)
      → Shows "Login successful" snackbar
      → AuthService.getIdToken()
          → Gets Firebase ID token (JWT) from currentUser
      → AuthService.sendTokenToBackend(token)
          → HTTP GET to http://10.0.2.2:8000/api/profile/
          → Header: Authorization: Bearer <token>
          → Django backend verifies token with Firebase Admin SDK
          → Returns user profile data
```

#### 3b. Passwordless Email Link Login

```
User enters email → Clicks "Send Sign-In Link"
  → AuthService.sendSignInLinkToEmail(email)
      → Firebase sends an email with a magic link
      → Email saved to SharedPreferences (for later retrieval)
  → User checks email, clicks the link
  → App opens via deep link (AppLinks package)
  → _handleIncomingEmailLink(link)
      → Checks if link is a valid Firebase sign-in link
      → Retrieves saved email from SharedPreferences
      → AuthService.signInWithEmailLink(email, link)
          → Firebase authenticates the user
```

#### 3c. Google Sign-In

```
User clicks "Continue with Google"
  → AuthService.signInWithGoogle()
      → GoogleSignIn.signIn()       // Opens Google account picker
      → Gets Google auth tokens
      → Creates GoogleAuthProvider credential
      → FirebaseAuth.signInWithCredential(credential)
          → Firebase links Google account to Firebase Auth
```

### 4. Reset Password (`lib/widgets/reset_password_page.dart`)

```
User enters email → Clicks "Send Reset Link"
  → AuthService.sendPasswordResetEmail(email)
      → FirebaseAuth.instance.sendPasswordResetEmail()
          → Firebase sends a password reset email
          → User clicks link → opens Firebase's reset page
          → User sets new password
      → Shows "Password reset email sent. Check your inbox."
```

---

## Project Structure

```
orientaa_mobile_app/
│
├── lib/
│   ├── main.dart                          # App entry point, Firebase init, routes
│   └── widgets/
│       ├── auth_service.dart              # All Firebase auth methods
│       ├── auth_logo.dart                 # Logo widget
│       ├── login_page.dart                # Login UI (email/password, link, Google)
│       ├── signup_page.dart               # Signup UI
│       ├── reset_password_page.dart       # Password reset UI
│       └── theme_provider.dart            # Dark/light theme toggle
│
├── backend/
│   ├── manage.py                          # Django management script
│   ├── requirements.txt                   # Python dependencies
│   ├── authapp/
│   │   ├── views.py                       # ProfileView API endpoint
│   │   ├── authentication.py              # Firebase token verification
│   │   ├── firebase.py                    # Firebase Admin SDK setup
│   │   └── urls.py                        # URL routing
│   └── config/
│       ├── settings.py                    # Django settings
│       ├── urls.py                        # Root URL config
│       └── wsgi.py                        # WSGI config
│
├── android/                               # Android platform files
├── ios/                                   # iOS platform files
├── web/                                   # Web platform files
├── test/                                  # Flutter tests
└── pubspec.yaml                           # Flutter dependencies
```

---

## Key Files Reference

| File | Purpose |
|------|---------|
| `lib/main.dart` | App entry point, Firebase initialization, route definitions |
| `lib/widgets/auth_service.dart` | All Firebase auth methods (signup, login, Google, passwordless, reset) |
| `lib/widgets/login_page.dart` | Login UI with 3 methods: email/password, passwordless link, Google sign-in |
| `lib/widgets/signup_page.dart` | Signup UI: name, email, password, confirm password |
| `lib/widgets/reset_password_page.dart` | Reset password UI: email input, send reset link |
| `backend/authapp/views.py` | Django endpoint returning user profile after Firebase token verification |
| `backend/authapp/authentication.py` | Custom Firebase authentication class for Django REST Framework |
| `backend/authapp/firebase.py` | Firebase Admin SDK initialization |

---

## Running the App

### Prerequisites

- Flutter SDK
- Python 3.x
- A Firebase project with Authentication enabled
- Google services configuration files:
  - `google-services.json` (Android) — already in `android/app/`
  - `GoogleService-Info.plist` (iOS) — already in `ios/Runner/`

### 1. Start the Django Backend

Open a terminal and run:

```bash
cd backend
python manage.py runserver
```

The server starts at `http://127.0.0.1:8000`. The Android emulator reaches it at `http://10.0.2.2:8000`.

### 2. Start the Flutter App

Open another terminal and run:

```bash
flutter run
```

Choose an Android emulator or connected device.

### Important Notes

- **Both the backend server and the emulator must be running** for the full app to work.
- The Django backend is only needed for the `/api/profile/` endpoint. Firebase Authentication works independently.
- For production deployment, the Django backend would be hosted on a cloud server (e.g., Render, Railway, AWS) and the Flutter app would point to that server's URL instead of `10.0.2.2:8000`.

---

## Planned: Firebase Firestore Integration

The app is designed to use **Firebase Firestore** (NoSQL) for data storage. To add it:

```bash
flutter pub add cloud_firestore
```

Then in your code:

```dart
import 'package:cloud_firestore/cloud_firestore.dart';

final firestore = FirebaseFirestore.instance;

// Write data
await firestore.collection('users').doc(userId).set({
  'name': 'John Doe',
  'email': 'john@example.com',
});

// Read data
final doc = await firestore.collection('users').doc(userId).get();
```

### Why Firestore over Realtime Database?

| Feature | Firestore (Recommended) | Realtime Database |
|---------|------------------------|-------------------|
| Data model | Collections > Documents > Fields | Large JSON tree |
| Querying | Powerful (compound, filtering, sorting) | Limited |
| Scaling | Automatic | Manual sharding needed |
| Offline support | Excellent (disk persistence) | Good (in-memory only) |

---

## Development vs Production

| Aspect | Development | Production |
|--------|-------------|------------|
| Backend location | Local machine (`localhost:8000`) | Cloud server (e.g., `https://api.yourdomain.com`) |
| Backend startup | Manual (`python manage.py runserver`) | Automatic (cloud service runs 24/7) |
| API URL in Flutter | `http://10.0.2.2:8000` | `https://your-deployed-url.com` |
| Firebase | Same Firebase project | Same or separate project |