import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:mobile/core/constants/app_colors.dart';
import 'package:mobile/core/network/api_client.dart';
import 'package:mobile/features/auth/presentation/auth_provider.dart';
import 'package:mobile/features/tasks/presentation/tasks_provider.dart';
import 'package:mobile/features/tasks/presentation/task_detail_screen.dart';
import 'package:mobile/features/rewards/presentation/daily_bonus_screen.dart';
import 'package:mobile/features/rewards/presentation/spin_wheel_screen.dart';
import 'package:mobile/features/rewards/presentation/scratch_card_screen.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback onOpenDrawer;
  final Function(int) onNavigateTab;

  const HomeScreen({
    super.key,
    required this.onOpenDrawer,
    required this.onNavigateTab,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, dynamic>? _profileData;
  Map<String, dynamic>? _streakData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    try {
      final results = await Future.wait([
        ApiClient().get('/profile/'),
        ApiClient().get('/rewards/daily-status/'),
      ]);
      if (mounted) {
        setState(() {
          _profileData = results[0];
          _streakData = results[1];
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authUser = context.watch<AuthProvider>().user;
    final tasksProvider = context.watch<TasksProvider>();
    final recommendedTasks = tasksProvider.tasks.take(3).toList();

    final username = _profileData?['display_name']?.isNotEmpty == true
        ? _profileData!['display_name']
        : (authUser?.username ?? 'Joseph');
    final level = _profileData?['level'] ?? 12;
    final xp = _profileData?['xp'] ?? 2480;
    final xpNext = _profileData?['xp_for_next_level'] ?? 3000;
    final xpPercent = (_profileData?['xp_progress_percent'] ?? 75.0) / 100.0;
    final streakCount = _streakData?['streak_count'] ?? 7;
    final balance = authUser?.walletBalance ?? 4820.0;
    final isStreakClaimed = _streakData?['is_claimed_today'] ?? false;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(CupertinoIcons.bars, color: AppColors.textPrimary),
          onPressed: widget.onOpenDrawer,
        ),
        title: Text(
          'VEWRA',
          style: GoogleFonts.outfit(
            color: AppColors.textPrimary,
            fontSize: 22,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.bell, color: AppColors.textPrimary),
            onPressed: () {},
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () async {
                await Future.wait([
                  _loadDashboardData(),
                  tasksProvider.fetchTasks(),
                ]);
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // User Greeting Card
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: AppColors.primary.withOpacity(0.2),
                          child: Text(
                            username.substring(0, 1).toUpperCase(),
                            style: const TextStyle(
                              color: AppColors.primaryLight,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Good morning, $username! 👋',
                              style: GoogleFonts.outfit(
                                color: AppColors.textPrimary,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Ready to earn today?',
                              style: GoogleFonts.outfit(
                                color: AppColors.textMuted,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Level XP Banner Card
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceCard,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      gradient: AppColors.primaryGradient,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      'Level $level',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    '$xp / $xpNext XP',
                                    style: GoogleFonts.outfit(
                                      color: AppColors.textSecondary,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              const Text('⭐', style: TextStyle(fontSize: 20)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: xpPercent.clamp(0.0, 1.0),
                              minHeight: 8,
                              backgroundColor: AppColors.surfaceElevated,
                              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Quick Stat Pills (Streak & Balance)
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceElevated,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: AppColors.border),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(CupertinoIcons.flame_fill, color: AppColors.flameOrange, size: 24),
                                      const SizedBox(width: 8),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '$streakCount',
                                            style: GoogleFonts.outfit(
                                              color: AppColors.textPrimary,
                                              fontSize: 16,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                          Text(
                                            'Day Streak',
                                            style: GoogleFonts.outfit(
                                              color: AppColors.textMuted,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceElevated,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: AppColors.border),
                                  ),
                                  child: Row(
                                    children: [
                                      const Text('🪙', style: TextStyle(fontSize: 20)),
                                      const SizedBox(width: 8),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            balance.toStringAsFixed(0),
                                            style: GoogleFonts.outfit(
                                              color: AppColors.coinGold,
                                              fontSize: 16,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                          Text(
                                            'Balance',
                                            style: GoogleFonts.outfit(
                                              color: AppColors.textMuted,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Daily Rewards Card
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceCard,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Daily Rewards',
                                style: GoogleFonts.outfit(
                                  color: AppColors.textPrimary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              GestureDetector(
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const DailyBonusScreen()),
                                ),
                                child: Text(
                                  'View All',
                                  style: GoogleFonts.outfit(
                                    color: AppColors.primaryLight,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // 7-day node timeline
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: List.generate(7, (i) {
                              final isCheck = i < (streakCount % 7);
                              final isToday = i == (streakCount % 7);
                              final isGift = i == 6;

                              return Column(
                                children: [
                                  Text(
                                    ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][i],
                                    style: GoogleFonts.outfit(
                                      color: isToday ? AppColors.textPrimary : AppColors.textMuted,
                                      fontSize: 10,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isCheck
                                          ? AppColors.success
                                          : (isToday ? AppColors.primary : AppColors.surfaceElevated),
                                      border: Border.all(
                                        color: isToday ? AppColors.primaryLight : AppColors.border,
                                      ),
                                    ),
                                    child: Center(
                                      child: isCheck
                                          ? const Icon(Icons.check, color: Colors.white, size: 16)
                                          : (isGift
                                              ? const Text('🎁', style: TextStyle(fontSize: 12))
                                              : Text(
                                                  '${i + 1}',
                                                  style: TextStyle(
                                                    color: isToday ? Colors.white : AppColors.textMuted,
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                )),
                                    ),
                                  ),
                                ],
                              );
                            }),
                          ),

                          const SizedBox(height: 16),

                          // Claim Button
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isStreakClaimed ? AppColors.surfaceElevated : AppColors.primary,
                                foregroundColor: isStreakClaimed ? AppColors.textMuted : Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const DailyBonusScreen()),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    isStreakClaimed ? 'Claimed for Today' : 'Claim Today',
                                    style: GoogleFonts.outfit(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15,
                                    ),
                                  ),
                                  if (!isStreakClaimed) ...[
                                    const SizedBox(width: 8),
                                    const Text('🪙 +120', style: TextStyle(fontWeight: FontWeight.bold)),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Quick Rewards (Spin Wheel & Scratch Card)
                    Text(
                      'Quick Rewards',
                      style: GoogleFonts.outfit(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const SpinWheelScreen()),
                            ),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceCard,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Center(
                                      child: Text('🎡', style: TextStyle(fontSize: 24)),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Spin',
                                        style: GoogleFonts.outfit(
                                          color: AppColors.textPrimary,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      Text(
                                        'Wheel',
                                        style: GoogleFonts.outfit(
                                          color: AppColors.textSecondary,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const ScratchCardScreen()),
                            ),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceCard,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: AppColors.coinGold.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Center(
                                      child: Text('🎴', style: TextStyle(fontSize: 24)),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Scratch',
                                        style: GoogleFonts.outfit(
                                          color: AppColors.textPrimary,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      Text(
                                        'Card',
                                        style: GoogleFonts.outfit(
                                          color: AppColors.textSecondary,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Recommended Tasks
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Recommended Tasks',
                          style: GoogleFonts.outfit(
                            color: AppColors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => widget.onNavigateTab(1),
                          child: Text(
                            'See All',
                            style: GoogleFonts.outfit(
                              color: AppColors.primaryLight,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    if (recommendedTasks.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceCard,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Center(
                          child: Text(
                            'No recommended tasks right now.',
                            style: GoogleFonts.outfit(color: AppColors.textMuted),
                          ),
                        ),
                      )
                    else
                      ...recommendedTasks.map((task) => Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceCard,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    width: 64,
                                    height: 64,
                                    color: AppColors.surfaceElevated,
                                    child: task.thumbnailUrl != null
                                        ? Image.network(task.thumbnailUrl!, fit: BoxFit.cover)
                                        : const Icon(CupertinoIcons.play_rectangle_fill, color: AppColors.primaryLight, size: 28),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        task.title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.outfit(
                                          color: AppColors.textPrimary,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          const Icon(CupertinoIcons.time, color: AppColors.textMuted, size: 13),
                                          const SizedBox(width: 4),
                                          Text(
                                            '5 min',
                                            style: GoogleFonts.outfit(color: AppColors.textMuted, fontSize: 12),
                                          ),
                                          const SizedBox(width: 10),
                                          const Text('🪙', style: TextStyle(fontSize: 12)),
                                          const SizedBox(width: 4),
                                          Text(
                                            task.rewardSummary,
                                            style: GoogleFonts.outfit(
                                              color: AppColors.coinGold,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 10),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => TaskDetailScreen(taskId: task.id),
                                      ),
                                    );
                                  },
                                  child: const Text('Start', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                          )),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }
}
