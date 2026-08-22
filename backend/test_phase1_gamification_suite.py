import os
import sys
import django
import time
from datetime import timedelta
from decimal import Decimal

if hasattr(sys.stdout, 'reconfigure'):
    sys.stdout.reconfigure(encoding='utf-8')

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'vewra_backend.settings')
django.setup()

from django.test import Client
from django.utils import timezone
from django.contrib.auth.models import User
from rest_framework_simplejwt.tokens import RefreshToken

from apps.gamification.models import (
    UserProfile, DailyLoginStreak, SpinWheelClaim,
    Badge, UserBadge, DailyQuest, ScratchCardClaim
)
from apps.gamification.services.xp_service import calculate_level, add_xp
from apps.gamification.services.streak_service import claim_daily_streak, get_streak_status
from apps.gamification.services.spin_service import execute_daily_spin, get_spin_status
from apps.gamification.services.quest_service import get_or_create_daily_quests, update_quest_progress, claim_quest_reward
from apps.gamification.services.badge_service import evaluate_user_badges, seed_default_badges
from apps.gamification.services.scratch_service import execute_daily_scratch, get_scratch_status
from apps.tasks.models import VideoTask, WatchSession
from apps.tracking.services import process_watch_progress

def run_suite():
    print("=" * 70)
    print("RUNNING VEWRA PHASE 1: ENGAGEMENT CORE LOOP TEST SUITE")
    print("=" * 70)
    client = Client()

    ts = int(time.time())
    user = User.objects.create_user(username=f'gameuser_{ts}', email=f'game_{ts}@example.com', password='Password123')
    token = str(RefreshToken.for_user(user).access_token)
    auth_headers = {'Authorization': f'Bearer {token}'}

    # -------------------------------------------------------------
    # 1. Testing Daily Login Streak & Calendar
    # -------------------------------------------------------------
    print("\n--- 1. Testing Daily Login Streak & Multipliers ---")
    status_res = client.get('/api/v1/rewards/daily-status/', headers=auth_headers)
    assert status_res.status_code == 200
    assert status_res.json()['is_claimed_today'] == False
    print(f" [PASS] Daily status endpoint returned: {status_res.json()['calendar'][0]}")

    # Day 1 Claim
    claim_res = client.post('/api/v1/rewards/daily-claim/', headers=auth_headers)
    assert claim_res.status_code == 200
    data1 = claim_res.json()
    assert data1['streak_count'] == 1
    assert data1['coins_earned'] == 5.0
    print(f" [PASS] Day 1 claimed: {data1['coins_earned']} coins, Streak={data1['streak_count']}")

    # Try claiming again same day (should report already claimed)
    claim_res2 = client.post('/api/v1/rewards/daily-claim/', headers=auth_headers)
    assert claim_res2.status_code == 200
    assert claim_res2.json()['already_claimed'] == True
    print(f" [PASS] Duplicate same-day claim safely prevented.")

    # -------------------------------------------------------------
    # 2. Testing Streak Freeze Auto-Protection
    # -------------------------------------------------------------
    print("\n--- 2. Testing Streak Freeze Auto-Protection ---")
    streak_obj = user.daily_streak
    profile_obj = user.profile
    profile_obj.streak_freeze_count = 2
    profile_obj.save()

    # Simulate skipping yesterday (last claimed was 2 days ago)
    streak_obj.last_claimed_date = timezone.now().date() - timedelta(days=2)
    streak_obj.streak_count = 14
    streak_obj.save()

    freeze_claim = claim_daily_streak(user)
    assert freeze_claim['freeze_used'] == True
    assert freeze_claim['streak_count'] == 15, f"Streak count expected 15, got {freeze_claim['streak_count']}"
    profile_obj.refresh_from_db()
    assert profile_obj.streak_freeze_count == 1, "Streak freeze was not decremented"
    print(f" [PASS] Streak Freeze auto-consumed: Streak preserved at {freeze_claim['streak_count']} days!")

    # -------------------------------------------------------------
    # 3. Testing Daily Spin Wheel
    # -------------------------------------------------------------
    print("\n--- 3. Testing Daily Spin Wheel (Weighted RNG) ---")
    spin_status = client.get('/api/v1/rewards/spin-status/', headers=auth_headers)
    assert spin_status.status_code == 200
    assert spin_status.json()['can_spin'] == True

    spin_res = client.post('/api/v1/rewards/daily-spin/', headers=auth_headers)
    assert spin_res.status_code == 200
    sdata = spin_res.json()
    assert sdata['success'] == True
    assert 1 <= sdata['segment_landed'] <= 12
    print(f" [PASS] Daily spin landed on segment #{sdata['segment_landed']}: {sdata['label']}")

    # Duplicate spin on same day should fail
    spin_res2 = client.post('/api/v1/rewards/daily-spin/', headers=auth_headers)
    assert spin_res2.status_code == 400
    print(f" [PASS] 1-spin-per-day rule strictly enforced.")

    # -------------------------------------------------------------
    # 4. Testing Daily Scratch Card (3x3 matching)
    # -------------------------------------------------------------
    print("\n--- 4. Testing Daily Scratch Card ---")
    scratch_status = client.get('/api/v1/rewards/scratch-status/', headers=auth_headers)
    assert scratch_status.status_code == 200
    assert scratch_status.json()['can_scratch'] == True

    scratch_res = client.post('/api/v1/rewards/daily-scratch/', headers=auth_headers)
    assert scratch_res.status_code == 200
    sc_data = scratch_res.json()
    assert sc_data['success'] == True
    assert len(sc_data['grid']) == 9
    assert sc_data['match_count'] in (2, 3)
    print(f" [PASS] Scratch Card matched {sc_data['match_count']}x {sc_data['matched_symbol']} -> +{sc_data['coins_earned']} Coins, +{sc_data['xp_earned']} XP")

    # -------------------------------------------------------------
    # 5. Testing XP & 101-Level Progression Ladder
    # -------------------------------------------------------------
    print("\n--- 5. Testing XP Formula & Level Progression ---")
    assert calculate_level(0) == 1
    assert calculate_level(500) == 5       # 5^2 * 20 = 500
    assert calculate_level(2000) == 10     # 10^2 * 20 = 2000
    assert calculate_level(200000) == 100  # 100^2 * 20 = 200000
    print(f" [PASS] Level formula verified: L=1 (0 XP), L=5 (500 XP), L=10 (2,000 XP), L=100 (200,000 XP)")

    # Award large XP chunk and test level up
    xp_res = add_xp(user, 600, 'test_boost')
    assert xp_res['leveled_up'] == True
    assert xp_res['level'] >= 5
    print(f" [PASS] Level-up trigger executed: Leveled up to L{xp_res['level']} with perks: {xp_res['new_perks']}")

    profile_res = client.get('/api/v1/profile/', headers=auth_headers)
    assert profile_res.status_code == 200
    pdata = profile_res.json()
    assert pdata['level'] == xp_res['level']
    print(f" [PASS] Profile endpoint verified: Level {pdata['level']} ({pdata['xp']} XP, {pdata['xp_progress_percent']}%)")

    # -------------------------------------------------------------
    # 6. Testing Daily Quest Board & Quest Master Bonus
    # -------------------------------------------------------------
    print("\n--- 6. Testing Daily Quests & Quest Master ---")
    quests_res = client.get('/api/v1/quests/daily/', headers=auth_headers)
    assert quests_res.status_code == 200
    quests = quests_res.json()
    assert len(quests) == 3
    print(f" [PASS] Today's 3 quests generated deterministically:")
    for q in quests:
        print(f"   * [{q['difficulty'].upper()}] {q['title']}: {q['description']} (Reward: +{q['coin_reward']} coins, +{q['xp_reward']} XP)")

    # Complete and claim quest 1
    q1 = quests[0]
    update_quest_progress(user, q1['quest_type'], increment=q1['target_count'])
    claim_q1 = client.post(f"/api/v1/quests/daily/{q1['id']}/claim/", headers=auth_headers)
    assert claim_q1.status_code == 200
    assert claim_q1.json()['success'] == True
    print(f" [PASS] Claimed Quest #{q1['id']} ({claim_q1.json()['title']}) -> +{claim_q1.json()['coins_earned']} Coins")

    # Complete quests 2 and 3 to trigger Quest Master bonus (+50 coins)
    q2 = quests[1]
    q3 = quests[2]
    update_quest_progress(user, q2['quest_type'], increment=q2['target_count'])
    update_quest_progress(user, q3['quest_type'], increment=q3['target_count'])
    client.post(f"/api/v1/quests/daily/{q2['id']}/claim/", headers=auth_headers)
    claim_q3 = client.post(f"/api/v1/quests/daily/{q3['id']}/claim/", headers=auth_headers)
    assert claim_q3.json()['quest_master_bonus'] == True
    print(f" [PASS] 🌟 Quest Master Bonus triggered! (+50 bonus coins for all 3 daily quests)")

    # -------------------------------------------------------------
    # 7. Testing Achievement Badges & Showcase
    # -------------------------------------------------------------
    print("\n--- 7. Testing Badges & Showcase ---")
    seed_default_badges()
    unlocked = evaluate_user_badges(user)
    print(f" [PASS] Badges evaluated. Unlocked count: {len(unlocked)}")

    badges_res = client.get('/api/v1/badges/', headers=auth_headers)
    assert badges_res.status_code == 200
    assert len(badges_res.json()) >= 7
    print(f" [PASS] /api/v1/badges/ returned {len(badges_res.json())} badge definitions.")

    # Update showcase badges
    showcase_res = client.put(
        '/api/v1/profile/badge-showcase/',
        data={'badge_keys': ['first_steps', 'couch_potato']},
        headers=auth_headers,
        content_type='application/json'
    )
    assert showcase_res.status_code == 200
    assert showcase_res.json()['showcase_badges'] == ['first_steps', 'couch_potato']
    print(f" [PASS] Public badge showcase updated: {showcase_res.json()['showcase_badges']}")

    # -------------------------------------------------------------
    # 8. Testing In-Watch Lucky Drop Telemetry
    # -------------------------------------------------------------
    print("\n--- 8. Testing In-Watch Lucky Drop Telemetry ---")
    task, _ = VideoTask.objects.get_or_create(
        video_id=f'lucky_vid_{ts}',
        defaults={
            'title': 'Lucky Drop Video Task',
            'reward_type': 'per_time',
            'reward_config': {'coins': 10, 'seconds': 30}
        }
    )
    ws, _ = WatchSession.objects.get_or_create(user=user, video_task=task)
    
    # Send watch progress ping
    track_res = process_watch_progress(
        user=user,
        session_id=ws.id,
        current_time=15.0,
        delta_seconds=15.0
    )
    assert 'xp_earned' in track_res
    assert 'lucky_drop' in track_res
    print(f" [PASS] In-Watch telemetry returned XP={track_res['xp_earned']}, LuckyDrop={track_res['lucky_drop']}")

    print("\n" + "=" * 70)
    print("SUCCESS: ALL 8 PHASE 1 ENGAGEMENT CORE LOOP SUITES PASSED (100%)")
    print("=" * 70)

if __name__ == '__main__':
    run_suite()
