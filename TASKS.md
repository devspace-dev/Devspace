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
- [x] Basic aura feedback for posts and comments
- [x] Explicit Supabase runtime setup path
- [x] Production-oriented Supabase schema for aura, streaks, events, and challenges
- [x] Backend RPC flow for post aura, like aura, comment aura, and accepted answers
- [x] Edge function structure for `/users`, `/posts`, `/events`, `/challenges`, and `/aura`

## In Progress
- [ ] Frontend screens/providers for events and daily challenges
- [ ] Feed migration from stream-only loading to explicit paginated API consumption
- [ ] Stronger regression coverage for new backend rules

## Next
1. Connect the new events and challenge APIs to real app screens
2. Add founder/admin controls for creating events and challenge seeds
3. Test rate limits, duplicate-prevention, and streak reset behavior on real devices
4. Move feed reads to paginated requests where infinite scrolling is needed
5. Add targeted tests for aura awarding and challenge completion edge cases

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
