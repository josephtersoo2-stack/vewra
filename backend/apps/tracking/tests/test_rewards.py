from decimal import Decimal
from django.test import TestCase
from django.contrib.auth.models import User
from apps.tasks.models import VideoTask, WatchSession
from apps.wallet.models import Wallet, WalletTransaction
from apps.tracking.services import RewardCalculator, process_watch_progress

class RewardCalculatorTestCase(TestCase):
    def test_per_time_reward(self):
        config = {'coins': 10, 'seconds': 60}

        # 0 -> 45s: no reward yet (less than 60s)
        coins, completed, _ = RewardCalculator.calculate(
            reward_type='per_time',
            reward_config=config,
            old_total_seconds=0,
            new_total_seconds=45
        )
        self.assertEqual(coins, Decimal('0.00'))
        self.assertFalse(completed)

        # 45s -> 65s: crossed 60s boundary -> +10 coins
        coins, completed, _ = RewardCalculator.calculate(
            reward_type='per_time',
            reward_config=config,
            old_total_seconds=45,
            new_total_seconds=65
        )
        self.assertEqual(coins, Decimal('10.00'))
        self.assertFalse(completed)

        # 65s -> 185s: crossed 120s and 180s -> +20 coins (2 intervals)
        coins, completed, _ = RewardCalculator.calculate(
            reward_type='per_time',
            reward_config=config,
            old_total_seconds=65,
            new_total_seconds=185
        )
        self.assertEqual(coins, Decimal('20.00'))
        self.assertFalse(completed)

    def test_watch_all_reward(self):
        config = {'coins': 200, 'duration': 100, 'target_percent': 95}

        # Under 95%
        coins, completed, _ = RewardCalculator.calculate(
            reward_type='watch_all',
            reward_config=config,
            old_total_seconds=0,
            new_total_seconds=80,
            current_time=80
        )
        self.assertEqual(coins, Decimal('0.00'))
        self.assertFalse(completed)

        # Reached 95%
        coins, completed, _ = RewardCalculator.calculate(
            reward_type='watch_all',
            reward_config=config,
            old_total_seconds=80,
            new_total_seconds=95,
            current_time=95
        )
        self.assertEqual(coins, Decimal('200.00'))
        self.assertTrue(completed)

    def test_watch_all_missing_duration_raises_error(self):
        from django.core.exceptions import ValidationError
        config = {'coins': 200}
        with self.assertRaises(ValidationError):
            RewardCalculator.calculate(
                reward_type='watch_all',
                reward_config=config,
                old_total_seconds=0,
                new_total_seconds=95
            )

    def test_target_reward(self):
        config = {'coins': 120, 'target_seconds': 300}

        # Under target
        coins, completed, _ = RewardCalculator.calculate(
            reward_type='target',
            reward_config=config,
            old_total_seconds=0,
            new_total_seconds=250
        )
        self.assertEqual(coins, Decimal('0.00'))
        self.assertFalse(completed)

        # Hit target
        coins, completed, _ = RewardCalculator.calculate(
            reward_type='target',
            reward_config=config,
            old_total_seconds=250,
            new_total_seconds=305
        )
        self.assertEqual(coins, Decimal('120.00'))
        self.assertTrue(completed)

    def test_already_completed_gives_zero(self):
        config = {'coins': 10, 'seconds': 60}
        coins, completed, _ = RewardCalculator.calculate(
            reward_type='per_time',
            reward_config=config,
            old_total_seconds=120,
            new_total_seconds=240,
            already_completed=True
        )
        self.assertEqual(coins, Decimal('0.00'))
        self.assertTrue(completed)

class TrackingIntegrationTestCase(TestCase):
    def setUp(self):
        self.user = User.objects.create_user(username='tester', email='test@vewra.com', password='password123')
        self.wallet = Wallet.objects.get(user=self.user)
        self.task = VideoTask.objects.create(
            youtube_url='https://www.youtube.com/watch?v=dQw4w9WgXcQ',
            video_id='dQw4w9WgXcQ',
            title='Test YouTube Task',
            keywords=['test', 'music', 'rick'],
            reward_type='per_time',
            reward_config={'coins': 10, 'seconds': 60}
        )
        self.session = WatchSession.objects.create(
            user=self.user,
            video_task=self.task
        )

    def test_process_watch_progress_accumulates_coins_and_ledger(self):
        # First ping: 10 seconds
        res1 = process_watch_progress(
            user=self.user,
            session_id=self.session.id,
            current_time=10.0,
            delta_seconds=10.0
        )
        self.assertEqual(res1['coins_earned'], 0.0)
        self.assertEqual(res1['wallet_balance'], 0.0)

        # Second ping: 50 seconds (should be clamped to 15s per ping, total becomes 25s)
        res2 = process_watch_progress(
            user=self.user,
            session_id=self.session.id,
            current_time=25.0,
            delta_seconds=50.0 # Clamped to 15.0s
        )
        self.assertEqual(res2['total_watched_seconds'], 25.0)
        self.assertEqual(res2['coins_earned'], 0.0)

        # Ping up to 65s (four 10s pings: 25 -> 35 -> 45 -> 55 -> 65s)
        for t in [35.0, 45.0, 55.0, 65.0]:
            res = process_watch_progress(
                user=self.user,
                session_id=self.session.id,
                current_time=t,
                delta_seconds=10.0
            )

        self.assertEqual(res['coins_earned'], 10.0)
        self.assertEqual(res['wallet_balance'], 10.0)
        self.assertEqual(res['total_watched_seconds'], 65.0)

        # Check wallet transaction ledger
        transactions = WalletTransaction.objects.filter(wallet=self.wallet)
        self.assertEqual(transactions.count(), 1)
        tx = transactions.first()
        self.assertEqual(tx.amount, Decimal('10.00'))
        self.assertEqual(tx.balance_after, Decimal('10.00'))
        self.assertEqual(tx.transaction_type, 'watch_reward')

