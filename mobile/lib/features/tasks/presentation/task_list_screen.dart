import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:mobile/core/constants/app_colors.dart';
import 'package:mobile/features/tasks/presentation/tasks_provider.dart';
import 'package:mobile/features/tasks/presentation/task_detail_screen.dart';

class TaskListScreen extends StatefulWidget {
  final VoidCallback? onOpenDrawer;

  const TaskListScreen({super.key, this.onOpenDrawer});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  int _selectedFilter = 0; // 0: All, 1: Video, 2: Surveys, 3: Social, 4: Daily, 5: Quest

  final List<String> _filterCategories = ['All', 'Video', 'Surveys', 'Social', 'Daily', 'Quest'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TasksProvider>().fetchTasks();
    });
  }

  @override
  Widget build(BuildContext context) {
    final tasksProvider = context.watch<TasksProvider>();
    final allTasks = tasksProvider.tasks;

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
          'Earn',
          style: GoogleFonts.outfit(
            color: AppColors.textPrimary,
            fontSize: 22,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.0,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.surfaceCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                const Icon(CupertinoIcons.slider_horizontal_3, color: AppColors.primaryLight, size: 16),
                const SizedBox(width: 6),
                Text(
                  'Filter',
                  style: GoogleFonts.outfit(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () => tasksProvider.fetchTasks(),
        child: Column(
          children: [
            // Filter Horizontal Chips
            Container(
              height: 48,
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _filterCategories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final isSelected = _selectedFilter == index;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedFilter = index),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary : AppColors.surfaceCard,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? AppColors.primaryLight : AppColors.border,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          _filterCategories[index],
                          style: GoogleFonts.outfit(
                            color: isSelected ? Colors.white : AppColors.textSecondary,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 8),

            // Task List View
            Expanded(
              child: tasksProvider.isLoading && allTasks.isEmpty
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                  : allTasks.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('📺', style: TextStyle(fontSize: 48)),
                              const SizedBox(height: 12),
                              Text(
                                'No Tasks Available',
                                style: GoogleFonts.outfit(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'New tasks will be published shortly!',
                                style: GoogleFonts.outfit(color: AppColors.textMuted, fontSize: 13),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: allTasks.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final task = allTasks[index];
                            return _buildTaskCard(task);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskCard(dynamic task) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          // Thumbnail / Icon
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: 68,
              height: 68,
              color: AppColors.surfaceElevated,
              child: task.thumbnailUrl != null
                  ? Image.network(task.thumbnailUrl!, fit: BoxFit.cover)
                  : const Center(
                      child: Icon(CupertinoIcons.play_rectangle_fill, color: AppColors.primaryLight, size: 30),
                    ),
            ),
          ),
          const SizedBox(width: 14),

          // Details
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
                Text(
                  'Video Task',
                  style: GoogleFonts.outfit(
                    color: AppColors.textMuted,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 6),
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
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 10),

          // Start Button
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TaskDetailScreen(taskId: task.id),
                ),
              );
            },
            child: const Text('Start', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}
