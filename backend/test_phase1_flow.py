import os
import sys
import time
import requests
import json

BASE_URL = "http://127.0.0.1:8001"


os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'vewra_backend.settings')
import django
django.setup()

from apps.tasks.models import VideoTask
from apps.wallet.models import Wallet, WalletTransaction
from django.contrib.auth.models import User

def test_phase1_checklist():
    print("=" * 70)
    print("RUNNING VEWRA PHASE 1 END-TO-END AUTOMATED TEST SUITE")
    print("=" * 70)

    # ----------------------------------------------------------------
    # 1. Backend & Admin Setup
    # ----------------------------------------------------------------
    print("\n--- 1. Testing Backend & Admin Setup ---")
    admin_res = requests.get(f"{BASE_URL}/admin/login/")
    assert admin_res.status_code == 200, f"Admin login page returned {admin_res.status_code}"
    print(" [PASS] Django server is running and /admin/ is accessible.")

    # ----------------------------------------------------------------
    # 2. Check / Seed the 3 Required Test Tasks
    # ----------------------------------------------------------------
    print("\n--- 2. Setting Up & Verifying Test Video Tasks ---")

    task_a, _ = VideoTask.objects.update_or_create(
        video_id='dQw4w9WgXcQ',
        defaults={
            'youtube_url': 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
            'title': 'Task A - Progressive Earning Music Video',
            'keywords': ['Rick Astley', 'music', 'never gonna give you up', 'pop'],
            'reward_type': 'per_time',
            'reward_config': {'coins': 10, 'seconds': 60},
            'thumbnail_url': 'https://img.youtube.com/vi/dQw4w9WgXcQ/hqdefault.jpg',
            'is_active': True,
        }
    )
    print(f" [PASS] Task A (per_time): '{task_a.title}' -> Config: {task_a.reward_config}")

    task_b, _ = VideoTask.objects.update_or_create(
        video_id='L_LUpnjgPso',
        defaults={
            'youtube_url': 'https://www.youtube.com/watch?v=L_LUpnjgPso',
            'title': 'Task B - Full Watch Flutter Video',
            'keywords': ['flutter', 'fireship', 'tutorial', 'mobile'],
            'reward_type': 'watch_all',
            'reward_config': {'coins': 100, 'duration': 180, 'target_percent': 95},
            'thumbnail_url': 'https://img.youtube.com/vi/L_LUpnjgPso/hqdefault.jpg',
            'is_active': True,
        }
    )
    print(f" [PASS] Task B (watch_all): '{task_b.title}' -> Config: {task_b.reward_config}")

    task_c, _ = VideoTask.objects.update_or_create(
        video_id='y881t8ilMyc',
        defaults={
            'youtube_url': 'https://www.youtube.com/watch?v=y881t8ilMyc',
            'title': 'Task C - Target Python Video',
            'keywords': ['python', 'programming', 'course', 'beginners'],
            'reward_type': 'target',
            'reward_config': {'coins': 50, 'target_seconds': 120},
            'thumbnail_url': 'https://img.youtube.com/vi/y881t8ilMyc/hqdefault.jpg',
            'is_active': True,
        }
    )
    print(f" [PASS] Task C (target): '{task_c.title}' -> Config: {task_c.reward_config}")

    # ----------------------------------------------------------------
    # 3. Authentication (Register, Login, Token Refresh, Profile)
    # ----------------------------------------------------------------
    print("\n--- 3. Testing Authentication Flow ---")
    unique_user = f"tester_{int(time.time())}"
    email = f"{unique_user}@vewra.com"
    password = "password123"

    # Register
    reg_res = requests.post(f"{BASE_URL}/api/v1/auth/register/", json={
        "username": unique_user,
        "email": email,
        "password": password
    })
    assert reg_res.status_code == 201, f"Registration failed: {reg_res.text}"
    reg_data = reg_res.json()
    access_token = reg_data['tokens']['access']
    refresh_token = reg_data['tokens']['refresh']
    print(f" [PASS] User '{unique_user}' registered successfully. Initial balance: {reg_data['user']['wallet_balance']}")

    # Login
    login_res = requests.post(f"{BASE_URL}/api/v1/auth/login/", json={
        "username": unique_user,
        "password": password
    })
    assert login_res.status_code == 200, f"Login failed: {login_res.text}"
    print(" [PASS] User login verified. JWT tokens received.")

    # Token Refresh
    ref_res = requests.post(f"{BASE_URL}/api/v1/auth/refresh/", json={
        "refresh": refresh_token
    })
    assert ref_res.status_code == 200, f"Token refresh failed: {ref_res.text}"
    new_access_token = ref_res.json()['access']
    auth_headers = {"Authorization": f"Bearer {new_access_token}"}
    print(" [PASS] Token refresh successful. Using renewed JWT access token.")

    # Me profile
    me_res = requests.get(f"{BASE_URL}/api/v1/auth/me/", headers=auth_headers)
    assert me_res.status_code == 200
    assert me_res.json()['username'] == unique_user
    print(" [PASS] /api/v1/auth/me/ returned authenticated profile.")

    # ----------------------------------------------------------------
    # 4. Tasks Screen Listing
    # ----------------------------------------------------------------
    print("\n--- 4. Testing Tasks Listing Endpoint ---")
    tasks_res = requests.get(f"{BASE_URL}/api/v1/tasks/", headers=auth_headers)
    assert tasks_res.status_code == 200
    tasks_list = tasks_res.json()
    assert len(tasks_list) >= 3
    print(f" [PASS] /api/v1/tasks/ returned {len(tasks_list)} active tasks with reward summaries:")
    for t in tasks_list:
        print(f"   * {t['title']} | Reward: {t['reward_summary']} | Completed: {t['is_completed_by_user']}")

    # ----------------------------------------------------------------
    # 5. Task Detail + Randomized Instructions
    # ----------------------------------------------------------------
    print("\n--- 5. Testing Task Detail & Randomized Instructions ---")
    detail_res1 = requests.get(f"{BASE_URL}/api/v1/tasks/{task_a.id}/", headers=auth_headers)
    assert detail_res1.status_code == 200
    detail_data1 = detail_res1.json()
    assert 'instruction' in detail_data1
    instruction = detail_data1['instruction']
    sq = instruction.get('searchQuery') or instruction.get('search_query')
    print(f" [PASS] Task Detail loaded with search query: \"{sq}\"")

    # ----------------------------------------------------------------
    # 6 & 7. In-App Browser Tracking & Reward Logic
    # ----------------------------------------------------------------
    print("\n--- 6 & 7. Testing In-App Browser Tracking & Rewards ---")

    # Start Session for Task A (per_time)
    start_a = requests.post(f"{BASE_URL}/api/v1/tasks/{task_a.id}/start/", headers=auth_headers)
    assert start_a.status_code in [200, 201]
    session_a = start_a.json()['session']
    session_a_id = session_a['id']
    print(f" [PASS] WatchSession for Task A started (ID: {session_a_id})")

    # Ping 1: 30s watched (below 60s interval -> 0 coins)
    p1 = requests.post(f"{BASE_URL}/api/v1/tracking/progress/", headers=auth_headers, json={
        "session_id": session_a_id,
        "current_time": 30.0,
        "delta_seconds": 30.0 # Will be clamped to 15s by backend safety
    }).json()
    print(f"   Ping 1 (30s requested, clamped to 15s): Watched={p1['total_watched_seconds']}s, Coins={p1['coins_earned']}, Bal={p1['wallet_balance']}")
    assert p1['coins_earned'] == 0.0
    assert p1['total_watched_seconds'] == 15.0

    # Simulate subsequent 10s pings: 15 -> 25 -> 35 -> 45 -> 55 -> 65s (crosses 60s -> +10 coins)
    for cur_t in [25.0, 35.0, 45.0, 55.0, 65.0]:
        p = requests.post(f"{BASE_URL}/api/v1/tracking/progress/", headers=auth_headers, json={
            "session_id": session_a_id,
            "current_time": cur_t,
            "delta_seconds": 10.0
        }).json()

    print(f"   Ping at 65s (crossed 60s): Watched={p['total_watched_seconds']}s, Coins={p['coins_earned']}, Bal={p['wallet_balance']}")
    assert p['coins_earned'] == 10.0
    assert p['wallet_balance'] == 10.0
    print(" [PASS] Task A (per_time) awarded +10 coins at 60s boundary.")

    # Cross 120s boundary: 65 -> 75 -> 85 -> 95 -> 105 -> 115 -> 125s (crosses 120s -> +10 coins)
    for cur_t in [75.0, 85.0, 95.0, 105.0, 115.0, 125.0]:
        p = requests.post(f"{BASE_URL}/api/v1/tracking/progress/", headers=auth_headers, json={
            "session_id": session_a_id,
            "current_time": cur_t,
            "delta_seconds": 10.0
        }).json()

    print(f"   Ping at 125s (crossed 120s): Watched={p['total_watched_seconds']}s, Coins={p['coins_earned']}, Bal={p['wallet_balance']}")
    assert p['coins_earned'] == 10.0
    assert p['wallet_balance'] == 20.0
    print(" [PASS] Task A (per_time) awarded +10 more coins (total: 20 coins).")

    # --- Task B (watch_all: 180s duration, 95% = 171s, 100 coins) ---
    print("\n--- Testing Task B (watch_all) ---")
    start_b = requests.post(f"{BASE_URL}/api/v1/tasks/{task_b.id}/start/", headers=auth_headers).json()
    session_b_id = start_b['session']['id']

    # Watch up to 160s (under 95%)
    p_b1 = requests.post(f"{BASE_URL}/api/v1/tracking/progress/", headers=auth_headers, json={
        "session_id": session_b_id,
        "current_time": 160.0,
        "delta_seconds": 15.0
    }).json()
    assert p_b1['coins_earned'] == 0.0
    assert p_b1['is_completed'] is False
    print(f"   Watched 160s / 180s (88%): Coins={p_b1['coins_earned']}, Completed={p_b1['is_completed']}")

    # Watch to 172s (hits 95% threshold -> awards 100 coins & completes)
    p_b2 = requests.post(f"{BASE_URL}/api/v1/tracking/progress/", headers=auth_headers, json={
        "session_id": session_b_id,
        "current_time": 172.0,
        "delta_seconds": 12.0
    }).json()
    assert p_b2['coins_earned'] == 100.0
    assert p_b2['is_completed'] is True
    assert p_b2['wallet_balance'] == 120.0 # 20 (Task A) + 100 (Task B)
    print(f"   Watched 172s / 180s (95.5%): Coins={p_b2['coins_earned']}, Completed={p_b2['is_completed']}, Bal={p_b2['wallet_balance']}")
    print(" [PASS] Task B (watch_all) awarded +100 coins and marked completed!")

    # Extra ping on completed Task B
    p_b3 = requests.post(f"{BASE_URL}/api/v1/tracking/progress/", headers=auth_headers, json={
        "session_id": session_b_id,
        "current_time": 180.0,
        "delta_seconds": 8.0
    }).json()
    assert p_b3['coins_earned'] == 0.0
    assert p_b3['wallet_balance'] == 120.0
    print(" [PASS] Further watching completed Task B gives 0 extra coins.")

    # --- Task C (target: target_seconds=120s, 50 coins) ---
    print("\n--- Testing Task C (target) ---")
    start_c = requests.post(f"{BASE_URL}/api/v1/tasks/{task_c.id}/start/", headers=auth_headers).json()
    session_c_id = start_c['session']['id']

    # Watch 100s
    p_c1 = requests.post(f"{BASE_URL}/api/v1/tracking/progress/", headers=auth_headers, json={
        "session_id": session_c_id,
        "current_time": 100.0,
        "delta_seconds": 15.0
    }).json()
    assert p_c1['coins_earned'] == 0.0

    # Watch to 125s (hits 120s target)
    p_c2 = requests.post(f"{BASE_URL}/api/v1/tracking/progress/", headers=auth_headers, json={
        "session_id": session_c_id,
        "current_time": 125.0,
        "delta_seconds": 15.0
    }).json()
    assert p_c2['coins_earned'] == 50.0
    assert p_c2['is_completed'] is True
    assert p_c2['wallet_balance'] == 170.0 # 120 + 50
    print(f"   Watched 125s (target 120s): Coins={p_c2['coins_earned']}, Completed={p_c2['is_completed']}, Bal={p_c2['wallet_balance']}")
    print(" [PASS] Task C (target) awarded +50 coins and marked completed!")

    # ----------------------------------------------------------------
    # 8. Wallet & Transaction Ledger Verification
    # ----------------------------------------------------------------
    print("\n--- 8. Testing Wallet & Ledger Endpoints ---")
    wallet_res = requests.get(f"{BASE_URL}/api/v1/wallet/", headers=auth_headers)
    assert wallet_res.status_code == 200
    wallet_data = wallet_res.json()
    assert float(wallet_data['balance']) == 170.0
    print(f" [PASS] /api/v1/wallet/ balance verified: {wallet_data['balance']} coins")

    tx_res = requests.get(f"{BASE_URL}/api/v1/wallet/transactions/", headers=auth_headers)
    assert tx_res.status_code == 200
    tx_list = tx_res.json()
    assert len(tx_list) == 4 # 2 from Task A, 1 from Task B, 1 from Task C
    print(f" [PASS] /api/v1/wallet/transactions/ returned {len(tx_list)} ledger entries:")
    for tx in tx_list:
        print(f"   * +{tx['amount']} Coins | Bal After: {tx['balance_after']} | Desc: '{tx['description']}' | Date: {tx['created_at']}")


    # ----------------------------------------------------------------
    # 9. Edge Cases
    # ----------------------------------------------------------------
    print("\n--- 9. Testing Edge Cases ---")

    # Negative delta rejection
    neg_res = requests.post(f"{BASE_URL}/api/v1/tracking/progress/", headers=auth_headers, json={
        "session_id": session_a_id,
        "current_time": 130.0,
        "delta_seconds": -5.0
    })
    assert neg_res.status_code == 400
    print(" [PASS] Negative delta_seconds rejected with 400 Bad Request.")

    # Unauthorized session access
    other_user_res = requests.post(f"{BASE_URL}/api/v1/auth/register/", json={
        "username": f"other_{int(time.time())}",
        "email": f"other_{int(time.time())}@vewra.com",
        "password": "password123"
    })
    other_token = other_user_res.json()['tokens']['access']
    hijack_res = requests.post(f"{BASE_URL}/api/v1/tracking/progress/", headers={"Authorization": f"Bearer {other_token}"}, json={
        "session_id": session_a_id,
        "current_time": 130.0,
        "delta_seconds": 5.0
    })
    assert hijack_res.status_code == 400
    print(" [PASS] Unauthorized user progress update on another user's session rejected.")

    print("\n" + "=" * 70)
    print("SUCCESS: ALL 9 PHASE 1 TEST CATEGORIES PASSED WITH 100% SUCCESS!")
    print("=" * 70)

if __name__ == '__main__':
    test_phase1_checklist()
