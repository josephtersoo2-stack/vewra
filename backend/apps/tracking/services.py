from decimal import Decimal
from django.db import transaction
from django.utils import timezone
from django.core.exceptions import ValidationError
from apps.tasks.models import WatchSession
from apps.wallet.models import Wallet, WalletTransaction

class RewardCalculator:
    """
    Pure calculation logic for rewards based on task configuration.
    Unit-testable without database dependencies.
    """

    @staticmethod
    def calculate(
        reward_type: str,
        reward_config: dict,
        old_total_seconds: float,
        new_total_seconds: float,
        current_time: float = 0.0,
        already_completed: bool = False
    ) -> tuple[Decimal, bool, str]:
        """
        Calculates (coins_earned, is_now_completed, description).
        """
        if already_completed:
            return Decimal('0.00'), True, "Session already completed"

        reward_config = reward_config or {}
        coins_earned = Decimal('0.00')
        is_completed = False
        description = ""

        if reward_type == 'per_time':
            interval = float(reward_config.get('seconds', 60))
            if interval <= 0:
                interval = 60.0
            coins_per_interval = Decimal(str(reward_config.get('coins', 10)))

            old_intervals = int(old_total_seconds // interval)
            new_intervals = int(new_total_seconds // interval)
            earned_intervals = new_intervals - old_intervals

            if earned_intervals > 0:
                coins_earned = Decimal(earned_intervals) * coins_per_interval
                description = f"Earned {coins_earned} coins for watching {earned_intervals * interval}s"
            
            # Optional maximum cap / duration if set
            max_seconds = reward_config.get('max_seconds')
            if max_seconds and new_total_seconds >= float(max_seconds):
                is_completed = True

        elif reward_type == 'watch_all':
            coins = Decimal(str(reward_config.get('coins', 150)))
            duration_val = reward_config.get('duration')
            if duration_val is None:
                raise ValidationError("Reward config must specify 'duration' for 'watch_all' reward type.")
            try:
                duration = float(duration_val)
                if duration <= 0:
                    raise ValueError()
            except (ValueError, TypeError):
                raise ValidationError("Invalid 'duration' in reward config for 'watch_all'.")

            # Default completion threshold is 95% of duration, or target_percent if specified
            target_percent = float(reward_config.get('target_percent', 95))
            threshold = duration * (target_percent / 100.0)

            if new_total_seconds >= threshold or current_time >= threshold:
                coins_earned = coins
                is_completed = True
                description = f"Earned {coins} coins for completing video"

        elif reward_type == 'target':
            coins = Decimal(str(reward_config.get('coins', 100)))
            target_seconds = float(reward_config.get('target_seconds', 300))

            if new_total_seconds >= target_seconds or current_time >= target_seconds:
                coins_earned = coins
                is_completed = True
                description = f"Earned {coins} coins for reaching target {target_seconds}s"


        return coins_earned, is_completed, description

def process_watch_progress(user, session_id: int, current_time: float, delta_seconds: float, request_ip: str = None) -> dict:
    """
    Processes a watch progress ping atomically.
    Protects against race conditions using select_for_update.
    """
    if delta_seconds < 0:
        raise ValidationError("Delta seconds cannot be negative.")

    if current_time < 0:
        raise ValidationError("Current time cannot be negative.")

    # Progress safety clamp:
    # Clamp delta_seconds to a maximum of 15.0 seconds per request to prevent cheating,
    # client manipulation, or exaggerated delta updates during network hiccups.
    MAX_ALLOWED_DELTA = 15.0
    if delta_seconds > MAX_ALLOWED_DELTA:
        delta_seconds = MAX_ALLOWED_DELTA

    # Evaluate Anti-Fraud Signal (FIX-12)
    try:
        from apps.core.fraud import evaluate_fraud_signal
        evaluate_fraud_signal(user=user, delta_seconds=delta_seconds, request_ip=request_ip)
    except Exception:
        pass

    with transaction.atomic():
        try:
            session = WatchSession.objects.select_for_update().get(id=session_id, user=user)
        except WatchSession.DoesNotExist:
            raise ValidationError("Watch session not found or does not belong to user.")

        wallet, _ = Wallet.objects.select_for_update().get_or_create(user=user)

        if session.is_completed:
            return {
                'session_id': session.id,
                'coins_earned': 0.0,
                'total_watched_seconds': session.total_watched_seconds,
                'current_position': session.current_position,
                'is_completed': True,
                'wallet_balance': float(wallet.balance),
                'message': 'Video task already completed.'
            }

        old_total = session.total_watched_seconds
        new_total = old_total + delta_seconds
        # Monotonic position: ensure current_position does not jump backward
        new_position = max(session.current_position, current_time)

        task = session.video_task
        coins_earned, is_completed, desc = RewardCalculator.calculate(
            reward_type=task.reward_type,
            reward_config=task.reward_config,
            old_total_seconds=old_total,
            new_total_seconds=new_total,
            current_time=new_position,
            already_completed=session.is_completed
        )


        # Update session
        session.total_watched_seconds = new_total
        session.current_position = new_position
        session.last_watched_at = timezone.now()
        if is_completed:
            session.is_completed = True
        session.save()

        # Update wallet and create ledger transaction if coins earned
        if coins_earned > 0:
            wallet.balance += coins_earned
            wallet.save()

            WalletTransaction.objects.create(
                wallet=wallet,
                amount=coins_earned,
                balance_after=wallet.balance,
                transaction_type='watch_reward',
                description=desc or f"Reward for watching {task.title}",
                reference_id=str(session.id)
            )

        # Gamification Integrations (Phase 1)
        xp_earned = int((delta_seconds / 60.0) * 10)
        if is_completed:
            xp_earned += 50  # Bonus XP on task completion

        lucky_drop = None
        try:
            from apps.gamification.services.xp_service import add_xp
            from apps.gamification.services.quest_service import update_quest_progress
            from apps.gamification.services.badge_service import evaluate_user_badges
            import random

            # Award XP
            if xp_earned > 0:
                add_xp(user, xp_earned, 'watch_video')

            # Update Quests
            update_quest_progress(user, 'watch_seconds', increment=int(delta_seconds))
            if is_completed:
                update_quest_progress(user, 'complete_tasks', increment=1)
                update_quest_progress(user, 'watch_video', increment=1)

            # Lucky Drop (1.7): Check every 600s interval crossed
            old_interval = int(old_total // 600)
            new_interval = int(new_total // 600)
            if new_interval > old_interval and random.random() < 0.05:  # 5% probability
                drop_coins = Decimal(str(random.choice([10.0, 25.0, 50.0])))
                wallet.balance += drop_coins
                wallet.save()
                WalletTransaction.objects.create(
                    wallet=wallet,
                    amount=drop_coins,
                    balance_after=wallet.balance,
                    transaction_type='lucky_drop',
                    description=f"💎 In-Watch Lucky Drop! (+{drop_coins} coins)",
                    reference_id=f"drop_{session.id}_{new_interval}"
                )
                lucky_drop = {
                    'type': 'coins',
                    'value': float(drop_coins),
                    'message': f"💎 Lucky Drop! You found +{drop_coins} Bonus Coins while watching!"
                }

            # Evaluate Badges
            evaluate_user_badges(user)
        except Exception:
            pass

        return {
            'session_id': session.id,
            'coins_earned': float(coins_earned),
            'total_watched_seconds': session.total_watched_seconds,
            'current_position': session.current_position,
            'is_completed': session.is_completed,
            'wallet_balance': float(wallet.balance),
            'xp_earned': xp_earned,
            'lucky_drop': lucky_drop,
            'message': desc or 'Progress updated.'
        }
