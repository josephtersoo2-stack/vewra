import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:mobile/core/constants/app_colors.dart';
import 'package:mobile/core/network/api_client.dart';
import 'package:mobile/features/auth/presentation/auth_provider.dart';
import 'package:mobile/features/progress/presentation/achievements_screen.dart';

class ProfileScreen extends StatefulWidget {
  final VoidCallback? onOpenDrawer;

  const ProfileScreen({super.key, this.onOpenDrawer});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _profileData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    try {
      final res = await ApiClient().get('/profile/');
      if (mounted) {
        setState(() {
          _profileData = res;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;

    final displayName = _profileData?['display_name']?.isNotEmpty == true
        ? _profileData!['display_name']
        : (user?.username ?? 'Joseph');
    final username = user?.username ?? 'joseph_vewra';
    final level = _profileData?['level'] ?? 12;
    final xp = _profileData?['xp'] ?? 2480;
    final xpNext = _profileData?['xp_for_next_level'] ?? 3000;
    final xpPercent = (_profileData?['xp_progress_percent'] ?? 75.0) / 100.0;
    final tasksCount = _profileData?['tasks_completed_count'] ?? 128;
    final totalCoins = user?.walletBalance ?? 4820.0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: widget.onOpenDrawer != null
            ? IconButton(
                icon: const Icon(CupertinoIcons.bars, color: AppColors.textPrimary),
                onPressed: widget.onOpenDrawer,
              )
            : null,
        title: Text(
          'Profile',
          style: GoogleFonts.outfit(
            color: AppColors.textPrimary,
            fontSize: 22,
            fontWeight: FontWeight.w900,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.pencil),
            onPressed: () {
              _showEditProfileDialog(displayName);
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                children: [
                  // User Avatar & Name Center Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceCard,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: AppColors.primaryGradient,
                            border: Border.all(color: AppColors.primaryLight, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.4),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              displayName.substring(0, 1).toUpperCase(),
                              style: const TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          displayName,
                          style: GoogleFonts.outfit(
                            color: AppColors.textPrimary,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '@$username',
                          style: GoogleFonts.outfit(
                            color: AppColors.textMuted,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Level & XP Progress
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Level $level',
                              style: GoogleFonts.outfit(
                                color: AppColors.primaryLight,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '$xp / $xpNext XP',
                              style: GoogleFonts.outfit(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: xpPercent.clamp(0.0, 1.0),
                            minHeight: 8,
                            backgroundColor: AppColors.surfaceElevated,
                            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 3 KPI Stat Cards (Tasks, Earned, Streak)
                  Row(
                    children: [
                      _buildKpiCard('Tasks Completed', '$tasksCount'),
                      const SizedBox(width: 10),
                      _buildKpiCard('Total Earned', totalCoins.toStringAsFixed(0), textColor: AppColors.coinGold),
                      const SizedBox(width: 10),
                      _buildKpiCard('Streak', '7 Days', textColor: AppColors.flameOrange),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Settings Menu List
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surfaceCard,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      children: [
                        _buildSettingsTile(
                          icon: CupertinoIcons.pencil_ellipsis_rectangle,
                          title: 'Edit Profile',
                          onTap: () => _showEditProfileDialog(displayName),
                        ),
                        _buildDivider(),
                        _buildSettingsTile(
                          icon: CupertinoIcons.star_circle_fill,
                          title: 'Achievements & Badges',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const AchievementsScreen()),
                          ),
                        ),
                        _buildDivider(),
                        _buildSettingsTile(
                          icon: CupertinoIcons.gear_alt,
                          title: 'Settings',
                          onTap: () {},
                        ),
                        _buildDivider(),
                        _buildSettingsTile(
                          icon: CupertinoIcons.shield_lefthalf_fill,
                          title: 'Security',
                          onTap: () {},
                        ),
                        _buildDivider(),
                        _buildSettingsTile(
                          icon: CupertinoIcons.bell,
                          title: 'Notifications',
                          onTap: () {},
                        ),
                        _buildDivider(),
                        _buildSettingsTile(
                          icon: CupertinoIcons.question_circle,
                          title: 'Help & Support',
                          onTap: () {},
                        ),
                        _buildDivider(),
                        _buildSettingsTile(
                          icon: CupertinoIcons.info_circle,
                          title: 'About Vewra',
                          onTap: () {},
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Sign Out Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: BorderSide(color: AppColors.error.withOpacity(0.5)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () async {
                        await authProvider.logout();
                      },
                      icon: const Icon(CupertinoIcons.square_arrow_right, size: 18),
                      label: Text(
                        'Log Out',
                        style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 15),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  Widget _buildKpiCard(String title, String value, {Color? textColor}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                color: AppColors.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: GoogleFonts.outfit(
                color: textColor ?? AppColors.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppColors.textSecondary, size: 20),
      title: Text(
        title,
        style: GoogleFonts.outfit(
          color: AppColors.textPrimary,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
      trailing: const Icon(CupertinoIcons.chevron_right, color: AppColors.textMuted, size: 16),
      onTap: onTap,
    );
  }

  Widget _buildDivider() {
    return const Divider(color: AppColors.divider, height: 1, indent: 56);
  }

  void _showEditProfileDialog(String currentName) {
    final controller = TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Edit Display Name'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Enter new display name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isNotEmpty) {
                await ApiClient().patch('/profile/', data: {'display_name': newName});
                _fetchProfile();
              }
              if (mounted) Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
