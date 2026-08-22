import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/core/constants/app_colors.dart';
import 'package:mobile/core/utils/formatters.dart';

class RewardCelebrationDialog extends StatelessWidget {
  final String taskTitle;
  final double coinsEarned;
  final double watchedSeconds;
  final VoidCallback onContinue;
  final VoidCallback onViewMore;

  const RewardCelebrationDialog({
    super.key,
    required this.taskTitle,
    required this.coinsEarned,
    required this.watchedSeconds,
    required this.onContinue,
    required this.onViewMore,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: AppColors.primaryLight.withOpacity(0.6), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.4),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 3D Glowing Gold Coin
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.coinGold.withOpacity(0.15),
                border: Border.all(color: AppColors.coinGold, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.coinGold.withOpacity(0.4),
                    blurRadius: 24,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Center(
                child: Text('🪙', style: TextStyle(fontSize: 48)),
              ),
            ),

            const SizedBox(height: 20),

            // Congratulations Headline
            Text(
              'Great Job!',
              style: GoogleFonts.outfit(
                color: AppColors.textPrimary,
                fontSize: 24,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "You've earned ",
                  style: GoogleFonts.outfit(color: AppColors.textSecondary, fontSize: 16),
                ),
                Text(
                  '+${Formatters.formatCoins(coinsEarned)} 🪙',
                  style: GoogleFonts.outfit(
                    color: AppColors.coinGold,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Task Summary Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    taskTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Completed in ${Formatters.formatDuration(watchedSeconds)}',
                    style: GoogleFonts.outfit(
                      color: AppColors.success,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // Action Buttons
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  shadowColor: AppColors.primary.withOpacity(0.5),
                  elevation: 6,
                ),
                onPressed: onContinue,
                child: Text(
                  'Continue',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            TextButton(
              onPressed: onViewMore,
              child: Text(
                'View More Tasks',
                style: GoogleFonts.outfit(
                  color: AppColors.primaryLight,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
