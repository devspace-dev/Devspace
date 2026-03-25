# FEATURE STATUS

## Implemented
- Auth UI for email/password and Google sign-in
- Session restore using stored MongoDB user id
- MongoDB-backed user creation and login/session model
- Home feed rendering from backend-loaded posts
- Create text posts with tags
- People directory with search and branch filter
- Profile viewing for self and other users
- Aura leaderboard and badge tiers
- Ask-question UI with local voting interactions
- GitHub activity card scaffold
- Notification and image-upload service scaffolding

## Partial
- Auth works in code, but runtime setup is brittle because the app still uses a placeholder MongoDB URI and missing platform config
- College email restriction exists in code but is disabled
- Follow/unfollow updates backend counts, but `isFollowing` state is not reliably hydrated in the UI
- Likes call backend methods, but liked-state hydration and full interaction UX are incomplete
- Comments backend exists, but the feed UI currently uses local comments instead of loading/saving the real comment stream
- Repost and bookmark actions are local-only and not persisted
- Profile data exists in the model and backend, but there is no onboarding or edit-profile flow
- Notifications initialize only when Firebase is configured, but there is no notifications inbox or product flow in the UI
- GitHub card exists, but the profile screen uses a hardcoded handle instead of per-user profile data
- Image upload widgets exist, but they are not integrated into post creation or profile editing
- Q&A exists as a screen, but it is local state only and not backed by MongoDB
- Automated coverage is limited to a login-screen smoke test

## Missing
- First-login onboarding
- Editable profile setup
- Sign-out/settings surface in the UI
- Real persistent comments UX
- Real persistent Q&A and answers
- Post image support in the live compose flow
- Post type system for project update / doubt / achievement / idea
- Notifications screen/inbox
- Real environment/config management for multiple collaborators
- Android Firebase config files
- Web-safe backend architecture if web remains a target
- Meaningful automated test coverage for core flows
