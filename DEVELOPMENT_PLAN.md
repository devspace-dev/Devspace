# DEVELOPMENT PLAN

## Summary
Core MVP social flows exist, but the backend now needs to carry more product logic so the founders are not manually policing abuse or engagement.

That means Phase 4 should focus on productionizing the existing app with backend-owned gamification and controlled engagement loops.

## Phase 4: Closed Beta Prep + Backend Productization
Goal:
- make the product safe for first-college testing without founder hand-holding
- move aura/challenge/event rules out of the client and into Supabase-backed backend logic

Work:
- finalize aura ledger, streak logic, and accepted-answer rewards
- ship events/opportunities gating based on aura thresholds
- ship one-daily-challenge assignment and completion flow
- run founder testing across auth, posting, Q&A, aura, events, and challenge behavior
- fix the top beta-blocking bugs found in that testing
- add a minimal settings/account surface if sign-out alone is not enough

Founder split:
- Founder A: challenge/event UX wiring, founder testing, admin seeding flow
- Founder B: backend reliability, regression coverage, setup/release readiness

Acceptance:
- no fake top-level surfaces remain in MVP
- both founders can install and test the app with the same setup steps
- aura and challenge rewards cannot be trivially abused from the client
- the app survives real student testing without constant manual fixes

## Phase 4: Closed Beta Prep + Backend Productization (Completed)
- Aura ledger, streaks, practice scoring (5/10/15/20 Aura), and badge synchronization are fully server-enforced with zero drift.
- Opportunities & daily challenge submission flows are operational.

## Phase 5: Launch-Ready Codebase Hardening (Completed)
- Purged 3,600+ lines of dead code (`lib/app.dart`, lines 291-334 in `main.dart`, and 6 legacy screens).
- Unified Profile Architecture: [profile_screen.dart](file:///Users/Devspace/lib/features/profile/screens/profile_screen.dart) handles self & peer profile views with Follow & Message actions.
- Anti-AI Design Hardening: Completely eliminated glassmorphic blurs (`GlassContainer`, `AppGlassCard`) in favor of solid tactile `DsCard` surfaces and crisp borders.
- Feed Hashtags & Post Auto-Tagging: Fully resolved `-1` offset crash on selecting suggested tags in `compose_box.dart` via safe offset clamping; added regex auto-extraction for `#hashtags` typed directly in post bodies.
- Events & Hackathons Glitch v1.0 Overhaul: Replaced outdated gradient and floating `"0"` circle avatar in `OpportunityDetailScreen` with Glitch v1.0 tactile components (`DsCard`, `DsTag`, `DsButton`, `DsText`); updated `community_screen.dart` and `backend_api_service.dart` to sort upcoming active hackathons by nearest deadline first and auto-filter expired events into collapsible Past Events.
- Official App Icon & Launcher Branding: Converted and packaged the authentic Glitch mascot on Coin Yellow (`#FFD23F`) across Android mipmaps (mdpi to xxxhdpi), iOS AppIcon xcassets set (1024x1024 down to 20x20), `app_launcher_icon.png`, and `app_icon_splash.png`; modernized `devspace_logo.dart` to display multi-color mascot graphics natively.
- Feed Doubts Polish: Added `#Doubt`, `#Question`, and `#Project` to trending tags for seamless campus feed posting with 1280x1280 compressed image uploads.
- Device Boot Safeguard: Added 2-second timeout to `SafeDevice` to prevent cold-boot hangs on physical Android devices.
- India-Optimized Opportunities Pipeline & Freshness Filter: High-signal ingestion and curated catalog of verified active 2025–2026 engineering hackathons tailored for Indian B.Tech students (SIH 2026, Flipkart GRiD 7.0, Google Solution Challenge, ETHIndia, Amazon ML Challenge, Hack This Fall) with automated multi-pattern date & keyword parsing, non-tech pruning, and automatic relegation of expired/TBA events into collapsible Past Events.
- Arena Question Bank Scaling to 30 Questions: Scaled quiz session length from 8 to 30 questions in `quiz_screen.dart`, expanded question pool in `practice_questions.dart` to 242 clean, non-repetitive CS and logic questions across all 4 modes (Easy: 60, Medium: 74, Hard: 58, Ultra: 50) with smart uncompleted-first quiz sampling, responsive `SegmentBar` scaling, and 100% database RPC schema compatibility.
- Path Tab Redesign: Productionized personalized learning route engine featuring 5 deep tracks (Flutter, Web, Backend, DSA, AI/ML), 48 curated nodes, starting level skipping (foundation nodes deducted from total hours without fake records), 3h/6h/10h finish date math, 60fps optimistic node completion with rollback on failure, single active roadmap enforcement (`user_roadmaps` table and `idx_user_roadmaps_one_active`), One Clear Next Step discovery, official documentation links, and comprehensive test coverage.

## Phase 6: Release Captain Stabilization & Safety Net (Completed)
- Startup Critical Path: Eliminated 1.6-second artificial sleep in `main.dart`, accelerating cold-boot time to interactive first frame.
- Config Hardening: Removed hardcoded production credentials from default parameters in `RuntimeConfig.load()`, adding `.env.staging.json.example`.
- Automated Safety Net: Added test coverage across critical user paths: `SettingsScreen` (sign out, account deletion), `WaitingForOpponentScreen`, `ChatDetailScreen` (messaging flow), and `DuelScreen` (countdown and live combat session).
- Polling & Network Efficiency: Optimized `streamConversations` from 15s to 45s with exponential backoff on error; reduced redundant duel invite and score sync polls; eliminated remote DB spam for solo mock bot duels.
- Query Projections: Added explicit column selection to high-traffic Supabase queries (`users`, `posts`, `conversations`).
- Dead Code Governance: Cataloged legacy `PracticeMapScreen` and `PracticeQuestionScreen` in Dead Code Inventory (Rule 9: preserved, not deleted).
- Static Analysis & Hygiene: Cleaned all 355 analyzer issues down to 0 errors, 0 warnings, 0 hints; const-qualified 350+ data structures to reduce heap pressure.
- Raster Cache & Memory Protection: Capped memory raster cache (`memCacheWidth` & `memCacheHeight`) across network images to prevent OOM on 4GB Android devices.
- Launch Indexes & Verification: Authored `supabase/patches/14_launch_indexes.sql` and `supabase/checks/14_launch_indexes_verify.sql` for high-throughput p95 performance under launch load.
- Security & Sensitive Columns: Enforced `safePublicUserColumns` in `getUserById`, `getUserByHandle`, and `getUsersByIds` to prevent leaking `fcm_token` and `email` over the wire; added 15s defensive network timeout.

## Best Next Decision
Proceed with **One-College Closed Beta Founder Smoke Testing** on physical Android devices before distributing the APK to the first cohort of students.

## What Not To Build Yet
- Expanded DM product scope beyond the current basic 1:1 chat
- full notifications product
- advanced gamification beyond aura, streaks, and challenge rewards
- post type system
- recruiter/premium tooling
- multi-college admin tooling
