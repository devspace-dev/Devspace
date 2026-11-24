# TASKS

## Current Goal
Execute release stabilization and performance hardening under strict feature freeze.

## Done
- [x] Fixed `CoachMarkOverlay` / `DsCard` layout crash & test regressions:
  - Eliminated `clipBehavior: Clip.antiAlias` from `DsCard` container, preventing Flutter `_DecorationClipper` and border `RenderPadding` assertions during dynamic typewriter text rendering and overlay animations.
  - Resolved unbounded horizontal layout crash in `CoachMarkOverlay` footer row by constraining `DsButton` with `width: 104` and adding configurable `width` to `DsButton`.
  - Inverted `Semantics` and `GestureDetector` to wrap `AnimatedBuilder` in `TypewriterText`, eliminating `!semantics.parentDataDirty` assertion during active animation ticks.
  - Added dedicated transparent hit target over the spotlight hole in `CoachMarkOverlay`, ensuring target taps reliably advance tour steps in tests.
  - Converted `TourAnchorRegistry` to extend `ChangeNotifier` with post-frame notification dispatch (`addPostFrameCallback`) and wired dynamic `anchorId` resolution with post-frame rebuilds into `CoachMarkOverlay` and `TourHost`, eliminating the `setState() called during build` assertion and ensuring coach marks dynamically bind to laid-out anchor coordinates across all steps.
  - Added `ConstrainedBox` + `ScrollConfiguration` + `SingleChildScrollView` to the unpositioned fallback branch in `CoachMarkOverlay._buildPositionedTooltip`, eliminating the 32px bottom RenderFlex overflow under 200% font scale.
  - Wrapped `TourCopy.s7BadgeEarned` in `Flexible` inside `TourModalPopup`, resolving the 211px horizontal overflow on 360dp screens.
  - Wrapped `_InsightItem` row in `FittedBox(fit: BoxFit.scaleDown)` in `SettingsScreen`, resolving the 16px horizontal overflow under 200% font scale.
  - Switched `CommunityScreen` tabs to `Tab(child: Text(...))` to eliminate the 32px vertical TabBar column overflow under 200% font scale.
  - Aligned test expectations in `duel_screen_test.dart` (`'Starting in '`, `'Rohan'`) and `router_test.dart` (`'STAY'`).
  - Removed non-existent column `cover_url` from `safePublicUserColumns` and `createUser` in `lib/services/supabase_service.dart`, resolving Google sign-in failure (`column users.cover_url does not exist`).
  - Added targeted `ClipRRect` inside `DsCard` strictly for `leftBar` lobby stripe rendering.
  - Validated `buildTheme()` import in `stage3_play_test.dart`.
  - Preserved test mock data in `UsersProvider.fetchUsers()` when `!isSupabaseReady`.
  - Fixed Feed load failure: Replaced non-existent columns `likes, comments, reposts` with canonical PostgreSQL columns `likes_count, comments_count, reposts_count` via `safePostColumns` in `lib/services/supabase_service.dart`.
  - Fixed Storage RLS 403 on Profile Photo upload: Corrected `uploadPath` in `lib/screens/profile_setup_screen.dart` to use dot delimiter (`profiles/${uid}.${timestamp}.jpg`), matching the active RLS policy `name LIKE ('profiles/' || auth.uid()::text || '.%')`; authored comprehensive storage RLS patch in `supabase/patches/15_storage_policies.sql`.
- [x] Release Captain Stage 0: Audit & Safety Net:
  - Feature Inventory across all screens, flows, background jobs, and owning files.
  - Golden-path regression checklist (~20 min) and automated coverage vs gaps matrix.
  - Physical Android baseline profiling commands and phone metric capture template.
  - Staging setup plan with isolated project, synthetic seed data, and `--dart-define-from-file`.
  - Performance budget table baseline tracking (Rule 5).
  - Findings Table (R0-01 through R0-12) classified and prioritized.
