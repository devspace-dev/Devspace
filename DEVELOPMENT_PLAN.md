# DEVELOPMENT PLAN

## Summary
Core MVP social flows exist, but the backend now needs to carry more product logic so the founders are not manually policing abuse or engagement.

That means Phase 4 should focus on productionizing the existing app with backend-owned gamification and controlled engagement loops.

## Phase 4: Closed Beta Prep + Backend Productization
Goal:
- make the product safe for first-college testing without founder hand-holding
- move aura/challenge/event rules out of the client and into Supabase-backed backend logic

Work:
- finalize aura ledger, streak logic, and accepted-answer rewards
- ship events/opportunities gating based on aura thresholds
- ship one-daily-challenge assignment and completion flow
- run founder testing across auth, posting, Q&A, aura, events, and challenge behavior
- fix the top beta-blocking bugs found in that testing
- add a minimal settings/account surface if sign-out alone is not enough

Founder split:
- Founder A: challenge/event UX wiring, founder testing, admin seeding flow
- Founder B: backend reliability, regression coverage, setup/release readiness

Acceptance:
- no fake top-level surfaces remain in MVP
- both founders can install and test the app with the same setup steps
- aura and challenge rewards cannot be trivially abused from the client
- the app survives real student testing without constant manual fixes

## Best Next Product Decision
Finish backend-owned engagement systems before adding any new social surface.

Why:
- the app already has enough core social surface for a first college
- aura, challenge, and opportunity logic are directly tied to retention and should be trustworthy
- backend-owned rules reduce client abuse and keep a small team from doing manual cleanup

Preferred path:
- integrate events and daily challenges into the app
- test and harden the backend rules
- then finish the remaining beta cleanup

Fallback path:
- if challenge/event flows prove unstable, keep the data model and cut the UI surface until after beta

## What Not To Build Yet
- Expanded DM product scope beyond the current basic 1:1 chat
- full notifications product
- advanced gamification beyond aura, streaks, and challenge rewards
- post type system
- recruiter/premium tooling
- multi-college admin tooling
