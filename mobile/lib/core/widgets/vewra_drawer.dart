import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:mobile/core/constants/app_colors.dart';
import 'package:mobile/features/auth/presentation/auth_provider.dart';
import 'package:mobile/features/rewards/presentation/daily_bonus_screen.dart';
import 'package:mobile/features/rewards/presentation/spin_wheel_screen.dart';
import 'package:mobile/features/rewards/presentation/scratch_card_screen.dart';
import 'package:mobile/features/progress/presentation/achievements_screen.dart';

class VewraDrawer extends StatelessWidget {
  final Function(int) onNavigateTab;

  const VewraDrawer({
    super.key,
    required this.onNavigateTab,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.background,
      child: SafeArea(
        child: Column(
          children: [
            // Drawer Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.4),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Text(
                            'V',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'VEWRA',
                        style: GoogleFonts.outfit(
                          color: AppColors.textPrimary,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(CupertinoIcons.xmark, color: AppColors.textSecondary),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(color: AppColors.divider, height: 1),

            // Scrollable Menu Sections
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                children: [
                  _buildMenuItem(
                    icon: CupertinoIcons.house_fill,
                    title: 'Home',
                    isActive: true,
                    onTap: () {
                      Navigator.pop(context);
                      onNavigateTab(0);
                    },
                  ),

                  const SizedBox(height: 12),
                  _buildSectionHeader('EARN'),
                  _buildMenuItem(
                    icon: CupertinoIcons.play_rectangle_fill,
                    title: 'Video Tasks',
                    onTap: () {
                      Navigator.pop(context);
                      onNavigateTab(1);
                    },
                  ),
                  _buildMenuItem(
                    icon: CupertinoIcons.doc_text_fill,
                    title: 'Surveys',
                    badge: 'NEW',
                    onTap: () {
                      Navigator.pop(context);
                      onNavigateTab(1);
                    },
                  ),
                  _buildMenuItem(
                    icon: CupertinoIcons.chat_bubble_2_fill,
                    title: 'Social Tasks',
                    onTap: () {
                      Navigator.pop(context);
                      onNavigateTab(1);
                    },
                  ),
                  _buildMenuItem(
                    icon: CupertinoIcons.checkmark_circle_fill,
                    title: 'Daily Tasks',
                    onTap: () {
                      Navigator.pop(context);
                      onNavigateTab(1);
                    },
                  ),

                  const SizedBox(height: 12),
                  _buildSectionHeader('REWARDS'),
                  _buildMenuItem(
                    icon: CupertinoIcons.money_dollar_circle_fill,
                    title: 'Wallet',
                    onTap: () {
                      Navigator.pop(context);
                      onNavigateTab(2);
                    },
                  ),
                  _buildMenuItem(
                    icon: CupertinoIcons.gift_fill,
                    title: 'Daily Bonus',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const DailyBonusScreen()),
                      );
                    },
                  ),
                  _buildMenuItem(
                    icon: CupertinoIcons.circle_grid_hex_fill,
                    title: 'Spin Wheel',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SpinWheelScreen()),
                      );
                    },
                  ),
                  _buildMenuItem(
                    icon: CupertinoIcons.square_grid_2x2_fill,
                    title: 'Scratch Card',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ScratchCardScreen()),
                      );
                    },
                  ),

                  const SizedBox(height: 12),
                  _buildSectionHeader('PROGRESS'),
                  _buildMenuItem(
                    icon: CupertinoIcons.star_fill,
                    title: 'XP & Levels',
                    onTap: () {
                      Navigator.pop(context);
                      onNavigateTab(3);
                    },
                  ),
                  _buildMenuItem(
                    icon: CupertinoIcons.star_circle_fill,
                    title: 'Achievements',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AchievementsScreen()),
                      );
                    },
                  ),

                  const SizedBox(height: 12),
                  _buildSectionHeader('ACCOUNT'),
                  _buildMenuItem(
                    icon: CupertinoIcons.person_fill,
                    title: 'Profile',
                    onTap: () {
                      Navigator.pop(context);
                      onNavigateTab(3);
                    },
                  ),
                  _buildMenuItem(
                    icon: CupertinoIcons.gear_alt_fill,
                    title: 'Settings',
                    onTap: () {
                      Navigator.pop(context);
                      onNavigateTab(3);
                    },
                  ),
                ],
              ),
            ),

            // Drawer Footer / Log Out
            const Divider(color: AppColors.divider, height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: ListTile(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                leading: const Icon(CupertinoIcons.square_arrow_left, color: AppColors.error),
                title: Text(
                  'Log Out',
                  style: GoogleFonts.outfit(
                    color: AppColors.error,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  await context.read<AuthProvider>().logout();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, top: 8, bottom: 6),
      child: Text(
        title,
        style: GoogleFonts.outfit(
          color: AppColors.textMuted,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    bool isActive = false,
    String? badge,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        color: isActive ? AppColors.primary.withOpacity(0.15) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: isActive ? Border.all(color: AppColors.primary.withOpacity(0.3)) : null,
      ),
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        leading: Icon(
          icon,
          color: isActive ? AppColors.primaryLight : AppColors.textSecondary,
          size: 20,
        ),
        title: Text(
          title,
          style: GoogleFonts.outfit(
            color: isActive ? AppColors.textPrimary : AppColors.textSecondary,
            fontSize: 14,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
        trailing: badge != null
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  badge,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            : null,
        onTap: onTap,
      ),
    );
  }
}
