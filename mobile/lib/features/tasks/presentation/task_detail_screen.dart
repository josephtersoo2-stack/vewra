import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile/core/constants/app_colors.dart';
import 'package:mobile/core/utils/formatters.dart';
import 'package:mobile/features/tasks/presentation/tasks_provider.dart';
import 'package:mobile/features/tasks/presentation/widgets/instruction_card.dart';
import 'package:mobile/features/browser/presentation/youtube_browser_screen.dart';

class TaskDetailScreen extends StatefulWidget {
  final int taskId;

  const TaskDetailScreen({super.key, required this.taskId});

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  bool _isStarting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<TasksProvider>(context, listen: false).fetchTaskDetail(widget.taskId);
    });
  }

  void _onStartTask() async {
    setState(() => _isStarting = true);
    final tasksProvider = Provider.of<TasksProvider>(context, listen: false);
    final session = await tasksProvider.startTask(widget.taskId);
    setState(() => _isStarting = false);

    if (!mounted) return;

    if (session != null && tasksProvider.currentTaskDetail != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => YouTubeBrowserScreen(
            task: tasksProvider.currentTaskDetail!,
            session: session,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(tasksProvider.errorMessage ?? 'Could not start task session.'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final tasksProvider = context.watch<TasksProvider>();
    final task = tasksProvider.currentTaskDetail;
    final isLoading = tasksProvider.isLoading && task == null;


    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Details'),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : task == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(CupertinoIcons.exclamationmark_triangle, color: AppColors.error, size: 48),
                      const SizedBox(height: 16),
                      Text(
                        tasksProvider.errorMessage ?? 'Task not found.',
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => tasksProvider.fetchTaskDetail(widget.taskId),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Video Thumbnail & Play Badge
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              height: 190,
                              width: double.infinity,
                              color: AppColors.surface,
                              child: task.thumbnailUrl != null
                                  ? Image.network(
                                      task.thumbnailUrl!,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => const Center(
                                        child: Icon(CupertinoIcons.video_camera, color: AppColors.textMuted, size: 40),
                                      ),
                                    )
                                  : const Center(
                                      child: Icon(CupertinoIcons.video_camera, color: AppColors.textMuted, size: 40),
                                    ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.7),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                CupertinoIcons.play_arrow_solid,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                            if (task.isCompletedByUser)
                              Positioned(
                                top: 12,
                                right: 12,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: AppColors.success,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(CupertinoIcons.check_mark_circled_solid, color: Colors.white, size: 14),
                                      SizedBox(width: 4),
                                      Text(
                                        'COMPLETED',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Title
                      Text(
                        task.title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Reward Configuration Card
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceCard,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.coinGold.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.coinGold.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(CupertinoIcons.circle_filled, color: AppColors.coinGold, size: 18),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Reward Rule',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    task.rewardSummary,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.coinGold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (task.watchedSeconds > 0)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  const Text(
                                    'Watched',
                                    style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                  ),
                                  Text(
                                    Formatters.formatDuration(task.watchedSeconds),
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Randomized Instruction Card
                      if (task.instruction != null) ...[
                        InstructionCard(instruction: task.instruction!),
                        const SizedBox(height: 24),
                      ],

                      // Start Task / Resume Task Action Button
                      SizedBox(
                        height: 54,
                        child: ElevatedButton.icon(
                          onPressed: _isStarting ? null : _onStartTask,
                          icon: _isStarting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Icon(CupertinoIcons.arrow_right_circle_fill, size: 22),
                          label: Text(
                            task.isCompletedByUser
                                ? 'Browse Again (Completed)'
                                : task.watchedSeconds > 0
                                    ? 'Resume Task'
                                    : 'Start Task & Open Browser',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
