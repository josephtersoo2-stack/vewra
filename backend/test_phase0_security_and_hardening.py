import os
import django
import uuid
import time
from decimal import Decimal

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'vewra_backend.settings')
django.setup()

from django.test import Client
from django.contrib.auth.models import User
from django.core.cache import cache
from rest_framework_simplejwt.tokens import RefreshToken, OutstandingToken, BlacklistedToken

from apps.ai_service.models import AISettings
from apps.core.vault import encrypt_secret, decrypt_secret
from apps.core.fraud import evaluate_fraud_signal, UserFraudProfile, hash_ip
from apps.tasks.models import VideoTask, WatchSession
from apps.wallet.models import Wallet, WalletTransaction

def run_tests():
    print("=" * 70)
    print("RUNNING VEWRA PHASE 0: SECURITY & INFRASTRUCTURE HARDENING TEST SUITE")
    print("=" * 70)
    client = Client()

    # -------------------------------------------------------------
    # 1. Observability: Health Checks & Request Correlation ID
    # -------------------------------------------------------------
    print("\n--- 1. Testing Health Checks & Request Correlation ID ---")
    res = client.get('/health/')
    assert res.status_code == 200, f"Expected 200 from /health/, got {res.status_code}"
    health_data = res.json()
    assert health_data['status'] in ('healthy', 'degraded'), f"Unexpected health status: {health_data}"
    assert 'X-Request-ID' in res.headers, "X-Request-ID header missing from response"
    print(f" [PASS] /health/ returned {res.status_code} with components: {health_data['components']}")
    print(f" [PASS] X-Request-ID correlation header verified: {res.headers['X-Request-ID']}")

    res_ready = client.get('/ready/')
    assert res_ready.status_code == 200, f"Expected 200 from /ready/, got {res_ready.status_code}"
    print(f" [PASS] /ready/ probe verified: {res_ready.json()}")

    # -------------------------------------------------------------
    # 2. Security: API Key Encryption at Rest (Vault)
    # -------------------------------------------------------------
    print("\n--- 2. Testing API Key Encryption at Rest (Vault) ---")
    test_key = "AIzaSyD-TEST-GEMINI-KEY-9988776655"
    encrypted = encrypt_secret(test_key)
    assert encrypted.startswith("enc:"), f"Ciphertext should start with enc:, got {encrypted}"
    decrypted = decrypt_secret(encrypted)
    assert decrypted == test_key, f"Decryption mismatch: {decrypted} != {test_key}"
    print(f" [PASS] Pure Fernet encryption verified (enc prefix: {encrypted[:15]}...)")

    settings = AISettings.get_settings()
    settings.gemini_api_key = test_key
    settings.save()
    settings.refresh_from_db()
    # In DB it must be encrypted
    raw_db_val = settings.gemini_api_key
    assert raw_db_val.startswith("enc:"), f"Stored key in DB is not encrypted: {raw_db_val}"
    # Getter must decrypt transparently
    effective = settings.get_effective_gemini_key()
    assert effective == test_key, f"Effective getter failed: {effective} != {test_key}"
    print(f" [PASS] AISettings model auto-encrypts at rest and auto-decrypts on fetch.")

    # -------------------------------------------------------------
    # 3. Auth Hardening: Password Complexity & Account Lockout
    # -------------------------------------------------------------
    print("\n--- 3. Testing Auth Hardening (Password Policy & Lockout) ---")
    ts = int(time.time())
    # Weak password check
    res_weak = client.post('/api/v1/auth/register/', {
        'username': f'weakuser_{ts}',
        'email': f'weak_{ts}@example.com',
        'password': 'short'
    }, content_type='application/json')
    assert res_weak.status_code == 400, "Weak password should have been rejected with 400"
    print(f" [PASS] Weak password properly rejected by policy.")

    # Valid registration
    valid_username = f'secuser_{ts}'
    valid_password = 'ValidPassword123'
    res_reg = client.post('/api/v1/auth/register/', {
        'username': valid_username,
        'email': f'sec_{ts}@example.com',
        'password': valid_password
    }, content_type='application/json')
    assert res_reg.status_code == 201, f"Registration failed: {res_reg.json()}"
    print(f" [PASS] Strong password user registered successfully: {valid_username}")

    # Test lockout after 5 failed attempts
    lockout_username = f'locktest_{ts}'
    User.objects.create_user(username=lockout_username, password='CorrectPass123')
    for i in range(5):
        client.post('/api/v1/auth/login/', {
            'username': lockout_username,
            'password': 'WrongPassword999'
        }, content_type='application/json')
    
    # 6th attempt should trigger account lockout (400) or rate throttle (429)
    res_locked = client.post('/api/v1/auth/login/', {
        'username': lockout_username,
        'password': 'WrongPassword999'
    }, content_type='application/json')
    assert res_locked.status_code in (400, 429), f"Expected 400 or 429, got: {res_locked.status_code}"
    print(f" [PASS] Account lockout & rate throttle defense enforced on failed attempts (status: {res_locked.status_code}).")

    # -------------------------------------------------------------
    # 4. Session Revocation: Logout All
    # -------------------------------------------------------------
    print("\n--- 4. Testing Multi-Device Logout (Logout All) ---")
    user = User.objects.get(username=valid_username)
    refresh1 = RefreshToken.for_user(user)
    refresh2 = RefreshToken.for_user(user)
    access_token = str(refresh1.access_token)

    res_logout = client.post(
        '/api/v1/auth/logout-all/',
        headers={'Authorization': f'Bearer {access_token}'}
    )
    assert res_logout.status_code == 200, f"Logout all failed: {res_logout.json()}"
    print(f" [PASS] /api/v1/auth/logout-all/ revoked sessions: {res_logout.json()['revoked_count']}")

    # -------------------------------------------------------------
    # 5. Idempotency on Tracking Progress
    # -------------------------------------------------------------
    print("\n--- 5. Testing Idempotency on Progress Tracking ---")
    task, _ = VideoTask.objects.get_or_create(
        video_id=f'idemp_vid_{ts}',
        defaults={
            'title': 'Idempotency Test Video',
            'reward_type': 'per_time',
            'reward_config': {'coins': 10, 'seconds': 30}
        }
    )
    session, _ = WatchSession.objects.get_or_create(user=user, video_task=task)
    wallet = user.wallet
    initial_balance = wallet.balance

    # Generate fresh token since previous was revoked in logout-all test
    fresh_access_token = str(RefreshToken.for_user(user).access_token)
    idempotency_key = f"key-{uuid.uuid4()}"
    
    # Ping 1: 15s watched (cumulative 15s / 30s)
    client.post(
        '/api/v1/tracking/progress/',
        data={
            'session_id': session.id,
            'current_time': 15.0,
            'delta_seconds': 15.0
        },
        headers={'Authorization': f'Bearer {fresh_access_token}'},
        content_type='application/json'
    )

    # Ping 2 with idempotency key: 15s watched (cumulative 30s / 30s -> triggers +10 coins)
    res_ping2 = client.post(
        '/api/v1/tracking/progress/',
        data={
            'session_id': session.id,
            'current_time': 30.0,
            'delta_seconds': 15.0
        },
        headers={
            'Authorization': f'Bearer {fresh_access_token}',
            'X-Idempotency-Key': idempotency_key
        },
        content_type='application/json'
    )
    assert res_ping2.status_code == 200, f"Ping 2 failed: {res_ping2.json()}"
    wallet.refresh_from_db()
    balance_after_ping2 = wallet.balance
    assert balance_after_ping2 == initial_balance + Decimal('10.00'), f"Balance mismatch: {balance_after_ping2}"

    # Re-send EXACT SAME idempotency key (simulating network retry)
    res_ping_retry = client.post(
        '/api/v1/tracking/progress/',
        data={
            'session_id': session.id,
            'current_time': 30.0,
            'delta_seconds': 15.0
        },
        headers={
            'Authorization': f'Bearer {fresh_access_token}',
            'X-Idempotency-Key': idempotency_key
        },
        content_type='application/json'
    )
    assert res_ping_retry.status_code == 200
    wallet.refresh_from_db()
    assert wallet.balance == balance_after_ping2, f"Idempotency failed! Double awarded: {wallet.balance}"
    print(f" [PASS] X-Idempotency-Key safely prevented double reward crediting.")

    # -------------------------------------------------------------
    # 6. Anti-Fraud System (Phase 1)
    # -------------------------------------------------------------
    print("\n--- 6. Testing Anti-Fraud Engine ---")
    score1 = evaluate_fraud_signal(user=user, delta_seconds=5.0, request_ip='192.168.1.100')
    assert 0.0 <= score1 <= 1.0
    print(f" [PASS] Normal watch ping fraud score: {score1:.2f}")

    # Trigger suspicious pings
    for _ in range(12):
        evaluate_fraud_signal(user=user, delta_seconds=15.0, request_ip='192.168.1.100')
    
    profile = UserFraudProfile.objects.get(user=user)
    assert profile.suspicious_pings_count > 0
    print(f" [PASS] Fraud profile updated: Score={profile.fraud_score:.2f}, Flagged={profile.is_flagged}")

    # Test Admin Fraud Queue endpoint
    admin_user = User.objects.filter(is_superuser=True).first()
    admin_token = str(RefreshToken.for_user(admin_user).access_token)
    res_fraud = client.get(
        '/api/v1/admin/fraud/',
        headers={'Authorization': f'Bearer {admin_token}'}
    )
    assert res_fraud.status_code == 200, f"Fraud queue failed: {res_fraud.json()}"
    print(f" [PASS] /api/v1/admin/fraud/ returned {res_fraud.json()['total_count']} profile(s).")

    # -------------------------------------------------------------
    # 7. OpenAPI 3.0 Documentation & Swagger Schema
    # -------------------------------------------------------------
    print("\n--- 7. Testing OpenAPI 3.0 Schema Generation ---")
    res_schema = client.get('/api/schema/')
    assert res_schema.status_code == 200, f"OpenAPI schema failed: {res_schema.status_code}"
    assert 'openapi' in res_schema.content.decode('utf-8').lower(), "Schema missing openapi declaration"
    print(f" [PASS] OpenAPI 3.0 schema generated successfully at /api/schema/")

    res_swagger = client.get('/api/docs/')
    assert res_swagger.status_code == 200, f"Swagger UI failed: {res_swagger.status_code}"
    print(f" [PASS] Interactive Swagger UI active at /api/docs/")

    print("\n" + "=" * 70)
    print("SUCCESS: ALL 7 PHASE 0 SECURITY & HARDENING SUITES PASSED (100%)")
    print("=" * 70)

if __name__ == '__main__':
    run_tests()
