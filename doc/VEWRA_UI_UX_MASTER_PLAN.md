# Vewra UI/UX Master Plan

## 1. Purpose

Vewra needs a UI/UX architecture that reflects the actual product described by the repository, backend, mobile application, and four product/architecture documents.

The earlier UI proposal was too narrow because it treated Vewra primarily as:

- Tasks
- Browser
- Wallet
- Profile

That structure is suitable for the current Phase 1 shell, but it does not provide enough room for the broader Vewra product direction.

The UI/UX should therefore be designed around the complete product architecture while allowing features to be introduced progressively by phase.

The central principle is:

> **Vewra should make earning feel understandable, progressive and trustworthy.**

Users should never wonder:

- What am I doing?
- What will I earn?
- Is Vewra tracking me?
- Was my progress saved?
- How much have I earned?
- What should I do next?

---

# 2. Repository and Product Context

The Vewra repository contains four key documentation files:

- `doc/app_architecture.md`
- `doc/feature_list.md`
- `doc/phase_1_implementation_plan.md`
- `doc/vewra_pro_master_plan.md`

The mobile application currently has a feature-oriented Flutter structure including:

- `auth`
- `browser`
- `profile`
- `tasks`
- `wallet`

The current mobile navigation shell exposes:

- Tasks
- Browser
- Wallet
- Profile

The backend is separated into domains including:

- accounts
- admin_api
- AI services
- tasks
- tracking
- wallet

The repository also contains an admin frontend with areas such as:

- Dashboard
- Tasks
- Users
- Security
- AI Settings

The product direction is larger than the current Phase 1 implementation. The UI architecture must therefore support the current implementation without forcing a redesign when later features are introduced.

---

# 3. Core UX Loop

The main Vewra experience should be:

```text
Discover
   ↓
Choose
   ↓
Understand the task
   ↓
Start
   ↓
Complete the required action
   ↓
Track progress
   ↓
Earn
   ↓
See progress
   ↓
Return
```

For a video task:

```text
Tasks
  ↓
Task Details
  ↓
Search Instruction
  ↓
Start Task
  ↓
Vewra Browser
  ↓
Correct Video Detected
  ↓
Tracking
  ↓
Progressive Reward
  ↓
Task Complete
  ↓
Wallet
```

---

# 4. Product Areas

The long-term Vewra UI should be organized into these major product areas:

```text
VEWRA
│
├── Home
│
├── Earn
│   ├── Video Tasks
│   ├── Surveys
│   ├── SMM Tasks
│   ├── Daily Tasks
│   └── Quests
│
├── Rewards
│   ├── Wallet
│   ├── Daily Bonus
│   ├── Spin Wheel
│   ├── Mystery Boxes
│   └── Reward Center
│
├── Progress
│   ├── Overview
│   ├── XP & Levels
│   ├── Achievements
│   ├── Badges
│   ├── Streaks
│   └── Leaderboard
│
├── Community
│   ├── Referrals
│   ├── Friends
│   ├── Guilds
│   └── Activity
│
├── Content
│   ├── Browse
│   ├── Continue Watching
│   ├── Watch History
│   └── Favorites
│
├── Membership
│   ├── Plans
│   ├── Upgrade
│   └── Subscription
│
└── Account
    ├── Profile
    ├── Settings
    ├── Security
    ├── Notifications
    └── Help & Support
```

This is the long-term information architecture.

Not every item needs to be enabled in Phase 1.

---

# 5. Phase-Based Navigation

The information architecture should support the complete product while only exposing implemented features.

## Phase 1

```text
Home

EARN
  Video Tasks

CONTENT
  Browser

REWARDS
  Wallet

ACCOUNT
  Profile
```

## Later Phases

```text
EARN
  Video Tasks
  Surveys
  SMM Tasks
  Daily Tasks
  Quests

REWARDS
  Wallet
  Daily Bonus
  Spin Wheel
  Mystery Boxes
  Reward Center

PROGRESS
  XP & Levels
  Achievements
  Badges
  Streaks
  Leaderboard

COMMUNITY
  Referrals
  Friends
  Guilds
  Activity

CONTENT
  Browser
  Continue Watching
  Watch History
  Favorites

MEMBERSHIP
  Plans
  Upgrade
  Subscription
```

The navigation should expand naturally rather than being redesigned every time a new feature is introduced.

---

# 6. Mobile Navigation

The current bottom navigation is:

