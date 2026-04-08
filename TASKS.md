# TASKS

## Current Goal
Upgrade the app backend for launch-ready gamification and gated engagement without adding product bloat.

## Done
- [x] Auth-gated app entry
- [x] Email/password sign up and sign in
- [x] Supabase-backed auth/session model
- [x] Onboarding and editable profile flow
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

## In Progress
- [ ] Feed migration from stream-only loading to explicit paginated API consumption
- [ ] Stronger regression coverage for new backend rules
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
