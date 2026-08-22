# VEWRA PRO — Complete Feature Roadmap
## From MVP to Enterprise Gamified Reward & SMM Platform

> **Reading guide:** Every feature is tagged with its Octalysis Core Drive (CD1-CD8) and estimated development effort in days. Features are ordered by implementation priority — build in this sequence.

---

## ⚠️ PHASE 0: CRITICAL FIXES & HARDENING (Week 1-2)
### Ship nothing new until these are done. These are the foundation.

---

### FIX-01: Database Migration — SQLite → PostgreSQL
**Effort:** 2 days | **Risk:** 🔴 CRITICAL

SQLite cannot handle concurrent writes, has no connection pooling, and cannot scale horizontally. Migrate to PostgreSQL with:
- `django.db.backends.postgresql` engine
- Connection pooling via pgBouncer
- Read replicas for analytics queries (later phase)
- Automated backups (pg_dump cron)

---

### FIX-02: Secret & API Key Vault
**Effort:** 2 days | **Risk:** 🔴 CRITICAL

Current state: `SECRET_KEY` hardcoded in `settings.py`. Gemini and OpenRouter API keys stored **plaintext** in the `AISettings` database model. This is a breach waiting to happen.

**Solution:**
- All secrets from environment variables only (no hardcoded fallbacks)
- API keys encrypted at rest using `django-fernet-fields` or a vault (HashiCorp Vault / AWS Secrets Manager for production)
- `SECRET_KEY` generated via `python -c "import secrets; print(secrets.token_urlsafe(64))"` and injected via env
- Audit: strip all hardcoded credentials from codebase immediately

---

### FIX-03: CORS & ALLOWED_HOSTS Lockdown
**Effort:** 0.5 days | **Risk:** 🔴 CRITICAL

Current state: `CORS_ALLOW_ALL_ORIGINS = True` and `ALLOWED_HOSTS = ['*']`. This exposes the API to CSRF attacks and host header injection.

**Solution:**
- `ALLOWED_HOSTS` = explicit list from environment variable
- `CORS_ALLOWED_ORIGINS` = explicit whitelist from environment variable
- Add `CSRF_TRUSTED_ORIGINS` matching the frontend domain
- Add security middleware headers: `SECURE_HSTS_SECONDS`, `SECURE_SSL_REDIRECT`, `SECURE_BROWSER_XSS_FILTER`, `X_FRAME_OPTIONS`

---

### FIX-04: Rate Limiting & API Throttling
**Effort:** 1 day | **Risk:** 🔴 CRITICAL

No rate limiting exists on any endpoint. Login, register, tracking progress, and wallet endpoints are all unprotected against brute force and abuse.

**Solution:**
- DRF throttling: `AnonRateThrottle` (100/day) and `UserRateThrottle` (1000/day)
- Custom scoped throttles for sensitive endpoints:
  - `/auth/login/` — 5 requests/minute per IP
  - `/auth/register/` — 3 requests/hour per IP  
  - `/tracking/progress/` — 60 requests/minute per user
  - `/wallet/` — 120 requests/minute per user
- Add `django-ratelimit` for view-level rate limiting

---

### FIX-05: Authentication Hardening
**Effort:** 3 days | **Risk:** 🟠 HIGH

**Additions:**
- Account lockout: 5 failed login attempts → 15-minute lockout
- 2FA/TOTP for admin/staff accounts (using `django-otp`)
- Session management endpoint: `POST /auth/logout-all/` to revoke all tokens for a user
- Password strength policy: minimum 8 chars, must include letter + number + special char
- Email verification on registration (send verification link; optional for phase 0, required for production)
- Add `django-axes` for login attempt tracking and lockout

---

### FIX-06: Structured Logging & Monitoring
**Effort:** 3 days | **Risk:** 🟠 HIGH

**Solution:**
- JSON-formatted structured logging via `python-json-logger`
- Correlation IDs: generate `X-Request-ID` on every request, propagate through all logs
- Log levels: INFO for request lifecycle, WARNING for auth failures, ERROR for exceptions
- Sentry integration for error tracking (`sentry-sdk`)
- Health check endpoints: `GET /health/` (DB + cache check), `GET /ready/` (all dependencies)
- Prometheus metrics endpoint at `/metrics/` via `django-prometheus`:
  - Request count, latency histogram
  - Active watch sessions gauge
  - Coin distribution rate
  - AI keyword generation latency

---

### FIX-07: CI/CD Pipeline
**Effort:** 2 days | **Risk:** 🟠 HIGH

**Solution:** GitHub Actions workflow:
```yaml
name: CI
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    services:
      postgres:
        image: postgres:16
    steps:
      - checkout
      - setup python 3.12
      - pip install -r requirements.txt
      - ruff check .
      - pytest --cov
  lint-frontend:
    - oxlint admin-frontend/
  build:
    - docker build -t vewra-backend .
    - docker build -t vewra-admin .
```

---

### FIX-08: Containerization & Docker Compose
**Effort:** 2 days | **Risk:** 🟠 HIGH

**Deliverables:**
- `Dockerfile` for Django backend (Python 3.12, gunicorn)
- `Dockerfile` for admin frontend (nginx serving Vite build)
- `Dockerfile` for Flutter web build
- `docker-compose.yml`: postgres + redis + backend + admin-frontend + nginx reverse proxy
- `docker-compose.prod.yml`: with Traefik, Let's Encrypt, health checks

---

### FIX-09: Redis Cache Layer
**Effort:** 1.5 days | **Risk:** 🟡 MEDIUM

**Solution:**
- Install `django-redis`
- Cache dashboard stats (currently hitting DB every 3s poll) → cache 30s TTL
- Cache AI keyword generation results per `video_id` → cache 7 days
- Cache available AI models list → cache 1 hour
- Session backend: switch to Redis-backed sessions
- Will also serve as Celery broker in next step

---

### FIX-10: Async Task Queue (Celery)
**Effort:** 2 days | **Risk:** 🟡 MEDIUM

**Solution:**
- Install `celery` + `redis` (broker)
- Move AI keyword generation to async task: task is created, video task saves placeholder, worker generates keywords, result stored
- Move wallet transaction creation to async (reduce tracking endpoint latency)
- Periodic Celery Beat tasks:
  - Cleanup expired blacklisted tokens (daily)
  - Aggregate daily stats into `DailyStats` model (nightly)
  - Check AI provider health (hourly)

---

### FIX-11: Database Optimizations & Model Cleanup
**Effort:** 2 days | **Risk:** 🟡 MEDIUM

- Add `created_at` / `updated_at` to `Wallet` model
- Add `soft delete` (`is_deleted` + `deleted_at`) to `VideoTask` and `User`
- Add database indexes:
  - `WatchSession.last_watched_at` (already used in queries but not indexed)
  - `WalletTransaction.created_at` (ordering)
  - `WalletTransaction.transaction_type` (filtering)
- Add `select_related` / `prefetch_related` audit on all admin API views
- Row-level security audit on admin balance adjustments (immutable audit log)

---

### FIX-12: Anti-Fraud System — Phase 1
**Effort:** 3 days | **Risk:** 🟡 MEDIUM

**Requirements:**
- Track per-user IP history (store hashed)
- Flag: multiple accounts from same IP within 24h
- Flag: VPN/proxy detection (integrate IPQS or ipapi)
- Flag: delta_seconds consistently maxed at 15s (automated pinger)
- Flag: session start and immediate completion (impossible watch speeds)
- Add `User.fraud_score` field (0.0-1.0). Users above 0.7 threshold require manual review
- Admin dashboard: fraud queue with evidence summary

