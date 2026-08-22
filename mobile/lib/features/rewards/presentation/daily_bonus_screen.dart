import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/core/constants/app_colors.dart';
import 'package:mobile/core/network/api_client.dart';

class DailyBonusScreen extends StatefulWidget {
  const DailyBonusScreen({super.key});

  @override
  State<DailyBonusScreen> createState() => _DailyBonusScreenState();
}

class _DailyBonusScreenState extends State<DailyBonusScreen> {
  bool _isLoading = true;
  bool _isClaiming = false;
  Map<String, dynamic>? _streakData;

  @override
  void initState() {
    super.initState();
    _fetchStreakStatus();
  }

  Future<void> _fetchStreakStatus() async {
    try {
      final res = await ApiClient().get('/rewards/daily-status/');
      if (mounted) {
        setState(() {
          _streakData = res;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _claimReward() async {
    setState(() => _isClaiming = true);
    try {
      final res = await ApiClient().post('/rewards/daily-claim/');
      if (mounted) {
        final data = res;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.success,
            content: Row(
              children: [
                const Icon(CupertinoIcons.checkmark_circle_fill, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text(data['message'] ?? 'Claimed successfully!')),
              ],
            ),
          ),
        );
        _fetchStreakStatus();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppColors.error,
            content: Text('Failed to claim daily reward.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isClaiming = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final streakCount = _streakData?['streak_count'] ?? 1;
    final isClaimed = _streakData?['is_claimed_today'] ?? false;
    final calendar = (_streakData?['calendar'] as List<dynamic>?) ?? [];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Daily Bonus'),
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Flame Streak Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceCard,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            gradient: AppColors.fireStreakGradient,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.flameOrange.withOpacity(0.4),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(CupertinoIcons.flame_fill, color: Colors.white, size: 32),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '$streakCount Day Streak',
                          style: GoogleFonts.outfit(
                            color: AppColors.textPrimary,
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "You're on fire! 🔥",
                          style: GoogleFonts.outfit(
                            color: AppColors.flameOrange,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // 7-Day Node Timeline
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: List.generate(7, (index) {
                            final dayIdx = index + 1;
                            final dayInfo = calendar.length > index ? calendar[index] : null;
                            final isDayClaimed = dayInfo?['is_claimed'] ?? false;
                            final isDayCurrent = dayInfo?['is_current'] ?? (dayIdx == ((streakCount % 7) == 0 ? 7 : (streakCount % 7)));
                            final isMystery = dayIdx == 7;

                            return Column(
                              children: [
                                Text(
                                  ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][index],
                                  style: GoogleFonts.outfit(
                                    color: isDayCurrent ? AppColors.textPrimary : AppColors.textMuted,
                                    fontSize: 12,
                                    fontWeight: isDayCurrent ? FontWeight.w700 : FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isDayClaimed
                                        ? AppColors.success
                                        : (isDayCurrent ? AppColors.primary : AppColors.surfaceElevated),
                                    border: Border.all(
                                      color: isDayCurrent ? AppColors.primaryLight : AppColors.border,
                                      width: isDayCurrent ? 2 : 1,
                                    ),
                                    boxShadow: isDayCurrent
                                        ? [
                                            BoxShadow(
                                              color: AppColors.primary.withOpacity(0.4),
                                              blurRadius: 8,
                                              offset: const Offset(0, 2),
                                            ),
                                          ]
                                        : null,
                                  ),
                                  child: Center(
                                    child: isDayClaimed
                                        ? const Icon(Icons.check, color: Colors.white, size: 20)
                                        : (isMystery
                                            ? const Text('🎁', style: TextStyle(fontSize: 16))
                                            : Text(
                                                'D$dayIdx',
                                                style: TextStyle(
                                                  color: isDayCurrent ? Colors.white : AppColors.textSecondary,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 11,
                                                ),
                                              )),
                                  ),
                                ),
                              ],
                            );
                          }),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Today's Reward Showcase Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.surfaceCard,
                          AppColors.surfaceElevated,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      children: [
                        Text(
                          "Today's Reward",
                          style: GoogleFonts.outfit(
                            color: AppColors.textSecondary,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('🪙', style: TextStyle(fontSize: 36)),
                            const SizedBox(width: 8),
                            Text(
                              '+${_streakData?['next_day_reward'] ?? 5.0}',
                              style: GoogleFonts.outfit(
                                color: AppColors.coinGold,
                                fontSize: 38,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Coins',
                              style: GoogleFonts.outfit(
                                color: AppColors.coinGoldLight,
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isClaimed ? AppColors.surfaceElevated : AppColors.primary,
                              foregroundColor: isClaimed ? AppColors.textMuted : Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            onPressed: (isClaimed || _isClaiming) ? null : _claimReward,
                            child: _isClaiming
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                                  )
                                : Text(
                                    isClaimed ? 'Claimed for Today' : 'Claim Reward',
                                    style: GoogleFonts.outfit(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "Come back tomorrow for Day ${((streakCount) % 7) + 1} and a bigger reward!",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(
                            color: AppColors.textMuted,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
