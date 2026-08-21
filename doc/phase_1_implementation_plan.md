# Vewra – Phase 1 Implementation Plan

**Version:** 1.0  
**Status:** Ready for Development  
**Goal:** Build and fully test the core YouTube Task + Tracking system before adding Membership, Referral, or advanced Rewards.

---

## 1. Phase 1 Scope

### Included
- User Authentication (Register / Login / JWT)
- Video Tasks (Admin-managed)
- Randomized search instructions
- Full in-app browser (YouTube)
- Accurate video ID detection
- Second-by-second watch tracking
- Progress persistence (pause & resume)
- Basic Wallet + Coin earning
- Multiple reward types support
- Django Admin for managing videos

### Explicitly Excluded (Phase 2+)
- Membership / Subscriptions
- Referral system
- Daily tasks / Quests
- Spending coins
- Custom Admin Dashboard
- Push notifications
- Leaderboards

---

## 2. User Flow (Phase 1)

1. User registers / logs in
2. User lands on **Tasks** screen → sees list of active video tasks (thumbnail + title)
3. User taps a task
4. App shows a **randomized instruction** (e.g. “Search for: keyword1 keyword2”)
5. User taps “Start Task” → full-screen in-app browser opens
6. User freely browses YouTube and searches according to the instruction
7. When the correct video ID is detected → tracking starts automatically
8. User can play, pause, seek, leave the app, and come back later
9. Progress is saved and only new watched time is rewarded
10. Coins are credited according to the reward type of that video
11. Once the video is completed (according to its rule), no more coins can be earned from it

---

## 3. Database Design (Django Models)

### 3.1 User
Use Django’s default User or a simple custom user.

### 3.2 VideoTask
```python
class VideoTask(models.Model):
    youtube_url = models.URLField()
    video_id = models.CharField(max_length=20, unique=True, db_index=True)
    title = models.CharField(max_length=300)
    keywords = models.JSONField(default=list)          # list of strings
    thumbnail_url = models.URLField(blank=True)
    
    reward_type = models.CharField(max_length=20, choices=[
        ('per_time', 'Per Time'),
        ('watch_all', 'Watch All'),
        ('target', 'Target'),
    ])
    
    # Examples of reward_config:
    # per_time  → {"coins": 10, "seconds": 60}
    # watch_all → {"coins": 150}
    # target    → {"coins": 100, "target_seconds": 300}  or {"coins": 100, "target_percent": 80}
    reward_config = models.JSONField(default=dict)
    
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
```

### 3.3 WatchSession
```python
class WatchSession(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='watch_sessions')
    video_task = models.ForeignKey(VideoTask, on_delete=models.CASCADE, related_name='sessions')
    
    current_position = models.FloatField(default=0)          # highest second reached
    total_watched_seconds = models.FloatField(default=0)     # total unique seconds watched
    is_completed = models.BooleanField(default=False)
    
    last_watched_at = models.DateTimeField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        unique_together = ('user', 'video_task')
```

### 3.4 Wallet
```python
class Wallet(models.Model):
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name='wallet')
    balance = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    updated_at = models.DateTimeField(auto_now=True)
```

### 3.5 WalletTransaction
```python
class WalletTransaction(models.Model):
    wallet = models.ForeignKey(Wallet, on_delete=models.CASCADE, related_name='transactions')
    amount = models.DecimalField(max_digits=12, decimal_places=2)   # positive = earn
    balance_after = models.DecimalField(max_digits=12, decimal_places=2)
    transaction_type = models.CharField(max_length=30, default='watch_reward')
    description = models.CharField(max_length=255)
    reference_id = models.CharField(max_length=50, blank=True)     # e.g. session id
    created_at = models.DateTimeField(auto_now_add=True)
```

---

## 4. API Endpoints (Phase 1)

### Authentication
- `POST /api/v1/auth/register/`
- `POST /api/v1/auth/login/`
- `POST /api/v1/auth/refresh/`
- `GET  /api/v1/auth/me/`

