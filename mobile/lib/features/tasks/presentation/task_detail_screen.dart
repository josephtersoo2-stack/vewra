import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:mobile/core/constants/app_colors.dart';
import 'package:mobile/features/tasks/presentation/tasks_provider.dart';
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
      context.read<TasksProvider>().fetchTaskDetail(widget.taskId);
    });
  }

  void _onStartTask() async {
    setState(() => _isStarting = true);
    final tasksProvider = context.read<TasksProvider>();
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Task Details'),
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.share),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Task link copied to clipboard!')),
              );
            },
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : task == null
              ? Center(
                  child: Text(
                    tasksProvider.errorMessage ?? 'Task not found.',
                    style: GoogleFonts.outfit(color: AppColors.textSecondary),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Hero Thumbnail with Play Icon
                      ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              height: 200,
                              width: double.infinity,
                              color: AppColors.surfaceElevated,
                              child: task.thumbnailUrl != null
                                  ? Image.network(task.thumbnailUrl!, fit: BoxFit.cover)
                                  : const Icon(CupertinoIcons.play_rectangle_fill, color: AppColors.primaryLight, size: 48),
                            ),
                            Container(
                              width: 58,
                              height: 58,
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.65),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white24, width: 2),
                              ),
                              child: const Icon(CupertinoIcons.play_fill, color: Colors.white, size: 28),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 18),

                      // Title
                      Text(
                        task.title,
                        style: GoogleFonts.outfit(
                          color: AppColors.textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Tag Pills
                      Row(
                        children: [
                          _buildTag(CupertinoIcons.play_rectangle_fill, 'Video Task', AppColors.primary),
                          const SizedBox(width: 8),
                          _buildTag(CupertinoIcons.time, '5 min', AppColors.surfaceElevated),
                          const SizedBox(width: 8),
                          _buildTag(Icons.monetization_on, task.rewardSummary, AppColors.coinGold.withOpacity(0.2), textColor: AppColors.coinGold),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Instructions Section
                      Text(
                        'Instructions',
                        style: GoogleFonts.outfit(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _buildBullet('Search and watch the video on YouTube.'),
                      _buildBullet('Watch the full required video time to receive coins.'),
                      _buildBullet('Do not change playback speed or minimize the browser.'),

                      const SizedBox(height: 24),

                      // Random Search Instruction Box
                      Text(
                        'Random Search Instruction',
                        style: GoogleFonts.outfit(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Search on YouTube for:',
                        style: GoogleFonts.outfit(color: AppColors.textMuted, fontSize: 13),
                      ),
                      const SizedBox(height: 10),

                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceCard,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                task.instruction?.searchQuery ?? task.title,
                                style: GoogleFonts.outfit(
                                  color: AppColors.textPrimary,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(CupertinoIcons.doc_on_doc, color: AppColors.primaryLight, size: 20),
                              onPressed: () {
                                Clipboard.setData(
                                  ClipboardData(text: task.instruction?.searchQuery ?? task.title),
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Search keyword copied!'),
                                    duration: Duration(seconds: 1),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Prominent Purple Start Task CTA
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            shadowColor: AppColors.primary.withOpacity(0.5),
                            elevation: 8,
                          ),
                          onPressed: _isStarting ? null : _onStartTask,
                          child: _isStarting
                              ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)
                              : Text(
                                  'Start Task',
                                  style: GoogleFonts.outfit(
                                    color: Colors.white,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildTag(IconData icon, String label, Color bgColor, {Color? textColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor ?? Colors.white),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.outfit(
              color: textColor ?? Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(color: AppColors.primaryLight, fontSize: 16)),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.outfit(color: AppColors.textSecondary, fontSize: 14, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
