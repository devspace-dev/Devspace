# FEATURE STATUS

## Implemented
- Auth UI for email/password
- Session restore using Supabase auth
- Supabase-backed user creation and login/session model
- Home feed rendering from backend-loaded posts
- Create text posts with tags
- People directory with search and branch filter
- Profile viewing for self and other users
- First-login onboarding flow
- Editable profile setup flow
- Aura leaderboard and badge tiers
- Persistent feed comments
- Ask-question UI with local voting interactions
- GitHub activity card scaffold
- Notification and image-upload service scaffolding

## Partial
- Google sign-in is visible in the UI but intentionally disabled during the Supabase migration
- College email restriction exists in code but is currently disabled
- Follow/unfollow updates backend counts, but the UX still needs polish and more explicit refresh behavior
- Likes call backend methods and optimistic UI, but interaction UX still needs polish
- Repost and bookmark actions are local-only and not persisted
- Notifications initialize only when Firebase is configured, but there is no notifications inbox or product flow in the UI
- Image upload widgets exist, but they are not integrated into live post creation everywhere they should be
- Q&A exists as a screen, but it is local state only and not backed by Supabase
- Automated coverage is still light

## Missing
- Sign-out/settings surface in the UI
- Real persistent Q&A and answers
- Post image support in the live compose flow
- Post type system for project update / doubt / achievement / idea
- Notifications screen/inbox
- Real environment/config management for multiple collaborators
- Android Firebase config files
- Meaningful automated test coverage for core flows
