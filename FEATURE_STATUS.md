# FEATURE STATUS

## Implemented
- Email/password auth with Supabase
- Phone OTP auth with Supabase
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
- Aura feedback for post and comment contribution
- Profile viewing for self and others
- Aura leaderboard
- Backend aura ledger, level mapping, and streak tracking
- Event gating model with eligible vs locked access
- Daily challenge tables and completion RPC flow
- Edge API structure for core backend domains
- Opportunities screen with locked/unlocked visibility and link access for eligible users
- Daily challenge screen with backend-backed submission flow
- Home engagement cards linked to full-screen challenge/opportunity views
- Founder tools restricted to allowlisted founder/developer devices on top of admin auth

## Partial
- Google sign-in is visible but intentionally disabled
- GitHub profile card is useful scaffold, not a finished identity system
- Notifications plumbing exists, but there is no full inbox/product flow beyond activity and message alerts
- Automated coverage exists, but it is still light for a production beta
- Feed still relies on realtime stream loading in the current UI, though paginated backend endpoints now exist
- Pre-production release hardening now covers runtime config gating, Crashlytics wiring, notification permission requests, HTTPS-only backend expectations, and friendlier network failure handling

## Missing
- Settings/account surface beyond sign-out
- Notifications screen/inbox
- Broader automated coverage for core flows
- External privacy policy URL and full Play Store listing assets/metadata
