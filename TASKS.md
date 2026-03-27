# TASKS

## Current Goal
Close Phase 4 prep: make the app safe for first-college testing by fixing the last fake or weak surfaces and tightening beta readiness.

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

## In Progress
- [ ] Settings/account surface beyond sign-out
- [ ] Notification inbox/product flow
- [ ] Stronger regression coverage for core flows

## Next
1. Run founder device testing on auth, posting, interaction, profile, and Q&A flows
2. Fix beta-blocking bugs found during device testing
3. Add a minimal settings/account screen if sign-out alone is not enough
4. Prepare a closed-beta checklist for the first student testers
5. Strengthen regression coverage for the highest-risk mobile flows

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
