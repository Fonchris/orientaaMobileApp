# Orientaa Mobile App

A production-style Flutter mobile application for African students and counsellors to explore universities, courses and scholarships abroad. Built with **Firebase Authentication**, **Cloud Firestore**, **Firebase Storage** and a Django REST backend.

---

## ✨ Features

### Authentication (Firebase Auth)
- Email/password sign-up with email verification
- Email/password login (unverified emails are blocked with a resend option)
- Passwordless email-link sign-in (deep links via `app_links`)
- Google OAuth sign-in (`google_sign_in`)
- Password reset email flow

### Onboarding
- 3-page welcome slideshow (`WelcomePage`)
- Role selection — Student or Counsellor (`OnboardingPage`)
- 6-step student onboarding (identity, location, financial, self-assessment, Big-Five personality, optional academics)
- Data saved to Firestore under `users/{uid}/onboardingData`

### App Shell (`AppShell`)
Bottom navigation with 4 tabs:

| Tab | Screen | Highlights |
|-----|--------|------------|
| Home | `HomeDashboard` | Greeting, notification bell with unread badge, recommended universities, upcoming counsellor session, suggested classrooms, recent activity |
| Search | `SearchPage` | Single search field with People / Universities / Classrooms / Posts tabs, role filters, recent + suggested + trending searches |
| Messages | `MessagesPage` / `ChatPage` | Inbox sorted by latest message, unread indicators, 1:1 + classroom conversations, privacy gating (followers-only), chat composer |
| Profile | `ProfilePage` | Photo upload, role badge, stats (followers/following/posts), academic summary, posts feed, follow/unfollow, edit profile, settings |

### Profile (`lib/widgets/profile/`)
- **ProfileHeader** — initials/photo avatar (Firebase Storage upload with camera/gallery picker, compression, progress dialog), name, role badge (Student / Counsellor / **Verified Counsellor** driven by real data), location, expandable bio with character-capped editing
- **ProfileStats** — tappable Followers / Following / Posts
- **AcademicSummaryCard** — education, degree goal, field of interest, saved universities, full onboarding details sheet
- **Posts** — live Firestore stream, likes (`likedBy` + counter), owner-only Edit/Delete overflow menu, relative timestamps, image support
- **Connections** — Followers / Following screens
- **EditProfile** — prefilled, validates, syncs Firestore + Firebase Auth display name
- **Settings** — account, password reset, Google link status, granular notifications, language, privacy (who can message you, saved-universities visibility), appearance (System/Light/Dark), logout, delete account (typed-email confirmation)
- **Follow/unfollow** — real Firestore batches with synced counters

### Localization (full in-app translation)
- **EN / FR / AR / PT** via `flutter_localizations` + ARB files (`lib/l10n/*.arb`)
- Live language switching in Settings, persisted in SharedPreferences
- **Arabic (RTL)** supported end-to-end, including the bundled **Cairo** variable font (`assets/fonts/Cairo-Variable.ttf`) which covers Arabic + Latin glyphs — the font family switches automatically when the locale is Arabic

### Theme
- Blue/gold brand theme (`AppTheme`) with intentionally designed **light and dark** modes (no naive color inversion)
- System / Light / Dark mode picker in Settings, persisted via `ThemeProvider`

### Media (Firebase Storage)
- Profile photos → `profile_photos/{uid}.jpg` (deterministic path = automatic overwrite)
- Post images → `post_images/{uid}/{timestamp}.jpg`
- Client-side compression via `image_picker` (`maxWidth`/`imageQuality`) — no cloud function needed
- `MediaService` handles uploads with progress, error handling and orphan cleanup

---

## 🏗 Architecture

```
┌──────────────────────────────────────────────────────────────┐
│                        FLUTTER APP                           │
│                                                              │
│  Welcome → Login/Signup/Reset → Onboarding → Role selection  │
│                                                │             │
│                                                ▼             │
│                                        AppShell (4 tabs)     │
│                          ┌──────────────┬───────┬──────────┐ │
│                          ▼              ▼       ▼          ▼ │
│                     HomeDashboard   Search   Messages   Profile
│                                                              │
│  AuthService ──► Firebase Authentication                     │
│  ProfileService ─► Cloud Firestore (users, posts, followers, │
│                    following, conversations, notifications,  │
│                    universities, classrooms, sessions)       │
│  MessagingService ─► Firestore conversations/messages        │
│  MediaService ──► Firebase Storage (profile_photos,          │
│                   post_images)                               │
│  AuthService ──► HTTP → Django backend (optional, /api/...)  │
└──────────────────────────────────────────────────────────────┘
```