---

### FIX-13: Idempotency for Coin-Awarding Endpoints
**Effort:** 1 day | **Risk:** 🟡 MEDIUM

**Problem:** If a tracking progress request times out but the server processed it, a retry could double-award coins.

**Solution:**
- Client generates `idempotency_key` (UUID v4) per tracking ping
- Server stores processed keys in Redis with 24h TTL
- Duplicate key → return original result, no re-processing
- Frontend generates key and sends in `X-Idempotency-Key` header

---

### FIX-14: API Documentation (OpenAPI / Swagger)
**Effort:** 1 day | **Risk:** ⚪ LOW

- Install `drf-spectacular`
- Auto-generate OpenAPI 3.0 schema from serializers and views
- Serve at `/api/docs/` (Swagger UI) and `/api/schema/` (raw schema)
- Document all query parameters, request bodies, and response schemas

---

## 🚀 PHASE 1: ENGAGEMENT CORE LOOP (Week 3-4)
### The habit-forming daily loop. This is what keeps users coming back.

---

### 1.1 — Daily Login Bonus (Streak Calendar)
**CD:** CD2 (Accomplishment), CD4 (Ownership) | **Effort:** 1.5 days

```
Day 1:  5 coins
Day 2: 10 coins
Day 3: 15 coins
Day 4: 20 coins
Day 5: 30 coins
Day 6: 40 coins
Day 7: 50 coins + Free Mystery Box
Day 8+: Reset to Day 1
```

**Backend:**
- `DailyLogin` model: `user`, `streak_count`, `last_claimed_date`, `longest_streak`
- `POST /api/v1/rewards/daily-claim/` — claim today's reward, increment streak if consecutive
- If `last_claimed_date != yesterday` → reset streak to 1 (grace: if today is same date, return already claimed)
- Streak multipliers: 7-day streak = 1.1x all earnings; 30-day = 1.3x; 100-day = 2x

**Frontend:**
- Calendar grid on home screen showing past 7 days (checked = claimed, X = missed, glow = today)
- "🔥 7-Day Streak!" toast with confetti animation on milestones

---

### 1.2 — Daily Spin Wheel
**CD:** CD7 (Unpredictability) | **Effort:** 2 days

**Mechanics:**
- 1 free spin per day (resets at midnight UTC)
- 12-segment wheel with weighted probabilities

| Segment | Weight | Reward |
|---------|--------|--------|
| 1 coin | 30% | 1 coin |
| 5 coins | 25% | 5 coins |
| 10 coins | 18% | 10 coins |
| 25 coins | 12% | 25 coins |
| 50 coins | 8% | 50 coins |
| 100 coins | 4% | 100 coins |
| 500 coins | 1.5% | 500 coins |
| 1000 coins | 0.5% | 1,000 coins (jackpot) |
| Streak Freeze | 0.4% | 1 streak freeze token |
| XP Boost (1h) | 0.3% | 2x XP for 1 hour |
| Mystery Box | 0.2% | Rare Mystery Box |
| 5000 coins | 0.1% | 5,000 coins (mega jackpot) |

**Backend:**
- `SpinWheel` model: tracks daily spins per user
- `POST /api/v1/rewards/daily-spin/` — validate eligibility, run weighted random, award prize, return result
- Result includes: `prize_type`, `prize_value`, `segment_landed` (for animation)
- Anti-cheat: server-side random only; no client seed

**Frontend:**
- Animated spinning wheel with sound effects
- Slow-down animation: 3 seconds spin, last 2 seconds gradual deceleration
- "Almost got the jackpot!" near-miss animation (lands one segment before)
- Share result button: "I just won 500 coins on Vewra! 🎰"

---

### 1.3 — XP & Leveling System
**CD:** CD2 (Accomplishment), CD3 (Empowerment) | **Effort:** 3 days

**XP Table:**

| Action | XP Earned |
|--------|-----------|
| Watch 1 minute of video | 10 XP |
| Complete a video task | 50 XP (bonus on top of watch XP) |
| Complete a survey | 100-300 XP (based on length) |
| Complete an SMM task (like/comment/share) | 25 XP |
| Daily spin claim | 15 XP |
| Referral signup | 200 XP |
| Purchase coins | 5 XP per $1 |

**Level Ladder (101 levels):**

```
Level  1:     0 XP — Newbie
Level  5:   500 XP — Unlock: Basic Badge Slot
Level 10: 2,000 XP — Unlock: Coin Shop access
Level 20: 8,000 XP — Unlock: Guild creation
Level 30: 18,000 XP — Unlock: Premium Tasks
Level 50: 50,000 XP — Unlock: Creator Dashboard
Level 75: 112,500 XP — Unlock: 2nd Badge Showcase Slot
Level 100: 200,000 XP — Unlock: Prestige Option
```

Formula: `XP_required(level) = level² × 20`

**Backend:**
- `UserProfile.xp` and `UserProfile.level` fields (extend via OneToOne or add to existing UserProfile)
- Signal or middleware: on every XP-earning action, call `add_xp(user, amount)`
- `add_xp()`: increment XP, check if level-up, if yes → trigger level-up flow (notification, rewards)
- `GET /api/v1/profile/` — returns `xp`, `level`, `xp_to_next_level`, `level_progress_percent`
- `GET /api/v1/profile/level-rewards/` — returns all unlocked perks

**Frontend:**
- XP progress bar always visible in top nav (circular, with level number in center)
- Level-up full-screen celebration: particles, new level badge reveal, reward summary
- Profile page: XP history graph, level timeline

---

### 1.4 — Achievement & Badge System
**CD:** CD2 (Accomplishment), CD5 (Social Influence) | **Effort:** 3 days

**50+ Badges across categories:**

#### Onboarding Badges
| Badge | Requirement | Tier Progression |
|-------|-------------|------------------|
| First Steps | Complete first video | — |
| Getting Started | Complete 5 videos | Bronze → Silver (25) → Gold (100) → Diamond (500) |
| Profile Set | Upload avatar + set display name | — |

#### Watch Badges
| Badge | Requirement | Tier Progression |
|-------|-------------|------------------|
| Couch Potato | 10 hours total watch time | Bronze → Silver (50h) → Gold (250h) → Diamond (1000h) |
| Night Owl | 10 videos watched between 12am-6am | Bronze → Silver (50) → Gold (200) |
| Speed Demon | Complete 10 videos at 2x speed | — |
| Marathoner | Complete a 30+ minute video | — |
| Scholar | Watch 50 educational videos | Bronze → Silver (200) → Gold (1000) |
| Binge Watcher | Watch 10 videos in one day | Bronze → Silver (25 in a day) → Gold (50 in a day) |

#### Social Badges
| Badge | Requirement |
|-------|-------------|
| Social Butterfly | Complete 50 SMM tasks (likes/comments/shares) |
| Referral King | Refer 10 active users |
| Guild Leader | Create a guild with 10+ members |
| Cheerleader | Send 100 cheers to friends |
| Influencer | Get 1000 total likes on your shared content |

#### Earning Badges
| Badge | Requirement |
|-------|-------------|
| Coin Collector | Earn 1,000 total coins |
| High Roller | Earn 50,000 total coins |
| Millionaire | Earn 1,000,000 total coins |
| Lucky Streak | 30-day login streak |
| Perfect Week | Complete all daily quests 7 days in a row |
| Jackpot Winner | Hit the 5000-coin spin wheel jackpot |

