# TASKS

## Current Goal
Build a stable MVP for launch inside one college, with real profiles, posting, feed interactions, and reliable local setup for both founders.

---

## Done
- [x] App shell with 5 tabs: Home, People, Q&A, Aura Board, Profile
- [x] Splash screen and auth-gated app entry
- [x] Email/password sign up and sign in
- [x] Google sign-in flow
- [x] MongoDB-backed user/session persistence
- [x] Feed list rendering from backend stream
- [x] Create text posts with tags
- [x] People directory with search and branch filter
- [x] Profile view screen
- [x] Follow/unfollow backend calls
- [x] Aura leaderboard and badge system
- [x] Basic ask-question UI
- [x] Basic GitHub activity card scaffold
- [x] Notification and image-upload scaffolding

---

## In Progress
- [ ] Real onboarding / profile setup flow
- [ ] Editable profile flow
- [ ] Fully persistent comments
- [ ] Consistent likes state in the UI
- [ ] Repost / bookmark persistence
- [ ] Persistent Q&A data
- [ ] Clean local runtime/setup flow

---

## Next Priority
1. Build onboarding + editable profile setup
2. Make comments fully persistent and visible in the feed
3. Stabilize likes and follows state in the UI
4. Add image support to real post creation
5. Add sign-out and basic account/session controls
6. Persist Q&A to MongoDB or cut it from MVP
7. Add post types:
   - Project Update
   - Doubt / Question
   - Achievement
   - Idea / Learning
8. Replace placeholder setup/config with real local-dev instructions
9. Test with real student users in one college
10. Fix bugs and improve usability from beta feedback

---

## Later
- [ ] Notifications inbox
- [ ] Collaboration requests
- [ ] Search/discovery improvements
- [ ] GitHub profile linking
- [ ] Leaderboard polish
- [ ] Streak system
- [ ] College expansion tools
- [ ] Premium / recruiter features

---

## Rules Before Building New Features
- Do not start advanced features before core profile + post + feed basics are stable
- Do not treat scaffolding as shipped product
- Prioritize retention-related features first: profile quality, posting, discovery, interaction
- Test each major feature with real student usage before moving to advanced ideas
- Do not optimize for web until the backend architecture supports it safely

---

## MVP Definition
The MVP is ready when:
- users can sign up and sign in
- users can complete a real profile
- users can create posts
- users can like and comment on posts
- users can follow students and view profiles
- users can discover students through search/profile info
- aura updates work in a basic visible way
- both founders can run the app locally without manual repo surgery
- the app is stable enough for first-college closed testing
