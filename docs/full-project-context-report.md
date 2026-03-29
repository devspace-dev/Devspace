# Full Project Context Report

Generated: 2026-03-29  
Repository: `/Users/mohammad/Desktop/devspace`

## Scope and method

- This report is based on direct inspection of the repository: docs, Flutter app code, providers, services, models, screens, SQL schema files, Supabase Edge Functions, the `backend/` folder, tests, package/config files, and platform files.
- No application code was changed, deleted, or refactored during this pass.
- Local verification was also run on 2026-03-29 with `flutter test` and `flutter analyze`; both exposed useful status/risk information and are summarized below.
- When intent is not explicit in the codebase, this report says `unclear from the codebase`.

---

# 1) Project identity

## Project name

- Product/app name in code and README: `DevSpace`
- Working title in product docs: `Student Developer Community App`

## What this product appears to be

- A mobile-first social/community app for student developers inside a college.
- It is positioned as a focused builder network rather than a general-purpose social app.

## Core purpose of the product

- Help engineering students share what they are building, ask technical doubts, discover other builders, and build a visible developer identity inside their campus community.

## The main problem it solves

- Students do not have a focused college-local platform to:
  - share projects and learning publicly
  - ask technical questions in a structured way
  - get feedback from peers
  - discover collaborators and senior/junior builders
  - accumulate visible proof of contribution

## Who it is for

- Primary audience:
  - engineering/BTech students
  - students in the founders’ own college
  - students interested in coding, hackathons, internships, projects, and tech learning
- Secondary audience:
  - seniors with experience
  - juniors seeking help
  - coding club members
  - students looking for collaborators

## The clearest one-sentence description

- DevSpace is a college-focused builder community app where student developers share project progress, ask practical questions, discover peers, and earn visible aura through contribution.

## A 50-word summary

DevSpace is a Flutter and Supabase app for student developers in a college community. It combines profiles, a builder feed, Q&A, follows, comments, aura points, streaks, daily missions, and gated opportunities. The product is designed for one-college launch and appears to be in MVP or closed-beta preparation rather than production.

## A 150-word summary

DevSpace is a student developer community product built as a mobile-first Flutter app backed mainly by Supabase. The repository shows a social layer centered on useful student-builder behaviors: creating posts, sharing project updates, asking technical doubts, replying to questions, following other builders, browsing profiles, and discovering peers by stack or branch. On top of this, the product adds lightweight gamification through aura points, streaks, accepted-answer rewards, daily challenge or mission flows, and opportunity gating for events and hackathons. The codebase also includes founder/admin tools for seeding events and challenges, plus a partially implemented messaging feature that appears to be ahead of current MVP scope. Product docs repeatedly emphasize that this is not generic social media and should stay narrow, useful, and realistic for a one-college launch. The current state looks like an MVP being hardened for founder testing or closed beta, with strong product direction but visible schema, setup, testing, and scope-drift issues.

---

# 2) Product overview

## What the user can do in this product

- Sign up and sign in with email and password.
- View an auth intro that frames the product around building in public, practical Q&A, finding builders, and earning aura.
- Complete onboarding or later edit a public profile.
- Browse a home feed of student-builder posts.
- Create text posts, image posts, or quote posts.
- Like, comment on, bookmark, and quote posts.
- Browse a People directory and search by stack, branch, project/building, role, or handle.
- View self and other user profiles.
- Follow/unfollow users and inspect followers/following lists.
- Ask questions, reply to questions, upvote questions, and mark a reply as solved.
- See aura and unlocked opportunities from the home engagement overview.
- Open a daily mission/challenge screen and submit work or answers.
- View an aura leaderboard.
- View notifications in a modal sheet and mark them read.
- Open a settings screen with theme selection, saved posts, about, and founder tools access when authorized.
- Use direct messaging screens if the messaging tables exist in the connected database.

## Main user journeys

- New student joins, creates account, completes profile, lands on feed.
- Student posts an update or asks a doubt.
- Another student discovers the post, likes or comments, or answers a question.
- The original asker marks a reply as solved, creating aura feedback.
- Users browse other builders in People and follow them.
- Users accumulate aura and see opportunities unlock.
- Founder/admin seeds events and challenge content from founder tools.

## Primary use cases

- Build in public inside a college.
- Ask and answer technical questions.
- Discover student developers working in similar areas.
- Build a visible campus reputation through contribution and aura.
- Nudge repeat engagement through streaks, daily missions, and gated opportunities.

## User types/personas inferred from the code

- Student builder: creates posts, tracks progress, asks doubts.
- Knowledge sharer/senior: replies to questions, earns aura from accepted answers.
- Explorer/networker: uses People, profiles, follows, connections, and saved posts.
- Competitive/engagement-driven user: checks aura, streaks, leaderboard, missions, and unlocks.
- Founder/admin: seeds opportunities and challenge content through founder tools.
- Possible developer-founder superuser: has extra “System” tab access when `isFounder` is true.

## What makes this product different or notable

- It is explicitly optimized for student builders, not general college socializing.
- It ties social participation to builder identity rather than vanity-heavy content formats.
- It combines feed + Q&A + people discovery + light gamification in one product.
- It uses aura, streaks, accepted-answer rewards, and opportunity gating to create structured engagement loops.
- The copy is consistently oriented around “builders”, “practical doubts”, and college collaboration rather than broad community language.

## What stage the product seems to be in, and why

- Best-fit stage: `MVP in closed-beta prep / founder-test stage`
- Why:
  - Core MVP flows exist end to end: auth, profile, feed, posting, Q&A, comments, follows, aura, opportunities, daily mission screen.
  - Planning docs explicitly frame the current step as “Phase 4: Closed Beta Prep + Backend Productization”.
  - There are founder-only tools and founder-device allowlisting, which strongly suggests internal testing and controlled rollout.
  - Tests are light and currently failing from model drift.
  - CI/CD, deployment workflow, env examples, and release hardening are not yet visible.
  - Some product/docs/setup drift indicates the codebase is still consolidating around a stable launch shape.

---

# 3) Feature inventory

The table below lists every identifiable feature surface found during the repo pass. “Planned” means a clear visible placeholder or documented intent exists but the working feature is not complete.