#### Special Badges
| Badge | Requirement |
|-------|-------------|
| Early Adopter | Joined in first month of launch |
| Beta Tester | Participated in beta |
| Event Champion | Won a seasonal tournament |
| Ghost Hunter | Watched a video at exactly 3:33 AM (hidden) |
| Century Club | Level 100 |
| Prestige I, II, III | Prestige 1x, 2x, 3x |

**Backend:**
- `Badge` model: `id`, `key` (slug), `name`, `description`, `icon_url`, `category`, `is_hidden`
- `UserBadge` model: `user`, `badge`, `tier` (bronze/silver/gold/diamond/legendary), `awarded_at`, `progress_current`, `progress_target`
- Badge evaluation: signals on action completion check all badge criteria asynchronously (Celery task)
- `GET /api/v1/badges/` — all badges with user progress
- `GET /api/v1/badges/earned/` — user's earned badges
- `GET /api/v1/profile/badge-showcase/` — 3 featured badges for public display
- `PUT /api/v1/profile/badge-showcase/` — update featured badges

---

### 1.5 — Daily Quest Board
**CD:** CD2 (Accomplishment), CD7 (Unpredictability) | **Effort:** 2 days

**Mechanics:**
- 3 random quests generated daily per user at midnight UTC
- Quest pool organized by difficulty:

| Difficulty | Example | Reward |
|-----------|---------|--------|
| Easy | "Watch 1 video" | 15 coins + 25 XP |
| Medium | "Complete 2 SMM tasks" | 40 coins + 75 XP |
| Hard | "Complete 5 videos + 1 survey" | 100 coins + 200 XP |

- Complete all 3 daily quests → bonus "Quest Master" reward: 50 coins + 1 Mystery Box
- Quests seeded with user_id + date for deterministic per-user randomization (prevents gaming; same quests all day)

**Backend:**
- `DailyQuest` model: `user`, `date`, `quest_type`, `quest_config` (JSON: category, count, reward), `progress_current`, `progress_target`, `is_completed`, `is_claimed`
- `GET /api/v1/quests/daily/` — today's 3 quests with progress
- `POST /api/v1/quests/daily/{quest_id}/claim/` — claim reward when completed
- Auto-update progress on matching actions (signals)

**Frontend:**
- Quest cards in a horizontal scrollable row on home screen
- Progress bar on each card: "Watch 2/3 videos"
- "Claim!" button pulses when quest is completed
- All 3 complete → confetti + "Quest Master!" full-screen celebration

---

### 1.6 — Streak Freeze System
**CD:** CD8 (Loss & Avoidance), CD4 (Ownership) | **Effort:** 1 day

**Mechanics:**
- `UserProfile.streak_freeze_count` (default: 0)
- When a user misses a day: auto-consume 1 freeze if available. Streak preserved. Notification: "Your streak was saved by a Streak Freeze! ❄️"
- No freeze available: streak resets to 1. Notification: "Your streak was broken. Start a new one!"
- Ways to earn freezes:
  - Daily spin wheel (0.4% drop)
  - Every 30-day streak milestone = +2 freezes
  - Level 20 reward = +1 freeze
  - Purchase from shop (50 coins each)
  - Referral reward

**Anti-Abuse:**
- Max 3 freezes consumed per week (prevents perpetual freeze hoarding)
- Freezes auto-consume only if `last_claimed_date` is exactly 2 days ago (not if 3+ days)

---

### 1.7 — Lucky Drop (Variable Reward During Watching)
**CD:** CD7 (Unpredictability) | **Effort:** 1.5 days

**Mechanics:**
- While a user is watching a video (tracking progress pings), there's a 5% chance every 10 cumulative minutes of a Lucky Drop
- Drop types (weighted):

| Drop | Weight | Description |
|------|--------|-------------|
| Coin Drop | 70% | 5-50 random coins |
| XP Boost | 15% | 2x XP for 30 minutes |
| Streak Freeze | 5% | +1 freeze |
| Mystery Box (Common) | 7% | Common mystery box |
| Mystery Box (Rare) | 2.5% | Rare mystery box |
| Mystery Box (Epic) | 0.5% | Epic mystery box |

**Backend:**
- Add to `process_watch_progress()` in `tracking/services.py`:
  - Track per-session `lucky_drop_checkpoints` (list of 10-min intervals already checked)
  - On crossing a new 10-min boundary: roll for drop, if hit → return drop info in progress response
- Drop result in tracking response: `lucky_drop: null | {type, value}`

**Frontend:**
- Gold coin descends from top of screen with sparkle trail
- "💎 Lucky Drop! +30 coins!" toast with sound effect
- Haptic feedback on mobile

---

### 1.8 — Daily Scratch Card
**CD:** CD7 (Unpredictability) | **Effort:** 1 day

**Mechanics:**
- 1 free scratch card per day (must complete at least 1 task to unlock)
- 3x3 grid (9 panels). User "scratches" 3 panels.
- Match 2 of same type = that prize. Match 3 = upgraded prize.

| Panel Type | Match 2 Prize | Match 3 Prize |
|-----------|---------------|---------------|
| Coin (common) | 10 coins | 50 coins |
| Coin (rare) | 50 coins | 250 coins |
| XP | 50 XP | 200 XP |
| Freeze | 1 freeze | 3 freezes |
| Mystery Box | Common box | Rare box |

**Frontend:**
- Scratch-off animation: finger/swipe reveals panels
- "Scratch all 3 panels!" instruction overlay
- Reveal animation: panels flip with shine

---

## 🏆 PHASE 2: COMPETITION & SOCIAL (Week 5-6)

---

### 2.1 — Global & Friends Leaderboard
**CD:** CD5 (Social Influence), CD2 (Accomplishment) | **Effort:** 3 days

**Leaderboard Types:**

| Type | Scope | Reset | Metric |
|------|-------|-------|--------|
| Weekly Earners | Global | Every Monday 00:00 UTC | Coins earned |
| Weekly Watchers | Global | Every Monday | Minutes watched |
| Weekly Taskers | Global | Every Monday | Tasks completed |
| Friends | User's friends only | Weekly | Coins earned |
| Country | Per-country | Weekly | Coins earned |
| Guild | All guilds | Weekly | Combined member coins |

**Backend:**
- Redis Sorted Sets for real-time leaderboards (fast, no DB load)
- `ZADD leaderboard:weekly:coins:{week_id} {coins} {user_id}`
- `ZREVRANK` + `ZSCORE` for position + score
- `GET /api/v1/leaderboard/?type=weekly_coins&scope=global&limit=100`
- Response includes: `rank`, `user_id`, `username`, `avatar_url`, `score`, `is_you`, `percentile`
- For logged-in user: always return their rank + score even if not in top 100

**Frontend:**
- Podium view for top 3 (gold/silver/bronze with crowns)
- Scrollable list for ranks 4-100
- "You" row pinned at bottom if outside top 100
- Tabs to switch between leaderboard types
- "🏆 #47 in Nigeria this week!" pill on home screen

---

### 2.2 — Referral System 2.0
**CD:** CD5 (Social Influence), CD4 (Ownership) | **Effort:** 2.5 days

**Mechanics:**
- Every user gets a unique referral code (e.g., `AKENDE42`)
- Referrer reward: 100 coins when referred user completes first video
- Referee reward: 50 coins welcome bonus
- Multi-level commission:
  - Level 1: 5% of direct referrals' lifetime earnings (paid by platform, not deducted from referral)
  - Level 2: 2% of referrals' referrals' earnings
- Referral milestones:

| Referrals | Reward |
|-----------|--------|
| 1 | "First Friend" badge |
| 5 | 500 coins + Silver Recruiter badge |
| 25 | 2,500 coins + Gold Recruiter badge |
| 100 | 10,000 coins + Diamond Recruiter badge |
| 500 | 50,000 coins + Legendary Recruiter badge + custom URL |

