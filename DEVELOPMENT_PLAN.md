# DEVELOPMENT PLAN

## Summary
This plan is optimized for 2 student founders building toward a closed beta in one college. The focus is not feature breadth. The focus is a reliable app where student engineers can sign in, set up real profiles, post, discover each other, and interact around work.

Core principle:
- do not add advanced features before profile quality, feed quality, and interaction quality are stable

## Phase 1: Stabilize the Core App
Goal:
- make the current app runnable, understandable, and consistent for both founders

Work:
- replace placeholder local setup assumptions with real local-dev instructions
- fix runtime/config blockers: MongoDB URI handling, missing setup notes, platform expectations
- add sign-out/account exit path in the UI
- stabilize profile/follow/like/comment state mismatches that already exist
- stop treating web as a default target until the backend architecture supports it safely

Founder split:
- Founder A: UI cleanup, sign-out/settings surface, feed/profile interaction polish
- Founder B: auth/runtime cleanup, MongoDB state consistency, local setup/documentation

Acceptance:
- both founders can run the app locally
- both founders can sign in successfully
- feed/profile/follow/like flows behave consistently enough for internal testing

## Phase 2: Profile Setup MVP
Goal:
- make every new user land with a meaningful, searchable engineering profile

Work:
- build onboarding after first login
- add editable profile fields:
  - name
  - handle
  - year / branch
  - building
  - stack
  - bio
  - GitHub handle
- persist profile completion to MongoDB
- make People search/discovery depend on real profile data, not placeholders

Founder split:
- Founder A: onboarding and edit-profile UI
- Founder B: persistence, validation, state refresh, handle uniqueness rules

Acceptance:
- a new user can complete a real profile without touching MongoDB manually
- profile changes appear correctly in Profile and People screens

## Phase 3: Social Interaction MVP
Goal:
- make posting and interaction reliable enough for real student use

Work:
- make comments fully persistent and visible in the feed
- finish likes/follows UX consistency
- add image support to post creation if it is stable enough
- add loading / empty / error states for core feed and profile surfaces
- connect aura updates to the final interaction flow in a basic, visible way

Founder split:
- Founder A: post/comment UX, interaction states, empty/loading polish
- Founder B: MongoDB read/write paths, counters, interaction persistence

Acceptance:
- users can post, like, comment, follow, and browse without obvious broken states
- interaction counts remain consistent after refresh/reopen

## Phase 4: Closed Beta Prep
Goal:
- prepare the product for first-college testing with real users

Work:
- either persist Q&A properly or cut it from MVP if it is still weak
- fix the top UX bugs found during founder testing
- tighten setup docs so onboarding teammates/testers is fast
- prepare a short closed-beta checklist for the first 20-50 students

Founder split:
- Founder A: bug triage, usability polish, tester feedback loop
- Founder B: reliability fixes, environment cleanup, release readiness

Acceptance:
- the app is stable enough to hand to real students without constant founder intervention

## Best Next Feature
Build `onboarding + editable profile setup` next.

Why this is the single best next move:
- it is a real MVP gap today
- it improves discovery, follow quality, and profile usefulness across the whole app
- the current auth flow creates users, but they land with placeholder data
- without real profiles, the social graph feels empty even if feed/auth technically work

## What Not To Build Yet
- DMs
- premium / recruiter tools
- multi-college admin tooling
- advanced gamification
- complex notification systems
- any feature that does not improve profile quality, posting, discovery, or interaction

## Assumptions
- MVP means a closed beta for one college, not app-store readiness
- mobile is the real target for MVP
- web is not required for MVP while `mongo_dart` is used directly in the client
- Q&A is optional for MVP if core social/profile flows are still weak