- [x] Release Captain Stage 1: Startup Critical Path & Config Hardening:
  - R0-02: Removed artificial 1,600ms sleep (`Future.delayed`) from `main.dart` bootstrap array, unblocking immediate first-frame rendering.
  - R0-01: Removed hardcoded production credentials from `RuntimeConfig.load()` default values; created `.env.staging.json.example`.
- [x] Release Captain Stage 2: Critical Safety Net Automated Tests:
  - R0-03: Created `test/features/settings_screen_test.dart` (account info, stats card, haptics, dialogs for sign out and account deletion).
  - R0-03: Created `test/features/waiting_for_opponent_screen_test.dart` (radar animation, opponent initial, cancel button).
  - R0-03: Created `test/features/chat_detail_screen_test.dart` (header label, message list, input, and send actions).
  - R0-03: Created `test/features/duel_screen_test.dart` (countdown phase 3-2-1, transition to playing phase, scoreboard, question display).
  - Added defensive offline/test try-catch handling around uninitialized realtime channels in `chat_detail_screen.dart` and `duel_screen.dart`.
- [x] Release Captain Stage 3: Network Polling & Realtime Optimization:
  - R0-06: Reduced `streamConversations` polling overhead from 15s to 45s with exponential backoff on error (up to 120s), eliminating 66%+ background request load.
  - R0-07: Reduced redundant `waiting_for_opponent_screen.dart` polling from 3s to 10s fallback heartbeat while websocket is active.
  - R0-07 & R0-09: Reduced duel score sync timer from 2s to 5s safety sync; eliminated redundant client-side remote DB score writes for solo mock bot duels.
- [x] Release Captain Stage 4: Query Projections & Dead Code Documentation:
  - R0-08: Added explicit column projections to `getUsers()` (excluding private tokens/emails) and `getPosts()` / `getUserPosts()`.
  - R0-12: Documented dead code inventory without deleting files (Rule 9).
- [x] Release Captain Stage 5: Static Analysis & Hygiene:
  - Cleaned all 355 analyzer issues down to 0 errors, 0 warnings, 0 hints.
  - Converted `practiceQuestionsData` to compile-time const, saving heap memory and allocations.
  - Resolved `use_build_context_synchronously` warnings and modernized deprecated Flutter APIs.
- [x] Role 1 Stage 6: Client Performance & Memory Protection:
  - Capped raster cache across network images (`memCacheWidth` & `memCacheHeight`) in `opportunity_detail_screen.dart`, `connections_screen.dart`, `builder_search_screen.dart`, `chat_detail_screen.dart`, and `opportunities_screen.dart`.
- [x] Role 2 Stage 7: Database & Realtime Optimization:
  - Created and executed `supabase/patches/14_launch_indexes.sql` indexing `posts`, `messages`, `users(aura)`, `notifications(to_uid)`, `comments`, and `follows`.
  - Verified live in PostgreSQL via `supabase/checks/14_launch_indexes_verify.sql` with all 8 launch performance indexes active.
- [x] Role 3 Stage 8: Security & Data Integrity:
  - Enforced `safePublicUserColumns` in `getUserById`, `getUserByHandle`, and `getUsersByIds` to prevent leaking `fcm_token` and `email` over the wire.
  - Added 15s defensive network timeout (`requestTimeout`) on core Supabase data queries to prevent infinite hanging futures.

- [x] Full test suite verification & stabilization:
  - 186+ unit and widget tests passing cleanly with 0 failures, 0 exceptions.
  - `flutter analyze` reports 0 issues (0 errors, 0 warnings, 0 hints).

- [x] Role 7: Independent Release Gate Audit & Scorecard sign-off:
  - Final Release Gate Scorecard generated with official GO FOR LAUNCH verdict.
  - Zero P0 and zero P1 blockers remaining.
  - All 8 database launch indexes verified live in PostgreSQL.

## In Progress
- [ ] One-College Closed Beta Founder Smoke Testing on physical Android devices.

## Next
- [ ] Build release APK (`flutter build apk --release`).
- [ ] 15-minute founder smoke test walkthrough on physical device.
- [ ] Distribute APK to first cohort of student builders in the target college.

