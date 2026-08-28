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
- [x] Removed floating trophy button (CupFab) from home screen and linked Daily Mission card in Arena to Daily Challenge Screen
- [x] Implemented 2v2 Team Duels gameplay scoring, pooled team points, divided reward distributions, and live activity feeds
- [x] Redesigned the Opportunities Detail Page to adopt the premium Warm Orange app theme, replacing outdated pink/purple styles with glassmorphic cards
- [x] Extended matchmaking search timeout to 45 seconds to prevent premature search failure
- [x] Fixed manual opportunity dates and registration deadlines in client, Edge Functions, and founder tools panel
- [x] Push notification delivery and tap routing for Arena Duel Invites across background, closed, and foreground app states
- [x] Added Burger Sidebar (Drawer) featuring Resources for You & quick navigation; removed Currently Building from onboarding and profile screens
- [x] Executed systematic codebase cleanup pass: purged 14 orphaned files (legacy mocks, deprecated screens/models/widgets), fixed unused imports and variables, optimized type checks, and updated unit test expectations to match current MVP Aura structure
- [x] Database Column & RLS Hardening: Enforced `BEFORE UPDATE` trigger on `public.users` protecting admin, aura, streaks, and premium state; created Storage RLS policies for avatar overwrites
- [x] Server-Side RPC Migration: Implemented `activate_user_premium` and `resolve_arena_match` RPCs; revoked public execute on `award_aura`
- [x] Backend Controller & Middleware Fix: Resolved `maybeSingle()` null crashes and passed `p_user_id` to `complete_daily_challenge`
- [x] FCM Stream Memory Leak Fix: Stored and canceled `FirebaseMessaging` subscriptions in NotificationService
- [x] Dead Code & Stale Features Purge: Removed deferred calling screens/service, unused StoryReel widget, obsolete pricing screen, and 11 root scratch scripts; verified all 20 unit tests pass with 0 failures
## In Progress
- [ ] Pre-production verification across release config, notifications, privacy surface, and network-failure handling


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