```text
Tasks | Browser | Wallet | Profile
```

The recommended scalable model is:

```text
┌────────────────────────────────────────┐
│  ☰    Vewra              🪙 1,250      │
├────────────────────────────────────────┤
│                                        │
│             Current screen             │
│                                        │
├────────────────────────────────────────┤
│  Home     Earn     Rewards    Profile  │
└────────────────────────────────────────┘
```

Primary mobile destinations:

- Home
- Earn
- Rewards
- Profile

A hamburger/site menu exposes the larger product structure.

This avoids trying to fit every Vewra feature into bottom navigation.

---

# 7. Site Menu / Navigation Drawer

Because Vewra has many options, the site menu should be sectioned rather than presenting one long flat list.

## Proposed Menu

```text
VEWRA

🏠 Home


EARN

▶ Video Tasks
📋 All Tasks
⚡ Quick Tasks
🎯 Daily Tasks
📝 Surveys
📱 Social Tasks


REWARDS

🪙 Wallet
🎁 Daily Bonus
🎡 Spin Wheel
📦 Mystery Boxes
🎉 Rewards


PROGRESS

⭐ XP & Levels
🏆 Achievements
🔥 Streaks
🏅 Badges
📊 Leaderboard


COMMUNITY

👥 Referrals
🏘 Guilds
🤝 Friends
💬 Activity


CONTENT

🌐 Browser
▶ Continue Watching
🕘 Watch History
❤️ Favorites


MEMBERSHIP

💎 Plans
⬆ Upgrade
📜 Subscription


ACCOUNT

👤 Profile
⚙ Settings
🔐 Security
🔔 Notifications
❓ Help & Support


[ Log Out ]
```

The menu should be:

- sectioned
- collapsible where appropriate
- searchable if it becomes large
- context-aware
- consistent across mobile and desktop

---

# 8. Responsive Navigation

The same information architecture should be presented differently depending on device.

## Mobile

- Bottom navigation for the four highest-value destinations
- Hamburger drawer for the complete menu

## Tablet

- Collapsible side navigation
- Bottom navigation may be removed if side navigation is persistent

## Desktop/Web

- Persistent sidebar
- Top header
- Breadcrumbs where useful
- User/reward summary in header
- Optional collapsible sidebar

The information architecture remains the same.

Only the presentation changes.

---

# 9. Home / Dashboard

The Home screen should become the user's personal Vewra command center.

It should not simply be a task list.

The long-term Home experience should include:

- greeting
- wallet balance
- XP
- level
- progress to next level
- streak
- daily reward
- recommended tasks
- quick rewards
- recent activity
- potentially achievements and milestones

Example:

```text
Good morning, Joseph 👋

Level 12
██████████████░░░░
2,480 / 3,000 XP

🔥 7 day streak
```

Then:

```text
┌────────────────────────────────────┐
│             WALLET                 │
│                                    │
│             🪙 4,820                │
│                                    │
│        +120 today                  │
│                                    │
│       [ View Wallet ]              │
└────────────────────────────────────┘
```

Then:

```text
DAILY REWARDS

🔥 7 Day Streak

Mon ✓  Tue ✓  Wed ✓
Thu ✓  Fri ✓  Sat ●
Sun ○

[ CLAIM TODAY ]
```

Then:

```text
QUICK REWARDS

┌───────────┐ ┌───────────┐
│ 🎡        │ │ 📦        │
│ Spin      │ │ Mystery   │
│ Wheel     │ │ Box       │
└───────────┘ └───────────┘
```

Then:

```text
RECOMMENDED TASKS

Video task
+50 🪙

Video task
+120 🪙

Survey
+200 🪙
```

---

# 10. Earn Section

Earn should be a complete ecosystem rather than a single Tasks screen.

```text
EARN
│
├── All
├── Video
├── Surveys
├── Social
├── Daily
└── Quests
```

The interface should allow filtering by:

- task type
- reward
- estimated duration
- progress/status
- availability

---

# 11. Universal Task Card

Different task types should share a common visual system.

## Video Task

```text
┌──────────────────────────────────────────┐
│ [thumbnail]                              │
│                                          │
│ Watch: Smartphone Review                 │
│ Video                                    │
│                                          │
│ ⏱ 5 min       🪙 +50                     │
│                                          │
│ ███████████░░░                           │
│                                          │
│                     [ START ]             │
└──────────────────────────────────────────┘
```

## Survey

