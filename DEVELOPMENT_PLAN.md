# DEVELOPMENT PLAN

## Summary
Phases 1, 2, and 3 are now effectively closed for MVP work:
- Phase 1: core app stabilized
- Phase 2: onboarding/profile completed
- Phase 3: social interaction MVP completed

The app should now move into Phase 4 work only.

## Phase 4: Closed Beta Prep
Goal:
- make the product safe for first-college testing without founder hand-holding

Work:
- either persist Q&A properly or remove it from MVP navigation
- run device-level founder testing across auth, profile, posting, and interactions
- fix the top beta-blocking bugs found in that testing
- add a minimal settings/account surface if sign-out alone is not enough
- tighten beta onboarding docs for teammates and testers

Founder split:
- Founder A: bug triage, usability polish, tester flow, settings/account surface
- Founder B: Q&A persistence or cut, backend reliability, setup/release readiness

Acceptance:
- no fake top-level surfaces remain in MVP
- both founders can install and test the app with the same setup steps
- the app survives real student testing without constant manual fixes

## Best Next Product Decision
Decide Q&A now.

Why:
- it already exists as a top-level tab
- today it is still local/demo behavior
- leaving a fake top-level surface in a beta is riskier than delaying another new feature

Preferred path:
- make Q&A real with Supabase persistence

Fallback path:
- if Q&A cannot be made real quickly, remove it from MVP navigation until it is ready

## What Not To Build Yet
- DMs
- full notifications product
- advanced gamification
- post type system
- recruiter/premium tooling
- multi-college admin tooling
