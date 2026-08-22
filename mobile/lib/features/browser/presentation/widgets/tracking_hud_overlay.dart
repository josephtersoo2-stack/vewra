import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/core/constants/app_colors.dart';
import 'package:mobile/core/utils/formatters.dart';
import 'package:mobile/features/tasks/domain/video_task_model.dart';
import 'package:mobile/features/browser/presentation/widgets/task_progress_modal.dart';

class TrackingHudOverlay extends StatelessWidget {
  final VideoTaskModel task;
  final bool isTargetDetected;
  final bool isTracking;
  final double totalWatchedSeconds;
  final double sessionCoinsEarned;
  final bool isCompleted;
  final bool isGoogleLoggedIn;
  final VoidCallback? onSignInTap;

  const TrackingHudOverlay({
    super.key,
    required this.task,
    required this.isTargetDetected,
    required this.isTracking,
    required this.totalWatchedSeconds,
    required this.sessionCoinsEarned,
    required this.isCompleted,
    this.isGoogleLoggedIn = true,
    this.onSignInTap,
  });

  @override
  Widget build(BuildContext context) {
    if (!isTargetDetected && !isCompleted) {
      return const SizedBox.shrink();
    }

    final targetSeconds = 300.0;
    final percent = (totalWatchedSeconds / targetSeconds).clamp(0.0, 1.0);
    final percentInt = (percent * 100).toInt();

    return Positioned(
      bottom: 16.0 + MediaQuery.paddingOf(context).bottom,
      left: 16,
      right: 16,
      child: GestureDetector(
        onTap: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => TaskProgressModal(
              taskTitle: task.title,
              totalWatchedSeconds: totalWatchedSeconds,
              targetSeconds: targetSeconds,
              coinsEarned: sessionCoinsEarned,
              isCompleted: isCompleted,
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceCard.withOpacity(0.96),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isCompleted
                  ? AppColors.success
                  : (isTracking ? AppColors.primaryLight : AppColors.border),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Task Progress',
                    style: GoogleFonts.outfit(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isCompleted
                          ? AppColors.success.withOpacity(0.2)
                          : (isTracking ? AppColors.primary.withOpacity(0.2) : AppColors.surfaceElevated),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isCompleted
                              ? CupertinoIcons.checkmark_circle_fill
                              : (isTracking ? CupertinoIcons.play_circle_fill : CupertinoIcons.pause_circle_fill),
                          color: isCompleted ? AppColors.success : (isTracking ? AppColors.primaryLight : AppColors.textMuted),
                          size: 14,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          isCompleted ? 'Complete' : (isTracking ? 'Active' : 'Paused'),
                          style: GoogleFonts.outfit(
                            color: isCompleted ? AppColors.success : (isTracking ? AppColors.primaryLight : AppColors.textMuted),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Watch for 5 minutes',
                    style: GoogleFonts.outfit(color: AppColors.textSecondary, fontSize: 13),
                  ),
                  Text(
                    '${Formatters.formatDuration(totalWatchedSeconds)} / ${Formatters.formatDuration(targetSeconds)} ($percentInt%)',
                    style: GoogleFonts.outfit(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: percent,
                  minHeight: 6,
                  backgroundColor: AppColors.surfaceElevated,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isCompleted ? AppColors.success : AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: 8),

              Text(
                'Do not close the app or minimize the player',
                style: GoogleFonts.outfit(
                  color: AppColors.textMuted,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