## Later
- [ ] Role 3 (Security Engineer): User column exposure public view, server-side anti-farming rate limits, founder device checks server-side enforcement.
- [ ] Role 4 (Trust, Safety & Privacy): Content reporting, user block/mute, age verification, data safety table.
- [ ] Role 5 (UX, Accessibility & Global): 200% font scale verification on 360dp screens, ARB internationalization plan.
- [ ] Role 6 (Reliability & Release Engineer): Sentry/Crashlytics alert thresholds, 16KB Android page size compliance, staged rollout config.
- [ ] Role 7 (Release Gate Auditor): Final pre-release GO / NO-GO scorecard.

## Dead Code Inventory (Rule 9: Preserved, Not Deleted)
1. `lib/screens/practice_map_screen.dart` (930 lines): Legacy 4-level practice map superseded by modern 30-question `QuizScreen` (`/quiz/:lobby`). Preserved; accessible only from drawer.
2. `lib/screens/practice_question_screen.dart` (716 lines): Legacy untimed question runner superseded by `QuizScreen`. Preserved; accessible only from `PracticeMapScreen`.
- [x] Pre-release Polish Stage 0: Audit & Diagnostics across Items A-K, with read-only SQL scripts (11_avatars.sql, 12_events_dates.sql).
- [x] Pre-release Polish Stage 1: Low-Risk UI hardening:
  - Item C: Removed static "Continue Path" card from PlayScreen.
  - Item D: Removed Aura badges and lock chips from event cards and opportunity details.
  - Item E: Removed collapsible "Past events" section; auto-filter expired events (UTC-to-local), while keeping TBA events visible.
  - Item F: Made chat text-only by removing attachment menu and disabling rich content insertion.
  - Item H: Replaced hardcoded "Active now" chat header with user's academic year/branch (`user.academicLabel`).
  - Item I: Permanently forced `ThemeMode.dark` in `ThemeProvider` and `MaterialApp`, removing settings appearance selector.
  - Item G: Hardened Path tab layout against 360dp width and 200% font scale (flexible progress bar, scrollable milestone row, 44dp touch targets).
- [x] Pre-release Polish Stage 2: Settings Screen Glitch Redesign (Item J):
  - Completely redesigned `SettingsScreen` using Glitch design tokens: `DsCard`, `DsTag`, `DsText`, `Ds.ink`, `Ds.surface`, `Ds.border`, `Ds.bone`, `Ds.muted`, `Ds.hot`, `Ds.aura`.
  - Rebuilt Account card and 3-column Analytics insights card (`POSTS`, `LIKES`, `AURA`) with `DsCard`.
  - Redesigned danger actions (Delete account & Sign out button) with `Ds.hot` borders and labels.
  - Rebuilt all confirmation dialogs (`Sign out`, `Delete account`, `About DevSpace`) using `Ds.surface` and neo-brutalist styling.
  - Removed old soft-card styling and purged dead theme switcher code.
- [x] Pre-release Polish Stage 3: Tour Overlay Coordinate Alignment & Card Redesign (Item B):
  - Fixed ~65px coordinate shift by wrapping `Scaffold` with `TourHost` in `AppShell` and eliminating incorrect `SafeArea` wrapping on coach mark layers.
  - Added dynamic `renderBox.globalToLocal` conversion in `CoachMarkOverlay` so target rects perfectly match local canvas space across all device sizes and safe areas.
  - Cutout is now 100% transparent and unobstructed with inflated padding and a 2.5px glowing `Ds.aura` border; target element is crisp and bright.
  - Redesigned Coach Mark Card with Glitch mascot, step pill tag (`STEP X OF Y`), Anton title, Typewriter text, and clean action buttons.
  - Prevented accidental background dismissal; tapping inside the spotlighted hole activates the target.
