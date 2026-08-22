import math
from django.db import transaction
from apps.gamification.models import UserProfile

LEVEL_PERKS = {
    1: ["Newbie Explorer Status", "Access to Standard Tasks"],
    5: ["Unlock Basic Badge Showcase Slot", "+50 Bonus Coins"],
    10: ["Unlock Coin Shop & Instant Voucher Exchange", "+100 Bonus Coins"],
    20: ["Unlock Guild Creation & Team Squads", "+1 Free Streak Freeze", "+250 Bonus Coins"],
    30: ["Unlock High-Payout Sponsor & Premium Tasks", "+500 Bonus Coins"],
    50: ["Unlock Creator Dashboard (Promote Your Own Videos)", "+1,000 Bonus Coins"],
    75: ["Unlock 2nd Badge Showcase Slot", "+2,500 Bonus Coins"],
    100: ["Prestige Master Rank Unlocked", "Lifetime 1.5x Multiplier", "+5,000 Bonus Coins"],
}

def calculate_level(total_xp: int) -> int:
    """
    Formula from Master Plan: XP_required(level) = level^2 * 20
    Solving for level given XP: level = floor(sqrt(total_xp / 20))
    Capped at minimum 1 and maximum 101.
    """
    if total_xp <= 0:
        return 1
    lvl = int(math.isqrt(total_xp // 20))
    return max(1, min(101, lvl if lvl > 0 else 1))

def get_level_rewards_catalog() -> list[dict]:
    """Returns milestone ladder with unlocked perks."""
    milestones = [1, 5, 10, 20, 30, 50, 75, 100]
    results = []
    for lvl in milestones:
        results.append({
            'level': lvl,
            'xp_required': (lvl ** 2) * 20,
            'perks': LEVEL_PERKS.get(lvl, [])
        })
    return results

def add_xp(user, amount: int, source: str = '') -> dict:
    """
    Awards XP to user, checks for level up, and returns status.
    """
    if amount <= 0:
        profile, _ = UserProfile.objects.get_or_create(user=user)
        return {
            'xp': profile.xp,
            'level': profile.level,
            'leveled_up': False,
            'new_perks': [],
            'xp_for_next_level': profile.xp_for_next_level,
        }

    with transaction.atomic():
        profile, _ = UserProfile.objects.select_for_update().get_or_create(user=user)
        old_level = profile.level
        profile.xp += amount
        new_level = calculate_level(profile.xp)

        leveled_up = new_level > old_level
        new_perks = []
        if leveled_up:
            profile.level = new_level
            # Collect newly unlocked perks
            for lvl in range(old_level + 1, new_level + 1):
                if lvl in LEVEL_PERKS:
                    new_perks.extend(LEVEL_PERKS[lvl])

        profile.save()

        return {
            'xp': profile.xp,
            'level': profile.level,
            'leveled_up': leveled_up,
            'new_perks': new_perks,
            'xp_for_next_level': profile.xp_for_next_level,
            'xp_progress_percent': profile.xp_progress_percent,
        }