```text
┌──────────────────────────────────────────┐
│ 📝 Survey                                │
│                                          │
│ Technology Preferences                   │
│                                          │
│ ⏱ 8 min       🪙 +250                    │
│                                          │
│                     [ START ]             │
└──────────────────────────────────────────┘
```

## Social Task

```text
┌──────────────────────────────────────────┐
│ 📱 Social Task                           │
│                                          │
│ Like + Comment                           │
│                                          │
│ ⏱ 2 min       🪙 +25                     │
│                                          │
│                     [ START ]             │
└──────────────────────────────────────────┘
```

---

# 12. Task States

Every task should have a consistent visual state.

## New

```text
+50 🪙
[ START ]
```

## In Progress

```text
68% complete
+50 🪙
[ CONTINUE ]
```

## Completed

```text
✓ Completed
50 🪙 earned
```

## Temporarily Unavailable

```text
Unavailable
```

---

# 13. Video Task Experience

Video tasks require a specialized experience because the backend supports:

- admin-approved videos
- randomized instructions
- target video detection
- cumulative tracking
- progressive rewards
- no double earning
- unrestricted browsing outside active tasks

The user journey should be:

```text
Task
 ↓
Task Details
 ↓
Search Instruction
 ↓
Start
 ↓
Vewra Browser
 ↓
Correct Video
 ↓
Tracking
 ↓
Progress
 ↓
Completion
```

---

# 14. Task Detail Screen

The task detail screen must answer:

- What am I supposed to do?
- What video/task am I looking for?
- How long is it?
- How much will I earn?
- What happens when I start?

Example:

```text
← Task

┌───────────────────────────────┐
│                               │
│          THUMBNAIL            │
│                               │
└───────────────────────────────┘

How to complete this task

Search YouTube for:

┌───────────────────────────────┐
│ "best smartphone camera 2026" │
│                         📋    │
└───────────────────────────────┘

Then open the video matching:

"Best Smartphone Camera Review"

────────────────────────────────

Reward

🪙 50 coins

Watch requirement

5 minutes

────────────────────────────────

        [ START TASK ]
```

---

# 15. Starting a Task

The transition into task mode should make the state change clear.

```text
Getting your task ready...

✓ Task assigned
✓ Search instruction ready
✓ Reward tracking enabled

Opening YouTube...
```

This communicates that the user has entered an active task session.

---

# 16. Vewra Browser

The browser should feel like normal browsing.

The task tracking layer should be subtle.

```text
┌─────────────────────────────────────────┐
│ ←   YouTube                    ⋮        │
├─────────────────────────────────────────┤
│                                         │
│             YOUTUBE                     │
│                                         │
│                                         │
├─────────────────────────────────────────┤
│                                         │
│ Search / browse normally                │
│                                         │
└─────────────────────────────────────────┘
```

When a task is active:

```text
┌─────────────────────────────┐
│ ✓ Tracking   +20 🪙        │
└─────────────────────────────┘
```

The tracking indicator should be collapsible.

---

# 17. Browser Tracking Details

Expanded tracking state:

```text
Tracking this task

02:18 / 05:00

████████████░░░░

Coins earned
20 🪙

Only unique watched time counts.
```

The tracking UI should not constantly obstruct the video.

---

# 18. Wrong Video State

If the user opens another video:

Do not show technical errors.

Use:

```text
You're browsing normally

Vewra is waiting for the task video.

Search for:

"best smartphone camera 2026"

Once you open the correct video,
tracking will start automatically.
```

This reinforces that browsing remains unrestricted.

---

# 19. Correct Video Detected

When the correct video is detected:

```text
✓ Task video found

Tracking is now active.

+0 🪙
```

Progressive rewards can be shown with small, restrained animations.

Avoid excessive coin animations.

---

# 20. Paused State

When the video is paused:

```text
⏸ Watching paused

Your progress is saved.
Resume whenever you're ready.
```

This reinforces persistent progress.

---

# 21. Leaving a Task

Progress should be auto-saved.

If an explicit exit confirmation is required:

```text
Save progress?

Your current progress will be saved automatically.

02:41 watched

[ CONTINUE WATCHING ]
[ EXIT TASK ]
```

Avoid unnecessary confirmation dialogs if progress is already safely persisted.

---

# 22. Task Completion

Completion should feel like a meaningful reward moment.

```text
🎉

Task Complete!

You earned

+50 🪙

─────────────

Watch time
05:02

─────────────

Wallet balance
1,300 🪙

[ FIND ANOTHER TASK ]
```

