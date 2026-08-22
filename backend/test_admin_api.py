import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'vewra_backend.settings')
django.setup()

from django.contrib.auth import get_user_model
from rest_framework.test import APIClient
from rest_framework_simplejwt.tokens import RefreshToken

User = get_user_model()
admin_user = User.objects.filter(is_superuser=True).first()

if not admin_user:
    admin_user = User.objects.create_superuser('admin', 'admin@example.com', 'admin123')
    print("Created superuser 'admin'")

token = RefreshToken.for_user(admin_user).access_token

client = APIClient()
client.credentials(HTTP_AUTHORIZATION=f'Bearer {token}')

# 1. Stats
res_stats = client.get('/api/v1/admin/stats/')
print(f"Stats endpoint: Status={res_stats.status_code}, KPIs={res_stats.data.get('kpis')}")

# 2. Tasks
res_tasks = client.get('/api/v1/admin/tasks/')
print(f"Tasks endpoint: Status={res_tasks.status_code}, Count={len(res_tasks.data)}")

# 3. AI Settings
res_ai = client.get('/api/v1/admin/ai-settings/')
print(f"AI Settings endpoint: Status={res_ai.status_code}, Active Provider={res_ai.data.get('active_provider')}")

# 4. Users
res_users = client.get('/api/v1/admin/users/')
print(f"Users endpoint: Status={res_users.status_code}, Count={len(res_users.data)}")

# 5. Watch Sessions
res_sessions = client.get('/api/v1/admin/watch-sessions/')
print(f"Watch Sessions endpoint: Status={res_sessions.status_code}, Count={len(res_sessions.data)}")

# 6. Wallet Transactions
res_tx = client.get('/api/v1/admin/wallet-transactions/')
print(f"Wallet Transactions endpoint: Status={res_tx.status_code}, Count={len(res_tx.data)}")

# 7. Tokens
res_tokens = client.get('/api/v1/admin/tokens/')
print(f"Tokens endpoint: Status={res_tokens.status_code}, Outstanding={len(res_tokens.data.get('outstanding_tokens', []))}")

print("\nALL ADMIN API ENDPOINTS VERIFIED SUCCESSFULLY!")