## Tech Stack

| Layer | Technology |
|-------|-----------|
| **Frontend** | Flutter (Dart) |
| **Auth** | Firebase Authentication |
| **Database** | Cloud Firestore (NoSQL) |
| **Media storage** | Firebase Storage |
| **Localization** | flutter_localizations + intl (EN/FR/AR/PT) |
| **Backend API (optional)** | Django + Django REST Framework |
| **State management** | ChangeNotifier providers + `StreamBuilder`/`FutureBuilder` on Firestore streams |
| **Fonts** | Bundled Cairo variable font (Arabic) + system font elsewhere |

---

## 📁 Project Structure

```
orientaa_mobile_app/
│
├── lib/
│   ├── main.dart                        # Entry point, Firebase init, locale/theme wiring, routes
│   ├── l10n/                            # ARB translation files + generated AppLocalizations
│   │   ├── app_en.arb                   # English template
│   │   ├── app_fr.arb / app_ar.arb / app_pt.arb
│   │   └── app_localizations*.dart      # Generated (flutter gen-l10n)
│   └── widgets/
│       ├── app_theme.dart               # Light/dark ThemeData (blue/gold brand)
│       ├── theme_provider.dart          # System/Light/Dark + persistence
│       ├── locale_provider.dart         # Active locale + persistence
│       ├── google_fonts.dart            # Locale-aware font family wrapper
│       ├── auth_service.dart            # All Firebase auth methods
│       ├── welcome_page.dart            # 3-page onboarding slideshow
│       ├── login_page.dart              # Email/password, passwordless link, Google
│       ├── signup_page.dart             # Account creation + verification
│       ├── reset_password_page.dart     # Password reset email
│       ├── onboarding_page.dart         # Role selection (student/counsellor)
│       ├── role_selection_card.dart     # Animated role card
│       ├── slideshow_scaffold.dart      # Swipeable tutorial scaffold
│       ├── app_shell.dart               # Bottom nav (Home/Search/Messages/Profile)
│       ├── home_dashboard.dart          # Home tab content
│       ├── search_page.dart             # People/Universities/Classrooms/Posts search
│       ├── student_onboarding/          # 6-step onboarding + shared step UI
│       │   ├── step_ui.dart             # StepReveal, StepHeroCard, buttons, StepNavBar
│       │   ├── student_onboarding_page.dart
│       │   └── step{1,2,3,4,5}_*.dart
│       └── profile/
│           ├── profile_models.dart      # ProfileData, PostData, etc.
│           ├── profile_service.dart     # Firestore CRUD (profile, posts, follow, likes)
│           ├── messaging_service.dart   # Conversations + messages
│           ├── media_service.dart       # Image pick/compress/upload to Storage
│           ├── profile_page.dart        # Main profile screen
│           ├── profile_header.dart      # Photo, name, role badge, bio
│           ├── profile_stats.dart       # Followers/Following/Posts row
│           ├── role_badge.dart          # Student/Counsellor/Verified badge
│           ├── profile_avatar.dart      # Initials/network avatar w/ caching
│           ├── academic_summary_card.dart
│           ├── profile_posts_section.dart
│           ├── profile_post_card.dart   # Post with like/edit/delete/image
│           ├── post_composer_page.dart  # Create post (text + optional image)
│           ├── connections_page.dart    # Followers/Following lists
│           ├── edit_profile_page.dart   # Edit personal + academic info
│           ├── settings_page.dart       # Account/notifications/language/privacy/appearance
│           ├── messages_page.dart       # Inbox
│           └── chat_page.dart           # 1:1 + classroom chat
│
├── backend/                             # Optional Django REST backend
│   ├── manage.py
│   ├── requirements.txt
│   ├── authapp/                         # views, urls, firebase admin auth
│   └── config/                          # settings, urls, wsgi
│
├── assets/
│   ├── fonts/Cairo-Variable.ttf         # Arabic-capable variable font
│   ├── flags/                           # Country flag assets
│   └── images/                          # App logos
│
├── firestore.rules                      # Firestore security rules
├── storage.rules                        # Storage security rules
├── firestore.indexes.json               # Composite index manifest
├── firebase.json                        # Firebase CLI deploy config
├── .firebaserc                          # Firebase project alias
├── l10n.yaml                            # gen-l10n configuration
├── android/ ios/ web/ linux/ macos/ windows/
└── test/                                # Widget + unit tests
```