---

# 23. Rewards Section

Rewards should be its own major area.

```text
REWARDS
│
├── Wallet
├── Daily Bonus
├── Spin Wheel
├── Mystery Boxes
└── Reward Center
```

---

# 24. Wallet

The wallet should be clean and easy to understand.

```text
Wallet

┌─────────────────────────────────────────┐
│                                         │
│              Your balance               │
│                                         │
│             🪙 1,250                    │
│                                         │
│             Vewra Coins                 │
│                                         │
└─────────────────────────────────────────┘
```

Then:

```text
Recent activity

+50 🪙     Task completed
Today      10:42 AM

+20 🪙     Watch reward
Today      09:15 AM

+50 🪙     Task completed
Yesterday
```

Phase 1 should avoid exposing spending/redemption functionality until those capabilities are actually implemented.

---

# 25. Transaction History

```text
Transactions

Today

+50 🪙
Task completed
10:42 AM

+20 🪙
Watch reward
09:15 AM

Yesterday

+50 🪙
Task completed
```

Potential filters:

```text
All | Earned | Spent
```

If spending is not yet implemented, start with:

```text
All | Earned
```

---

# 26. Daily Bonus

Daily rewards deserve their own destination.

```text
7-Day Streak

Mon ✓  Tue ✓  Wed ✓
Thu ✓  Fri ✓  Sat ●
Sun ○

Current streak
7 days

Today's reward
+100 🪙

[ CLAIM TODAY ]
```

Include:

- current streak
- today's reward
- next reward
- milestone information
- claim status

---

# 27. Spin Wheel

The Spin Wheel should be a dedicated reward experience.

```text
🎡

      ┌───────────┐
      │           │
      │   WHEEL   │
      │           │
      └───────────┘

       1 free spin

       [ SPIN ]
```

The visual experience should make the action feel special without making Vewra look like a casino.

---

# 28. Mystery Boxes

Mystery boxes should similarly have a dedicated interaction.

```text
Mystery Box

You have:
2 boxes

┌───────────┐
│     📦    │
│           │
│  Mystery  │
└───────────┘

[ OPEN BOX ]
```

Reward reveal should be animated and clearly explain the result.

---

# 29. XP and Levels

XP must be visible throughout the app.

Header example:

```text
Lv 12   ███████░
```

Expanded progress:

```text
Level 12

2,480 XP
████████████░░░

Next level
520 XP
```

The user should be able to tap the level indicator to reach the Progress section.

---

# 30. Progress Section

```text
PROGRESS
│
├── Overview
├── XP & Levels
├── Achievements
├── Badges
├── Streaks
└── Leaderboard
```

Progress overview:

```text
Level 12

2,480 XP
████████████░░░

Next level
520 XP

─────────────────

🔥 Current streak
7 days

🏆 Achievements
18 / 50

🎖 Badges
12 / 50
```

---

# 31. Achievements and Badges

Badges should be visual.

```text
┌───────┐ ┌───────┐ ┌───────┐
│  🏆   │ │  🎯   │ │  🔥   │
│ First │ │Watch  │ │Lucky  │
│ Steps │ │Master │ │Streak │
└───────┘ └───────┘ └───────┘
```

Locked:

```text
┌───────┐
│   🔒  │
│ ???   │
│ Locked│
└───────┘
```

Categories can include:

- onboarding
- watching
- social
- earning
- special achievements

---

# 32. Community

The broader product should reserve a complete Community area.

```text
COMMUNITY
│
├── Referrals
├── Friends
├── Guilds
├── Leaderboard
└── Activity
```

Community should not be mixed into Profile.

---

# 33. Referrals

Example:

```text
Invite friends

Your referral code

VEWRA-JOSEPH

[ COPY ]

[ SHARE ]

────────────────────

Earn together

You get:
200 coins

Your friend gets:
100 coins

────────────────────

Your referrals

12 joined
8 active
```

---

# 34. Content Section

Content features should be separate from earning.

```text
CONTENT
│
├── Continue Watching
├── Watch History
└── Favorites
```

This makes it clear that ordinary browsing does not automatically mean earning.

---

# 35. Continue Watching

```text
Continue Watching

┌──────────────────────────────┐
│ thumbnail                    │
│ Video title                  │
│ ███████████░░ 72%            │
│                              │
│ [ CONTINUE ]                 │
└──────────────────────────────┘
```

