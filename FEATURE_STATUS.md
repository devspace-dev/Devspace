# FEATURE STATUS

## Implemented
- Email/password auth with Supabase
- Explicit runtime bootstrap for Supabase URL and anon key
- Lightweight first-login onboarding and editable profiles
- People discovery with search and branch filtering
- Feed loading / empty / error states
- Text-only, image-only, and text + image posting
- Quote posts
- Persistent Q&A with questions, replies, upvotes, and solved answers
- Persistent comments
- Likes and follows with stabilized interaction state
- Basic 1:1 direct messaging with unread state and message notifications
- Sign-out from profile
- Profile viewing for self and others
- Arena-only Aura system & synchronized Monthly / All-Time leaderboard (`practice_question`, `complete_daily_mission`, `attempt_daily_mission`, `arena_duel`) with server-enforced rewards and 100% `users.aura == aura_ledger` parity
- Backend aura ledger, level mapping, and streak tracking
- Event gating model with eligible vs locked access
- Daily challenge tables and completion RPC flow
- Edge API structure for core backend domains
- Opportunities screen with locked/unlocked visibility and link access for eligible users
- Daily challenge screen with backend-backed submission flow
- Home engagement cards linked to full-screen challenge/opportunity views
- Founder tools restricted to allowlisted founder/developer devices on top of admin auth
- Explore resources now open gamified roadmap levels with learning materials and aura-style rewards
- Dynamic Arena mode category scores (Combat, Team, Daily Challenge) calculated from the user's Aura ledger
- Automated daily streak verification and DB reset via client-invoked Postgres RPC
- Expanded Arena mode question pool to 520+ distinct questions across reflex, logic, and trivia
- Implemented 2v2 Team Duels gameplay simulation, including pooled scores, split aura rewards, activity logging, and stacked avatars
- Redesigned Opportunities Detail Page with glassmorphism layouts, clean metadata rows, and premium Warm Orange theme integration
- Push notification delivery and tap routing for Arena Duel Invites across background, closed, and foreground app states
- Native Google Sign-In on Android + PKCE deep-link OAuth fallback
- Glitch v1.0 Design System & Full Application-Wide Consistency: ink ground (`#0D0E14`), bone text, coin-yellow Aura currency (`#FFD23F`), Anton headings, chunky 3D buttons (`DsButton`), slanted tags (`DsTag`), Glitch vector mascot, 5-branch persistent GoRouter navigation (`AppShell`), modernized Auth & Onboarding flows (intro, sign-in, profile setup), unified Post and Detail views, integrated compose sheet, synchronized Ranks leaderboard with college/monthly filters, clickable builder profiles, practice-backed solved counts, notifications bell navigation, unified cold-boot splash, native splash color alignment, Daily Mission screen modernized, Play quiz overflow protection (Wrap tags, scrollable code blocks, top-aligned option chips), and production ProGuard / R8 rules (36/36 passing tests, 0 analyzer issues, verified Android debug APK build)
- Area 1 Play Tab Aura: Strict 4-tier difficulty level mapping (Easy 5, Medium 10, Hard 15, Ultra 20), awards RPC called only on correct answer, client updates total directly from server RPC response and refreshes user across Play lobby, Arena header, Profile, Aura Board, and Aura History with zero drift
- Area 2 Path Tab Deep Redesign: Complete 5-track personalized learning route engine (Flutter App Developer, Web Frontend, Backend & Systems Engineering, DSA & Placements, AI/ML Foundations) with 48 curated nodes, starting level skipping without fake records, 3h/6h/10h weekly commitment finish-date forecasting, 60fps optimistic node completion with rollback, single active roadmap enforcement (`public.user_roadmaps` and `idx_user_roadmaps_one_active`), One Clear Next Step discovery, and verified official documentation links
- Area 3 Community Tab:
  - 3A Feed: Full-width Instagram-style media cards, aspect ratio clamped (200-460dp), `memCacheWidth: 1080`, author header, action row, like count, expandable caption, comment preview
  - 3B Q&A: Direct solutions & threaded replies replacing Pull Request UI; question authors can mark accepted answers via `mark_question_reply_solved` (0 Aura)
  - 3C Developer Search: Multi-select stack chips with search input, case-insensitive ANY-match filtering across name, handle, branch, stack, and match-count ranking with highlighted stack chips (`search_developers_by_stack` RPC)