---

## 🔥 Firebase Setup (required once)

The app requires a Firebase project with **Authentication**, **Cloud Firestore** and **Storage** enabled.

1. **Enable Firebase Storage** in the Firebase console (free tier) — the only service you must turn on beyond Auth/Firestore.
2. **Deploy security rules** (from the project root, with the Firebase CLI installed and logged in):
   ```bash
   firebase login
   firebase deploy --only firestore:rules,storage
   ```
   - `firestore.rules` — authenticated users can read/write their own data; follow/unfollow and likes are explicitly allowed to update the affected counters; notifications, posts, conversations, universities, classrooms and sessions are covered.
   - `storage.rules` — profile photos and post images are locked to their owner (`request.auth.uid == uid`) with size/content-type checks.
3. **Android**: `android/app/google-services.json` (already present locally; gitignored).
4. **iOS**: `ios/Runner/GoogleService-Info.plist` (gitignored).

### Firestore data model

| Collection | Document | Purpose |
|-----------|----------|---------|
| `users/{uid}` | profile fields + `onboardingData` | User profile + onboarding answers |
| `users/{uid}/followers` / `following` | `{uid, name, photoUrl, ...}` | Social graph |
| `users/{uid}/notifications` | `{type, read, createdAt, ...}` | Notification inbox |
| `posts` | `{authorId, content, imageUrl, likesCount, likedBy, createdAt}` | User posts |
| `conversations` | `{participantIds, lastMessage, lastMessageAt}` | Messaging |
| `conversations/{id}/messages` | `{senderId, text, createdAt}` | Chat messages |
| `universities` / `classrooms` / `sessions` | discovery data | Dashboard recommendations |

> **Note:** the `universities`, `classrooms`, `sessions` and `notifications` collections are empty until seeded — the UI shows friendly empty states instead of fake data.

---

## 🌍 Localization

- Add/update strings in `lib/l10n/app_en.arb` (the template), then mirror the key in `app_fr.arb`, `app_ar.arb` and `app_pt.arb`.
- Regenerate the Dart bindings:
  ```bash
  flutter gen-l10n
  ```
- Access translations with `AppLocalizations.of(context).someKey`.
- Language switching lives in **Settings → Language**. Arabic enables RTL automatically (Flutter handles directionality) and switches the app font to Cairo.

---

## ▶️ Running the App

### Prerequisites
- Flutter SDK (Dart `^3.11.4`)
- A Firebase project configured as above
- (Optional) Python 3.x for the Django backend

### 1. Start the Django backend (optional)
```bash
cd backend
pip install -r requirements.txt
python manage.py runserver
```
The app hits it at `http://10.0.2.2:8000` (Android emulator) / `127.0.0.1:8000` (iOS/desktop). The backend is **optional** — Firebase Auth/Firestore work without it; `ApiConfig` (`lib/widgets/api_config.dart`) points at the local dev URL.

### 2. Run the Flutter app
```bash
flutter pub get
flutter run
```

---

## 🧪 Testing

```bash
flutter analyze
flutter test
```

Tests cover onboarding step navigation, the self-assessment split flow, profile models and profile widgets (all with localization delegates wired in).

---

## 🔒 Security

- Firebase Auth is the source of truth for identity; Firestore/Storage rules enforce ownership.
- Follow/unfollow and like counters use **batched writes** so counts stay in sync.
- Deleting an account requires the user to type their email to confirm; destructive actions always confirm first.
- No secrets are committed: `google-services.json`, `GoogleService-Info.plist`, service-account keys, `.env`, keystores and backend secrets are gitignored.

---

## 🚀 Production Checklist

- [ ] Replace the Django `SECRET_KEY` placeholder in `backend/config/settings.py`
- [ ] Host the backend (Render/Railway/AWS) and update `ApiConfig.baseUrl` to the deployed URL
- [ ] Deploy Firestore + Storage rules (`firebase deploy`)
- [ ] Seed `universities`, `classrooms`, `sessions` data
- [ ] Add Firestore security rules review + budget alerts
- [ ] Set up app signing keys (gitignored) for release builds
