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
- [x] Push notification delivery and tap routing for Arena Duel Invites across background, closed, and foreground app states
- [x] Added Burger Sidebar (Drawer) featuring Resources for You & quick navigation; removed Currently Building from onboarding and profile screens
- [x] Executed systematic codebase cleanup pass: purged 14 orphaned files (legacy mocks, deprecated screens/models/widgets), fixed unused imports and variables, optimized type checks, and updated unit test expectations to match current MVP Aura structure
- [x] Database Column & RLS Hardening: Enforced `BEFORE UPDATE` trigger on `public.users` protecting admin, aura, and streaks; reconciled all 21 live tables' RLS policies and user-scoped Storage RLS policies (`posts/<uid>/%`, `documents/<uid>/%`, `profiles/<uid>.*`, `covers/<uid>.*`) into canonical `supabase/devspace_schema.sql`
- [x] Server-Side RPC & Security Teardown: Implemented `resolve_arena_match` RPC; revoked public execute on `award_aura`; completely tore down the orphaned premium feature (`activate_user_premium` RPC, `premium_questions` table, `is_premium`/`career_goal` columns, and 7 unreachable premium Dart files)
- [x] Backend Controller & Middleware Fix: Resolved `maybeSingle()` null crashes and passed `p_user_id` to `complete_daily_challenge`
- [x] FCM Stream Memory Leak Fix: Stored and canceled `FirebaseMessaging` subscriptions in NotificationService
- [x] Beta-Readiness Codebase & Dependency Audit: Removed 20 total dead/orphaned Dart files and 6 unused dependencies from `pubspec.yaml`, hardened Storage MIME/size validation (`StorageService`), URL schemes (`https://` / `http://`), PostgREST `.or()` filter escaping (`Sanitizer`), and resolved all analyzer warnings (`0 errors, 0 warnings`, `28 / 28` tests passing)

## In Progress
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