| Feature | What it does | Where it lives | Related frontend files | Related backend files | Related DB/models | Related APIs/actions/jobs | Status | Hidden/admin/internal-only |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Runtime bootstrap/setup guard | Stops app on a setup screen if Supabase init fails or config is missing | App entry | `lib/main.dart` | none | Supabase runtime config | Supabase init | Partial | Not hidden |
| Splash + auth intro | Shows splash, then onboarding-value intro before auth | Entry/auth | `lib/main.dart`, `lib/screens/splash_screen.dart`, `lib/screens/auth_intro_screen.dart` | none | none | none | Complete | Not hidden |
| Email/password auth | Active sign-up/sign-in flow via Supabase Auth | Auth | `lib/screens/login_screen.dart`, `lib/providers/auth_provider.dart`, `lib/services/auth_service.dart` | Supabase Auth | `auth.users`, `public.users`, `UserModel` | Supabase Auth `signUp`, `signInWithPassword`, sign-out | Complete | Not hidden |
| Google sign-in placeholder | Visible button that returns “coming soon” | Auth | `lib/screens/login_screen.dart`, `lib/services/auth_service.dart` | none | none | `AuthService.signInWithGoogle()` | Planned/partial | Not hidden |
| First-login profile creation | Creates a default user row after successful auth | Auth/profile bootstrap | `lib/services/auth_service.dart`, `lib/services/supabase_service.dart` | none | `public.users`, `UserModel` | `SupabaseService.createUser()` | Complete | Not hidden |
| Profile completion prompt | Prompts incomplete users to finish onboarding | Root app shell | `lib/main.dart` | none | `users.profile_completed` | modal prompt, navigation to onboarding | Complete | Not hidden |
| Profile onboarding/edit flow | Collects name, handle, role, year, branch, college, building, stack, bio, GitHub | Profile | `lib/screens/profile_setup_screen.dart`, `lib/providers/auth_provider.dart` | `AuthService.updateCurrentUserProfile()` | `public.users`, `UserModel` | user update writes | Complete | Not hidden |
| Home feed | Paginated feed with intro copy, composer, engagement cards, tags, loading/empty/error states | Main tab | `lib/screens/home_screen.dart`, `lib/providers/posts_provider.dart` | `lib/services/backend_api_service.dart`, `lib/services/supabase_service.dart` | `public.posts`, `PostModel` | `GET /posts`, direct Supabase fallback | Complete | Not hidden |
| Compose post | Create text, image, or text+image post | Feed/posting | `lib/widgets/compose_box.dart`, `lib/providers/posts_provider.dart` | `lib/services/supabase_service.dart`, `lib/services/storage_service.dart` | `posts`, storage `images`, `PostModel` | RPC `create_post_with_aura`, storage upload | Complete | Not hidden |
| Quote posts | Lets users quote an existing post into a new one | Feed/posting | `lib/widgets/post_card.dart`, `lib/providers/posts_provider.dart` | `lib/services/supabase_service.dart` | `posts.quote_post_id` | `createPost(... quotePostId)` | Complete | Not hidden |
| Post likes | Toggle like/unlike with optimistic UI | Feed/post card | `lib/widgets/post_card.dart`, `lib/providers/posts_provider.dart` | `lib/services/supabase_service.dart` | `likes`, `posts.likes_count`, `aura_ledger` | RPC `like_post_with_aura`, `unlike_post` | Complete | Not hidden |
| Post comments | Comment on posts with persistent storage and aura | Feed/post card | `lib/widgets/post_card.dart`, `lib/providers/posts_provider.dart` | `lib/services/supabase_service.dart` | `comments`, `posts.comments_count`, `aura_ledger` | RPC `add_comment_with_aura` | Complete | Not hidden |
| Saved posts/bookmarks | Save posts and revisit from settings | Feed/settings | `lib/widgets/post_card.dart`, `lib/screens/saved_posts_screen.dart`, `lib/providers/posts_provider.dart` | `lib/services/supabase_service.dart` | `bookmarks` | bookmark add/remove/read | Complete | Not hidden |
| People discovery | Search builders by stack, branch, handle, role, building/project | People tab | `lib/screens/people_screen.dart`, `lib/widgets/profile_card.dart`, `lib/providers/users_provider.dart` | `lib/services/supabase_service.dart` | `users`, `UserModel` | realtime users stream | Complete | Not hidden |
| Profile view | View self/other profile, stats, posts, GitHub card, connections | Profile | `lib/screens/profile_screen.dart`, `lib/widgets/github_card.dart` | `lib/services/github_service.dart`, `lib/services/supabase_service.dart` | `users`, `posts`, follow counts | public GitHub API, user/post reads | Complete | Not hidden |
| Follow/unfollow | Follow builder profiles and update counts | Profile/people | `lib/widgets/profile_card.dart`, `lib/providers/users_provider.dart`, `lib/screens/connections_screen.dart` | `lib/services/supabase_service.dart` | `follows`, `users.followers`, `users.following` | direct insert/delete | Complete | Not hidden |
| Connections screens | Browse follower/following lists with search | Profile | `lib/screens/connections_screen.dart`, `lib/providers/users_provider.dart` | `lib/services/supabase_service.dart` | `follows`, `users` | follow list loaders | Complete | Not hidden |
| Direct messaging | Start conversations and send messages between users | Profile/app bar/messages | `lib/widgets/profile_card.dart`, `lib/screens/messages_screen.dart`, `lib/screens/chat_detail_screen.dart`, `lib/providers/messages_provider.dart` | `lib/services/supabase_service.dart` | `conversations`, `messages`, `ConversationModel`, `MessageModel` | conversation stream, message stream, send message | Partial/risky | Hidden in docs scope; not hidden in UI |
| Q&A list | List questions and open detail threads | Q&A tab | `lib/screens/qa_screen.dart`, `lib/providers/questions_provider.dart` | `lib/services/supabase_service.dart` | `questions`, `QuestionModel` | realtime questions stream | Complete | Not hidden |
| Ask question | Create persistent question posts with tags | Q&A | `lib/screens/qa_screen.dart`, `lib/providers/questions_provider.dart` | `lib/services/supabase_service.dart` | `questions` | direct insert | Complete | Not hidden |
| Replies to questions | Add replies, including one nested reply level | Q&A detail | `lib/screens/question_detail_screen.dart`, `lib/providers/questions_provider.dart` | `lib/services/supabase_service.dart` | `question_replies`, `QuestionReplyModel` | direct insert + validation | Complete | Not hidden |
| Question upvotes | Upvote/un-upvote questions | Q&A | `lib/screens/question_detail_screen.dart`, `lib/providers/questions_provider.dart` | `lib/services/supabase_service.dart` | `question_votes`, `questions.upvotes_count` | insert/delete | Complete | Not hidden |
| Solved answers | Mark one reply as solved and award aura | Q&A detail | `lib/screens/question_detail_screen.dart`, `lib/providers/questions_provider.dart` | `lib/services/supabase_service.dart`, SQL RPC | `questions.solved_reply_id`, `aura_ledger` | RPC `mark_question_reply_solved` | Complete | Not hidden |
| Notifications modal | Shows recent notifications and read state | App shell | `lib/app.dart`, `lib/providers/notifications_provider.dart` | `lib/services/supabase_service.dart`, `lib/services/notification_service.dart` | `notifications`, `NotificationModel` | notifications stream, mark read | Partial | No full inbox/product flow |
| Local notification plumbing | Creates notification channel and helper methods to push records | Services | `lib/services/notification_service.dart` | none | `notifications` | local notification init, helper writers | Partial | Internal plumbing; actual call sites are unclear from active flows |
| Aura overview | Loads aura summary, events, daily mission summary for home cards | Engagement layer | `lib/providers/engagement_provider.dart`, `lib/widgets/engagement_overview.dart` | `lib/services/backend_api_service.dart` | `users`, `aura_ledger`, `events`, `challenges`/`missions` | `GET /aura`, `GET /events/eligible`, `GET /missions/daily` | Complete | Not hidden |
| Aura leaderboard | Displays ranked users and aura tiers | Dedicated screen | `lib/screens/aura_board_screen.dart`, `lib/providers/users_provider.dart` | none | `users.aura` | realtime users stream | Partial | Weekly/monthly toggle is UI-only |
| Opportunities / event gating | Shows locked/unlocked opportunities based on aura, plus event tab | Main tab | `lib/screens/opportunities_screen.dart`, `lib/widgets/engagement_overview.dart` | `lib/services/backend_api_service.dart`, event edge function/service | `events`, `user_events`, `EventAccessModel` | `GET /events/eligible`, admin event endpoints | Complete | Not hidden |
| Daily mission/challenge screen | Assigns today’s challenge/mission and lets user submit work/answer | Dedicated screen/FAB | `lib/screens/daily_challenge_screen.dart`, `lib/providers/engagement_provider.dart` | `lib/services/backend_api_service.dart`, challenge/mission edge services | `challenges`, `user_challenges`, `missions`, `user_missions`, `DailyChallengeModel` | `/missions/daily`, `/missions/submit`, fallbacks to `/challenges/*` and RPCs | Partial | Not hidden |
| Founder tools | Admin UI for events/challenges and limited system actions | Settings | `lib/screens/founder_tools_screen.dart`, `lib/widgets/founder_access_denied_view.dart` | `lib/services/backend_api_service.dart`, edge functions | `events`, `challenges`, `founder_devices`, `users.is_admin` | admin event/challenge endpoints, founder-access check | Partial | Internal/admin only |
| Founder device allowlisting | Requires allowlisted device ID in addition to admin auth | Backend authz | none | `lib/services/founder_device_service.dart`, `supabase/functions/_shared/auth.ts`, `supabase/functions/users/controller.ts` | `founder_devices`, `users.is_admin` | `X-Device-Id`, `/users/founder-access` | Complete | Internal/admin only |
| Mission admin backend | Backend endpoints for creating/reviewing missions | API layer only | no matching founder UI surfaced | `lib/services/backend_api_service.dart`, `supabase/functions/missions/*` | `missions`, `user_missions` | mission CRUD/review endpoints | Partial/planned | Internal/admin; backend exists more than UI |
| GitHub profile card | Shows public GitHub repos/commits/user stats for a handle | Profile | `lib/widgets/github_card.dart`, `lib/services/github_service.dart` | public GitHub REST API | GitHub user/repos/events | outbound GitHub API calls | Partial | Not hidden |
| Settings/account surface | Theme switcher, edit profile, saved posts, about, sign out, founder tools entry | Settings | `lib/screens/settings_screen.dart`, `lib/providers/theme_provider.dart` | `lib/services/backend_api_service.dart` | theme pref, user/profile data | sign-out, founder-access check | Partial but more complete than docs say | Founder tools entry is access-gated |

## Feature status summary

- Complete or mostly complete user-facing surfaces:
  - email/password auth
  - onboarding/edit profile
  - feed
  - create post
  - likes/comments/bookmarks
  - people discovery
  - profiles/follows/connections
  - Q&A with solved answers
  - opportunities gating
  - daily mission/challenge screen
- Partial or drift-prone surfaces:
  - Google sign-in
  - notifications as a product
  - daily mission vs daily challenge transition
  - founder mission admin UI
  - messaging schema/setup consistency
  - leaderboard timeframe logic
  - GitHub card depth

---

# 4) End-to-end flow mapping

## User signup, login, onboarding

### Entry point

- `main()` initializes Supabase and `AuthService`, then `_Root` decides between splash, auth intro, and the main app.

### Key screens/components

- `SplashScreen`
- `AuthIntroScreen`
- `LoginScreen`
- `ProfileSetupScreen`
- profile-completion prompt bottom sheet in `lib/main.dart`

### Backend handlers/services

- `AuthService.init()`
- `AuthService.signUpWithEmail()`
- `AuthService.signInWithEmail()`
- `AuthService._loadOrCreateProfile()`
- `AuthProvider.updateProfile()`

### Database reads/writes

- Reads current Supabase auth session.
- Reads `public.users` by current auth user ID.
- Creates a new `public.users` row on first login if missing.
- Updates user profile fields on onboarding completion.

