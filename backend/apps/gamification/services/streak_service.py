from datetime import date, timedelta
from decimal import Decimal
from django.db import transaction
from django.utils import timezone
from apps.gamification.models import DailyLoginStreak, UserProfile
from apps.gamification.services.xp_service import add_xp
from apps.wallet.models import Wallet, WalletTransaction

DAILY_REWARD_TABLE = {
    1: 5.0,
    2: 10.0,
    3: 15.0,
    4: 20.0,
    5: 30.0,
    6: 40.0,
    7: 50.0,
}

def get_streak_status(user) -> dict:
    streak, _ = DailyLoginStreak.objects.get_or_create(user=user)
    today = timezone.now().date()
    yesterday = today - timedelta(days=1)
    
    is_claimed_today = streak.last_claimed_date == today
    day_in_cycle = ((streak.streak_count - 1) % 7) + 1 if streak.streak_count > 0 else 0
    next_day_reward = DAILY_REWARD_TABLE.get(((day_in_cycle) % 7) + 1, 5.0)

    # 7-day calendar history representation
    calendar = []
    for day_idx in range(1, 8):
        calendar.append({
            'day': day_idx,
            'coins': DAILY_REWARD_TABLE[day_idx],
            'has_mystery_box': day_idx == 7,
            'is_claimed': day_idx <= day_in_cycle if (streak.last_claimed_date in (today, yesterday)) else False,
            'is_current': day_idx == ((day_in_cycle % 7) + 1) if not is_claimed_today else (day_idx == day_in_cycle),
        })

    return {
        'streak_count': streak.streak_count,
        'longest_streak': streak.longest_streak,
        'day_in_cycle': day_in_cycle,
        'is_claimed_today': is_claimed_today,
        'streak_multiplier': streak.streak_multiplier,
        'next_day_reward': next_day_reward,
        'calendar': calendar,
    }

def claim_daily_streak(user) -> dict:
    today = timezone.now().date()
    yesterday = today - timedelta(days=1)
    two_days_ago = today - timedelta(days=2)

    with transaction.atomic():
        streak, _ = DailyLoginStreak.objects.select_for_update().get_or_create(user=user)
        profile, _ = UserProfile.objects.select_for_update().get_or_create(user=user)
        wallet, _ = Wallet.objects.select_for_update().get_or_create(user=user)

        if streak.last_claimed_date == today:
            return {
                'already_claimed': True,
                'message': 'Daily streak reward already claimed today!',
                'streak_count': streak.streak_count,
                'day_in_cycle': ((streak.streak_count - 1) % 7) + 1,
                'coins_earned': 0.0,
                'streak_multiplier': streak.streak_multiplier,
            }

        freeze_used = False
        if streak.last_claimed_date == yesterday:
            streak.streak_count += 1
        elif streak.last_claimed_date == two_days_ago:
            # Check for Streak Freeze auto-protection
            if profile.streak_freeze_count > 0 and streak.freeze_used_this_week < 3:
                profile.streak_freeze_count -= 1
                profile.save()
                streak.freeze_used_this_week += 1
                streak.streak_count += 1
                freeze_used = True
            else:
                streak.streak_count = 1
        else:
            # Broken streak or first time claim
            streak.streak_count = 1

        streak.last_claimed_date = today
        streak.longest_streak = max(streak.longest_streak, streak.streak_count)
        streak.save()

        # Calculate reward
        day_in_cycle = ((streak.streak_count - 1) % 7) + 1
        base_coins = DAILY_REWARD_TABLE.get(day_in_cycle, 5.0)
        mystery_box_unlocked = day_in_cycle == 7

        # Credit wallet
        coins_dec = Decimal(str(base_coins))
        wallet.balance += coins_dec
        wallet.save()

        WalletTransaction.objects.create(
            wallet=wallet,
            amount=coins_dec,
            balance_after=wallet.balance,
            transaction_type='daily_streak',
            description=f"Day {day_in_cycle} Daily Streak Bonus ({streak.streak_count}d streak)",
            reference_id=f"streak_{today.isoformat()}"
        )

        # Award XP (15 XP for daily streak)
        xp_res = add_xp(user, 15, 'daily_streak')

        # Check 30-day milestone: award +2 streak freezes
        if streak.streak_count > 0 and streak.streak_count % 30 == 0:
            profile.streak_freeze_count += 2
            profile.save()

        return {
            'already_claimed': False,
            'message': f"Claimed Day {day_in_cycle} Streak Reward! (+{base_coins} Coins)",
            'streak_count': streak.streak_count,
            'longest_streak': streak.longest_streak,
            'day_in_cycle': day_in_cycle,
            'coins_earned': base_coins,
            'mystery_box_unlocked': mystery_box_unlocked,
            'streak_multiplier': streak.streak_multiplier,
            'freeze_used': freeze_used,
            'wallet_balance': float(wallet.balance),
            'xp_earned': 15,
            'level_info': xp_res,
        }
