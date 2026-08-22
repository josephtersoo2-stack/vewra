import random
from decimal import Decimal
from django.db import transaction
from django.utils import timezone
from apps.gamification.models import SpinWheelClaim, UserProfile
from apps.gamification.services.xp_service import add_xp
from apps.wallet.models import Wallet, WalletTransaction

# 12 Segments with Master Plan weights
SPIN_SEGMENTS = [
    {'segment': 1, 'type': 'coins', 'value': '1', 'label': '1 Coin', 'weight': 30.0, 'coins': 1.0},
    {'segment': 2, 'type': 'coins', 'value': '5', 'label': '5 Coins', 'weight': 25.0, 'coins': 5.0},
    {'segment': 3, 'type': 'coins', 'value': '10', 'label': '10 Coins', 'weight': 18.0, 'coins': 10.0},
    {'segment': 4, 'type': 'coins', 'value': '25', 'label': '25 Coins', 'weight': 12.0, 'coins': 25.0},
    {'segment': 5, 'type': 'coins', 'value': '50', 'label': '50 Coins', 'weight': 8.0, 'coins': 50.0},
    {'segment': 6, 'type': 'coins', 'value': '100', 'label': '100 Coins', 'weight': 4.0, 'coins': 100.0},
    {'segment': 7, 'type': 'coins', 'value': '500', 'label': '500 Coins', 'weight': 1.5, 'coins': 500.0},
    {'segment': 8, 'type': 'coins', 'value': '1000', 'label': '1,000 Coins Jackpot!', 'weight': 0.5, 'coins': 1000.0},
    {'segment': 9, 'type': 'freeze', 'value': '1', 'label': '1 Streak Freeze ❄️', 'weight': 0.4, 'coins': 0.0},
    {'segment': 10, 'type': 'xp_boost', 'value': '2x', 'label': '2x XP Boost (1h) ⚡', 'weight': 0.3, 'coins': 0.0},
    {'segment': 11, 'type': 'mystery_box', 'value': 'rare', 'label': 'Rare Mystery Box 🎁', 'weight': 0.2, 'coins': 0.0},
    {'segment': 12, 'type': 'coins', 'value': '5000', 'label': '5,000 Coins Mega Jackpot! 🎰', 'weight': 0.1, 'coins': 5000.0},
]

def get_spin_status(user) -> dict:
    today = timezone.now().date()
    has_claimed = SpinWheelClaim.objects.filter(user=user, date=today).exists()
    return {
        'can_spin': not has_claimed,
        'today_date': today.isoformat(),
        'segments': [
            {'segment': s['segment'], 'type': s['type'], 'label': s['label'], 'value': s['value']}
            for s in SPIN_SEGMENTS
        ]
    }

def execute_daily_spin(user) -> dict:
    today = timezone.now().date()

    with transaction.atomic():
        if SpinWheelClaim.objects.filter(user=user, date=today).exists():
            return {
                'success': False,
                'message': 'You have already used your free daily spin today. Come back tomorrow!'
            }

        # Weighted selection
        weights = [s['weight'] for s in SPIN_SEGMENTS]
        selected = random.choices(SPIN_SEGMENTS, weights=weights, k=1)[0]

        # Record claim
        claim = SpinWheelClaim.objects.create(
            user=user,
            date=today,
            prize_type=selected['type'],
            prize_value=selected['value'],
            segment_landed=selected['segment']
        )

        # Distribute prize
        wallet, _ = Wallet.objects.select_for_update().get_or_create(user=user)
        profile, _ = UserProfile.objects.select_for_update().get_or_create(user=user)

        if selected['type'] == 'coins' and selected['coins'] > 0:
            coin_val = Decimal(str(selected['coins']))
            wallet.balance += coin_val
            wallet.save()

            WalletTransaction.objects.create(
                wallet=wallet,
                amount=coin_val,
                balance_after=wallet.balance,
                transaction_type='spin_reward',
                description=f"Won {selected['label']} on Daily Lucky Spin",
                reference_id=f"spin_{claim.id}"
            )
        elif selected['type'] == 'freeze':
            profile.streak_freeze_count += 1
            profile.save()

        # Award 15 XP for daily spin claim
        xp_res = add_xp(user, 15, 'daily_spin')

        return {
            'success': True,
            'segment_landed': selected['segment'],
            'prize_type': selected['type'],
            'prize_value': selected['value'],
            'label': selected['label'],
            'wallet_balance': float(wallet.balance),
            'freezes_count': profile.streak_freeze_count,
            'xp_earned': 15,
            'level_info': xp_res,
        }
