import os
import sys
import django

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'vewra_backend.settings')
django.setup()

from apps.gamification.models import Badge

ALL_BADGES = [
    # Onboarding
    {'key': 'first_steps', 'name': 'First Steps', 'desc': 'Complete your very first video task.', 'cat': 'onboarding', 'b': 1, 's': 1, 'g': 1, 'd': 1},
    {'key': 'getting_started', 'name': 'Task Enthusiast', 'desc': 'Complete video tasks on Vewra.', 'cat': 'onboarding', 'b': 5, 's': 25, 'g': 100, 'd': 500},
    {'key': 'profile_set', 'name': 'Identity Established', 'desc': 'Upload avatar and configure custom profile.', 'cat': 'onboarding', 'b': 1, 's': 1, 'g': 1, 'd': 1},

    # Watch & Retention
    {'key': 'couch_potato', 'name': 'Couch Potato', 'desc': 'Total watch time hours accumulated on Vewra.', 'cat': 'watch', 'b': 10, 's': 50, 'g': 250, 'd': 1000},
    {'key': 'night_owl', 'name': 'Night Owl', 'desc': 'Watch videos between 12 AM and 6 AM.', 'cat': 'watch', 'b': 10, 's': 50, 'g': 200, 'd': 500},
    {'key': 'marathoner', 'name': 'Marathoner', 'desc': 'Complete 30+ minute video tasks without skipping.', 'cat': 'watch', 'b': 1, 's': 5, 'g': 20, 'd': 50},
    {'key': 'binge_watcher', 'name': 'Binge Viewer', 'desc': 'Watch videos in a single 24-hour day.', 'cat': 'watch', 'b': 10, 's': 25, 'g': 50, 'd': 100},

    # Social & Referral
    {'key': 'social_butterfly', 'name': 'Social Butterfly', 'desc': 'Complete social media and comment tasks.', 'cat': 'social', 'b': 10, 's': 50, 'g': 200, 'd': 500},
    {'key': 'referral_king', 'name': 'Referral Ambassador', 'desc': 'Refer active earning users to Vewra.', 'cat': 'social', 'b': 3, 's': 10, 'g': 50, 'd': 200},
    {'key': 'guild_leader', 'name': 'Squad Commander', 'desc': 'Form and lead an active earning squad.', 'cat': 'social', 'b': 1, 's': 5, 'g': 10, 'd': 25},

    # Earning & Economy
    {'key': 'coin_collector', 'name': 'Coin Collector', 'desc': 'Total coins accumulated in your wallet ledger.', 'cat': 'earning', 'b': 100, 's': 1000, 'g': 10000, 'd': 50000},
    {'key': 'high_roller', 'name': 'High Roller', 'desc': 'Accumulate 50,000+ total coins.', 'cat': 'earning', 'b': 10000, 's': 25000, 'g': 50000, 'd': 100000},
    {'key': 'millionaire', 'name': 'Vewra Millionaire', 'desc': 'Accumulate 1,000,000 total lifetime coins.', 'cat': 'earning', 'b': 100000, 's': 250000, 'g': 500000, 'd': 1000000},
    {'key': 'lucky_streak', 'name': 'Streak Legend', 'desc': 'Maintain daily login streak days.', 'cat': 'earning', 'b': 7, 's': 30, 'g': 60, 'd': 100},
    {'key': 'jackpot_winner', 'name': 'Jackpot Champion', 'desc': 'Hit the 1,000 or 5,000 coin jackpot on the Lucky Wheel.', 'cat': 'earning', 'b': 1, 's': 3, 'g': 5, 'd': 10},

    # Special & Milestones
    {'key': 'early_adopter', 'name': 'Early Pioneer', 'desc': 'Joined Vewra in the founding launch phase.', 'cat': 'special', 'b': 1, 's': 1, 'g': 1, 'd': 1},
    {'key': 'century_club', 'name': 'Century Club', 'desc': 'Reach higher account level tiers.', 'cat': 'special', 'b': 5, 's': 20, 'g': 50, 'd': 100},
    {'key': 'prestige_master', 'name': 'Prestige Master', 'desc': 'Prestige your account after reaching Level 100.', 'cat': 'special', 'b': 1, 's': 2, 'g': 3, 'd': 5},
]

def seed_badges():
    count = 0
    for b in ALL_BADGES:
        _, created = Badge.objects.update_or_create(
            key=b['key'],
            defaults={
                'name': b['name'],
                'description': b['desc'],
                'category': b['cat'],
                'target_bronze': b['b'],
                'target_silver': b['s'],
                'target_gold': b['g'],
                'target_diamond': b['d'],
            }
        )
        if created:
            count += 1
    print(f"Successfully seeded/updated {len(ALL_BADGES)} badges ({count} new created)!")

if __name__ == '__main__':
    seed_badges()