**Backend:**
- `Referral` model: `referrer`, `referred_user`, `code_used`, `level` (1 or 2), `created_at`
- `ReferralEarning` model: `referrer`, `amount`, `source_user`, `source_action`, `created_at`
- `GET /api/v1/referrals/` — referral stats, earnings, leaderboard
- `GET /api/v1/referrals/code/` — user's referral code and share link
- Crons: calculate and credit referral commissions daily

**Frontend:**
- Referral dashboard: "You've earned X coins from Y referrals"
- Share sheet: native share with personalized message + link
- Referral leaderboard visible to incentivize competition

---

### 2.3 — Guilds / Clans System
**CD:** CD5 (Social Influence), CD1 (Epic Meaning), CD3 (Empowerment) | **Effort:** 5 days

**Mechanics:**
- Create guild: 1,000 coins (anti-spam gate), Level 20+ requirement
- Max 50 members per guild (increases with guild level)
- Guild roles: Leader, Co-Leader, Elder, Member
- Guild features:

| Feature | Description |
|---------|-------------|
| Guild Chat | Real-time chat (WebSocket or polling) |
| Guild Level | Earned via combined member XP. Levels unlock: more member slots, custom banner, guild badge |
| Guild Bank | Members donate coins. Leader allocates for: guild upgrades, event entries, member rewards |
| Guild Quests | "As a guild, watch 500 videos this week." Combined progress. Reward distributed to all who contributed. |
| Guild Leaderboard | Weekly ranking. Top 3 guilds get: banner frame + member coin bonus (10%, 5%, 3%) |
| Guild Wars | Monthly bracket tournament. Combined member earnings over 48 hours. Winner takes prize pool (entry fees). |

**Backend:**
- `Guild` model: `name`, `description`, `tag`, `banner_url`, `level`, `xp`, `coins_in_bank`, `created_at`
- `GuildMember` model: `guild`, `user`, `role`, `joined_at`, `xp_contributed`
- `GuildQuest` model: similar to daily quest but scoped to guild
- `GuildWar` / `GuildWarMatch` models
- WebSocket endpoint: `ws://api/ws/guild/{guild_id}/` for real-time chat
- REST endpoints for CRUD guild operations

**Frontend:**
- Guild home: banner, member list with roles, chat panel
- Guild discovery: search, filter by level/members, request to join
- Guild war bracket visualization
- Guild quest progress tracker

---

### 2.4 — Watch Party (Co-Watch)
**CD:** CD5 (Social Influence), CD7 (Unpredictability) | **Effort:** 2 days

**Mechanics:**
- Host creates a watch party room (generates shareable link)
- Up to 10 friends join
- Host controls playback (play/pause/seek syncs to all)
- Chat sidebar during watch
- Bonus: +20% coin earnings for all participants (social multiplier)

**Backend:**
- `WatchParty` model: `host`, `video_task`, `room_code`, `is_active`, `participant_count`, `created_at`
- `WatchPartyParticipant` model: `party`, `user`, `joined_at`
- WebSocket room: sync playback state, relay chat messages
- `POST /api/v1/watch-party/create/` — create room
- `POST /api/v1/watch-party/join/{code}/` — join room

---

### 2.5 — Friend System & Activity Feed
**CD:** CD5 (Social Influence) | **Effort:** 2 days

**Mechanics:**
- Add friends by username, phone contact sync, or referral
- Friend requests with accept/decline
- Activity feed: "John earned the Night Owl badge!" "Sarah hit Level 25!"
- Cheer/Taunt system: Send reaction to friend's activity
- Max 500 friends

**Backend:**
- `Friendship` model: `user`, `friend`, `status` (pending/accepted/blocked), `created_at`
- `ActivityEvent` model: `user`, `event_type`, `event_data` (JSON), `visibility`, `created_at`
- `GET /api/v1/social/feed/` — paginated activity feed
- `POST /api/v1/social/friends/{user_id}/cheer/` or `/taunt/`

---

## 💎 PHASE 3: MYSTERY, SURPRISE & VARIABLE REWARDS (Week 7-8)

---

### 3.1 — Mystery Box System
**CD:** CD7 (Unpredictability), CD4 (Ownership) | **Effort:** 2.5 days

**Rarity Tiers:**

| Rarity | Drop Rate | Contains |
|--------|-----------|----------|
| Common (Gray) | 60% | 5-25 coins, 15-50 XP, 1 basic item |
| Rare (Blue) | 25% | 50-200 coins, 100-500 XP, streak freeze, 1h XP boost |
| Epic (Purple) | 12% | 200-1000 coins, 500-2000 XP, 3 streak freezes, 24h XP boost, rare badge |
| Legendary (Gold) | 2.5% | 1000-5000 coins, 5000-10000 XP, 10 streak freezes, exclusive skin, legendary badge, 7-day VIP pass |
| Mythic (Red/Particle) | 0.5% | 5000-25000 coins, instant level-up, mythic badge (only 100 ever), physical merch voucher |

**Ways to obtain Mystery Boxes:**
- Daily login streak day 7
- Daily spin wheel (rare/epic)
- Complete all 3 daily quests
- Lucky drop while watching
- Level-up rewards (every 10 levels = 1 box)
- Guild quest completion
- Purchase from shop: Common (50 coins), Rare (200 coins), Epic (1,000 coins)

**Backend:**
- `MysteryBox` model: `user`, `rarity`, `source` (how obtained), `is_opened`, `opened_at`
- `BoxItem` model: defines possible contents per rarity
- `POST /api/v1/boxes/open/{box_id}/` — roll contents, return result, mark opened
- Opening animation: server returns result after randomized delay (0.5-2s for suspense)

**Frontend:**
- Box opening animation: box shakes, glows based on rarity, bursts open
- Contents cascade reveal: coins count up, items appear with particle effects
- Screen shake on Legendary/Mythic
- "Share this pull!" button for Legendary+

---

### 3.2 — Golden Video Mechanic
**CD:** CD7 (Unpredictability), CD6 (Scarcity) | **Effort:** 1.5 days

**Mechanics:**
- Every hour, one random active video task becomes "Golden" 🥇
- Golden video pays **5x normal reward**
- Displayed prominently on task list with gold border + shimmer animation
- Timer: "Golden for 48 more minutes!"
- Notification: "🎬 A Golden Video just appeared! 5x rewards for the next hour!"

**Backend:**
- Cron job: every hour, pick random active task, set `is_golden = True`, set `golden_expires_at`
- Previous golden video cleared
- Task list response includes `is_golden` and `golden_expires_at`
- Reward calculation: if task is golden at time of reward → multiply by 5

---

### 3.3 — Random Bonus Multiplier (Post-Video)
**CD:** CD7 (Unpredictability) | **Effort:** 1 day

**Mechanics:**
- On completing a video task: "Spin for a bonus multiplier!" mini-game
- Weighted wheel:

| Multiplier | Weight |
|-----------|--------|
| 1x | 50% |
| 1.5x | 25% |
| 2x | 15% |
| 3x | 7% |
| 5x | 2.5% |
| 10x | 0.5% |

- Multiplier applies to that video's reward only
- VIP tiers get slightly better odds (e.g., Gold: 1x drops to 40%, 10x rises to 0.8%)

---

### 3.4 — Surprise Gift Drops (Push-to-Engage)
**CD:** CD7 (Unpredictability), CD5 (Social) | **Effort:** 1 day

