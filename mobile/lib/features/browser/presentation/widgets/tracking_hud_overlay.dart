import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile/core/constants/app_colors.dart';
import 'package:mobile/core/utils/formatters.dart';
import 'package:mobile/features/tasks/domain/video_task_model.dart';

class TrackingHudOverlay extends StatefulWidget {
  final VideoTaskModel task;
  final bool isTargetDetected;
  final bool isTracking;
  final double totalWatchedSeconds;
  final double sessionCoinsEarned;
  final bool isCompleted;

  const TrackingHudOverlay({
    super.key,
    required this.task,
    required this.isTargetDetected,
    required this.isTracking,
    required this.totalWatchedSeconds,
    required this.sessionCoinsEarned,
    required this.isCompleted,
  });

  @override
  State<TrackingHudOverlay> createState() => _TrackingHudOverlayState();
}

class _TrackingHudOverlayState extends State<TrackingHudOverlay> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    // Only appear when the target video is detected or task is completed
    if (!widget.isTargetDetected && !widget.isCompleted) {
      return const SizedBox.shrink();
    }

    final bottomPadding = MediaQuery.paddingOf(context).bottom;

    return Positioned(
      bottom: 16.0 + bottomPadding,
      left: 16,
      right: 16,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surfaceCard.withOpacity(0.96),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: widget.isCompleted
                ? AppColors.success
                : widget.isTargetDetected
                    ? AppColors.primary
                    : AppColors.border,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                // Status Indicator Dot / Icon
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: widget.isCompleted
                        ? AppColors.success.withOpacity(0.2)
                        : widget.isTracking
                            ? AppColors.success.withOpacity(0.2)
                            : AppColors.primary.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    widget.isCompleted
                        ? CupertinoIcons.check_mark_circled_solid
                        : widget.isTracking
                            ? CupertinoIcons.play_circle_fill
                            : CupertinoIcons.pause_circle_fill,
                    color: widget.isCompleted
                        ? AppColors.success
                        : widget.isTracking
                            ? AppColors.success
                            : AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),

                // Status text & Watch Timer
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.isCompleted
                            ? 'Task Completed! 🎉'
                            : widget.isTracking
                                ? 'Tracking Watch Time...'
                                : 'Target Video Paused',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: widget.isCompleted
                              ? AppColors.success
                              : widget.isTracking
                                  ? AppColors.success
                                  : AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(CupertinoIcons.time, size: 12, color: AppColors.textMuted),
                          const SizedBox(width: 4),
                          Text(
                            'Watched: ${Formatters.formatDuration(widget.totalWatchedSeconds)}',
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Coins Earned Pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.coinGold.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.coinGold.withOpacity(0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(CupertinoIcons.circle_filled, color: AppColors.coinGold, size: 12),
                      const SizedBox(width: 5),
                      Text(
                        '+${Formatters.formatCoins(widget.sessionCoinsEarned)}',
                        style: const TextStyle(
                          color: AppColors.coinGold,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 6),
                // Expand / Collapse Info Toggle
                IconButton(
                  icon: Icon(
                    _isExpanded ? CupertinoIcons.chevron_down : CupertinoIcons.info_circle,
                    color: AppColors.textSecondary,
                    size: 20,
                  ),
                  onPressed: () {
                    setState(() {
                      _isExpanded = !_isExpanded;
                    });
                  },
                ),
              ],
            ),

            // Expanded Helper Info
            if (_isExpanded) ...[
              const Divider(color: AppColors.divider, height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Target: ${widget.task.title}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Target Video ID: ${widget.task.videoId}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
