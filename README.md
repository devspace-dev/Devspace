# DevSpace Flutter

A social platform for college developers built with Flutter for mobile.

## Getting Started

### Prerequisites
- Flutter SDK `>=3.0.0`
- Android Studio / Xcode (for device builds)
- A device or emulator
- Supabase project URL and anon key

### Run the App

```bash
# 1. Install dependencies
flutter pub get

# 2. Run on Android
flutter run -d android

# 3. Run on iOS
flutter run -d ios

# 4. Build release APK (Android)
flutter build apk --release

# 5. Build App Bundle (Play Store)
flutter build appbundle --release
```

Pass Supabase credentials at runtime if you are not using the checked-in dev values:

```bash
flutter run \
  --dart-define=SUPABASE_URL=your-project-url \
  --dart-define=SUPABASE_ANON_KEY=your-anon-key
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
- **Flutter 3** — mobile app framework
- **Provider** — state management
- **Supabase** — auth, database, and storage
- **Firebase Messaging** — deferred notification plumbing
- **Google Fonts** — typography
- **timeago** — human-readable timestamps
- **go_router** — navigation
- **uuid** — unique IDs

## Auth Model
- Email/password is the active auth flow.
- Supabase auth session is the source of truth for login state.
- Google sign-in is not active in the current build.

## Next Steps
- [ ] Push notifications (FCM)
- [ ] GitHub integration
- [ ] Hackathon tracker
- [ ] Camera / image uploads
