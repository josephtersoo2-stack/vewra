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

def process_watch_progress(user, session_id: int, current_time: float, delta_seconds: float) -> dict:
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

        return {
            'session_id': session.id,
            'coins_earned': float(coins_earned),
            'total_watched_seconds': session.total_watched_seconds,
            'current_position': session.current_position,
            'is_completed': session.is_completed,
            'wallet_balance': float(wallet.balance),
            'message': desc or 'Progress updated.'
        }
