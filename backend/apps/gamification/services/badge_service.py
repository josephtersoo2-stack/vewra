from django.db.models import Sum
from django.utils import timezone
from apps.gamification.models import Badge, UserBadge, UserProfile, DailyLoginStreak
from apps.tasks.models import WatchSession
from apps.wallet.models import Wallet

DEFAULT_BADGES = [
    # Onboarding
    {'key': 'first_steps', 'name': 'First Steps', 'desc': 'Complete your very first video task.', 'cat': 'onboarding', 'b': 1, 's': 1, 'g': 1, 'd': 1},
    {'key': 'getting_started', 'name': 'Task Collector', 'desc': 'Complete video tasks.', 'cat': 'onboarding', 'b': 5, 's': 25, 'g': 100, 'd': 500},
    # Watch
    {'key': 'couch_potato', 'name': 'Couch Potato', 'desc': 'Total watch time hours on Vewra.', 'cat': 'watch', 'b': 10, 's': 50, 'g': 250, 'd': 1000},
    {'key': 'marathoner', 'name': 'Marathoner', 'desc': 'Complete a 30+ minute video task.', 'cat': 'watch', 'b': 1, 's': 5, 'g': 20, 'd': 50},
    # Earning
    {'key': 'coin_collector', 'name': 'Coin Collector', 'desc': 'Total coins accumulated in wallet.', 'cat': 'earning', 'b': 100, 's': 1000, 'g': 10000, 'd': 50000},
    {'key': 'lucky_streak', 'name': 'Streak Legend', 'desc': 'Maintain daily login streak days.', 'cat': 'earning', 'b': 7, 's': 30, 'g': 60, 'd': 100},
    # Leveling
    {'key': 'century_club', 'name': 'Century Club', 'desc': 'Reach higher account levels.', 'cat': 'special', 'b': 5, 's': 20, 'g': 50, 'd': 100},
]

def seed_default_badges():
    for bdata in DEFAULT_BADGES:
        Badge.objects.update_or_create(
            key=bdata['key'],
            defaults={
                'name': bdata['name'],
                'description': bdata['desc'],
                'category': bdata['cat'],
                'target_bronze': bdata['b'],
                'target_silver': bdata['s'],
                'target_gold': bdata['g'],
                'target_diamond': bdata['d'],
            }
        )

def evaluate_user_badges(user) -> list[dict]:
    """
    Evaluates and updates badges for a user based on their current stats.
    Returns any newly unlocked or tier-upgraded badges.
    """
    profile, _ = UserProfile.objects.get_or_create(user=user)
    streak, _ = DailyLoginStreak.objects.get_or_create(user=user)
    wallet, _ = Wallet.objects.get_or_create(user=user)

    completed_tasks = WatchSession.objects.filter(user=user, is_completed=True).count()
    watch_hours = (WatchSession.objects.filter(user=user).aggregate(Sum('total_watched_seconds'))['total_watched_seconds__sum'] or 0.0) / 3600.0

    stat_map = {
        'first_steps': completed_tasks,
        'getting_started': completed_tasks,
        'couch_potato': watch_hours,
        'marathoner': completed_tasks,
        'coin_collector': float(wallet.balance),
        'lucky_streak': streak.streak_count,
        'century_club': profile.level,
    }

    badges = Badge.objects.all()
    newly_unlocked = []

    for badge in badges:
        ub, _ = UserBadge.objects.get_or_create(user=user, badge=badge)
        current_val = stat_map.get(badge.key, 0)
        ub.progress_current = current_val

        # Determine highest tier achieved
        new_tier = 'none'
        if current_val >= badge.target_diamond:
            new_tier = 'diamond'
            ub.progress_target = badge.target_diamond
        elif current_val >= badge.target_gold:
            new_tier = 'gold'
            ub.progress_target = badge.target_diamond
        elif current_val >= badge.target_silver:
            new_tier = 'silver'
            ub.progress_target = badge.target_gold
        elif current_val >= badge.target_bronze:
            new_tier = 'bronze'
            ub.progress_target = badge.target_silver
        else:
            ub.progress_target = badge.target_bronze

        if new_tier != 'none' and (new_tier != ub.tier or not ub.is_unlocked):
            ub.tier = new_tier
            ub.is_unlocked = True
            ub.awarded_at = timezone.now()
            newly_unlocked.append({
                'badge_key': badge.key,
                'name': badge.name,
                'tier': new_tier,
            })

        ub.save()

    return newly_unlocked