- Area 4 Badges System: Server-computed 11-badge system (First Practice Solve, Easy/Med/Hard/Ultra Cleared, 3-Day/7-Day Streak, First Duel Win, Duel Winner x10, Accepted Answer, Top 10 This Month) with zero Aura, idempotent `sync_my_badges` RPC, public read-only RLS policy `user_badges_select_all`, client display of earned & locked badges with rules on Profile tab, and automated sync triggers
- Area 5 Regression & Launch Readiness: Full test suite passing, 0 static analysis errors, `supabase/devspace_schema.sql` synchronized with all SQL patches, zero secrets in git repository, 3,600+ lines of dead code eradicated (purged `app.dart` and 6 legacy screens), unified Profile architecture with peer viewing, and 100% removal of legacy glassmorphism containers.
- Feed Hashtags & Post Auto-Tagging: Fully resolved `-1` offset crash on tapping hashtag suggestions in `compose_box.dart` with bulletproof selection clamping, text range replacement, and automatic hashtag extraction from post content upon submission.
- Glitch v1.0 Event Details & Active Deadline Sorting: Completely overhauled `OpportunityDetailScreen` from generic gradients and floating `"0"` avatars into tactile Glitch v1.0 design tokens (`DsCard`, `DsTag`, `DsButton`, `DsText`); updated `community_screen.dart` and `backend_api_service.dart` to sort upcoming active hackathons by nearest deadline first and auto-filter expired events into collapsible Past Events.
- Official App Icon & Launcher Branding: Converted and packaged the authentic Glitch mascot on Coin Yellow (`#FFD23F`) across Android mipmaps (mdpi to xxxhdpi), iOS AppIcon xcassets set (1024x1024 down to 20x20), `app_launcher_icon.png`, and `app_icon_splash.png`; modernized `devspace_logo.dart` to display multi-color mascot graphics natively.
- India-Optimized Opportunities Pipeline & Freshness Filter: High-signal ingestion and curated catalog of verified active 2025–2026 engineering hackathons tailored for Indian B.Tech students (SIH 2026, Flipkart GRiD 7.0, Google Solution Challenge, ETHIndia, Amazon ML Challenge, Hack This Fall) with automated multi-pattern date & keyword parsing, non-tech pruning, and automatic relegation of expired/TBA events into collapsible Past Events.
- Arena Practice & Quiz Engine Expansion to 30 Questions: Scaled quiz session length from 8 to 30 questions in `quiz_screen.dart`, expanded question pool in `practice_questions.dart` to 242 high-signal CS, DSA, and architecture questions across Easy (60), Medium (74), Hard (58), and Ultra (50) with smart uncompleted-first quiz sampling, verified step-by-step explanations, dynamically responsive `SegmentBar`, and 100% database RPC schema compatibility.
- First-Run Onboarding & Feature Tour (Stages 0–8): Full Duolingo-style guided tour with Glitch companion mascot, root-level TourHost coordinate-mapped overlay, circular/rounded-rect spotlight cutouts, pulsing halo rings, typewriter copy, state-aware step skipping, cross-tab route auto-navigation, practice completion reward celebration modal (+5 AURA, Glitch win mood, heavy haptic feedback), Settings haptic toggle & replay tour controls, app lifecycle pause/resume handling, 200% font scale accessibility on 360dp screens, and Play tab First Quests starter card with real provider-derived completion and auto-dismissal (54 passing tests across 11 test suites).

## Partial
- GitHub profile card is useful scaffold, not a finished identity system
- Notifications plumbing exists, but there is no full inbox/product flow beyond activity and message alerts
- Automated coverage exists, but it is still light for a production beta
- Feed still relies on realtime stream loading in the current UI, though paginated backend endpoints now exist
- Pre-production release hardening now covers runtime config gating, Crashlytics wiring, notification permission requests, HTTPS-only backend expectations, and friendlier network failure handling

## Missing
- Settings/account surface (Implemented with theme, haptic feedback toggle, and tour replay)
- Notifications screen/inbox (Implemented)
- Broader automated coverage for core flows
- External privacy policy URL and full Play Store listing assets/metadata