### External integrations

- Supabase Auth
- Supabase Database

### Side effects

- First successful auth creates a user profile row.
- Successful sign-in initializes notifications locally and inside provider state.
- Incomplete profiles trigger a modal prompt that links to onboarding.

### Failure points / risk points

- README/setup docs say checked-in Supabase defaults are gone, but both `lib/main.dart` and `BackendApiService` still contain fallback URL/key defaults.
- Sign-up can fail if Supabase email confirmation remains enabled.
- College-domain enforcement is disabled, so current college targeting is policy-light.
- Target-college identity is inconsistent: `_collegeDomain` is `mnit.ac.in`, default user college is `Jaipur National University`, and dropdown options include both JNU and MNIT Jaipur.

## Main dashboard/home flow

### Entry point

- After auth gate passes, `_Root` returns `DevSpaceApp`.

### Key screens/components

- `DevSpaceApp` with a `PageView` and custom bottom nav
- `HomeScreen`
- `ComposeBox`
- `EngagementOverview`
- `PostCard`

### Backend handlers/services

- `UsersProvider.fetchUsers()`
- `PostsProvider.fetchFeed()`
- `QuestionsProvider.fetchQuestions()`
- `NotificationsProvider.init()`
- `EngagementProvider.fetchOverview()`

### Database reads/writes

- Users loaded from realtime users stream.
- Feed loaded from paginated backend endpoint with direct-Supabase fallback.
- Engagement overview reads aura summary, eligible events, and daily mission/challenge assignment.

### External integrations

- Supabase Edge Functions `/posts`, `/aura`, `/events/eligible`, `/missions/daily`
- Direct Supabase fallback reads

### Side effects

- Notification provider subscribes to realtime notifications.
- Messages provider subscribes to conversations.
- FAB routes into the daily mission screen.

### Failure points / risk points

- Feed docs/status files still describe stream-based feed loading, but `PostsProvider` now defaults to paginated API loading.
- The app shell still shows messages and notifications even though both are not fully productized.
- There is no route framework in active use despite `go_router` dependency presence; navigation is widget-local and ad hoc.

## Core action flow: create post and interact

### Entry point

- User taps or uses the composer on `HomeScreen`.

### Key screens/components

- `ComposeBox`
- `PostCard`
- quote-post sheet inside `PostCard`

### Backend handlers/services

- `PostsProvider.addPost()`
- `PostsProvider.addQuotePost()`
- `SupabaseService.createPost()`
- `StorageService` image upload methods
- `PostsProvider.toggleLike()`
- `PostsProvider.addComment()`
- `PostsProvider.toggleBookmark()`

### Database writes/reads

- Inserts `posts`
- Uploads post image to `images` storage bucket
- Inserts/deletes `likes`
- Inserts `comments`
- Inserts/deletes `bookmarks`
- Reads quoted posts as needed

### External integrations

- Supabase Storage
- Supabase RPCs:
  - `create_post_with_aura`
  - `like_post_with_aura`
  - `add_comment_with_aura`
  - `unlike_post`

### Side effects

- Aura is awarded via backend-owned RPCs.
- Like/comment counts update.
- Saved posts become visible in `SavedPostsScreen`.

### Failure points / risk points

- Storage setup is manual and only documented at a high level.
- Notification helper methods exist for likes/comments but active integration from posting flows is unclear from the codebase.
- Rate limiting exists in SQL, but there are few tests covering abuse/edge cases.

## Core action flow: Q&A

### Entry point

- User opens the Q&A tab or taps “Ask a question”.

### Key screens/components

- `QAScreen`
- `QuestionDetailScreen`
- inline reply composer in detail view

### Backend handlers/services

- `QuestionsProvider.fetchQuestions()`
- `QuestionsProvider.addQuestion()`
- `QuestionsProvider.addReply()`
- `QuestionsProvider.toggleUpvote()`
- `QuestionsProvider.markSolvedReply()`
- `SupabaseService` question/reply/vote methods

### Database writes/reads

- Inserts `questions`
- Inserts `question_replies`
- Inserts/deletes `question_votes`
- Updates `questions.solved_reply_id`
- Reads replies per question

### External integrations

- Direct Supabase DB reads/writes
- RPC `mark_question_reply_solved`

### Side effects

- Accepted-answer aura is awarded through SQL.
- One nested reply level is supported; deeper nesting is rejected.
- Solved reply is surfaced in the detail screen and snackbars.

### Failure points / risk points

- `mark_question_reply_solved` is defined twice in `supabase/devspace_schema.sql`, which increases schema drift risk.
- The Q&A flow is direct-Supabase heavy; backend-owned moderation/safety logic is minimal.

## Payment/billing flow

- No payment or billing flow was found during repo scan.
- No Stripe, Razorpay, RevenueCat, checkout, subscription, or billing configuration was found in the repository scan outside false-positive matches on “subscription” as stream subscription naming.
- Monetization is therefore `unclear from the codebase`, and no live payment architecture is visible.

## Notifications/emails flow

### Entry point

- Notification badge in app bar opens a modal bottom sheet.

### Key screens/components

- notifications modal in `lib/app.dart`
- `NotificationsProvider`
- `NotificationService`

### Backend handlers/services

- `SupabaseService.streamNotifications()`
- `markNotificationAsRead()`
- `markAllNotificationsAsRead()`
- helper writers: `notifyLike`, `notifyComment`, `notifyFollow`

### Database writes/reads

- Reads `notifications` in realtime for the signed-in recipient.
- Marks notifications read by ID or all by `to_uid`.
- Manual notification insert helper exists.

### External integrations

- Flutter Local Notifications for local channel setup
- Supabase DB

### Side effects

- Local Android notification channel creation on app init.
- Unread count appears as an app bar badge.

### Failure points / risk points

- There is no dedicated notifications inbox screen.
- The helper methods that write notification rows appear underused from active interaction flows.
- README and FEATURE_STATUS both describe notifications as incomplete.

## Admin/moderation flow

### Entry point

- Settings screen -> Founder tools

### Key screens/components

- `SettingsScreen`
- `FounderToolsScreen`
- `FounderAccessDeniedView`

### Backend handlers/services

- `BackendApiService.hasFounderAccess()`
- event/challenge admin methods in `BackendApiService`
- `requireFounderDeviceUser()` in edge auth helper
- `users/founder-access` endpoint

### Database writes/reads

- Reads `users.is_admin`
- Reads `founder_devices`
- Admin CRUD on `events` and `challenges`

### External integrations

- Supabase Edge Functions
- founder device ID header `X-Device-Id`

### Side effects

- Unauthorized users see a denial view.
- Founder users get an extra `System` tab.

### Failure points / risk points

- No moderation/reporting/blocking flows were found for user-generated content.
- The system tab contains mostly placeholder snackbars, not real operations.
- Mission admin exists in backend services but is not exposed in the current founder UI.

## Data creation/update/delete flows

### Create

- User row created after first successful auth login.
- Posts created through RPC-backed insert.
- Questions created through direct insert.
- Replies created through direct insert.
- Likes/bookmarks/follows/messages created through direct insert or RPC.
- Events/challenges/missions created via admin endpoints.

### Update

- User profile updated through `AuthService.updateCurrentUserProfile()`.
- Post text can be updated through `SupabaseService.updatePost()`.
- Notifications marked read by update.
- Conversations updated with last-message metadata.
- Events/challenges/missions updated by admin endpoints.

### Delete / deactivate

- Posts can be deleted by direct delete.
- Likes, bookmarks, follows can be removed.
- Admin tools currently “deactivate” events/challenges rather than hard delete in edge flow.
- Legacy Express backend still includes a hard-delete challenge route.

### Main risk points across CRUD

- Canonical backend path is unclear because similar challenge management exists in both Supabase Edge Functions and `backend/`.
- Messaging depends on tables that do not exist in the main checked-in schema file.
- Setup docs omit parts of the currently visible backend data model.

---

# 5) Technical architecture

## Frontend framework and structure

- Frontend framework: Flutter
- UI architecture:
  - single mobile app
  - `main.dart` bootstraps providers and auth gate
  - `app.dart` defines the main shell
  - screens under `lib/screens/`
  - reusable widgets under `lib/widgets/`
  - service wrappers under `lib/services/`
  - providers under `lib/providers/`
  - models under `lib/models/`

## Backend framework and structure

- Primary active backend appears to be Supabase:
  - Supabase Auth
  - Postgres tables/RLS/RPCs
  - Supabase Storage
  - Supabase Edge Functions under `supabase/functions/`
- Secondary/legacy backend:
  - `backend/` Node/Express service with challenge/admin routes
  - likely older or parallel path
  - no scripts are defined in `backend/package.json`

## API style/pattern

- Hybrid pattern:
  - direct client-to-Supabase queries and realtime streams for users, questions, follows, likes, comments, notifications, messages
  - HTTP calls from Flutter to Supabase Edge Functions for aura summary, feed pagination, events, challenges, missions, founder access
  - direct SQL RPCs for aura-bearing actions like post creation, likes, comments, streak logic, event eligibility, and accepted-answer rewards

## State management