### Video Tasks
- `GET /api/v1/tasks/`  
  → List all active VideoTasks (id, title, thumbnail, reward summary)

- `GET /api/v1/tasks/{id}/`  
  → Task detail + **randomized instruction** for this user

- `POST /api/v1/tasks/{id}/start/`  
  → Create or return existing WatchSession for this user + task

### Tracking
- `POST /api/v1/tracking/progress/`  
  Body example:
  ```json
  {
    "session_id": 12,
    "current_time": 187.5,
    "delta_seconds": 12.3
  }
  ```
  Backend will:
  - Validate session belongs to user
  - Only increase `current_position` and `total_watched_seconds`
  - Calculate coins earned
  - Create WalletTransaction if coins > 0
  - Mark as completed if rule is satisfied

### Wallet
- `GET /api/v1/wallet/`
- `GET /api/v1/wallet/transactions/`

---

## 5. Reward Calculation Rules

### per_time
- Example config: `{"coins": 10, "seconds": 60}`
- Every 60 new seconds watched → +10 coins
- Only count seconds above previous `total_watched_seconds`

### watch_all
- Example config: `{"coins": 200}`
- User must reach near the end of the video (e.g. 95%+)
- Award full coins once and mark completed

### target
- Example config: `{"coins": 120, "target_seconds": 300}`
- When `total_watched_seconds >= target_seconds` → award coins and complete

**Important Rules**
- Never decrease `current_position` or `total_watched_seconds`
- Once `is_completed = True` → no more coins can be earned from that video
- Backend is the single source of truth for coin calculation

---

## 6. Flutter App Structure (Phase 1)

```
lib/
├── main.dart
├── app.dart
├── core/
│   ├── constants/
│   ├── network/          # Dio client + interceptors
│   ├── theme/
│   └── utils/
├── features/
│   ├── auth/
│   │   ├── data/
│   │   ├── presentation/
│   │   └── domain/
│   ├── tasks/
│   │   ├── data/
│   │   ├── presentation/  # Task list + Task detail
│   │   └── domain/
│   ├── browser/
│   │   ├── presentation/  # Full screen WebView
│   │   └── tracking/      # JS injection + event handling
│   ├── wallet/
│   └── profile/
├── models/
└── services/
```

### Key Screens
1. Login / Register
2. Tasks List
3. Task Detail (shows randomized instruction)
4. Full-screen Browser (WebView)
5. Wallet / Balance (simple)
6. Profile (basic)

---

## 7. In-App Browser & Tracking Requirements

- Use `flutter_inappwebview`
- Allow full YouTube experience (login, search, browse freely)
- Inject JavaScript that:
  - Detects current video ID
  - Listens to play / pause / timeupdate / seek
  - Sends currentTime to Flutter every 3–5 seconds or on important events
- When correct `video_id` is detected → notify Flutter to start/resume session
- Flutter sends progress updates to backend periodically
- Handle app backgrounding / closing gracefully (save last position)

---

## 8. Admin Side (Phase 1)

Use **Django Admin** to:
- Create / Edit / Activate VideoTasks
- View WatchSessions
- View WalletTransactions

Later we will build a proper admin dashboard.

---

## 9. Acceptance Criteria (Phase 1 Done When)

- [ ] User can register and login
- [ ] Admin can create VideoTasks via Django Admin
- [ ] User sees list of active tasks
- [ ] User receives a randomized search instruction
- [ ] In-app browser works like normal mobile Chrome
- [ ] App correctly detects when the target video is opened
- [ ] Watch progress is saved and can be resumed
- [ ] Coins are correctly calculated and added to wallet
- [ ] User cannot earn more after a video is completed
- [ ] Watching wrong videos gives zero coins
- [ ] All APIs are protected with JWT

---

## 10. Technical Notes

- Extract `video_id` from YouTube URL on the backend when creating a VideoTask
- Use `select_for_update()` or proper locking when updating WatchSession + Wallet
- Rate-limit the progress endpoint
- Log important tracking events for debugging
- Make reward calculation pure and unit-testable
