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
    return Positioned(
      bottom: 24,
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
                        : widget.isTargetDetected
                            ? AppColors.primary.withOpacity(0.2)
                            : AppColors.secondary.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    widget.isCompleted
                        ? CupertinoIcons.check_mark_circled_solid
                        : widget.isTargetDetected
                            ? CupertinoIcons.play_circle_fill
                            : CupertinoIcons.search,
                    color: widget.isCompleted
                        ? AppColors.success
                        : widget.isTargetDetected
                            ? AppColors.primary
                            : AppColors.secondary,
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
                            : widget.isTargetDetected
                                ? (widget.isTracking ? 'Tracking Watch Time...' : 'Target Video Paused')
                                : 'Searching Target Video...',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: widget.isCompleted
                              ? AppColors.success
                              : widget.isTargetDetected
                                  ? AppColors.textPrimary
                                  : AppColors.textSecondary,
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

            // Search Prompt Banner when searching target video
            if (!widget.isTargetDetected && !widget.isCompleted && widget.task.instruction != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.background.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(CupertinoIcons.search, size: 14, color: AppColors.secondary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        widget.task.instruction!.searchQuery,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: widget.task.instruction!.searchQuery));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Search phrase copied! Paste into YouTube search.'),
                            backgroundColor: AppColors.success,
                            duration: Duration(seconds: 2),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(CupertinoIcons.doc_on_doc, size: 12, color: AppColors.primaryLight),
                            SizedBox(width: 4),
                            Text('Copy', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primaryLight)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Expanded Helper Info
            if (_isExpanded) ...[
              const Divider(color: AppColors.divider, height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Target Video: ${widget.task.title}',
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
                      'Search phrase: "${widget.task.instruction?.searchQuery ?? widget.task.title}"',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.secondary,
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
