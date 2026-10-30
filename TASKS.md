# TASKS

## Current Goal
Upgrade the app backend for launch-ready gamification and gated engagement without adding product bloat.

## Done
- [x] Auth-gated app entry
- [x] Email/password sign up and sign in
- [x] Phone OTP sign in/sign up through Supabase
- [x] Supabase-backed auth/session model
- [x] Lightweight onboarding and editable profile flow
- [x] Searchable People directory
- [x] Profile view for self and other users
- [x] Sign-out from profile
- [x] Feed loading / empty / error states
- [x] Text, image, and quote posts
- [x] Persistent Q&A with replies, upvotes, and solved answers
- [x] Persistent comments
- [x] Likes / follows stabilization
- [x] Basic 1:1 direct messaging hardened with schema-backed RPCs, unread state, and realtime setup
- [x] Basic aura feedback for posts and comments
- [x] Explicit Supabase runtime setup path
- [x] Production-oriented Supabase schema for aura, streaks, events, and challenges
- [x] Backend RPC flow for post aura, like aura, comment aura, and accepted answers
- [x] Edge function structure for `/users`, `/posts`, `/events`, `/challenges`, and `/aura`
- [x] Student-facing opportunities screen with aura-locked/unlocked states
- [x] Student-facing daily challenge screen with submission flow
- [x] Home engagement cards now link into full opportunities/challenge screens
- [x] Founder tools locked behind admin plus allowlisted device checks
- [x] Integrated new brand identity (Logo 1) and premium "Cyber-Premium" theme
- [x] Resolved Google Play Console Foreground Service declaration error (Android 14+)
- [x] Incremented app version to 1.0.15+21 for new release
- [x] Redesigned Opportunities screen and updated navigation bar labels/icons/colors to match the Explore mock layout
- [x] Added gamified resource roadmap levels for DSA, system design, GitHub workflows, and open source learning
- [x] Fixed theme transition glitch on splash screen for light/dark themes
- [x] Fixed duplicate verification checkmarks (double ticks) on profile pictures
- [x] Fixed profile stats (followers, following, aura) when viewing other users
- [x] Removed non-functional search and settings icons from the Opportunities screen
- [x] Redesigned upcoming hackathons card with Unsplash banners and distinct dates
- [x] Opportunities UI polish (no logic changes): replaced random stock/Unsplash photos on hackathon and opportunity cards with consistent flat designed banners, unified the three different card hero styles into one, and moved the screen to shared theme tokens; added a render test
- [x] Opportunities: removed built-in fake opportunities (Microsoft/NASA/Postman/MLH/Google) and fake hackathons from the feed, and stopped inventing future dates for hackathons (cards show real dates or "TBA"; past hackathons drop out of "Upcoming")
- [x] Added a searchable roadmap directory (~90 roadmap.sh roadmaps, filterable by stack/category), reached via a "Browse all roadmaps" entry in the drawer's Resources for you section; opens roadmap.sh in-app via url_launcher's inAppWebView (no new dependency). Links only, no reproduced content — roadmap.sh's license doesn't permit republishing their roadmap content, only linking to it.
- [x] Replaced the drawer's old "Resources for you" section (4 hand-written articles + Show More/Less) with a single featured "Explore Roadmaps" card that opens the roadmap directory. Removed the now-fully-orphaned `roadmap_model.dart` and `learning_roadmap_screen.dart` (nothing else referenced them).
- [x] Hackathons are now India-only: the sync no longer imports Devpost (global feed, no country data), filters Devfolio by India timezone and Unstop by India country, shows real city names for Unstop events, and removes previously-synced Devpost rows; the app also hides any leftover Devpost hackathons immediately. Added backend filter tests (`npm test` in backend/)
- [x] Opportunities redesign: compact cards (title first, then organizer, icon chips for type/location/aura, deadline row), result count, "See all" on the hackathon strip, monogram avatars; removed invented per-organiser tags; detail page no longer shows a hardcoded "Swags & Certs" reward (shows real time-left or type instead) and no longer truncates deadline/location
- [x] Removed floating trophy button (CupFab) from home screen and linked Daily Mission card in Arena to Daily Challenge Screen
- [x] Implemented 2v2 Team Duels gameplay scoring, pooled team points, divided reward distributions, and live activity feeds
- [x] Redesigned the Opportunities Detail Page to adopt the premium Warm Orange app theme, replacing outdated pink/purple styles with glassmorphic cards
- [x] Extended matchmaking search timeout to 45 seconds to prevent premature search failure
- [x] Fixed manual opportunity dates and registration deadlines in client, Edge Functions, and founder tools panel
- [x] Phase 1: Play Tab Aura synchronized across all levels (Easy 5, Med 10, Hard 15, Ultra 20) with immediate client state refresh from RPC response
- [x] Phase 2: Path Tab Roadmap implemented with InteractiveViewer mind map canvas, verified learning resources, node detail sheets, and user_roadmap_progress persistence
- [x] Phase 3: Community Tab upgraded with Instagram-style feed post cards, PR replacement with plain replies in Q&A, and case-insensitive multi-stack developer search
- [x] Phase 4: Badges system implemented with 11 server-computed badges (0 Aura), sync_my_badges RPC, public read-only RLS, and earned/locked badge sheet on Profile
- [x] Phase 5: Regression verified (65/65 tests passed, 0 analyzer errors, devspace_schema.sql updated and matching all SQL patches, zero secrets in git status)
- [x] Push notification delivery and tap routing for Arena Duel Invites across background, closed, and foreground app states
- [x] Added Burger Sidebar (Drawer) featuring Resources for You & quick navigation; removed Currently Building from onboarding and profile screens
- [x] Executed systematic codebase cleanup pass: purged 14 orphaned files (legacy mocks, deprecated screens/models/widgets), fixed unused imports and variables, optimized type checks, and updated unit test expectations to match current MVP Aura structure
- [x] Database Column & RLS Hardening: Enforced `BEFORE UPDATE` trigger on `public.users` protecting admin, aura, and streaks; reconciled all 21 live tables' RLS policies and user-scoped Storage RLS policies (`posts/<uid>/%`, `documents/<uid>/%`, `profiles/<uid>.*`, `covers/<uid>.*`) into canonical `supabase/devspace_schema.sql`
- [x] Server-Side RPC & Security Teardown: Implemented `resolve_arena_match` RPC; revoked public execute on `award_aura`; completely tore down the orphaned premium feature (`activate_user_premium` RPC, `premium_questions` table, `is_premium`/`career_goal` columns, and 7 unreachable premium Dart files)
- [x] Backend Controller & Middleware Fix: Resolved `maybeSingle()` null crashes and passed `p_user_id` to `complete_daily_challenge`
- [x] FCM Stream Memory Leak Fix: Stored and canceled `FirebaseMessaging` subscriptions in NotificationService
- [x] Beta-Readiness Codebase & Dependency Audit: Removed 20 total dead/orphaned Dart files and 6 unused dependencies from `pubspec.yaml`, hardened Storage MIME/size validation (`StorageService`), URL schemes (`https://` / `http://`), PostgREST `.or()` filter escaping (`Sanitizer`), and resolved all analyzer warnings (`0 errors, 0 warnings`, `28 / 28` tests passing)