- [x] Pre-release Polish Stage 4: Avatar Display & Pipeline Hardening (Item K):
  - Integrated `CachedNetworkImage` into `RanksScreen` across Top 3 Podium, leaderboard rows (rank 4+), and pinned YOU row (compact and standard).
  - Validated HTTP avatar URLs before passing to image loaders, falling back cleanly to user initials on `Ds.surface` to prevent URL parse errors.
  - Redesigned `DsNavBar` Profile button to a 28dp circle with active yellow ring (`Ds.aura`), loaded profile picture, and fallback initials.
  - Stopped writing legacy initials strings (e.g. 'AK') into `users.avatar` in `AuthService`; store `null` instead when user has no photo.
  - Added cache-busting timestamp (`?t=...`) and evicted old URLs upon upload in `ImageUploadWidget`.
  - Prepared SQL migration `supabase/patches/avatars-01-cleanup.sql` to clean non-URL values from `users.avatar`.
- [x] Pre-release Polish Stage 5: Combat Multiplayer Rematch Flow (Item A):
  - Fixed Rematch button in `DuelResultScreen`: replaced placeholder `Navigator.popUntil((route) => route.isFirst)` with real challenge issuance via `sendDuelRequest`.
  - Passed `category` from `DuelScreen` to `DuelResultScreen` so rematches preserve category alongside mode and opponent.
  - Pushes `WaitingForOpponentScreen`: if accepted, smoothly transitions both players into `DuelScreen` with a brand-new match ID; if declined or timed out, returns back to `DuelResultScreen` with a status snackbar message.
  - Added double-tap protection, in-flight "WAITING..." state with spinner, and a 10-second cooldown timer (`REMATCH (10s)`) disabling the button upon return.
  - Added `PopScope` to `DuelResultScreen` preventing unintended back-navigation into intermediate match routes.
  - Ensured touch targets >= 48dp and immunity to overflow at 360dp width and 200% font scale.
  - Added full test suite in `test/features/duel_result_screen_test.dart`.
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
- [x] Redesigned Path Tab: Personalised 5-track roadmaps (Flutter, Web, Backend, DSA, AI/ML) with 48 curated nodes, starting level skipping (foundation nodes deducted from hours without fake records), 3h/6h/10h finish date math, 60fps optimistic node completion with rollback on failure, single active roadmap enforcement (user_roadmaps table and idx_user_roadmaps_one_active), One Clear Next Step discovery, official documentation links, and comprehensive unit/widget tests.
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
- [x] India-Optimized Hackathons & B.Tech Tech Internships:
  - Database schema patched (`supabase/patches/events-01-support-internships.sql` and `supabase/devspace_schema.sql`) to expand `events_type_check` for `internship` support.
  - Multi-page engineering-filtered Unstop fetcher implemented for hackathons and software/developer tech internships with non-tech role filtering (sales, marketing, HR pruned).
  - Devfolio fetcher filtered strictly for Indian timezones (`Asia/Kolkata`, `Asia/Calcutta`).
  - Backend sync engine (`backend/src/services/hackathonSyncService.js`) and Supabase Edge Function (`supabase/functions/_shared/services/event-service.ts`) updated with graceful constraint retry fallbacks.
  - 4 automated filter test suites passing (`backend/test/hackathonFilters.test.js`).
  - Verified client compatibility in `lib/screens/opportunities_screen.dart` and `lib/screens/opportunity_detail_screen.dart`.
- [x] Arena Practice Question Pool Scaling & Deduplication:
  - Expanded question bank from 80 to 190 high-signal, non-repetitive CS, DSA, OOPs, and logic questions across Easy (44), Medium (74), Hard (42), and Ultra (30).
  - Pruned duplicate and near-identical numeric templates from PDF 2 while preserving distinct archetypes.
  - Integrated LeetCode/interview patterns (Two-Sum, Kadane, LIS, Mountain Array, Climbing Stairs DP, Move Zeroes, Majority Element) into Ultra.
  - Upgraded `quiz_screen.dart` to Smart Sampling (prioritizes uncompleted questions, mixing in completed ones for revision).
  - Generated complete verification document `ARENA_QUESTIONS_ORGANIZED.md` and verified with passing widget tests.

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