**Mechanics:**
- Admin-triggered or scheduled random gift drops
- Push notification: "🎁 Vewra just dropped 50 free coins! Claim in the next 30 minutes!"
- Time-limited claim (creates urgency)
- Occasional "First 1000 claimants get 2x" mechanics
- Scheduled drops during low-activity hours to re-engage users

---

## 🛡️ PHASE 4: SMM TASK ENGINE (Week 9-10)

---

### 4.1 — Social Media Microtasks
**CD:** CD4 (Ownership), CD5 (Social) | **Effort:** 5 days

#### Task Types & Payouts

**YouTube Tasks:**

| Action | Verification Method | Coins |
|--------|---------------------|-------|
| Like a video | OAuth / user reports | 5 |
| Subscribe to channel | OAuth / screenshot + AI verify | 15 |
| Comment on video | Copy comment text, AI validates quality (min 10 words, no spam) | 10-25 (based on quality) |
| Share video | Deep link verification | 10 |

**Instagram Tasks:**

| Action | Verification Method | Coins |
|--------|---------------------|-------|
| Like a post/reel | User confirms, periodic re-verification | 5 |
| Follow account | OAuth or screenshot + AI | 15 |
| Comment | Text validation | 10-20 |
| Save post | Screenshot verification | 8 |
| Share to story | Screenshot verification | 15 |

**TikTok Tasks:**

| Action | Verification Method | Coins |
|--------|---------------------|-------|
| Like video | User confirms | 5 |
| Follow | Screenshot + AI | 15 |
| Comment | Text validation | 10-20 |
| Favorite | User confirms | 8 |

**Twitter/X Tasks:**