Persistent watch sessions can support this experience.

---

# 36. Membership

Membership should have a reserved section even before every membership feature is implemented.

```text
MEMBERSHIP

Free
────────────

Vewra Plus
────────────

Vewra Pro
────────────

[ UPGRADE ]
```

Membership UI should support:

- current plan
- available plans
- benefits
- upgrade
- subscription management
- cancellation
- payment status
- feature gating

---

# 37. Profile / Account Center

Profile should become an Account Center rather than a dumping ground for every setting.

```text
PROFILE

Avatar
Username
Level
XP
Streak

────────────────

Account
  Edit profile
  Password
  Security

Preferences
  Notifications
  Appearance

Membership
  Current plan

Activity
  Watch history

Danger zone
  Delete account
```

---

# 38. Global UI States

These should be designed as reusable components.

## Loading

Prefer skeleton states over generic spinners.

## Empty

Example:

```text
📺

No tasks yet

New watching opportunities
will appear here soon.

[ REFRESH ]
```

## Wallet Empty

```text
🪙

No transactions yet

Complete your first task
to start earning coins.
```

## Offline

```text
☁️

You're offline

Check your connection and
try again.

[ RETRY ]
```

## Error

Never expose raw API errors.

Instead:

```text
Something went wrong.

We couldn't load your tasks.

[ TRY AGAIN ]
```

Technical details belong in logs.

---

# 39. Visual Design Direction

The visual identity should be:

- dark
- premium
- energetic
- trustworthy
- modern
- reward-oriented

Avoid making Vewra look:

- like a casino
- like a cryptocurrency trading app
- overly neon
- cluttered
- excessively gradient-heavy

The goal is a legitimate rewards/productivity platform.

---

# 40. Design Tokens

Initial design direction:

```text
Background
#0B0D10

Surface
#12161C

Surface Elevated
#181D24

Border
#252B34

Text Primary
#FFFFFF

Text Secondary
#9CA3AF

Success
#22C55E

Warning
#F59E0B

Error
#EF4444
```

The final brand accent should be determined from the existing Vewra branding and the current `AppColors` implementation before implementation.

---

# 41. Typography

Use the existing Google Fonts dependency rather than introducing a separate typography system.

Potential typefaces:

- Inter
- Manrope
- Plus Jakarta Sans

Suggested hierarchy:

```text
Display / Hero
28–32px / Bold

Screen title
24px / Bold

Section title
18px / SemiBold

Card title
16px / SemiBold

Body
14–15px

Caption
12–13px
```

Typography should have clear hierarchy and generous spacing.

---

# 42. Component System

The UI should use reusable components.

Suggested structure:

```text
core/
  theme/
    app_theme.dart
    app_colors.dart
    app_spacing.dart
    app_radius.dart

widgets/
  vewra_button.dart
  vewra_text_field.dart
  vewra_card.dart
  coin_badge.dart
  reward_badge.dart
  progress_bar.dart
  task_card.dart
  transaction_tile.dart
  empty_state.dart
  error_state.dart
  loading_skeleton.dart
  app_header.dart
  bottom_nav.dart
  site_menu.dart
```

This prevents every screen from developing a slightly different UI language.

---

# 43. Authentication

Authentication should remain intentionally simple.

## Login

```text
VEWRA
Earn while you watch

[ Email ]

[ Password ] 👁

Forgot password?

[ SIGN IN ]

──────── or ────────

New to Vewra?
Create an account
```

## Registration

```text
Create your account

Username
[________________]

Email
[________________]

Password
[________________]

Confirm password
[________________]

☐ I agree to the Terms

[ CREATE ACCOUNT ]

Already have an account?
Sign in
```

Use:

- inline validation
- loading states
- clear errors
- password visibility toggle
- keyboard-friendly layouts

---

# 44. Admin UI

The admin interface should share the Vewra brand but should not look like the consumer mobile application.

Consumer UI:

> Dark / friendly / reward-focused / simple

Admin UI:

> Dense / analytical / operational / desktop-first

The existing admin frontend already has areas such as:

- Dashboard
- Tasks
- Users
- Security
- AI Settings
- task modal
- sidebar
- header
- stat cards
- badges
- modals

The eventual admin system should be expanded to cover the complete operational model.

---

# 45. Admin Information Architecture

Proposed structure:

