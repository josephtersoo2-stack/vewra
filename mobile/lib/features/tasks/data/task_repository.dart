import 'package:mobile/core/constants/api_endpoints.dart';
import 'package:mobile/core/network/api_client.dart';
import 'package:mobile/features/tasks/domain/video_task_model.dart';
import 'package:mobile/features/tasks/domain/watch_session_model.dart';

class TaskRepository {
  final ApiClient _api = ApiClient();

  Future<List<VideoTaskModel>> getTasks() async {
    final response = await _api.get(ApiEndpoints.tasks);
    if (response is List) {
      return response.map((e) => VideoTaskModel.fromJson(e as Map<String, dynamic>)).toList();
    }
    return [];
  }

  Future<VideoTaskModel> getTaskDetail(int id) async {
    final response = await _api.get(ApiEndpoints.taskDetail(id));
    return VideoTaskModel.fromJson(response as Map<String, dynamic>);
  }

  Future<WatchSessionModel> startTask(int id) async {
    final response = await _api.post(ApiEndpoints.taskStart(id));
    final sessionJson = response['session'] as Map<String, dynamic>;
    return WatchSessionModel.fromJson(sessionJson);
  }

  Future<Map<String, dynamic>> sendWatchProgress({
    required int sessionId,
    required double currentTime,
    required double deltaSeconds,
  }) async {
    final response = await _api.post(
      ApiEndpoints.trackingProgress,
      data: {
        'session_id': sessionId,
        'current_time': currentTime,
        'delta_seconds': deltaSeconds,
      },
    );
    return response as Map<String, dynamic>;
  }
}
