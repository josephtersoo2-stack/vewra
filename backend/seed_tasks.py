import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'vewra_backend.settings')
django.setup()

from django.contrib.auth.models import User
from apps.tasks.models import VideoTask
from apps.wallet.models import Wallet

def seed():
    # Create superuser / admin if not exists
    if not User.objects.filter(username='admin').exists():
        u = User.objects.create_superuser('admin', 'admin@vewra.com', 'admin123')
        print(f"Created superuser: admin (password: admin123)")

    # Create demo user
    if not User.objects.filter(username='demo').exists():
        u = User.objects.create_user('demo', 'demo@vewra.com', 'demo123')
        print(f"Created demo user: demo (password: demo123)")

    # Create sample VideoTasks
    tasks_data = [
        {
            'youtube_url': 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
            'video_id': 'dQw4w9WgXcQ',
            'title': 'Never Gonna Give You Up - Official Music Video',
            'keywords': ['Rick Astley', 'music', 'never gonna give you up', '80s classic pop hit'],
            'reward_type': 'per_time',
            'reward_config': {'coins': 15, 'seconds': 30},
            'thumbnail_url': 'https://img.youtube.com/vi/dQw4w9WgXcQ/hqdefault.jpg'
        },
        {
            'youtube_url': 'https://www.youtube.com/watch?v=L_LUpnjgPso',
            'video_id': 'L_LUpnjgPso',
            'title': 'Flutter in 100 Seconds - Quick Overview',
            'keywords': ['Flutter', 'Fireship', 'Flutter 100 seconds', 'cross platform dart mobile'],
            'reward_type': 'watch_all',
            'reward_config': {'coins': 100, 'duration': 140, 'target_percent': 90},
            'thumbnail_url': 'https://img.youtube.com/vi/L_LUpnjgPso/hqdefault.jpg'
        },
        {
            'youtube_url': 'https://www.youtube.com/watch?v=y881t8ilMyc',
            'video_id': 'y881t8ilMyc',
            'title': 'Python Tutorial for Beginners - Full Course',
            'keywords': ['python tutorial', 'programming', 'python for beginners freecodecamp', 'coding course'],
            'reward_type': 'target',
            'reward_config': {'coins': 200, 'target_seconds': 120},
            'thumbnail_url': 'https://img.youtube.com/vi/y881t8ilMyc/hqdefault.jpg'
        }
    ]

    for tdata in tasks_data:
        task, created = VideoTask.objects.update_or_create(
            video_id=tdata['video_id'],
            defaults=tdata
        )
        status_str = "Created" if created else "Updated"
        print(f"{status_str} task: {task.title} ({task.video_id})")

if __name__ == '__main__':
    seed()