```text
ADMIN
│
├── Dashboard
│
├── Users
│   ├── All Users
│   ├── User Details
│   ├── Activity
│   └── Security
│
├── Tasks
│   ├── All Tasks
│   ├── Create Task
│   ├── Edit Task
│   ├── Categories
│   └── Task Performance
│
├── Tracking
│   ├── Watch Sessions
│   ├── Active Sessions
│   ├── Completion
│   └── Fraud Signals
│
├── Wallet
│   ├── Transactions
│   ├── Adjustments
│   └── Reward Ledger
│
├── Rewards
│   ├── Daily Rewards
│   ├── Spin Wheel
│   ├── Mystery Boxes
│   └── Reward Rules
│
├── Membership
│   ├── Plans
│   ├── Subscribers
│   └── Feature Gates
│
├── Gamification
│   ├── XP
│   ├── Levels
│   ├── Achievements
│   ├── Badges
│   └── Streaks
│
├── Community
│   ├── Referrals
│   ├── Guilds
│   └── Leaderboards
│
├── AI
│   ├── AI Settings
│   ├── Content Generation
│   └── AI Activity
│
├── Analytics
│
└── System
    ├── Security
    ├── Settings
    └── Audit Logs
```

---

# 46. UI Must Map to the Real Architecture

We should not design screens disconnected from the repository.

Every major screen should eventually map:

```text
UI Screen
   ↓
Flutter Feature
   ↓
Provider / State
   ↓
API Endpoint
   ↓
Django App
   ↓
Model
```

Examples:

```text
Task List
   ↓
features/tasks
   ↓
TaskProvider
   ↓
GET /tasks
   ↓
tasks app
```

```text
Wallet
   ↓
features/wallet
   ↓
WalletProvider
   ↓
GET /wallet
   ↓
wallet app
```

```text
Video Tracking
   ↓
features/browser / tasks
   ↓
tracking state
   ↓
tracking endpoints
   ↓
tracking app
```

This keeps the UI grounded in the actual backend.

---

# 47. UI/UX Design Principles

## Principle 1 — Clarity

Users should always know what to do next.

## Principle 2 — Reward visibility

Show:

- reward
- progress
- earned amount
- remaining amount

without overwhelming the user.

## Principle 3 — Trust

Users must understand:

- when tracking begins
- when it stops
- what counts
- what does not count
- that progress is saved

## Principle 4 — Progressive disclosure

Do not expose every advanced feature at once.

The site menu contains the architecture, but individual screens should remain focused.

## Principle 5 — Consistency

Buttons, cards, badges, task states, progress indicators and navigation should behave consistently.

## Principle 6 — Scalability

Adding a new task type or reward feature should not require a complete navigation redesign.

## Principle 7 — Gamification without casino aesthetics

Vewra can be fun and rewarding without becoming visually associated with gambling.

---

# 48. Recommended Design Process

Do not start by coding every screen.

Work in this order.

## Stage 1 — Information Architecture

Finalize:

- complete product hierarchy
- site menu
- mobile navigation
- desktop navigation
- phase visibility

## Stage 2 — Design Foundation

Finalize:

- logo/brand treatment
- colors
- typography
- spacing
- radii
- shadows
- icons
- buttons
- inputs
- cards
- badges
- progress bars

## Stage 3 — Golden Path

Design:

```text
Login
 ↓
Home
 ↓
Earn
 ↓
Task Detail
 ↓
Start
 ↓
Browser
 ↓
Tracking
 ↓
Completion
 ↓
Wallet
```

## Stage 4 — Secondary Experience

Design:

- Profile
- Settings
- Transactions
- Browser Home
- Continue Watching
- History
- Empty states
- Error states
- Offline states

## Stage 5 — Gamification

Design:

- XP
- Levels
- Achievements
- Badges
- Streaks
- Daily Rewards
- Spin Wheel
- Mystery Boxes

## Stage 6 — Social

Design:

- Referrals
- Friends
- Guilds
- Leaderboard
- Activity

## Stage 7 — Membership

Design:

- Plans
- Upgrade
- Subscription
- Feature gates

## Stage 8 — Admin

Design the operational dashboard and management tools.

## Stage 9 — Implementation Mapping

Map every final screen to:

- Flutter file
- widget
- provider/state
- API
- backend app
- model

---

# 49. Recommended Screen Inventory

The UI/UX specification should eventually cover the following.

## Authentication

1. Splash
2. Login
3. Register
4. Forgot Password
5. Password Reset
6. Verification where required