- Provider-based state management via `ChangeNotifierProvider`
- Global providers:
  - `ThemeProvider`
  - `AuthProvider`
  - `PostsProvider`
  - `QuestionsProvider`
  - `UsersProvider`
  - `AuraProvider`
  - `NotificationsProvider`
  - `EngagementProvider`
  - `MessagesProvider`

## Auth/authz model

- Supabase auth session is the main authentication source.
- App-level auth state is mirrored through `AuthService.authStateChanges` and `AuthProvider`.
- Authorization layers:
  - normal user access via Supabase session
  - RLS on many Postgres tables
  - admin access via `users.is_admin`
  - founder-superuser logic via founder email in client/legacy backend
  - founder device allowlisting via `founder_devices` plus `X-Device-Id`

## Data layer / ORM / DB setup

- No ORM is used.
- Data access is written directly against Supabase client and SQL/RPCs.
- SQL setup is checked in as raw SQL:
  - `supabase/devspace_schema.sql`
  - `supabase/daily_missions.sql`
  - `supabase/daily_missions_seed.sql`
  - `DATABASE_FIX.sql`
- The database model is richer than the “official” setup doc suggests.

## Background jobs / queues / cron

- No queue worker, cron configuration, or background job runner was found.
- Daily challenge/mission assignment is performed on demand through SQL functions or edge services when the app asks for “today’s” assignment.

## File storage / media handling

- Supabase Storage bucket `images`
- Public URLs are used for:
  - profile images
  - cover images
  - post images
- Upload logic lives in `lib/services/storage_service.dart`

## Caching

- No explicit server-side caching layer was found.
- Client-side state is cached in Provider memory during runtime.
- Realtime streams keep in-memory collections current for several domains.

## Analytics / tracking

- No analytics SDK or event tracking system was found during repo scan.
- Founder/system UI mentions “analytics”, but no concrete analytics implementation was found.

## Integrations

- Supabase Auth, Database, RPC, Realtime, Storage, Edge Functions
- GitHub public REST API for profile cards
- Flutter Local Notifications
- Google services file detection on Android
- Legacy Firebase setup docs remain in repo, but active Firebase runtime integration is not present in `pubspec.yaml` beyond historical remnants

## Deployment/infrastructure clues

- No deployment manifests were found during scan:
  - no GitHub Actions workflow files
  - no Dockerfile
  - no docker-compose
  - no Vercel/Netlify/Render/Railway config
  - no `supabase/config.toml`
- Local setup is documented only for running SQL manually in Supabase and launching Flutter with `--dart-define`.
- Edge function deployment steps are not documented in the checked-in setup files.

## CI/CD clues

- No CI workflow files were found.
- No release automation or infra-as-code was found.

## Testing strategy

- Minimal Flutter unit tests exist under `test/`.
- `test/engagement_provider_test.dart` covers the engagement provider conceptually.
- Local verification on 2026-03-29:
  - `flutter test` failed because `DailyChallengeModel` now requires `missionType`, `question`, `options`, `link`, and `isCorrect`, but the test helper `_challenge()` does not supply them.
  - `flutter analyze` reported the same model-constructor drift as hard errors plus additional warnings/infos.
- Broader automated coverage is explicitly called out as still light in repo planning/status docs.

## Monorepo or single repo structure

- Best description: `single product repo with multiple backend artifacts`
- Contents include:
  - the Flutter app
  - raw Supabase schema and edge functions
  - a sidecar Node backend
  - platform folders
  - planning docs

## Important architectural decisions visible from the code

- Gamification logic is moving out of the client and into database RPCs and backend services.
- The product uses realtime streams heavily for social freshness.
- Navigation is currently app-local and widget-driven rather than route-first.
- The codebase is mid-transition from legacy “daily challenges” to richer “daily missions”.
- Messaging appears implemented opportunistically even though product docs say not to prioritize it.

---

# 6) Repository map

## Top-level folders and what each does

| Path | Purpose |
| --- | --- |
| `lib/` | Main Flutter app source |
| `test/` | Flutter tests |
| `assets/` | App assets |
| `android/` | Android platform project |
| `ios/` | iOS platform project |
| `web/` | Flutter web scaffold |
| `linux/`, `macos/`, `windows/` | Desktop scaffolding |
| `supabase/` | Raw schema SQL, daily mission SQL, and Edge Functions |
| `backend/` | Legacy or parallel Node/Express backend for challenge/admin routes |
| `docs/` | Documentation output folder created for this report |

## Most important files to read first

- `README.md`
- `PRODUCT_CONTEXT.md`
- `DEVELOPMENT_PLAN.md`
- `FEATURE_STATUS.md`
- `TASKS.md`
- `lib/main.dart`
- `lib/app.dart`
- `lib/services/auth_service.dart`
- `lib/services/backend_api_service.dart`
- `lib/services/supabase_service.dart`
- `supabase/devspace_schema.sql`
- `supabase/daily_missions.sql`
- `supabase/functions/_shared/auth.ts`
- `supabase/functions/_shared/services/*.ts`
- `lib/screens/home_screen.dart`
- `lib/screens/profile_setup_screen.dart`
- `lib/screens/qa_screen.dart`
- `lib/screens/question_detail_screen.dart`
- `lib/screens/opportunities_screen.dart`
- `lib/screens/founder_tools_screen.dart`

## Config files that define behavior

- `pubspec.yaml`
- `android/app/build.gradle.kts`
- `ios/Runner/Info.plist`
- `web/index.html`
- `SUPABASE_SETUP.md`
- `DATABASE_FIX.sql`

## Env files and what kinds of secrets/configs seem required

- No `.env` or env example files were found during repo scan.
- Required or likely required config:
  - `SUPABASE_URL`
  - `SUPABASE_ANON_KEY`
  - `SUPABASE_SERVICE_ROLE_KEY` for `backend/`
  - `PORT` for the legacy Node backend
  - Supabase Edge Function environment for `SUPABASE_URL` and `SUPABASE_ANON_KEY`
  - Google services files are optionally detected on Android, but active app support is incomplete

## Scripts and commands available

- Flutter app:
  - `flutter pub get`
  - `flutter run -d <device-id> --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...`
  - `flutter test`
  - `flutter analyze`
- Backend:
  - `backend/package.json` defines no `scripts`
  - inferred local start command would be `node src/index.js` from `backend/package.json` and `backend/src/index.js`

## Build/test/dev commands

- Build/dev:
  - `flutter pub get`
  - `flutter devices`
  - `flutter run ...`
- Verification:
  - `flutter test`
  - `flutter analyze`

## How local setup likely works

1. Create a Supabase project.
2. Run `supabase/devspace_schema.sql` manually in the SQL editor.
3. Create a public storage bucket named `images`.
4. Pass Supabase URL and anon key with `--dart-define`.
5. Possibly also apply:
   - `supabase/daily_missions.sql`
   - `supabase/daily_missions_seed.sql`
   - `DATABASE_FIX.sql`
6. Deploy Supabase Edge Functions for `aura`, `users`, `posts`, `events`, `challenges`, and `missions`.

Important note:

- Steps 5 and 6 are inferred from code presence and runtime dependencies, but they are not fully documented in the setup docs. Exact intended setup is `unclear from the codebase`.

---

# 7) Data model and business entities

## Core social entities

| Entity | What it represents | Key fields | Relationships | Created | Updated | Displayed | Business rules / validation | Lifecycle |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| User | Student profile and identity record | `id`, `name`, `email`, `handle`, `avatar`, `role`, `year`, `branch`, `building`, `stack`, `bio`, `college`, `github_handle`, `profile_completed`, `is_admin`, `aura` | Owns posts/questions/replies; participates in follows, notifications, conversations | `AuthService._loadOrCreateProfile()` | onboarding/edit profile, follow count sync, aura/streak changes | auth gate, people, profiles, leaderboard, settings | handle uniqueness; profile completion inferred if enough fields present | created on first auth; enriched through onboarding; persists as public profile |
| Post | Main feed content item | `id`, `user_id`, `content`, `tags`, `image_url`, `quote_post_id`, counts, `created_at` | belongs to user; can quote another post; has likes/comments/bookmarks | `SupabaseService.createPost()` via RPC | `updatePost`, likes/comments counters | home feed, profile posts, saved posts | auth user must match creator; aura award via RPC | created -> engaged with -> optionally quoted/updated/deleted |
| Comment | Post comment | `id`, `post_id`, `user_id`, `content`, `created_at` | belongs to post and user | `add_comment_with_aura` | no edit path found | within `PostCard` details | empty comments rejected | created -> visible in thread |
| Follow | Relationship between two users | `follower_id`, `following_id`, `created_at` | user to user many-to-many | `SupabaseService.follow()` | removed by `unfollow()` | profile, people, connections | self-follow blocked in provider; DB unique pair | created -> removed |
| Bookmark | Saved post relation | `post_id`, `user_id`, `created_at` | user to post many-to-many | `bookmarkPost()` | removed by `removeBookmark()` | saved posts screen | unique `(post_id,user_id)` | created -> removed |
| Question | Persistent Q&A topic | `id`, `user_id`, `title`, `body`, `tags`, `upvotes_count`, `replies_count`, `solved_reply_id` | has replies and votes | `createQuestion()` | votes, replies count, solved reply update | Q&A list, question detail | title/body required | created -> discussed -> optionally solved |
| QuestionReply | Reply inside a question thread | `id`, `question_id`, `user_id`, `content`, `parent_reply_id`, `replying_to_user_id` | belongs to question, optionally a top-level reply parent | `addQuestionReply()` | no edit path found | question detail | content required; only one nested reply level allowed | created -> visible -> can become solved answer |
| QuestionVote | Upvote relation on question | `question_id`, `user_id` | user votes on question | `upvoteQuestion()` | removed by `removeQuestionUpvote()` | reflected in question cards | unique pair by DB | created -> removed |
| Notification | User notification record | `to_uid`, `from_uid`, `type`, `post_id`, `message`, `read` | points from one user to another and optionally a post | helper `pushNotification()` | mark read | notification modal | recipient-only read policy via RLS | created -> unread -> read |
| Conversation | DM thread | `id`, `participants`, `last_message`, `last_message_at` | has messages; many users via array | `getOrCreateConversation()` | last message metadata updated after send | messages list | participant filtering is client-side + RLS in `DATABASE_FIX.sql` | created -> active thread |
| Message | DM message | `id`, `conversation_id`, `sender_id`, `content`, `is_read`, `created_at` | belongs to conversation and sender | `sendMessage()` | no read-receipt update path found | chat detail | empty messages ignored | created -> displayed |