| Action | Verification Method | Coins |
|--------|---------------------|-------|
| Like tweet | User confirms | 5 |
| Retweet | API verification (if OAuth'd) or user confirms | 10 |
| Quote tweet | Text validation | 20 |
| Reply | Text validation | 15 |
| Follow | API verification | 15 |

**Telegram Tasks:**

| Action | Verification Method | Coins |
|--------|---------------------|-------|
| Join channel/group | Bot API verification | 10 |
| Send message | Bot API | 15 |

**Backend:**
- `SMMTask` model: `platform`, `action_type`, `target_url`, `target_id`, `reward_coins`, `verification_method`, `is_active`, `daily_cap_per_user`
- `SMMTaskCompletion` model: `user`, `task`, `proof_data` (JSON: screenshot URL, text, etc.), `verification_status` (pending/verified/rejected), `verified_by` (AI/manual), `coins_awarded`
- Verification pipeline:
  1. User submits completion with proof
  2. AI validates: text quality check, duplicate detection, spam filter
  3. If AI confidence > 90% → auto-verify + award coins
  4. If AI confidence < 90% → queue for manual review (admin dashboard)
  5. If rejected: reason shown to user, no coins awarded
- Rate limits: max 50 SMM tasks per user per day, max 5 of same action per hour

**Frontend:**
- SMM task cards with platform icon, action type, reward
- "Complete & Earn" button → opens target in WebView/browser
- After action: proof submission form (paste comment, upload screenshot)
- "Pending Verification" status with estimated time
- History: all SMM completions with status

---

### 4.2 — Offerwall Integration
**CD:** CD4 (Ownership) | **Effort:** 2 days

**Partner Integrations (choose 2-3):**
- Pollfish / CPALead / AdGate Media / Ayet Studios
- ironSource / Tapjoy for app install offers

**Mechanics:**
- Third-party offerwall SDK embedded in app
- Callback/webhook when user completes offer → award coins
- Server-side verification of all completions
- `OfferwallCompletion` model: `user`, `offer_id`, `provider`, `reward_coins`, `provider_tx_id`, `completed_at`

---

### 4.3 — In-App Survey Engine
**CD:** CD4 (Ownership), CD3 (Empowerment) | **Effort:** 2.5 days

**Survey Types:**

| Type | Duration | Payout | Frequency |
|------|----------|--------|-----------|
| Quick Poll | 10 seconds | 3 coins | Daily |
| Short Survey | 1-2 minutes | 25-50 coins | 5/day |
| Medium Survey | 3-5 minutes | 75-150 coins | 3/day |
| Long Survey | 10-15 minutes | 200-500 coins | 1/day |

**Backend:**
- `Survey` model: `title`, `description`, `estimated_duration_seconds`, `reward_coins`, `questions` (JSON array), `target_demographics` (JSON), `max_responses`, `current_responses`, `is_active`
- `SurveyResponse` model: `user`, `survey`, `answers` (JSON), `completed_at`, `coins_awarded`
- Admin panel: survey builder with drag-and-drop question types (multiple choice, rating scale, text input, ranking)
- `GET /api/v1/surveys/available/` — surveys user hasn't taken and matches demographics
- `POST /api/v1/surveys/{id}/submit/` — submit answers, validate, award coins

**Frontend:**
- One-question-at-a-time survey flow (progressive disclosure, reduces abandonment)
- Progress bar: "Question 3 of 10"
- Estimated time remaining shown
- Survey card on task list: reward, duration, topic

---

### 4.4 — Daily Poll (Community Pulse)
**CD:** CD5 (Social), CD7 (Unpredictability) | **Effort:** 1 day

**Mechanics:**
- 1 poll question per day, visible to all users
- Answer = 5 coins (instant reward)
- After voting: see live results (% breakdown)
- Comment/discussion thread below poll
- Past polls archived and viewable

**Backend:**
- `DailyPoll` model: `question`, `options` (JSON array), `date`, `total_votes`
- `PollVote` model: `poll`, `user`, `option_index`, `created_at`
- `GET /api/v1/polls/today/` — today's poll + user's vote
- `POST /api/v1/polls/today/vote/` — cast vote

---

## 📦 PHASE 5: BATTLE PASS & MONETIZATION (Week 11-12)

---

### 5.1 — Monthly Battle Pass (Season Pass)
**CD:** CD2 (Accomplishment), CD4 (Ownership), CD6 (Scarcity) | **Effort:** 4 days

**Structure:**

| | Free Track | Premium ($4.99/mo) | Elite ($9.99/mo) |
|---|---|---|---|
| Tiers | 50 | 50 | 50 + instant skip 10 |
| Coin rewards | Basic (total ~500) | 3x coins (total ~1500) | 3x coins + bonus |
| Mystery Boxes | 2 Common | 3 Common + 2 Rare + 1 Epic | 5 Common + 3 Rare + 2 Epic |
| Exclusive items | 0 | Season badge + skin + frame | Season badge + skin + frame + animated variant |
| XP Boosts | 0 | 3 × 1-hour 2x boosts | 5 × 2-hour 2x boosts |
| Streak Freezes | 1 | 5 | 10 |
| Grand Prize Entry | ❌ | ✅ | ✅ + 2x entries |
| Ad-Free | ❌ | ❌ | ✅ |
| Discord Role | ❌ | ✅ | ✅ (exclusive channel) |

**Season Length:** Calendar month (1st - 28th/30th/31st)

**Progression:**
- Earn Battle Pass XP (BPXP) from all activities
- Each tier requires 100 BPXP
- 1 BPXP per coin earned (organic), 2 BPXP per minute watched, 5 BPXP per SMM task, 10 BPXP per survey
- Average active user reaches tier 35-40 in free track

**Grand Prize (monthly):**
- Premium pass holders entered into draw
- Prize rotates: iPhone, PlayStation, $500 Amazon gift card, crypto bundle
- Winner announced 1st of next month

**Backend:**
- `Season` model: `name`, `theme`, `start_date`, `end_date`, `is_active`
- `SeasonPass` model: `user`, `season`, `tier` (free/premium/elite), `bpxp`, `current_tier`, `purchased_at`
- `SeasonTierReward` model: `season`, `tier_number`, `track_type`, `reward_type`, `reward_config`
- `UserSeasonReward` model: `user`, `season`, `tier_number`, `is_claimed`
- `GET /api/v1/battle-pass/current/` — current season info + user progress + all tiers with claim status
- `POST /api/v1/battle-pass/claim/{tier}/` — claim tier reward
- `POST /api/v1/battle-pass/upgrade/` — purchase premium/elite
- Webhook: on any coin-earning action → also award BPXP

**Frontend:**
- Horizontal scrollable tier track (like Fortnite): left (earned) → right (locked)
- Free/Premium toggle to compare tracks
- "Unlock Premium" CTA after tier 10 ("You're missing out on 3x more rewards!")
- Tier unlock animation: bar fills, glows, item appears
- Season countdown timer: "14 days left in Cyberpunk June!"

---

### 5.2 — VIP Subscription Tiers
**CD:** CD4 (Ownership), CD6 (Scarcity), CD1 (Epic Meaning) | **Effort:** 2 days

| Perk | Free | Silver $2.99 | Gold $5.99 | Platinum $9.99 | Diamond $19.99 |
|------|------|-------------|------------|----------------|----------------|
| Earnings multiplier | 1x | 1.2x | 1.5x | 2x | 3x |
| Daily spins | 1 | 2 | 3 | 5 | Unlimited |
| Streak freezes/month | 0 | 1 | 3 | 5 | 10 |
| Ad-free | ❌ | ❌ | ✅ | ✅ | ✅ |
| Exclusive tasks | ❌ | ❌ | ❌ | ✅ | ✅ |
| Withdrawal priority | Standard | Standard | 24h | 12h | Instant |
| VIP badge | ❌ | Silver | Gold | Platinum | Diamond |
| Monthly gift box | ❌ | ❌ | ❌ | ❌ | Physical merch |
| Discord role | ❌ | ❌ | ✅ | ✅ | ✅ |
| Account manager | ❌ | ❌ | ❌ | ❌ | Personal rep |
| Custom profile URL | ❌ | ❌ | ❌ | ✅ | ✅ |

**Backend:**
- `Subscription` model: `user`, `tier`, `start_date`, `end_date`, `is_active`, `auto_renew`, `payment_provider`, `provider_subscription_id`
- Middleware/utility: `get_user_multiplier(user)` — returns 1.0-3.0 based on active tier
- All reward calculations multiply by this factor
- Stripe / Paystack / Flutterwave integration for recurring billing
- Webhook handler for subscription lifecycle events

---

### 5.3 — Virtual Coin & Item Shop
**CD:** CD4 (Ownership), CD6 (Scarcity) | **Effort:** 2.5 days

**Shop Categories:**

#### Coin Store (Fiat → Coins)
| Bundle | Price | Coins | Bonus |
|--------|-------|-------|-------|
| Starter | $0.99 | 1,000 | — |
| Popular | $4.99 | 5,500 | +10% |
| Value | $9.99 | 12,000 | +20% |
| Pro | $19.99 | 25,000 | +25% |
| Elite | $49.99 | 65,000 | +30% |
| Legendary | $99.99 | 150,000 | +50% |

#### Item Shop (Coins → Items)
| Item | Cost | Description |
|------|------|-------------|
| XP Boost (1 hour, 2x) | 50 coins | Double XP for 1 hour |
| XP Boost (24 hours, 2x) | 500 coins | Double XP for 24 hours |
| Streak Freeze | 50 coins | 1 freeze token |
| Streak Freeze Pack (5) | 200 coins | 5 freeze tokens |
| Mystery Box (Common) | 50 coins | 1 common box |
| Mystery Box (Rare) | 200 coins | 1 rare box |
| Mystery Box (Epic) | 1,000 coins | 1 epic box |
| Name Color Change | 500 coins | Custom name color (permanent) |
| Profile Frame | 1,000-5,000 coins | Animated frames |

#### Limited-Time Shop (Rotating)
- Refreshes every 48 hours
- Exclusive items: holiday skins, event badges, rare boosts
- "Leaving soon" timer on each item

**Backend:**
- `ShopItem` model: `name`, `category`, `price_coins`, `price_fiat`, `item_type`, `item_config` (JSON), `is_limited`, `available_until`, `stock_remaining`
- `Purchase` model: `user`, `item`, `price_paid_coins`, `price_paid_fiat`, `purchased_at`
- `GET /api/v1/shop/` — all available items
- `POST /api/v1/shop/buy/{item_id}/` — purchase with coins or fiat

---

### 5.4 — Creator Sponsorship & Task Promotion
**CD:** CD3 (Empowerment), CD4 (Ownership) | **Effort:** 3 days

**For Creators (YouTube/TikTok channels):**
- Creator dashboard: submit videos as tasks, set reward config, track performance
- Pricing tiers:
  - **Starter (Free):** 1 active task, basic analytics
  - **Growth ($9.99/mo):** 5 active tasks, detailed analytics, priority listing
  - **Pro ($49.99/mo):** 25 active tasks, advanced analytics, API access, featured placement
  - **Enterprise ($199.99/mo):** Unlimited tasks, white-label, dedicated support, custom integrations

**For Brands/Advertisers:**
- **Sponsored Tasks:** Brand pays to have their content as a task. Higher reward = more engagement.
- **Branded Challenges:** "Nike 30-Day Fitness Challenge" — quest line with branded rewards
- Pay-per-engagement model: brand pays per view/click/comment

**Backend:**
- `CreatorProfile` model: extends UserProfile with creator-specific fields
- `CreatorSubscription` model: tier, payment tracking
- `SponsoredCampaign` model: `brand_name`, `budget`, `cpm_rate`, `start_date`, `end_date`, `total_engagements_delivered`
- Analytics: impressions, completions, engagement rate, demographic breakdown

---

## 📱 PHASE 6: MOBILE & PLATFORM EXPANSION (Week 13-14)

---

### 6.1 — Flutter Mobile App — Full Feature Build
**Effort:** 10 days

Build out the Flutter app (currently only wallet screens exist):

#### Screens to Build:
1. **Home / Feed:** Daily spin, quest cards, streak calendar, golden video banner, lucky drop notifications
2. **Task List:** Watch tasks, SMM tasks, surveys, offers — filterable by category/reward/platform
3. **Task Detail:** Video embed with tracking overlay, instructions, reward breakdown, multiplier indicator
4. **Wallet:** Balance card, transaction history (exists — enhance with charts)
5. **Leaderboard:** Tabs for Global/Friends/Country/Guild, podium view
6. **Guild:** Guild home, chat, quests, member list
7. **Battle Pass:** Tier track, free/premium toggle, claim animation
8. **Shop:** Coin store, item shop, limited-time deals
9. **Profile:** Avatar, level/XP bar, badge showcase, stats, settings
10. **Social:** Friend list, activity feed, referral dashboard

#### Technical:
- State management: Keep Provider (already in pubspec.yaml)
- Real-time: WebSocket for guild chat, watch party, live leaderboard updates
- Local notifications: `flutter_local_notifications` for streak reminders, golden video alerts, gift drops
- Deep links: Referral codes, watch party invites, task sharing

---

### 6.2 — Push Notification Engine
**Effort:** 2 days

**Notification Types:**

| Type | Trigger | Message Template |
|------|---------|------------------|
| Streak Reminder | 2 hours before midnight if not claimed | "🔥 Don't lose your 12-day streak! Claim your daily bonus now." |
| Golden Video | New golden video appears | "🎬 A Golden Video just dropped! 5x rewards for the next 58 minutes!" |
| Gift Drop | Admin-triggered | "🎁 50 free coins waiting for you! Claim in the next 29 minutes." |
| Friend Activity | Friend earns badge/levels up | "👏 Sarah just hit Level 25! Send a cheer!" |
| Guild Alert | Guild war starting/ending | "⚔️ Guild War starts in 1 hour! Rally your team!" |
| Weekly Recap | Every Monday 9am | "📊 Last week: You earned 2,450 coins, watched 3.2 hours, and ranked #47 in Nigeria!" |
| Battle Pass | Tier unlocked, season ending | "⏰ 2 days left in the season! You're 3 tiers from the grand prize." |
| Referral Milestone | Referral signs up, milestone hit | "🎉 Your friend just joined! +100 coins. 4 more referrals to Silver Recruiter!" |

**Backend:**
- FCM (Firebase Cloud Messaging) for Android/iOS
- Web push for admin dashboard
- `NotificationPreference` model: per-user toggle for each notification type
- `NotificationLog` model: all sent notifications for analytics
- Segmentation: send to users by level, subscription tier, activity status, country

---

### 6.3 — PWA / Web App
**Effort:** 2 days

- Service worker for offline caching
- Install prompt (Add to Home Screen)
- Push notifications via Web Push API
- Responsive design audit for mobile web

---

## 💸 PHASE 7: WITHDRAWAL & REAL-WORLD VALUE (Week 15-16)

---

### 7.1 — Expanded Withdrawal Options
**Effort:** 3 days

| Method | Min | Fee | Speed | Regions |
|--------|-----|-----|-------|---------|
| PayPal | $5 | 2% | 24-48h | Global |
| Bank Transfer | $10 | 1% | 2-5 business days | Country-specific |
| Bitcoin (BTC) | $10 | Network fee | 1-6 confirmations | Global |
| Ethereum (ETH) | $10 | Network fee | 12 confirmations | Global |
| USDT (TRC20) | $5 | $1 flat | Minutes | Global |
| USDC (Polygon) | $5 | $0.01 flat | Seconds | Global |
| M-Pesa | $1 | 1% | Instant | Kenya, Tanzania, etc. |
| Airtel Money | $1 | 1% | Instant | 14 African countries |
| MTN Mobile Money | $1 | 1% | Instant | 15+ African countries |
| Amazon Gift Card | $5 | 0% | Instant | Global |
| Google Play Gift Card | $5 | 0% | Instant | Global |
| Apple Gift Card | $5 | 0% | Instant | Global |
| Steam Gift Card | $5 | 0% | Instant | Global |
| Netflix Gift Card | $10 | 0% | Instant | Global |
| Spotify Gift Card | $10 | 0% | Instant | Global |
| Airtime Top-Up | $0.50 | 0% | Instant | 100+ countries |

**Backend:**
- `WithdrawalRequest` model: `user`, `method`, `amount_coins`, `amount_fiat`, `exchange_rate`, `status` (pending/processing/completed/rejected), `destination_detail` (encrypted), `fee`, `created_at`
- Exchange rate: admin-configurable, dynamic per VIP tier
- KYC trigger: cumulative withdrawals > $100 → require ID verification
- Admin dashboard: withdrawal queue with approve/reject actions

---

### 7.2 — Airtime Top-Up Integration
**Effort:** 1.5 days

Integrate Reloadly API or DingConnect for airtime:
- Detect user's country from phone number
- Show available carriers and denominations
- Instant top-up delivery
- Receipt stored in transaction history

---

### 7.3 — Charity & Social Impact
**CD:** CD1 (Epic Meaning), CD5 (Social Influence) | **Effort:** 1.5 days

**Mechanics:**
- Users donate coins to verified charity partners
- 100 coins = platform converts to $0.10 real donation
- Community milestones: "Vewra community has donated 1,000,000 coins = $1,000 to clean water projects!"
- Charity leaderboard: top donors
- Special charity badge for donors
- Seasonal charity campaigns: "December: 2x donation matching!"

**Backend:**
- `CharityPartner` model: `name`, `description`, `logo_url`, `is_active`
- `CharityCampaign` model: `partner`, `goal_coins`, `current_coins`, `start_date`, `end_date`
- `CharityDonation` model: `user`, `campaign`, `coins_donated`, `fiat_equivalent`
- `POST /api/v1/charity/donate/` — donate coins

---

## 🎨 PHASE 8: PERSONALIZATION & CREATIVE EXPRESSION (Week 17-18)

---

### 8.1 — Full Avatar Customizer
**CD:** CD3 (Empowerment), CD4 (Ownership) | **Effort:** 3 days

**Customizable Elements:**
- Face shape, skin tone
- Hairstyle (20+ options) + hair color
- Eyes, eyebrows, mouth
- Outfit tops (50+ options, some premium)
- Accessories: glasses, hats, earrings, necklaces
- Background: solid colors, gradients, scenes (unlockable)
- Pet companion (unlockable)

**Unlock Methods:**
- Level milestones
- Battle pass tiers
- Mystery box drops
- Shop purchases
- Achievement rewards
- Seasonal event exclusives

**Backend:**
- `AvatarItem` model: `type`, `name`, `image_url`, `rarity`, `unlock_method`, `unlock_config`
- `UserAvatar` model: stores current equipped items per slot
- `UserInventory` model: tracks owned avatar items
- `GET /api/v1/avatar/items/` — all items with ownership status
- `PUT /api/v1/avatar/equip/` — update equipped items

---

### 8.2 — Profile Customization
**CD:** CD3 (Empowerment), CD4 (Ownership), CD5 (Social) | **Effort:** 1.5 days

| Element | Options | Unlock |
|---------|---------|--------|
| Name Color | 20 colors | Shop, level rewards |
| Name Effect | Glow, Sparkle, Fire, Ice, Rainbow | Rare+ items |
| Profile Frame | 30+ animated frames | Battle pass, shop, achievements |
| Profile Background | 20+ themes | Level milestones, shop |
| Status Message | Custom text | Free |
| Badge Showcase | Choose 3 to display | Level unlocks slots |

---

### 8.3 — Collectible Card System
**CD:** CD4 (Ownership), CD7 (Unpredictability), CD5 (Social) | **Effort:** 2 days

**Mechanics:**
- Themed card sets: "Crypto Icons" (10 cards), "YouTube Legends" (8 cards), "Vewra Mascots" (12 cards), "Season 1 Memories" (15 cards)
- Cards obtained from: Mystery Boxes, Battle Pass tiers, achievements, events
- Rarities: Common, Uncommon, Rare, Epic, Legendary, Holo (animated)
- Complete a set → bonus reward (coins + exclusive badge)
- Duplicate cards → trade with friends or dissolve for coins
- Card viewer: full-screen with flip animation, rarity effects

**Backend:**
- `CardSet` model: `name`, `description`, `total_cards`, `completion_reward`, `theme`
- `Card` model: `set`, `card_number`, `name`, `rarity`, `image_url`, `is_holo`
- `UserCard` model: `user`, `card`, `quantity`, `acquired_at`, `acquired_from`

---

## 🔗 PHASE 9: WEB3 & ADVANCED (Week 19-20)

---

### 9.1 — Vewra Token ($VEWRA)
**CD:** CD4 (Ownership), CD1 (Epic Meaning) | **Effort:** 5 days

**Tokenomics:**
- Chain: Polygon (low fees, EVM-compatible, fast)
- Max supply: 1,000,000,000 $VEWRA
- Distribution:

| Category | % | Vesting |
|----------|---|---------|
| Community rewards | 40% | Released over 4 years |
| Team & advisors | 15% | 2-year cliff, 4-year linear |
| Ecosystem fund | 20% | Governance-controlled |
| Liquidity pool | 10% | Unlocked at TGE |
| Reserve | 15% | 5-year linear |

**Utility:**
- Stake $VEWRA for passive yield (APY from platform revenue share)
- Governance: vote on feature proposals, reward rates, charity partners
- Premium features: unlock with $VEWRA staking (no monthly fee)
- Discounted shop purchases when paying with $VEWRA
- Exclusive $VEWRA-only items and events
- Tipping: send $VEWRA to other users

**Backend:**
- Smart contracts: ERC-20 token, staking pool, governance (OpenZeppelin templates)
- `CryptoWallet` model: `user`, `wallet_address`, `chain`, `is_verified`
- Integration: Web3.py for server-side contract interaction
- `POST /api/v1/crypto/connect-wallet/` — link wallet
- `POST /api/v1/crypto/stake/` — stake tokens
- `POST /api/v1/crypto/claim-rewards/` — claim staking yield

---

### 9.2 — Soulbound NFT Achievements
**CD:** CD4 (Ownership), CD5 (Social), CD8 (Loss & Avoidance) | **Effort:** 3 days

**Mechanics:**
- Major achievements minted as soulbound NFTs (non-transferable)
- Stored in user's wallet; portable reputation across platforms
- Examples:
  - "Vewra Pioneer" — Minted to first 10,000 users
  - "Level 100" — Achievement NFT
  - "Diamond Recruiter" — Achievement NFT
  - "Season 1 Champion" — Tournament winner NFT
- NFT metadata includes: achievement details, date earned, rarity
- Can be displayed on OpenSea, Rarible, etc.

---

## 📊 PHASE 10: ENTERPRISE ADMIN & ANALYTICS (Week 21-22)

---

### 10.1 — Advanced Analytics Dashboard
**Effort:** 4 days

**Real-Time Metrics:**
- DAU, WAU, MAU (with trend lines)
- Revenue: ad revenue, coin purchases, subscriptions (MRR, ARR)
- Task completion rates by type, platform, time of day
- User acquisition: by channel, referral source, country, device
- Retention cohorts: Day 1, Day 7, Day 30, Day 90
- LTV per user segment
- Churn prediction: users inactive for 3+ days flagged

**Coin Economy Analytics:**
- Total coins in circulation
- Daily coin issuance vs. withdrawal (inflation/deflation)
- Coin velocity (how fast coins move)
- Exchange rate history
- Revenue per coin issued

**Fraud Analytics:**
- Flagged users count and trend
- Fraud detection accuracy
- VPN usage heatmap
- Multi-account clusters visualization

**Backend:**
- `AnalyticsEvent` model (or use existing + aggregate views)
- Materialized views for daily/weekly/monthly aggregates
- `GET /api/v1/admin/analytics/` — dashboard data
- Export to CSV/PDF

---

### 10.2 — A/B Testing Engine
**Effort:** 3 days

**Capabilities:**
- Test: reward rates, UI layouts, notification timing, quest difficulty, spin wheel weights
- Traffic split: configurable % per variant
- Metrics tracked: conversion rate, retention, revenue per user
- Statistical significance calculator built in
- Admin UI: create experiment, set variants, monitor results, declare winner

---

### 10.3 — Role-Based Access Control (RBAC)
**Effort:** 2 days

**Roles:**
| Role | Permissions |
|------|------------|
| Super Admin | Full access, system config, token management |
| Admin | User management, task management, analytics view |
| Moderator | Fraud review, content moderation, withdrawal approval |
| Support | View users, view transactions, respond to tickets |
| Creator | Creator dashboard, task submission, analytics for own tasks |
| Advertiser | Campaign management, spend tracking |

---

### 10.4 — Immutable Audit Log
**Effort:** 2 days

- Every admin action logged: who, what, when, old value, new value, IP
- Append-only table (no updates, no deletes)
- Especially critical for: balance adjustments, withdrawal approvals, user bans
- `AuditLog` model: `actor`, `action`, `target_type`, `target_id`, `old_value` (JSON), `new_value` (JSON), `ip_address`, `created_at`

---

## 📋 PHASE 11: QUALITY & POLISH (Ongoing)

---

### 11.1 — TypeScript Migration for Admin Frontend
**Effort:** 5 days

- Convert all `.jsx` to `.tsx`
- Define interfaces for all API responses
- Strict mode enabled
- This catches bugs at compile time and improves developer experience

---

### 11.2 — Comprehensive Test Suite
**Effort:** 5 days

- Backend: pytest with 80%+ coverage
  - Unit tests for RewardCalculator, process_watch_progress
  - Integration tests for all API endpoints
  - Load tests: locust for 1000 concurrent users watching
- Frontend: Vitest + React Testing Library
- Mobile: Flutter widget tests + integration tests

---

### 11.3 — Performance Optimization
**Effort:** 3 days

- Database query optimization: eliminate N+1 queries (django-debug-toolbar audit)
- Redis caching for hot queries
- CDN for static assets
- Image optimization: WebP format, lazy loading
- Code splitting in admin frontend (React.lazy + Suspense)
- API response pagination audit (all list endpoints)

---

### 11.4 — Accessibility (WCAG 2.1 AA)
**Effort:** 3 days

- Keyboard navigation for admin dashboard
- Screen reader support (ARIA labels)
- Color contrast ratios
- Focus indicators
- Mobile accessibility audit

---

## 📅 SUMMARY: IMPLEMENTATION SEQUENCE

```
Week  1-2:  ⚠️  Phase 0  — Critical Fixes (DB, secrets, CORS, rate limiting, auth, logging, CI/CD, Docker, Redis, Celery, anti-fraud, idempotency, API docs)
Week  3-4:  🚀  Phase 1  — Engagement Core Loop (daily login, spin wheel, XP/levels, badges, daily quests, streak freeze, lucky drop, scratch card)
Week  5-6:  🏆  Phase 2  — Competition & Social (leaderboard, referral 2.0, guilds, watch party, friends feed)
Week  7-8:  💎  Phase 3  — Mystery & Surprise (mystery boxes, golden video, bonus multiplier, gift drops)
Week  9-10: 🛡️  Phase 4  — SMM Task Engine (social media microtasks, offerwall, surveys, daily poll)
Week 11-12: 📦  Phase 5  — Battle Pass & Monetization (monthly pass, VIP tiers, shop, creator sponsorship)
Week 13-14: 📱  Phase 6  — Mobile & Platform (Flutter full build, push notifications, PWA)
Week 15-16: 💸  Phase 7  — Withdrawals & Real-World (expanded payout options, airtime, charity)
Week 17-18: 🎨  Phase 8  — Personalization (avatar customizer, profile themes, collectible cards)
Week 19-20: 🔗  Phase 9  — Web3 & Advanced ($VEWRA token, NFT badges, staking, governance)
Week 21-22: 📊  Phase 10 — Enterprise Admin (analytics, A/B testing, RBAC, audit log)
Ongoing:   📋  Phase 11 — Quality & Polish (TypeScript, tests, performance, accessibility)
```

---

> **Total:** 22 weeks from MVP to enterprise-grade gamified reward + SMM platform.
>
> **Parallelization potential:** Phases 4-5 can overlap. Phases 8-9 can overlap. Mobile can start earlier with a dedicated mobile developer alongside backend work.