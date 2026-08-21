import 'package:flutter/material.dart';
import 'package:mobile/core/network/api_exception.dart';
import 'package:mobile/features/tasks/data/task_repository.dart';
import 'package:mobile/features/tasks/domain/video_task_model.dart';
import 'package:mobile/features/tasks/domain/watch_session_model.dart';

class TasksProvider extends ChangeNotifier {
  final TaskRepository _repo = TaskRepository();

  List<VideoTaskModel> _tasks = [];
  bool _isLoading = false;
  String? _errorMessage;

  VideoTaskModel? _currentTaskDetail;
  WatchSessionModel? _activeSession;

  List<VideoTaskModel> get tasks => _tasks;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  VideoTaskModel? get currentTaskDetail => _currentTaskDetail;
  WatchSessionModel? get activeSession => _activeSession;

  Future<void> fetchTasks() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _tasks = await _repo.getTasks();
      _isLoading = false;
      notifyListeners();
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to load tasks: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<VideoTaskModel?> fetchTaskDetail(int id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentTaskDetail = await _repo.getTaskDetail(id);
      _isLoading = false;
      notifyListeners();
      return _currentTaskDetail;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
      return null;
    } catch (e) {
      _errorMessage = 'Failed to load task: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<WatchSessionModel?> startTask(int taskId) async {
    try {
      _activeSession = await _repo.startTask(taskId);
      notifyListeners();
      return _activeSession;
    } catch (e) {
      _errorMessage = 'Could not start watch session: ${e.toString()}';
      notifyListeners();
      return null;
    }
  }

  void updateSessionProgress({
    required double currentPosition,
    required double totalWatched,
    required bool isCompleted,
  }) {
    if (_activeSession != null) {
      _activeSession = _activeSession!.copyWith(
        currentPosition: currentPosition,
        totalWatchedSeconds: totalWatched,
        isCompleted: isCompleted,
      );
      notifyListeners();
    }
  }

  void markTaskCompleted(int taskId) {
    fetchTasks();
  }


  void clearCurrentTask() {
    _currentTaskDetail = null;
    _activeSession = null;
    notifyListeners();
  }
}