## Engagement, gamification, and gating entities

| Entity | What it represents | Key fields | Relationships | Created | Updated | Displayed | Business rules / validation | Lifecycle |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Aura ledger | Immutable record of aura awards | `user_id`, `action`, `points`, `reference_type`, `reference_id`, `source_user_id` | links users to contributing actions | SQL functions | append-only | not directly surfaced; summarized via aura overview | dedupe index prevents repeated awards on same reference | append on qualifying actions |
| Rate limit event | Abuse-prevention log | `user_id`, `action`, `reference_id`, `created_at` | supports social RPC limits | SQL functions | append-only | not user-facing | used to throttle create/like/comment | append on protected action |
| Event | Opportunity/event/hackathon entry | `title`, `description`, `required_aura`, `link`, `type`, `is_active`, `created_by` | linked to `user_events` | founder tools / edge API | admin update/deactivate | opportunities and events tab | type constraint, aura gating | seeded -> active -> deactivated |
| UserEvent | Per-user unlocked state for an event | `user_id`, `event_id`, `unlocked`, `unlocked_at` | joins users and events | SQL eligibility function | updated on eligibility recompute | not directly visible as table | derived from aura threshold | created/upserted as eligibility is computed |
| Challenge | Legacy daily challenge template | `title`, `description`, `difficulty`, `tech_stack`, `points_reward`, `publish_date`, `is_active` | linked to `user_challenges` | founder tools / admin APIs | admin update/deactivate | daily challenge flows, founder tools | difficulty enum | seeded -> assignable -> inactive |
| UserChallenge | Per-user daily challenge assignment | `user_id`, `challenge_id`, `assigned_date`, `selected_tech_stack`, submission fields, completion fields | joins user and challenge | SQL/edge assignment | completion updates | daily challenge screen | unique one assignment per user per date | assigned -> submitted/completed |
| Mission | Newer daily mission template | `title`, `type`, `tech_stack`, `question`, `options`, `correct_answer`, `link`, `points_reward`, `publish_date`, `is_active` | linked to `user_missions` | mission admin API/seed | admin update/deactivate | daily mission flows | type-specific behavior in model and services | seeded -> assignable -> inactive |
| UserMission | Per-user mission assignment/submission | `user_id`, `mission_id`, `assigned_date`, answer/submission fields, `completed`, `is_correct`, review fields` | joins user and mission | mission assignment function | submit/review flow | daily mission screen | reviewed correctness for some mission types | assigned -> submitted -> reviewed/completed |
| UserBadge | Badge awarded for streak milestones | `user_id`, `badge_key`, `badge_name` | belongs to user | challenge completion SQL | append-only | included in aura summary | unique by badge key per user | awarded on milestone |

## Admin and internal entities

| Entity | What it represents | Key fields | Relationships | Created | Updated | Displayed | Business rules / validation | Lifecycle |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| FounderDevice | Allowed founder/admin device for restricted tools | `user_id`, `device_id`, `label`, `is_active` | belongs to user | manual/unclear from codebase | activate/deactivate via DB | not directly shown except access result | admin + device both required for edge founder tools | provisioned -> active -> disabled |
| Auth session | Supabase auth session | access token, auth user | parent for app auth and edge auth | Supabase Auth | token refresh | not UI-visible | bearer token required for edge APIs | session exists until sign-out/expiry |

---

# 8) API and integration map

## Inbound APIs and service domains

| Domain | Purpose | Inbound/outbound | Endpoint/service name | Auth requirements | Payload/data touched | Files involved | Failure/risk considerations |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Supabase Edge Function: aura | Return aura summary and refresh streaks | Inbound | `GET /functions/v1/aura`, `POST /functions/v1/aura/refresh-streak` | Bearer auth | user aura, badges, streaks | `supabase/functions/aura/*`, `lib/services/backend_api_service.dart` | Requires deployed edge functions; has direct DB fallback in Flutter |
| Supabase Edge Function: users | Read current profile and founder access authorization | Inbound | `GET /functions/v1/users`, `GET /functions/v1/users/me`, `GET /functions/v1/users/founder-access` | Bearer auth; founder access also checks `X-Device-Id` indirectly | current user profile, founder authorization | `supabase/functions/users/*`, shared auth, `BackendApiService.hasFounderAccess()` | Device allowlisting can silently deny founder UI access if not provisioned |
| Supabase Edge Function: posts | Paginated post reads and social mutations | Inbound | `GET /functions/v1/posts`, `POST /functions/v1/posts`, `POST /functions/v1/posts/:id/like`, `DELETE /functions/v1/posts/:id/like`, `POST /functions/v1/posts/:id/comments` | Bearer auth | posts, likes, comments | `supabase/functions/posts/*`, post service, `BackendApiService.getPosts()` | Current app still mixes this with direct Supabase writes |
| Supabase Edge Function: events | List events, compute eligibility, admin CRUD | Inbound | `GET /functions/v1/events`, `GET /functions/v1/events/eligible`, `POST /functions/v1/events`, `PATCH /functions/v1/events/:id`, `POST /functions/v1/events/:id/deactivate` | Bearer auth; admin/create paths rely on protected edge auth flow | events, user_events | `supabase/functions/events/*`, `BackendApiService` | Setup docs do not explain edge deployment |
| Supabase Edge Function: challenges | Legacy challenge assignment and admin CRUD | Inbound | `GET /functions/v1/challenges`, `GET /functions/v1/challenges/daily`, `GET /functions/v1/challenges/today`, `POST /functions/v1/challenges`, `POST /functions/v1/challenges/complete`, `PATCH /functions/v1/challenges/:id`, `POST /functions/v1/challenges/:id/deactivate` | Bearer auth; admin endpoints need protected access | challenges, user_challenges | `supabase/functions/challenges/*`, `BackendApiService` | Overlaps with both missions system and Node backend |
| Supabase Edge Function: missions | Newer mission assignment, submit, admin CRUD, review | Inbound | `GET /functions/v1/missions`, `GET /functions/v1/missions/daily`, `GET /functions/v1/missions/today`, `POST /functions/v1/missions`, `POST /functions/v1/missions/submit`, `PATCH /functions/v1/missions/:id`, `POST /functions/v1/missions/:id/deactivate`, `POST /functions/v1/missions/assignments/:id/review` | Bearer auth; review/admin paths require privileged access | missions, user_missions | `supabase/functions/missions/*`, `BackendApiService` | App UI uses it, founder tools UI does not yet expose mission admin |
| Legacy Express API | Older challenge backend and admin challenge CRUD | Inbound | `/api/challenges/today`, `/api/challenges/complete`, `/api/admin/challenges*` | Bearer auth; admin checks `is_admin` or founder email | challenges, users | `backend/src/index.js`, `routes/index.js`, controllers, middleware | Canonical backend path is unclear; package has no scripts or docs |
| Direct Supabase client service | Most core social CRUD and realtime streams | Inbound from app to DB | `SupabaseService.*` methods rather than HTTP endpoints | Supabase session / RLS | users, posts, likes, comments, follows, bookmarks, questions, replies, notifications, messages | `lib/services/supabase_service.dart` | Heavy client-side coupling to raw schema; setup drift hits hard |

## Outbound integrations

| Integration | Purpose | Inbound/outbound | Endpoint/service name | Auth requirements | Data touched | Files involved | Failure/risk considerations |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Supabase Auth | User authentication/session | Outbound | Supabase auth APIs | anon key + user credentials/session | auth session, auth user | `lib/services/auth_service.dart`, `main.dart` | email confirmation and schema mismatch can block auth UX |
| Supabase Database | Core app data and realtime | Outbound | table reads/writes, streams, RPCs | user auth / RLS | most product entities | `lib/services/supabase_service.dart` | schema drift and missing tables/functions break flows |
| Supabase Storage | Media uploads/public URLs | Outbound | bucket `images` | authenticated storage policies | avatars, covers, post images | `lib/services/storage_service.dart` | storage policies are not checked in; manual setup required |
| GitHub REST API | Public developer identity card | Outbound | `https://api.github.com/users/...` | no token configured | repos, public events, stats | `lib/services/github_service.dart` | rate limits and public-only data |
| Flutter Local Notifications | Local notification channel/device display | Outbound/device-local | plugin init and channel creation | local device only | local notification channel | `lib/services/notification_service.dart` | no full push-notification pipeline in active code |
| Google Services detection | Conditional Android plugin apply if JSON file exists | Build-time integration | `google-services.json` detection | file presence | build config only | `android/app/build.gradle.kts` | active Google sign-in flow is still disabled |

---

# 9) UX/UI understanding

## Likely information architecture

- Entry:
  - splash
  - auth intro
  - login/signup
- Main app tabs:
  - Home
  - People
  - Q&A
  - Opportunities
  - Profile
  - Aura Board
- Secondary screens:
  - Profile setup/edit
  - Settings
  - Saved posts
  - Connections
  - Messages
  - Chat detail
  - Daily mission
  - Founder tools

## Navigation structure

- Main navigation is a `PageView` controlled by a custom bottom navigation bar.
- App bar includes:
  - notifications
  - current aura shortcut to Aura Board
  - messages icon
- Floating action button routes to `DailyChallengeScreen`.
- Deeper detail screens use `Navigator.push`.

## Major pages/screens

- `AuthIntroScreen`: value proposition framing
- `LoginScreen`: auth form with visible Google CTA
- `HomeScreen`: builder feed + composer + engagement overview
- `PeopleScreen`: searchable builder directory
- `QAScreen`: question discovery and create-question entry
- `QuestionDetailScreen`: threaded replies and solved answer
- `OpportunitiesScreen`: locked/unlocked opportunities + events
- `ProfileScreen`: identity, activity, connections, GitHub card
- `AuraBoardScreen`: leaderboard and tiers
- `SettingsScreen`: account and founder entry points
- `MessagesScreen` / `ChatDetailScreen`: direct messaging
- `FounderToolsScreen`: event/challenge seeding

## Recurring UI patterns

- Strong use of cards, glass panels, chips, and large rounded containers.
- Consistent empty/error/loading states via shared widgets.
- Builder-focused headings and explanatory text.
- Provider-driven optimistic state updates for likes, follows, votes, bookmarks.
- Heavy emphasis on badges/chips for tags, difficulty, status, and aura context.

## Onboarding experience

- The intro sequence is clearly product-positioning-driven:
  - Build In Public
  - Practical Q&A
  - Find Builders
  - Earn Aura
- After auth, profile completion is prompted with specific rationale:
  - better discovery
  - follows
  - collaboration
- Onboarding itself is structured as a 3-step flow and includes a final preview.

## Empty states / error states / loading states if visible

- Feed:
  - loading: “Fetching the latest updates...”
  - empty: “Be the first to share an update.”
  - retryable error state
- People:
  - searching state
  - empty search state
- Q&A:
  - loading/error state patterns and reply errors
- Opportunities:
  - no opportunities
  - no events scheduled
- Daily mission:
  - loading
  - “No mission today”
- Messages:
  - “No messages yet”
  - “No messages yet. Say hi!”
- Saved posts:
  - loading/error/empty states

## Product tone/voice seen in interface copy

- Tone is direct, practical, and builder-oriented.
- Repeated language:
  - “student builders”
  - “campus builder feed”
  - “practical doubts”
  - “builder identity”
  - “grow your aura”
- The copy pushes usefulness over entertainment and keeps a campus-technical vibe rather than generic social copy.

---

# 10) Business and product inference

## Business model

- `Unclear from the codebase`
- No payments, premium entitlements, billing workflows, or monetization integrations were found during repo scan.
- Current posture looks like a free product optimized for engagement and validation rather than revenue.

## Monetization

- No monetization implementation was found.
- Repo docs explicitly list paid features and recruiter tooling as not-in-MVP.

## Target market

- One-college launch for engineering/BTech students.
- Especially students interested in coding, projects, hackathons, internships, and peer learning.

## User pain points

- LinkedIn is too formal.
- WhatsApp and Discord are noisy and unstructured.
- Broad social apps do not help student developers build visible proof of work.
- Students struggle to discover nearby collaborators and knowledgeable peers inside their own college.

## Activation strategy

- Low-friction entry through email/password auth.
- Prompted profile completion to improve discovery.
- Immediate access to feed, people, Q&A, and posting.
- Aura and daily mission provide first-session and second-session engagement hooks.

## Retention hooks

- Aura accumulation
- streak tracking
- accepted-answer aura
- daily missions/challenges
- opportunity/event gating based on aura
- leaderboard visibility
- follows/connections

## Collaboration/network effects if any

- Yes, but lightweight:
  - follows
  - Q&A replies
  - feed interactions
  - people discovery
  - profile-based discovery
- Messaging exists in code, which would deepen network effects, but product docs say it should not be prioritized yet.

## Trust/safety/privacy signals

- Positive signals:
  - RLS enabled on core tables
  - rate-limited social RPCs
  - backend-owned aura awarding
  - founder tools protected by admin + allowlisted device
- Weak/missing signals:
  - no visible reporting flow
  - no block/mute flow found
  - no dedicated moderation workflow
  - no delete-account/export-data/privacy-policy flow found

## What success metric this product probably cares about most

- Most likely:
  - retained active student builders in one college
- Practical proxy metrics from the docs:
  - daily/weekly active users
  - posts per day
  - comments per post
  - return rate
  - number of active creators

---

# 11) Gaps, risks, and unknowns

## Incomplete features

- Google sign-in is visible but disabled.
- Notifications have infrastructure and UI surface, but not a fully productized flow.
- Mission admin endpoints exist, but founder tools only expose events and legacy challenges.
- Leaderboard timeframe toggle does not appear tied to separate weekly/monthly calculations.
- GitHub card is useful but shallow.

## TODO/FIXME-style drift and product-doc mismatch

- Docs say settings beyond sign-out are incomplete, but a real settings screen exists.
- Docs say checked-in Supabase defaults are gone, but default URL/anon key still exist in app code.
- Status docs still describe feed as stream-based in the current UI, but `PostsProvider` now uses paginated API loading.
- Product docs say not to build DMs yet, but DMs are implemented in the client.
- Daily challenge vs daily mission terminology and data model are mixed across app/backend/docs.

## Dead code / stale areas

- `FIREBASE_SETUP.md` appears stale relative to current Supabase-first architecture.
- `DATABASE_FIX.sql` contains important schema pieces but is not referenced by setup docs.
- `lib/widgets/story_reel.dart` appears unused.
- `lib/data/mock_posts.dart` and `lib/data/mock_users.dart` appear unused in active app flow.
- `go_router` dependency is present but no active router usage was found in `lib/`.
- `backend/node_modules` is tracked in git, which is usually a stale-repo hygiene smell.

## Obvious technical debt

- Hybrid backend paths:
  - direct Supabase
  - edge functions
  - legacy Express backend
- Main schema drift:
  - messaging tables are not present in `supabase/devspace_schema.sql`
  - they do appear in `DATABASE_FIX.sql`
- Duplicate SQL function definitions:
  - `mark_question_reply_solved`
- Setup docs do not describe all active schema/function dependencies.

## Missing tests

- Automated coverage is sparse and explicitly acknowledged as light.
- The one visible engagement-provider test file is already stale against the current model contract.
- No strong test coverage was found for:
  - aura awarding correctness
  - rate-limit behavior
  - founder-device access control
  - opportunity gating correctness
  - mission review flow

## Security/privacy concerns

- Default Supabase URL and anon key are still checked into app code despite docs claiming otherwise.
- Android release build uses debug signing and disables minify/shrink, which is not production-grade.
- No account deletion/data export/privacy surface found.
- No moderation/report/block features found for user-generated content.
- Founder/superuser logic partly depends on a hard-coded founder email.

## Scalability concerns

- User search is in-memory over streamed user lists.
- Multiple domains rely on broad realtime streams from the client.
- Client still performs a lot of direct database access rather than consolidating rules behind backend APIs.
- Messaging conversation lookup uses array containment and might become awkward at scale.

## Places where intent is unclear

- Which backend path is canonical: edge functions, direct DB, or legacy Express.
- Whether messaging is intentionally part of MVP despite docs saying not to prioritize it.
- Whether the target college is MNIT Jaipur, Jaipur National University, or both.
- Whether Firebase is truly deprecated or still intended later.
- Whether missions have officially replaced challenges or both are intended to coexist.

## Assumptions that need founder confirmation

- Is DevSpace currently a one-college private test product or already being used by real students?
- Is messaging intentionally shipping, or should it be hidden/cut from MVP?
- Should the product focus on one named college at launch?
- Are events/opportunities meant to be founder-seeded only, or community-submitted later?
- Is the legacy Node backend still used anywhere?

## Notable code-level risks to flag immediately

- `DailyChallengeScreen._buildMissionHeader()` reads `me?.currentStreak` on a `dynamic` value, but `UserModel` has no `currentStreak` field. This is a likely runtime bug path.
- `MessagesProvider.init()` creates a stream subscription but does not store/cancel it.
- Messaging UI depends on tables absent from the main schema file.
- Local test/analyze health is not green.

---

# 12) Planning-ready summary

## What we should know before future planning

### Biggest strengths of the project

- Strong product focus on student builders instead of generic social clutter.
- Core MVP social flows are already real, not mock-only.
- Gamification/business rules are increasingly backend-owned rather than client-trusted.
- UI copy and information architecture are coherent around builder identity and contribution.
- The app is already rich enough for meaningful founder testing in one college.

### Biggest weaknesses

- Schema/setup/documentation drift is significant.
- Canonical backend architecture is not cleanly settled.
- Tests are light and currently broken by model drift.
- Notifications, missions, messaging, and founder tooling are in inconsistent states.
- Production readiness is weak: no CI, no documented deploy flow, no release hardening, no env examples.

### Biggest opportunities

- Tighten the one-college launch story and make onboarding/discovery sharper.
- Consolidate the backend path so contributors know what is authoritative.
- Finish the missions/opportunities loop because it is the clearest retention mechanic.
- Improve contributor readiness by fixing setup docs and schema sequencing.
- Publicly position DevSpace around “builder identity on campus” rather than generic social features.

### Biggest product questions

- Should messaging be part of MVP or removed from launch surface?
- Is Q&A meant to stay its own tab, or become a post type within feed later?
- How important is college email gating for trust and relevance?
- Are opportunities meant to be aspirational rewards, practical events, or both?
- How much competition/leaderboard pressure is healthy for this audience?

### Biggest technical questions

- Which schema files are authoritative?
- Which backend path should new work target?
- Are missions replacing challenges, or are challenges legacy data only?
- How should notifications actually be created: app-side, SQL trigger, or edge function?
- What is the intended deployment workflow for edge functions and SQL changes?

### Most important missing context to confirm with the founder/team

- Named launch college and rollout plan
- canonical backend strategy
- canonical schema migration path
- whether Firebase is dead code or deferred future work
- whether DMs should remain in the product
- minimum release-readiness bar before inviting real students

---

# 13) Marketing-ready extraction

## Raw material for future content and marketing

### Product positioning angles

- A focused social layer for student developers, not generic campus social media
- Build in public inside your college
- Ask practical doubts and get answers from real student builders
- Turn contribution into visible developer identity
- One place for projects, doubts, peers, and momentum

### Transformation/value proposition

- From scattered, noisy, informal channels to a structured builder community
- From invisible effort to visible proof of work
- From isolated student projects to peer discovery and campus collaboration
- From passive scrolling to contribution-driven reputation

### Pain points solved

- LinkedIn is too formal for student experimentation
- WhatsApp and Discord are noisy and hard to search
- Student builders lack campus-local discovery and proof-of-skill channels
- Questions and answers get buried in existing channels

### Possible customer outcomes

- More visibility for projects and progress
- Faster help on technical doubts
- Better discovery of peers with similar stacks
- Stronger campus developer identity
- More consistent motivation through aura, streaks, and daily missions

### Strongest differentiators

- Builder-first copy and flows
- combined feed + Q&A + people + gamified contribution loop
- campus-local relevance
- aura-backed participation system with accepted-answer rewards
- gated opportunities tied to contribution rather than popularity alone

### Proof points visible in the product/code

- real posting, comments, follows, bookmarks, Q&A, solved answers
- backend-owned aura ledger and rate-limited social RPCs
- daily assignment logic and opportunity gating in SQL/backend
- founder tools for seeding opportunities and challenges
- GitHub profile card support for technical identity

### Features that are easiest to talk about publicly

- builder feed
- student Q&A
- aura system
- daily mission
- people discovery
- opportunities unlock

### Features that sound technically impressive

- backend-owned aura and streak logic
- accepted-answer rewards
- aura-gated events/opportunities
- per-user daily assignment model
- founder device allowlisting on admin surfaces

### Features that sound commercially valuable

- community retention loop through missions/streaks
- opportunity distribution to engaged students
- strong niche positioning around student builders
- potential campus-by-campus expansion model

### Founder-story or behind-the-scenes angles inferred from the build

- Built by student founders for their own college community
- Explicitly constrained to avoid overbuilding
- Product docs repeatedly emphasize realism for a tiny team
- Codebase reflects real founder testing concerns: abuse prevention, founder-device access, beta readiness

---

# 14) Simple explanations

## Explain it to a developer

DevSpace is a Flutter app backed mainly by Supabase. It mixes direct database access, SQL RPCs, realtime streams, and Supabase Edge Functions to support auth, profiles, feed posting, Q&A, follows, aura gamification, daily missions, and aura-gated opportunities. The repo also contains a legacy Express backend and several setup/schema drift points.

## Explain it to a product manager

This is a student-builder community app designed for one-college launch. The core loop is: students create a profile, share updates, ask technical questions, discover peers, and earn visible aura through contribution. The product is beyond concept stage, but still needs consolidation and hardening before broad student rollout.

## Explain it to an investor

DevSpace is a vertical social/community product for engineering students. Instead of competing as general social media, it focuses on public building, practical Q&A, peer discovery, and lightweight reputation signals inside a college network. The codebase suggests an MVP being prepared for a closed beta, with a plausible campus-by-campus expansion story if retention works.

## Explain it to a customer in simple language

DevSpace is a place for student developers in your college to share what they are building, ask coding questions, find other builders, and grow their reputation by helping and posting consistently.

---

# 15) Source-backed appendix

Major claims above are backed below with concrete file paths, functions/components, routes, and exact evidence.

| Claim | Evidence |
| --- | --- |
| Product name is DevSpace | `README.md:1`, `pubspec.yaml:1-2` show `# DevSpace` and `name: devspace`, `description: A social platform for college developers — built by devs, for devs.` |
| Product is a mobile-first student developer community app for one-college launch | `README.md:3` says `DevSpace is a mobile-first student developer community app for one-college launch.` |
| Product is not meant to be generic social media | `PRODUCT_CONTEXT.md:7-10` says it is a focused app for engineering students and “not meant to be generic social media.” |
| Target users are engineering/BTech students in the founders’ own college | `PRODUCT_CONTEXT.md:11-21` lists phase-1 users and secondary users. |
| Main problem is lack of a focused platform for sharing projects, asking doubts, feedback, and discovery | `PRODUCT_CONTEXT.md:23-33` enumerates the problem and contrasts LinkedIn/WhatsApp/Discord. |
| Docs explicitly say not to prioritize DMs, advanced notifications, paid features, recruiter tooling | `PRODUCT_CONTEXT.md:92-103`, `DEVELOPMENT_PLAN.md:47-53` |
| Current product focus is closed beta prep and backend productization | `DEVELOPMENT_PLAN.md:8-29` defines `Phase 4: Closed Beta Prep + Backend Productization`. |
| Auth, onboarding, feed posting, Q&A, likes/comments/follows/aura, and people discovery are core current build areas | `README.md:5-12` |
| App bootstraps Supabase and then chooses setup/auth/app flows | `lib/main.dart:24-69`, `_Root` at `lib/main.dart:124-287` |
| Checked-in Supabase default URL and anon key still exist in app code | `lib/main.dart:28-35`, `lib/services/backend_api_service.dart:15-22` |
| App uses Provider and Flutter | `pubspec.yaml:10-23`, `lib/main.dart:77-88` |
| `go_router` dependency is present but active route usage was not found in `lib/` | `pubspec.yaml:23`; repo search for router usage returned no `GoRouter` references in `lib/` |
| Auth intro is builder-positioned | `lib/screens/auth_intro_screen.dart:21`, `40`, `59`, `78`, `386` show `Build In Public`, `Practical Q&A`, `Find Builders`, `Earn Aura`, and `Made for student builders` |
| Google sign-in is visible but disabled | `lib/services/auth_service.dart:254-257` returns `Google sign-in is coming soon...`; button exists in `lib/screens/login_screen.dart:257-268` and label `Continue with Google` at `lib/screens/login_screen.dart:605` |
| College-domain enforcement exists in concept but is disabled | `lib/services/auth_service.dart:17-19`, `_isAllowedEmail` at `84-87` |
| Default created user college is Jaipur National University while domain constant is MNIT | `lib/services/auth_service.dart:160-175` sets `college: 'Jaipur National University'`; `_collegeDomain` is `mnit.ac.in` at `17`; `lib/utils/constants.dart:30-33` includes both college options |
| Main shell tabs are Home, People, Q&A, Opportunities, Profile, Aura Board | `lib/app.dart:35-42`, `239-246` |
| App shell also exposes notifications, aura pill, and messages icon | `lib/app.dart:300-350` |
| FAB routes to the daily mission/challenge screen | `lib/app.dart:254-266` |
| Feed uses paginated loading with load-more behavior | `lib/screens/home_screen.dart:37-43`, `51-58`, `108-148`; `lib/providers/posts_provider.dart:46`, `67`, `122-173` |
| Feed copy is builder-focused | `lib/screens/home_screen.dart:181-192` uses `Campus builder feed` and builder-focused subcopy |
| People discovery searches by handle/branch/building/role/stack | `lib/providers/users_provider.dart:128-138`; `lib/screens/people_screen.dart:230-243` says `Search students by stack, branch, project, or handle...` |
| Q&A supports posting questions, replies, upvotes, and solved answers | `lib/providers/questions_provider.dart:112-152`, `175-219`, `221-269`, `271-325`; `lib/screens/qa_screen.dart:80`, `291`; `lib/screens/question_detail_screen.dart:136-150`, `692` |
| Reply threading allows only one nested reply level | `lib/services/supabase_service.dart:577-599` rejects deeper nesting with `Only one reply level is supported in this thread.` |
| Solved answers award aura | `lib/screens/question_detail_screen.dart:149` references `+kAuraAnswerAccepted aura`; SQL RPC exists at `supabase/devspace_schema.sql:1887-1950` |
| Notifications are shown in a modal sheet rather than a full inbox screen | `lib/app.dart:62-209` |
| Notifications provider uses realtime notifications stream and read-state updates | `lib/providers/notifications_provider.dart:17-46`; `lib/services/supabase_service.dart:666-686` |
| Notification writing helpers exist | `lib/services/notification_service.dart:42-87` |
| No SQL trigger or notification insert workflow was found in checked-in schema beyond helper methods | repo search for `insert into public.notifications` in `supabase/` returned no matches on 2026-03-29 |
| Opportunities are aura-gated and can unlock copyable links | `lib/screens/opportunities_screen.dart:59-61`, `139-207`; SQL eligibility RPC at `supabase/devspace_schema.sql:1514-1575` |
| Events tab currently uses placeholder `Coming Soon` date copy | `lib/screens/opportunities_screen.dart:265` |
| Daily challenge screen is now mission-oriented and supports coding/MCQ/one-word types | `lib/screens/daily_challenge_screen.dart:129`, `204-263`; `lib/models/daily_challenge_model.dart:13-40`, `42-76` |
| Daily challenge vs mission backend is transitional with multi-path fallback logic | `lib/services/backend_api_service.dart:355-440`, `663-711` |
| `DailyChallengeScreen` likely has a runtime bug on streak display | `lib/screens/daily_challenge_screen.dart:141-156` reads `me?.currentStreak`; `lib/models/user_model.dart:3-48` and `61-106` contain no `currentStreak` field |
| Messaging is implemented in the Flutter client | `lib/widgets/profile_card.dart:89-118`, `lib/screens/messages_screen.dart:11-112`, `lib/screens/chat_detail_screen.dart:11-165`, `lib/providers/messages_provider.dart:13-34`, `lib/services/supabase_service.dart:723-787` |
| Messaging is not present in the main schema file but is present in `DATABASE_FIX.sql` | search in `supabase/devspace_schema.sql` found no `conversations`/`messages` table creation; `DATABASE_FIX.sql:45-61` creates both tables |
| Founder tools are admin-restricted and device-gated | `lib/screens/founder_tools_screen.dart:63-159`; `supabase/functions/_shared/auth.ts:43-83`; `supabase/functions/users/controller.ts:24-27` |
| Founder tools currently load events and legacy challenges, not missions | `lib/screens/founder_tools_screen.dart:430-444`; mission admin methods exist in `lib/services/backend_api_service.dart:546-645` |
| Founder/system tab is mostly placeholder actions | `lib/screens/founder_tools_screen.dart:392-427` includes snackbars like `Console interface coming soon.` |
| Backend-owned aura and anti-abuse rules are in SQL RPCs | `supabase/devspace_schema.sql:1338-1512` (`create_post_with_aura`, `like_post_with_aura`, `add_comment_with_aura`) and `1241-1272` rate limit helpers |
| Aura summary, streaks, and badges are backend-backed | `supabase/devspace_schema.sql:1672-1885` covers completion, streaks, badges, and summary; `lib/providers/engagement_provider.dart:58-68` loads summary/events/daily challenge |
| Missions schema and functions exist separately from the main schema | `supabase/daily_missions.sql:3-36`, `161-361`; `supabase/daily_missions_seed.sql:1-82` |
| Setup docs do not mention missions schema, seed file, or edge function deployment | `SUPABASE_SETUP.md:1-35` only references `supabase/devspace_schema.sql`, bucket setup, and runtime vars |
| `FIREBASE_SETUP.md` is legacy/stale relative to active architecture | `FIREBASE_SETUP.md:57-157` documents Firebase Auth/Firestore/Storage/FCM; active deps in `pubspec.yaml:12-38` show Supabase and no `firebase_messaging`; only comment `# firebase_core was here` at `pubspec.yaml:16` |
| Android release build is not production-hardened | `android/app/build.gradle.kts:39-48` uses debug signing and disables minify/shrink |
| Web scaffold is still generic | `web/index.html:21` says `A new Flutter project.` |
| No CI/CD or deployment manifests were found | repo scan on 2026-03-29 for `.github/workflows`, Docker, Vercel, Netlify, Render, Railway, Makefile, etc. returned no results |
| No `.env` or env example files were found | repo scan on 2026-03-29 for `.env`, `.env.*`, and env example patterns returned no results |
| No analytics SDK was found | repo scan on 2026-03-29 for Mixpanel/Amplitude/Segment/PostHog/Firebase Analytics terms returned no implementation matches |
| No moderation/report/block/privacy/account-delete flows were found | repo scan on 2026-03-29 for moderation/report/block/privacy/export/delete-account terms returned no implementation matches |
| No payments/billing implementation was found | repo scan on 2026-03-29 for Stripe/Razorpay/checkout/subscription/revenuecat returned no product-payment implementation matches |
| Backend `package.json` has no scripts and minimal dependencies | `backend/package.json:1-12` |
| Legacy Express backend exposes challenge/admin routes | `backend/src/index.js:14-22`, `backend/src/routes/index.js:8-16` |
| Legacy backend uses Supabase service role and hard-coded founder email override | `backend/src/config/supabase.js:5-7`, `backend/src/middleware/authMiddleware.js:20-24` |
| `backend/node_modules` is tracked in git | `git ls-files backend/node_modules` on 2026-03-29 returned tracked files such as `backend/node_modules/.bin/mime` and package contents |
| Automated coverage is currently broken by model drift | `test/engagement_provider_test.dart:104-117` constructs `DailyChallengeModel` without required fields introduced in `lib/models/daily_challenge_model.dart:19-35`; local `flutter test` and `flutter analyze` both failed on 2026-03-29 for this mismatch |

---

# Top 20 files to read first

1. `README.md`
2. `PRODUCT_CONTEXT.md`
3. `DEVELOPMENT_PLAN.md`
4. `FEATURE_STATUS.md`
5. `TASKS.md`
6. `SUPABASE_SETUP.md`
7. `lib/main.dart`
8. `lib/app.dart`
9. `lib/services/auth_service.dart`
10. `lib/services/backend_api_service.dart`
11. `lib/services/supabase_service.dart`
12. `lib/providers/posts_provider.dart`
13. `lib/providers/questions_provider.dart`
14. `lib/providers/engagement_provider.dart`
15. `lib/screens/home_screen.dart`
16. `lib/screens/profile_setup_screen.dart`
17. `lib/screens/question_detail_screen.dart`
18. `lib/screens/founder_tools_screen.dart`
19. `supabase/devspace_schema.sql`
20. `supabase/daily_missions.sql`

# Top 10 unanswered questions for the founder

1. What is the exact launch college: MNIT Jaipur, Jaipur National University, or another campus?
2. Is direct messaging intentionally in the launch product, or should it be hidden/removed from MVP?
3. Which backend path is canonical for future work: direct Supabase, Edge Functions, or the Node backend?
4. Which SQL file is authoritative for new environments: `devspace_schema.sql`, `daily_missions.sql`, `DATABASE_FIX.sql`, or some combination?
5. Have missions officially replaced legacy challenges, or are both meant to remain active?
6. Should college-domain restriction be enabled before student rollout?
7. How should notifications be generated in the final architecture: app-side helpers, SQL triggers, or edge functions?
8. What is the intended founder-device registration workflow when devices change or are reinstalled?
9. What minimum moderation/trust features are required before opening the app to real students?
10. What exact release-readiness bar do the founders want before broader beta: setup reproducibility, green tests, admin tooling, analytics, or all of them?

# One-paragraph plain-English summary of the entire project

DevSpace is a student developer community app built in Flutter and backed mainly by Supabase. It already supports the core experience of joining with email, setting up a builder profile, posting updates, asking technical questions, replying, following other students, earning aura, and unlocking opportunities through participation. The product direction is strong and clearly focused on one-college launch for engineering students, but the repository also shows a lot of transition: challenge logic is evolving into missions, documentation and setup instructions lag behind the actual code, a legacy backend still exists beside Edge Functions, messaging is implemented even though docs say not to prioritize it, and automated coverage is still light and currently broken by model drift. The project looks promising for founder-led beta testing, but it needs consolidation and hardening before it is contributor-friendly or production-ready.
