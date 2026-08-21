import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile/core/constants/app_colors.dart';
import 'package:mobile/core/utils/formatters.dart';
import 'package:mobile/features/auth/presentation/auth_provider.dart';
import 'package:mobile/features/tasks/presentation/tasks_provider.dart';
import 'package:mobile/features/tasks/presentation/widgets/task_card.dart';
import 'package:mobile/features/tasks/presentation/task_detail_screen.dart';

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<TasksProvider>(context, listen: false).fetchTasks();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final tasksProvider = context.watch<TasksProvider>();
    final user = authProvider.user;


    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(CupertinoIcons.play_rectangle_fill, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 10),
            const Text(
              'Vewra Tasks',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
            ),
          ],
        ),
        actions: [
          // Quick Balance Badge in App Bar
          if (user != null)
            Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.surfaceCard,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.coinGold.withOpacity(0.4)),
              ),
              child: Row(
                children: [
                  const Icon(CupertinoIcons.circle_filled, color: AppColors.coinGold, size: 14),
                  const SizedBox(width: 6),
                  Text(
                    Formatters.formatCoins(user.walletBalance),
                    style: const TextStyle(
                      color: AppColors.coinGold,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await tasksProvider.fetchTasks();
          await authProvider.refreshUser();
        },
        color: AppColors.primary,
        backgroundColor: AppColors.surfaceCard,
        child: tasksProvider.isLoading && tasksProvider.tasks.isEmpty
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              )
            : tasksProvider.errorMessage != null && tasksProvider.tasks.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(CupertinoIcons.exclamationmark_triangle, color: AppColors.error, size: 48),
                          const SizedBox(height: 16),
                          Text(
                            tasksProvider.errorMessage!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: () => tasksProvider.fetchTasks(),
                            child: const Text('Try Again'),
                          ),
                        ],
                      ),
                    ),
                  )
                : tasksProvider.tasks.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(CupertinoIcons.tv, color: AppColors.textMuted, size: 54),
                            const SizedBox(height: 16),
                            const Text(
                              'No Active Tasks Available',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Check back soon for new video tasks!',
                              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                            ),
                            const SizedBox(height: 20),
                            OutlinedButton.icon(
                              onPressed: () => tasksProvider.fetchTasks(),
                              icon: const Icon(CupertinoIcons.refresh, size: 16),
                              label: const Text('Refresh'),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 24.0 + MediaQuery.paddingOf(context).bottom),
                        itemCount: tasksProvider.tasks.length + 1,
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Welcome, ${user?.username ?? 'Viewer'}!',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'Available Video Tasks',
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  const Text(
                                    'Complete guided searches to earn coins.',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }

                          final task = tasksProvider.tasks[index - 1];
                          return TaskCard(
                            task: task,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => TaskDetailScreen(taskId: task.id),
                                ),
                              );
                            },
                          );
                        },
                      ),
      ),
    );
  }
}