- [x] Launch Readiness & Codebase Hardening:
  - [x] Purged 6 orphaned/dead files (`lib/app.dart`, `lib/screens/home_screen.dart`, `lib/screens/arena_screen.dart`, `lib/screens/explore_screen.dart`, `lib/screens/splash_screen.dart`, `lib/screens/qa_screen.dart`), eliminating over 3,600 lines of dead code
  - [x] Removed outdated glass container abstractions (`lib/widgets/glass_container.dart`) and unified profile routing on `lib/features/profile/screens/profile_screen.dart` with optional `userId` support
  - [x] Feed Hashtag Bugfix: Resolved `RangeError: -1` crash upon tapping hashtag suggestions in `compose_box.dart` via safe offset clamping; added regex auto-extraction for `#hashtags` typed directly in post bodies
  - [x] Events & Hackathons Glitch v1.0 Redesign: Replaced outdated gradient and floating `"0"` circle avatar in `OpportunityDetailScreen` with Glitch v1.0 tactile components (`DsCard`, `DsTag`, `DsButton`, `DsText`); updated `community_screen.dart` and `backend_api_service.dart` to sort upcoming active hackathons by nearest deadline first and auto-filter expired events into collapsible Past Events
  - [x] App Logo & Launcher Icon Modernization: Replaced legacy icons with the official Glitch on Coin Yellow (`#FFD23F`) asset across Android mipmaps (mdpi to xxxhdpi), iOS AppIcon set (1024x1024 down to 20x20), `app_launcher_icon.png`, and `app_icon_splash.png`; updated `devspace_logo.dart` to preserve full-color mascot graphics
  - [x] Unified Profile Architecture: Upgraded `lib/features/profile/screens/profile_screen.dart` to support both self and peer profile viewing (with Follow/Message buttons, badges, public posts) and deleted legacy `lib/screens/profile_screen.dart`
  - [x] Anti-AI Design System Hardening: Completely deleted `GlassContainer` and `AppGlassCard`, replacing all residual glassmorphism in `post_card.dart`, `compose_box.dart`, and `daily_challenge_screen.dart` with solid `DsCard` surfaces
  - [x] Feed Doubts Polish: Added `#Doubt`, `#Question`, and `#Project` to `kTrendingTags` and enabled fast doubt creation in the unified Community Feed
  - [x] Storage & Device Safeguards: Added 2-second timeout fallback for `SafeDevice` checks on physical devices, and enforced image compression (1280x1280 @ 82% quality) in `compose_box.dart`
  - [x] Active Hackathons Pipeline & Multi-Pattern Expiry Filtering: Filtered expired, closed, and stale TBA hackathons from the active feed via robust date & keyword parsing; populated upcoming opportunities with verified active 2025–2026 national Indian student hackathons (`kCuratedIndianHackathons` in `community_screen.dart` and `opportunities_screen.dart`)
  - [x] Play Mode Question Expansion to 30: Increased session length from 8 to 30 questions in `quiz_screen.dart`, expanded question pool in `practice_questions.dart` to 242 questions across all 4 modes (Easy: 60, Medium: 74, Hard: 58, Ultra: 50), dynamically scaled `SegmentBar` for 30 segments, and synchronized `quiz_screen_test.dart`
  - [x] Native Splash Color & Asset Cleanliness: Aligned `flutter_native_splash` background color in `pubspec.yaml` with `Ds.ink` (`#0D0E14`), purged orphaned 525KB asset `assets/images/tactical_pilot.png`, and verified brand asset integrity
  - [x] Play Quiz Text & Code Overflow Immunity: Replaced fixed header tag row with `Wrap(spacing: 8, runSpacing: 8)`, enabled horizontal scrolling on monospace code blocks, constrained pinned feedback panel height, and top-aligned `QuizOptionRow` letter chips
  - [x] Daily Mission Glitch v1.0 Modernization: Fully restyled `daily_challenge_screen.dart` to Glitch v1.0 design system (`Ds.ink`, `DsCard`, `DsTag`, `DsButton`, `AuraChip`, `Glitch` celebration overlay) with zero logic changes to `submit_daily_mission`, streak tracking, or aura rewards
  - [x] Opportunity Detail Banner Polish: Safeguarded `opportunity_detail_screen.dart` with `isLogoPhotoUrl` check using `BoxFit.contain` to prevent low-resolution or circular thumbnail logos from zooming/clipping awkwardly across mobile screens
  - [x] Event Expiry & Date Parser Hardening: Fixed false-positive past-event classification where words like "Smart" matched "mar" (March) or date ranges evaluated against the start month instead of deadline; added word-boundary token matching, deadline segment extraction, and updated curated hackathon dates to active 2026/2027 windows (`Dec 2026 - Mar 2027`)
