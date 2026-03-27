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
- run device-level founder testing across auth, profile, posting, and interactions
- run device-level founder testing across auth, profile, posting, Q&A, and interactions
- fix the top beta-blocking bugs found in that testing
- add a minimal settings/account surface if sign-out alone is not enough
- tighten beta onboarding docs for teammates and testers

Founder split:
- Founder A: bug triage, usability polish, tester flow, settings/account surface
- Founder B: backend reliability, regression coverage, setup/release readiness

Acceptance:
- no fake top-level surfaces remain in MVP
- both founders can install and test the app with the same setup steps
- the app survives real student testing without constant manual fixes

## Best Next Product Decision
Close the last beta-readiness gaps now.

Why:
- Q&A is now real, so the product should shift from feature completion to bug pressure and release reliability
- the remaining work is horizontal polish, not another major surface
- first-college testing will expose setup and mobile-flow issues faster than another feature will

Preferred path:
- device testing, settings/account cleanup, and regression coverage

Fallback path:
- if any surface proves too unstable in founder testing, cut or simplify it before broader beta

## What Not To Build Yet
- DMs
- full notifications product
- advanced gamification
- post type system
- recruiter/premium tooling
- multi-college admin tooling