## In Progress
- [x] Glitch v1.0 Design System Implementation:
  - [x] Phase 1: Core Design System Tokens & Components (`colors.dart`, `text.dart`, `theme.dart`, `glitch.dart`, `ds_button.dart`, `ds_card.dart`, `ds_tag.dart`, `aura_chip.dart`, `segment_bar.dart`, `ds_nav_bar.dart`, `design_system_preview.dart`)
  - [x] Phase 2: Navigation & Routing (`router.dart` and `AppShell` with 5 persistent tabs: Play, Path, Ranks, Community, Profile)
  - [x] Phase 3: Quiz Screen (`features/quiz/` full-screen with options, shake, Glitch feedback, confetti)
  - [x] Phase 4: Play Screen (`features/play/` hub + lobbies + daily puzzle) & Ranks Screen (`features/ranks/` Top 3 podium, college rivalry card, rank tags, and pinned YOU row)
  - [x] Phase 5: Community Screen (`features/community/` Feed, Events, Q&A, People) & Profile Screen (`features/profile/` Stats, badges, stack chips, and settings)
  - [x] Phase 6: Path Screen (`features/path/` native roadmap visualization with zigzag rail, status nodes, and Glitch companion)
  - [x] Phase 7: Splash Screen, Motion, Accessibility & Definition of Done verification
- [x] Application-Wide Consistency & Logic Plan:
  - [x] Phase A: Token & Theme Bridge (`app_colors.dart` and `app_theme.dart` unified to `Ds` dark ink & aura tokens)
  - [x] Phase B: Auth & Onboarding Modernization (`auth_intro_screen.dart`, `login_screen.dart`, `profile_setup_screen.dart` with chunky 3D buttons, Anton/Rubik typography, Glitch mascot, and dark gaming cards)
  - [x] Phase C: Detail Views & Creation Flow Polish (`post_card.dart`, `post_detail_screen.dart`, `compose_box.dart`, `daily_challenge_screen.dart` upgraded to `DsText` and `Ds` tokens)
  - [x] Phase D: Logic Synchronization & Route Fixes (Ranks monthly/college filtering, people tap-to-profile, real practice solved counts in profile, notification bell entry points in top bars, path milestone roadmap/quiz wiring)
  - [x] Phase E: Full Test Suite & Analyzer Verification (36/36 tests passing, 0 analyzer errors or warnings)
  - [x] Phase 8: Launch Readiness & Release Stabilization:
    - [x] Cold-Boot Splash Unification (`lib/main.dart` mapped directly to `features/splash/screens/splash_screen.dart` with `buildTheme()`)
    - [x] ProGuard / R8 Hardening (`android/app/proguard-rules.pro` keeping Flutter embedding, Firebase Crashlytics, SafeDevice JNI, and Desugaring)
    - [x] Android Build Verification (`flutter build apk --debug` succeeded with zero packaging or Gradle errors)
    - [x] Code Quality Audit (36/36 tests passing, 0 analyzer errors, 0 warnings)

## In Progress
- [ ] End-to-end founder smoke testing on real Android devices

## Next
1. Test rate limits, duplicate-prevention, and streak reset behavior on real devices

## Later
- Offline font bundling for Anton and Rubik in release builds.
- Native splash screen updates (`flutter_native_splash`).
- [ ] Pre-production verification across release build smoke checks and network-failure handling


## Next
1. Test rate limits, duplicate-prevention, and streak reset behavior on real devices
2. Move feed reads to paginated requests where infinite scrolling is needed
3. Run Android release smoke checks on at least one low-end and one mid-range phone
4. Add targeted tests for aura awarding and challenge completion edge cases
5. Add a simple founder-device registration checklist for phone changes and reinstalls
6. Founder-test direct messaging on two real accounts after re-running the latest Supabase schema

## Later
- [ ] Google sign-in
- [ ] Post type system
- [ ] Notifications productization
- [ ] Better automated coverage
- [ ] Recruiter / premium ideas
- [ ] Multi-college tooling

## MVP Definition
The MVP is ready when:
- users can sign in and complete a real profile
- users can create text, image, and quote posts
- users can ask questions, reply, upvote, and mark a solved answer
- users can like, comment, follow, and browse reliably
- setup for both founders is predictable
- the app is stable enough for one-college closed testing
