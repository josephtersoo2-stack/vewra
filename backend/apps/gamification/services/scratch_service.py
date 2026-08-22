import random
from decimal import Decimal
from django.db import transaction
from django.utils import timezone
from apps.gamification.models import ScratchCardClaim, UserProfile
from apps.gamification.services.xp_service import add_xp
from apps.wallet.models import Wallet, WalletTransaction

PANEL_TYPES = [
    {'type': 'coin_common', 'symbol': '🪙', 'm2_coins': 10.0, 'm3_coins': 50.0, 'm2_xp': 0, 'm3_xp': 0, 'freezes': 0},
    {'type': 'coin_rare', 'symbol': '💰', 'm2_coins': 50.0, 'm3_coins': 250.0, 'm2_xp': 0, 'm3_xp': 0, 'freezes': 0},
    {'type': 'xp', 'symbol': '⚡', 'm2_coins': 0.0, 'm3_coins': 0.0, 'm2_xp': 50, 'm3_xp': 200, 'freezes': 0},
    {'type': 'freeze', 'symbol': '❄️', 'm2_coins': 0.0, 'm3_coins': 0.0, 'm2_xp': 0, 'm3_xp': 0, 'freezes': 1},
    {'type': 'mystery', 'symbol': '🎁', 'm2_coins': 20.0, 'm3_coins': 100.0, 'm2_xp': 50, 'm3_xp': 150, 'freezes': 0},
]

def get_scratch_status(user) -> dict:
    today = timezone.now().date()
    has_claimed = ScratchCardClaim.objects.filter(user=user, date=today).exists()
    return {
        'can_scratch': not has_claimed,
        'today_date': today.isoformat(),
    }

def execute_daily_scratch(user) -> dict:
    today = timezone.now().date()

    with transaction.atomic():
        if ScratchCardClaim.objects.filter(user=user, date=today).exists():
            return {'success': False, 'message': 'You have already played today\'s Scratch Card!'}

        # Generate 3x3 layout with a guaranteed match 2 or match 3
        chosen_panel = random.choice(PANEL_TYPES)
        match_count = 3 if random.random() < 0.25 else 2  # 25% chance of match 3

        grid = [chosen_panel['type']] * match_count
        other_types = [p['type'] for p in PANEL_TYPES if p['type'] != chosen_panel['type']]
        while len(grid) < 9:
            grid.append(random.choice(other_types))
        random.shuffle(grid)

        # Calculate prize
        coins_won = chosen_panel['m3_coins'] if match_count == 3 else chosen_panel['m2_coins']
        xp_won = chosen_panel['m3_xp'] if match_count == 3 else chosen_panel['m2_xp']
        freezes_won = 3 if (chosen_panel['type'] == 'freeze' and match_count == 3) else (1 if chosen_panel['type'] == 'freeze' else 0)

        claim = ScratchCardClaim.objects.create(
            user=user,
            date=today,
            grid_panels=grid,
            prize_type=chosen_panel['type'],
            prize_value=f"{coins_won} coins, {xp_won} XP, {freezes_won} freeze"
        )

        wallet, _ = Wallet.objects.select_for_update().get_or_create(user=user)
        profile, _ = UserProfile.objects.select_for_update().get_or_create(user=user)

        if coins_won > 0:
            coin_dec = Decimal(str(coins_won))
            wallet.balance += coin_dec
            wallet.save()

            WalletTransaction.objects.create(
                wallet=wallet,
                amount=coin_dec,
                balance_after=wallet.balance,
                transaction_type='scratch_reward',
                description=f"Matched {match_count}x {chosen_panel['symbol']} on Daily Scratch Card",
                reference_id=f"scratch_{claim.id}"
            )

        if freezes_won > 0:
            profile.streak_freeze_count += freezes_won
            profile.save()

        xp_res = {}
        if xp_won > 0:
            xp_res = add_xp(user, xp_won, 'scratch_card')

        return {
            'success': True,
            'grid': grid,
            'match_count': match_count,
            'matched_symbol': chosen_panel['symbol'],
            'matched_type': chosen_panel['type'],
            'coins_earned': coins_won,
            'xp_earned': xp_won,
            'freezes_earned': freezes_won,
            'wallet_balance': float(wallet.balance),
            'level_info': xp_res,
        }
