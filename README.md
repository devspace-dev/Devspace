# DevSpace Flutter 🚀

A social platform for college developers — built with Flutter for Android, iOS & Web.

## Getting Started

### Prerequisites
- Flutter SDK `>=3.0.0`
- Android Studio / Xcode (for device builds)
- A device or emulator

### Run the App

```bash
# 1. Install dependencies
flutter pub get

# 2. Run on Android
flutter run -d android

# 3. Run on iOS
flutter run -d ios

# 4. Run on Web
flutter run -d chrome

# 5. Build release APK (Android)
flutter build apk --release

# 6. Build App Bundle (Play Store)
flutter build appbundle --release
```

## Project Structure

```
lib/
├── main.dart             # Entry point + providers
├── app.dart              # Shell with bottom nav
├── models/               # Data models
│   ├── user_model.dart
│   ├── post_model.dart
│   ├── badge_model.dart
│   └── question_model.dart
├── providers/            # State management (Provider)
│   ├── auth_provider.dart
│   ├── posts_provider.dart
│   ├── users_provider.dart
│   └── aura_provider.dart
├── screens/              # Full pages
│   ├── splash_screen.dart
│   ├── home_screen.dart
│   ├── people_screen.dart
│   ├── profile_screen.dart
│   ├── aura_board_screen.dart
│   └── qa_screen.dart
├── widgets/              # Reusable components
│   ├── user_avatar.dart
│   ├── aura_pill.dart
│   ├── aura_bar.dart
│   ├── post_card.dart
│   ├── story_reel.dart
│   ├── compose_box.dart
│   ├── profile_card.dart
│   └── bottom_nav.dart
├── theme/
│   ├── app_theme.dart
│   └── app_colors.dart
├── data/                 # Mock data
│   ├── mock_users.dart
│   └── mock_posts.dart
└── utils/
    ├── constants.dart
    └── aura_helpers.dart
```

## Aura System

| Badge    | Aura Range    |
|----------|---------------|
| 🌱 Sprout  | 0 – 999       |
| ✨ Spark   | 1,000 – 1,999 |
| 🔥 Flame   | 2,000 – 2,999 |
| ⚡ Voltage | 3,000 – 4,999 |
| 🌟 Nova    | 5,000+        |

## Tech Stack
- **Flutter 3** — cross-platform (Android, iOS, Web)
- **Provider** — state management
- **MongoDB Atlas** — app user profiles, posts, follows, notifications
- **Google Sign-In** — optional authentication provider
- **Google Fonts** — DM Sans typography
- **timeago** — human-readable timestamps
- **go_router** — navigation
- **shared_preferences** — local storage
- **uuid** — unique IDs

## Auth Model
- Email/password and Google sign-in are both supported.
- The app always persists the MongoDB user ID locally in `SharedPreferences`.
- Google sign-in resolves or auto-creates the same MongoDB user record, so both methods can land on one DevSpace profile.

## Next Steps
- [ ] Connect to Firebase (Firestore + Auth)
- [ ] Push notifications (FCM)
- [ ] GitHub integration
- [ ] DMs / Direct Messaging
- [ ] Hackathon tracker
- [ ] Camera / image uploads