## Home

7. Home Dashboard
8. Notifications
9. Quick Actions

## Earn

10. Earn Overview
11. All Tasks
12. Video Tasks
13. Survey Tasks
14. Social Tasks
15. Daily Tasks
16. Quests
17. Task Details
18. Task Progress
19. Task Completion

## Browser

20. Browser Home
21. YouTube Browser
22. Active Task Browser
23. Tracking Panel
24. Wrong Video State
25. Correct Video State
26. Paused State
27. Browser Error

## Rewards

28. Wallet
29. Transaction History
30. Daily Bonus
31. Spin Wheel
32. Spin Result
33. Mystery Boxes
34. Mystery Box Result
35. Reward Center

## Progress

36. Progress Overview
37. XP & Levels
38. Achievements
39. Badges
40. Streaks
41. Leaderboard

## Community

42. Referrals
43. Referral Details
44. Friends
45. Guilds
46. Guild Details
47. Activity

## Content

48. Continue Watching
49. Watch History
50. Favorites

## Membership

51. Plans
52. Plan Details
53. Upgrade
54. Subscription
55. Subscription Management

## Account

56. Profile
57. Edit Profile
58. Settings
59. Security
60. Change Password
61. Notifications
62. Help & Support
63. Terms
64. Privacy
65. Delete Account

## Global States

66. Loading
67. Empty
68. Offline
69. Error
70. Confirmation
71. Success
72. Network Retry

## Admin

73. Admin Login
74. Dashboard
75. User Management
76. User Details
77. Task Management
78. Task Creation
79. Task Editing
80. Tracking / Watch Sessions
81. Wallet Management
82. Reward Management
83. Gamification Management
84. Membership Management
85. AI Settings
86. Analytics
87. Security
88. Audit Logs
89. System Settings

This is the target inventory, not a requirement that all 89 screens be implemented immediately.

---

# 50. Final Navigation Model

The recommended long-term Vewra model is:

```text
                         VEWRA
                           │
          ┌────────────────┼────────────────┐
          │                │                │
        HOME             EARN            REWARDS
          │                │                │
          │        ┌───────┼───────┐        ├── Wallet
          │        │       │       │        ├── Daily Bonus
          │      Video   Survey   SMM       ├── Spin
          │        │                       └── Mystery
          │        └── Daily / Quests
          │
          ├── XP / Level
          ├── Streak
          ├── Daily Reward
          ├── Recommended Tasks
          └── Activity
                           │
            ┌──────────────┼──────────────┐
            │              │              │
        PROGRESS        COMMUNITY       CONTENT
            │              │              │
        XP/Levels       Referrals      Continue
        Achievements    Friends        History
        Badges          Guilds         Favorites
        Streaks         Leaderboard
                           │
                     MEMBERSHIP
                           │
                     Free / Paid
                           │
                        ACCOUNT
                           │
              Profile / Settings / Security
```

---

# 51. Final Product Philosophy

Vewra should not feel like a collection of unrelated features.

The product should feel like one connected progression system:

```text
                    VEWRA
                      │
              ┌───────┴───────┐
              │               │
            EARN            ENGAGE
              │               │
       Tasks / Surveys    Streaks / Spin
       SMM / Quests       Rewards / Boxes
              │               │
              └───────┬───────┘
                      │
                     XP
                      │
                   LEVELS
                      │
              ACHIEVEMENTS
                      │
                  COMMUNITY
                      │
                 MEMBERSHIP
```

The user earns through activity.

Activity generates rewards and XP.

XP produces progression.

Progression unlocks status, achievements and potentially membership benefits.

Community adds retention.

The wallet provides a clear record of earned value.

The browser provides the underlying content experience.

All of these should feel like parts of **one Vewra ecosystem**.

---

# 52. Immediate Next Deliverable

The next artifact should be a detailed:

## `VEWRA UI/UX MASTER SPECIFICATION`

It should turn this architecture into actual screen-by-screen designs.

The next stage should focus first on:

1. Final information architecture
2. Mobile site menu
3. Desktop sidebar
4. Mobile bottom navigation
5. Header
6. Home dashboard
7. Earn overview
8. Universal task card
9. Video task flow
10. Browser/tracking experience
11. Wallet
12. Progress
13. Rewards
14. Profile
15. Global UI states

Only after those are settled should we move into Flutter implementation.

The goal is to create the UI/UX as a **system**, not a collection of individual screens.
