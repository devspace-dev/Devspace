# DevSpace

DevSpace is a mobile-first student developer community app for one-college launch.

The current build focuses on:
- email/password auth
- onboarding and editable profiles
- feed posting with text, image, and quote posts
- persistent Q&A with replies and solved answers
- likes, comments, follows, and aura feedback
- people discovery and profile browsing

## Current Product Truth

Implemented:
- email/password auth with Supabase
- profile setup and edit flow
- home feed with real posts
- text-only, image-only, and text + image posts
- quote posts
- Q&A with real questions, replies, upvotes, and solved answers
- persistent comments
- likes and follows
- sign-out from profile

Not complete yet:
- settings surface beyond sign-out
- notifications inbox/product flow
- Google sign-in

## Prerequisites

- Flutter SDK
- Android Studio or Xcode for device builds
- a Supabase project

## Local Setup

1. Run [`supabase/devspace_schema.sql`](/Users/mohammad/Desktop/devspace/supabase/devspace_schema.sql) in Supabase SQL Editor.
2. Create a public storage bucket named `images`.
3. Get your Supabase project URL and anon key.
4. Read [SUPABASE_SETUP.md](/Users/mohammad/Desktop/devspace/SUPABASE_SETUP.md) for auth and storage notes.

## Run The App

```bash
flutter pub get
flutter devices
flutter run -d <device-id> \
  --dart-define=SUPABASE_URL=your-project-url \
  --dart-define=SUPABASE_ANON_KEY=your-anon-key
```

The app no longer relies on checked-in Supabase defaults. If those runtime values are missing, the app will stop on a setup screen with the required command.

## Tech Stack

- Flutter
- Provider
- Supabase Auth / Database / Storage
- Firebase Messaging plumbing for deferred notification work

## Auth Model

- email/password is the active auth flow
- Supabase auth session is the source of truth
- Google sign-in is visible but intentionally disabled in the current build

## Current Focus

The next product step is Phase 4 work:
- founder device testing and bug triage
- beta-readiness cleanup
- minimal settings/account surface and stronger regression coverage
