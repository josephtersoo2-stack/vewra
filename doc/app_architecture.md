# App Architecture – YouTube Task & Rewards Platform

## 1. Project Overview

This is a cross-platform mobile application where users complete guided YouTube watching tasks to earn virtual coins. The system includes membership, wallet, rewards, and referral systems.

**Core Principle**: Users must discover admin-approved videos through randomized search instructions. Only approved videos give rewards. Progress is persistent and rewards are progressive.

---

## 2. Tech Stack

### Mobile App
- **Framework**: Flutter
- **WebView**: `flutter_inappwebview` (advanced JS injection + tracking)
- **State Management**: Riverpod or Bloc
- **Local Storage**: Hive or Shared Preferences + Secure Storage
- **Networking**: Dio
- **Auth Token**: Flutter Secure Storage

### Backend
- **Framework**: Django 5.x + Django REST Framework
- **Authentication**: SimpleJWT
- **Task Queue**: Celery + Redis
- **Database**: PostgreSQL
- **Admin**: Django Admin (later custom admin if needed)

### Infrastructure
- Redis (Celery + caching)
- PostgreSQL
- Optional: S3 / Cloudflare R2 for media

---

## 3. High-Level Architecture

```text
Flutter App
│
├── Authentication
├── Task List (Approved Videos)
├── In-App Browser (WebView)
├── Tracking Engine (JS Injection)
└── Wallet / Profile / Referral
│
▼
Django REST API
│
├── Users & Auth
├── Video Tasks
├── Watch Sessions & Events
├── Wallet (Ledger)
├── Rewards Engine
├── Membership
└── Referral
│
▼
PostgreSQL + Redis + Celery
```

---

## 4. Core Domains

### 4.1 Users & Authentication
- Custom User model
- JWT authentication
- Profile data

### 4.2 Video Tasks (Phase 1 Core)
- Admin creates video tasks
- Fields: youtube_url, video_id, title, keywords, thumbnail, reward_type, reward_config
- Reward Types:
  - `per_time`
  - `watch_all`
  - `target`

### 4.3 Watch Session & Tracking
- One WatchSession per user per video
- Stores: current_position, total_watched_seconds, is_completed, last_watched_at
- WatchEvents for detailed logs (optional for high accuracy)
- Progress is cumulative and only moves forward

### 4.4 Wallet System
- Wallet model (one per user)
- WalletTransaction (ledger) – never update balance directly
- Transaction types: earn, spend, adjustment, referral, etc.

### 4.5 Rewards Engine
- Rule-based system
- Triggered by events (watch progress, referral success, daily login, etc.)

### 4.6 Membership
- Plan model
- Subscription model
- Feature flags / permissions per plan

### 4.7 Referral
- Unique referral code per user
- Referral relationship tracking
- Reward on successful referral

---

## 5. Database Models (Key Ones)

### User
- id, email, username, password, date_joined, is_active, etc.

### VideoTask
- id
- youtube_url
- video_id (extracted)
- title
- keywords (JSONField)
- thumbnail_url
- reward_type (per_time | watch_all | target)
- reward_config (JSONField) – e.g. {"coins_per_seconds": 10, "seconds": 60}
- is_active
- created_at

### WatchSession
- id
- user (FK)
- video_task (FK)
- current_position (Float) – highest position reached in seconds
- total_watched_seconds (Float)
- is_completed (Boolean)
- last_watched_at
- created_at
- updated_at

### Wallet
- id
- user (OneToOne)
- balance (Decimal)
- updated_at

### WalletTransaction
- id
- wallet (FK)
- amount (Decimal) – positive = earn, negative = spend
- balance_after
- transaction_type
- reference (GenericForeignKey or JSON)
- description
- created_at

### Referral
- id
- referrer (FK)
- referred_user (FK)
- status
- rewarded (Boolean)
- created_at

---

## 6. YouTube Tracking Flow (Phase 1)

1. User opens a VideoTask
2. Backend returns a randomized instruction (from keywords/title)
3. App opens WebView with YouTube
4. JavaScript injection continuously reads current video ID and player time
5. When correct `video_id` is detected → start/resume session
6. App sends periodic progress updates to backend:
   - current_time
   - delta_watched
7. Backend:
   - Updates WatchSession (only increases current_position and total_watched_seconds)
   - Calculates coins earned based on reward_type
   - Creates WalletTransaction if coins > 0
8. When completion condition is met → mark as completed and stop further earnings

---

## 7. API Structure (Initial)

### Auth
- POST /api/v1/auth/register/
- POST /api/v1/auth/login/
- POST /api/v1/auth/refresh/
- GET  /api/v1/auth/me/

### Video Tasks
- GET  /api/v1/tasks/                  → list active tasks
- GET  /api/v1/tasks/{id}/             → task detail + randomized instruction
- POST /api/v1/tasks/{id}/start/       → create/get WatchSession

### Tracking
- POST /api/v1/tracking/progress/      → send progress updates (batch friendly)

### Wallet
- GET  /api/v1/wallet/
- GET  /api/v1/wallet/transactions/

---

## 8. Flutter App Structure

```text
lib/
├── main.dart
├── app/
├── core/
│   ├── constants/
│   ├── network/
│   ├── utils/
│   └── theme/
├── features/
│   ├── auth/
│   ├── tasks/
│   ├── browser/          ← WebView + JS tracking
│   ├── wallet/
│   ├── profile/
│   └── referral/
├── models/
└── services/
```

---

## 9. Phase Breakdown

### Phase 1 (Current Focus)
- User Auth
- VideoTask (Admin via Django Admin for now)
- WatchSession + Progress tracking
- In-app browser with detection + second-by-second tracking
- Basic Wallet (earn only from watching)
- Randomized search instructions

### Phase 2
- Full Membership
- Referral system
- Better Rewards Engine
- Daily tasks

### Phase 3
- Admin Dashboard (custom)
- Store / Spending coins
- Advanced analytics
- Push notifications

---

## 10. Important Business Rules

- User can only earn on admin-approved videos
- Progress only moves forward
- No double earning after completion
- Different users can receive different search instructions for the same video
- Browser is fully free (user can browse anywhere)
- Tracking only activates on the correct video_id

---

## 11. Security Notes

- All tracking endpoints require authentication
- Validate video_id against the assigned task
- Rate limit progress updates
- Use ledger for all coin movements
- Never trust client-side coin calculations (backend is source of truth)
