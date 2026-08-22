import hashlib
import random
from decimal import Decimal
from django.db import transaction
from django.utils import timezone
from apps.gamification.models import DailyQuest, UserProfile
from apps.gamification.services.xp_service import add_xp
from apps.wallet.models import Wallet, WalletTransaction

QUEST_TEMPLATES = {
    'easy': [
        {'type': 'watch_video', 'title': 'Daily Tune-In', 'desc': 'Watch at least 1 video task', 'target': 1, 'coins': 15.0, 'xp': 25},
        {'type': 'watch_seconds', 'title': 'Quick Session', 'desc': 'Watch 60 seconds of video content', 'target': 60, 'coins': 15.0, 'xp': 25},
        {'type': 'daily_spin', 'title': 'Lucky Day', 'desc': 'Take a spin on the Daily Wheel', 'target': 1, 'coins': 10.0, 'xp': 20},
    ],
    'medium': [
        {'type': 'watch_video', 'title': 'Video Enthusiast', 'desc': 'Watch 2 distinct video tasks', 'target': 2, 'coins': 40.0, 'xp': 75},
        {'type': 'watch_seconds', 'title': 'Deep Focus', 'desc': 'Watch 180 seconds of video content', 'target': 180, 'coins': 40.0, 'xp': 75},
        {'type': 'complete_tasks', 'title': 'Task Finisher', 'desc': 'Complete 1 full video task', 'target': 1, 'coins': 50.0, 'xp': 80},
    ],
    'hard': [
        {'type': 'complete_tasks', 'title': 'Task Master', 'desc': 'Complete 3 video tasks to 100%', 'target': 3, 'coins': 100.0, 'xp': 200},
        {'type': 'watch_seconds', 'title': 'Marathon Watcher', 'desc': 'Watch 600 total seconds of content', 'target': 600, 'coins': 120.0, 'xp': 220},
        {'type': 'watch_video', 'title': 'Binge Viewer', 'desc': 'Watch 5 different video tasks', 'target': 5, 'coins': 100.0, 'xp': 200},
    ]
}

def get_or_create_daily_quests(user) -> list[DailyQuest]:
    today = timezone.now().date()
    existing = DailyQuest.objects.filter(user=user, date=today).order_by('difficulty')
    if existing.count() >= 3:
        return list(existing)

    # Seed deterministic RNG for today
    seed_str = f"{user.id}_{today.isoformat()}"
    seed_int = int(hashlib.md5(seed_str.encode('utf-8')).hexdigest()[:8], 16)
    rng = random.Random(seed_int)

    quests = []
    with transaction.atomic():
        for diff in ['easy', 'medium', 'hard']:
            tpl = rng.choice(QUEST_TEMPLATES[diff])
            quest, _ = DailyQuest.objects.get_or_create(
                user=user,
                date=today,
                difficulty=diff,
                defaults={
                    'quest_type': tpl['type'],
                    'title': tpl['title'],
                    'description': tpl['desc'],
                    'target_count': tpl['target'],
                    'coin_reward': Decimal(str(tpl['coins'])),
                    'xp_reward': tpl['xp'],
                }
            )
            quests.append(quest)
    return quests

def update_quest_progress(user, quest_type: str, increment: int = 1):
    today = timezone.now().date()
    quests = DailyQuest.objects.filter(user=user, date=today, quest_type=quest_type, is_completed=False)
    for q in quests:
        q.current_count = min(q.target_count, q.current_count + increment)
        if q.current_count >= q.target_count:
            q.is_completed = True
        q.save(update_fields=['current_count', 'is_completed'])

def claim_quest_reward(user, quest_id: int) -> dict:
    today = timezone.now().date()
    with transaction.atomic():
        try:
            quest = DailyQuest.objects.select_for_update().get(id=quest_id, user=user)
        except DailyQuest.DoesNotExist:
            return {'success': False, 'message': 'Quest not found.'}

        if not quest.is_completed:
            return {'success': False, 'message': 'Quest is not yet completed.'}
        if quest.is_claimed:
            return {'success': False, 'message': 'Quest reward has already been claimed.'}

        quest.is_claimed = True
        quest.claimed_at = timezone.now()
        quest.save(update_fields=['is_claimed', 'claimed_at'])

        wallet, _ = Wallet.objects.select_for_update().get_or_create(user=user)
        wallet.balance += quest.coin_reward
        wallet.save()

        WalletTransaction.objects.create(
            wallet=wallet,
            amount=quest.coin_reward,
            balance_after=wallet.balance,
            transaction_type='quest_reward',
            description=f"Completed Daily Quest: {quest.title}",
            reference_id=f"quest_{quest.id}"
        )

        xp_res = add_xp(user, quest.xp_reward, 'daily_quest')

        # Check if all 3 quests are claimed today -> Quest Master bonus!
        all_today = DailyQuest.objects.filter(user=user, date=today)
        all_claimed = all_today.count() == 3 and all(q.is_claimed for q in all_today)
        quest_master_bonus = False

        if all_claimed:
            # Award +50 coins Quest Master bonus
            bonus_coins = Decimal('50.00')
            wallet.balance += bonus_coins
            wallet.save()

            WalletTransaction.objects.create(
                wallet=wallet,
                amount=bonus_coins,
                balance_after=wallet.balance,
                transaction_type='quest_master',
                description="🌟 Quest Master Bonus: Completed all 3 daily quests!",
                reference_id=f"quest_master_{today.isoformat()}"
            )
            add_xp(user, 100, 'quest_master')
            quest_master_bonus = True

        return {
            'success': True,
            'quest_id': quest.id,
            'title': quest.title,
            'coins_earned': float(quest.coin_reward),
            'xp_earned': quest.xp_reward,
            'quest_master_bonus': quest_master_bonus,
            'wallet_balance': float(wallet.balance),
            'level_info': xp_res,
        }
