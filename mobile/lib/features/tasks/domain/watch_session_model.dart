class WatchSessionModel {
  final int id;
  final int videoTaskId;
  final String? taskTitle;
  final String? videoId;
  final double currentPosition;
  final double totalWatchedSeconds;
  final bool isCompleted;
  final String? lastWatchedAt;

  WatchSessionModel({
    required this.id,
    required this.videoTaskId,
    this.taskTitle,
    this.videoId,
    this.currentPosition = 0.0,
    this.totalWatchedSeconds = 0.0,
    this.isCompleted = false,
    this.lastWatchedAt,
  });

  factory WatchSessionModel.fromJson(Map<String, dynamic> json) {
    return WatchSessionModel(
      id: json['id'] as int,
      videoTaskId: json['video_task'] as int? ?? json['video_task_id'] as int? ?? 0,
      taskTitle: json['task_title'] as String?,
      videoId: json['video_id'] as String?,
      currentPosition: (json['current_position'] is num)
          ? (json['current_position'] as num).toDouble()
          : double.tryParse(json['current_position']?.toString() ?? '0') ?? 0.0,
      totalWatchedSeconds: (json['total_watched_seconds'] is num)
          ? (json['total_watched_seconds'] as num).toDouble()
          : double.tryParse(json['total_watched_seconds']?.toString() ?? '0') ?? 0.0,
      isCompleted: json['is_completed'] as bool? ?? false,
      lastWatchedAt: json['last_watched_at'] as String?,
    );
  }

  WatchSessionModel copyWith({
    int? id,
    int? videoTaskId,
    String? taskTitle,
    String? videoId,
    double? currentPosition,
    double? totalWatchedSeconds,
    bool? isCompleted,
    String? lastWatchedAt,
  }) {
    return WatchSessionModel(
      id: id ?? this.id,
      videoTaskId: videoTaskId ?? this.videoTaskId,
      taskTitle: taskTitle ?? this.taskTitle,
      videoId: videoId ?? this.videoId,
      currentPosition: currentPosition ?? this.currentPosition,
      totalWatchedSeconds: totalWatchedSeconds ?? this.totalWatchedSeconds,
      isCompleted: isCompleted ?? this.isCompleted,
      lastWatchedAt: lastWatchedAt ?? this.lastWatchedAt,
    );
  }
}