- [x] First-Run Onboarding & Feature Tour (Stages 0–8):
  - [x] Stage 0: Codebase diagnosis, token alignment, and dependency audit
  - [x] Stage 1: Tour infrastructure (`TourController`, `TourStep`, `TourAnchor`, `CoachMarkOverlay`, `TourHost`, `RewardFeedback`)
  - [x] Stage 2: Welcome modal (S1) and Goal / Path selection spotlight (S2)
  - [x] Stage 3: Play tab practice spotlight (S3), First practice reward celebration modal (S3b), and Daily routine return (S7)
  - [x] Stage 4: Community tab post creation FAB spotlight (S4) with user post skipping logic
  - [x] Stage 5: Events / Hackathons tab spotlight (S5) with dynamic tab availability skipping
  - [x] Stage 6: Ranks tab leaderboard spotlight (S6) with responsive compact layout under 200% font scale
  - [x] Stage 7: Tour polish, Settings screen controls (haptic feedback toggle, replay tour button), lifecycle pause/resume, and route auto-nav
  - [x] Stage 8: First Quests card on Play tab with live provider-derived progress, zero DB writes, and auto-dismissal
  - [x] Final Pre-Release Audit & Launch Hardening:
    - [x] Universal tactile haptics wired through `RewardFeedback` across all buttons, navigation tabs, quiz selections, post likes, bookmarks, and daily challenge.
    - [x] Purged 1,000+ lines of dead code (`roadmaps_data.dart`, `bottom_nav.dart`, `post_shimmer.dart`, `question_pull_request_model.dart`, unused PR provider getters).
    - [x] RepaintBoundary performance optimization on Glitch SVG animation and coach mark spotlight painters.
    - [x] Memory optimization: bounded raster cache on image decodes (`memCacheWidth: 720`).
    - [x] Security verification: read-only client Aura (server RPC calculations only), PostgREST filter injection protection, and UID-scoped storage.
    - [x] 200% font scale overflow immunity on 360dp screens verified across Play, Profile, Settings, and First Quests (`overflow_immunity_test.dart`).
    - [x] 100% test pass rate achieved across all 164 automated test suites in the codebase.

## In Progress
- [ ] End-to-end founder smoke testing on real Android devices (including opportunity feeds & sync verification)

## Next
1. Run `supabase/patches/events-01-support-internships.sql` in the Supabase SQL Editor to allow `'internship'` types in the database.
2. Test rate limits, duplicate-prevention, and streak reset behavior on real devices.
3. Move feed reads to paginated requests where infinite scrolling is needed.
4. Run Android release smoke checks on at least one low-end and one mid-range phone.
5. Add targeted tests for aura awarding and challenge completion edge cases.
6. Add a simple founder-device registration checklist for phone changes and reinstalls.
7. Founder-test direct messaging on two real accounts after re-running the latest Supabase schema.

## Later
- Offline font bundling for Anton and Rubik in release builds.
- Native splash screen updates (`flutter_native_splash`).
- Post type system.
- Recruiter / premium ideas.
- Multi-college tooling.

## MVP Definition
The MVP is ready when:
- users can sign in and complete a real profile
- users can create text, image, and quote posts
- users can ask questions, reply, upvote, and mark a solved answer
- users can like, comment, follow, and browse reliably
- setup for both founders is predictable
- the app is stable enough for one-college closed testing
