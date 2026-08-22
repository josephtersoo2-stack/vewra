import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/core/constants/app_colors.dart';
import 'package:mobile/core/utils/formatters.dart';

class TaskProgressModal extends StatelessWidget {
  final String taskTitle;
  final double totalWatchedSeconds;
  final double targetSeconds;
  final double coinsEarned;
  final bool isCompleted;

  const TaskProgressModal({
    super.key,
    required this.taskTitle,
    required this.totalWatchedSeconds,
    this.targetSeconds = 300.0,
    required this.coinsEarned,
    required this.isCompleted,
  });

  @override
  Widget build(BuildContext context) {
    final percent = targetSeconds > 0 ? (totalWatchedSeconds / targetSeconds).clamp(0.0, 1.0) : 0.0;
    final int percentInt = (percent * 100).toInt();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.borderLight,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          // Title
          Text(
            'Task Progress',
            style: GoogleFonts.outfit(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 24),

          // Circular Progress Ring (Screen 6 in mockup)
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 140,
                height: 140,
                child: CircularProgressIndicator(
                  value: percent,
                  strokeWidth: 10,
                  backgroundColor: AppColors.surfaceElevated,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$percentInt%',
                    style: GoogleFonts.outfit(
                      color: AppColors.textPrimary,
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    '${Formatters.formatDuration(totalWatchedSeconds)} / ${Formatters.formatDuration(targetSeconds)}',
                    style: GoogleFonts.outfit(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 28),

          // Step Timeline Checklist
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                _buildTimelineStep(
                  isDone: true,
                  title: 'Task Started',
                  subtitle: 'Initial session established',
                ),
                const SizedBox(height: 12),
                _buildTimelineStep(
                  isDone: true,
                  title: 'Target Video Detected',
                  subtitle: 'YouTube player synchronized',
                ),
                const SizedBox(height: 12),
                _buildTimelineStep(
                  isDone: totalWatchedSeconds > 0,
                  isActive: !isCompleted && totalWatchedSeconds > 0,
                  title: isCompleted ? 'Watch Goal Reached' : 'Watching & Accumulating..',
                  subtitle: 'Watch time: ${Formatters.formatDuration(totalWatchedSeconds)}',
                ),
                const SizedBox(height: 12),
                _buildTimelineStep(
                  isDone: isCompleted,
                  title: 'Reward Credited',
                  subtitle: isCompleted ? 'Coins saved to wallet' : 'Pending completion',
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Notice
          Text(
            'Keep watching to complete the task and earn your reward.',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              color: AppColors.textMuted,
              fontSize: 13,
            ),
          ),

          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text('Back to Video'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineStep({
    required bool isDone,
    bool isActive = false,
    required String title,
    required String subtitle,
  }) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDone
                ? AppColors.success
                : (isActive ? AppColors.primary : AppColors.surfaceCard),
            border: Border.all(
              color: isDone
                  ? AppColors.success
                  : (isActive ? AppColors.primaryLight : AppColors.borderLight),
            ),
          ),
          child: Center(
            child: isDone
                ? const Icon(Icons.check, size: 14, color: Colors.white)
                : (isActive
                    ? const SizedBox(
                        width: 10,
                        height: 10,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const SizedBox.shrink()),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.outfit(
                  color: isDone || isActive ? AppColors.textPrimary : AppColors.textMuted,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                subtitle,
                style: GoogleFonts.outfit(
                  color: AppColors.textMuted,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
