class TaskInstruction {
  final String searchQuery;
  final String fullInstruction;
  final String title;
  final String? thumbnailUrl;

  TaskInstruction({
    required this.searchQuery,
    required this.fullInstruction,
    required this.title,
    this.thumbnailUrl,
  });

  factory TaskInstruction.fromJson(Map<String, dynamic> json) {
    return TaskInstruction(
      searchQuery: json['search_query'] as String? ?? '',
      fullInstruction: json['full_instruction'] as String? ?? '',
      title: json['title'] as String? ?? '',
      thumbnailUrl: json['thumbnail_url'] as String?,
    );
  }
}

class VideoTaskModel {
  final int id;
  final String videoId;
  final String title;
  final List<String> keywords;
  final String? thumbnailUrl;
  final String rewardType;
  final Map<String, dynamic> rewardConfig;
  final String rewardSummary;
  final bool isCompletedByUser;
  final double watchedSeconds;
  final String? youtubeUrl;
  final TaskInstruction? instruction;

  VideoTaskModel({
    required this.id,
    required this.videoId,
    required this.title,
    required this.keywords,
    this.thumbnailUrl,
    required this.rewardType,
    required this.rewardConfig,
    required this.rewardSummary,
    this.isCompletedByUser = false,
    this.watchedSeconds = 0.0,
    this.youtubeUrl,
    this.instruction,
  });

  factory VideoTaskModel.fromJson(Map<String, dynamic> json) {
    return VideoTaskModel(
      id: json['id'] as int,
      videoId: json['video_id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      keywords: (json['keywords'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      thumbnailUrl: json['thumbnail_url'] as String?,
      rewardType: json['reward_type'] as String? ?? 'per_time',
      rewardConfig: (json['reward_config'] as Map<String, dynamic>?) ?? {},
      rewardSummary: json['reward_summary'] as String? ?? '',
      isCompletedByUser: json['is_completed_by_user'] as bool? ?? false,
      watchedSeconds: (json['watched_seconds'] is num)
          ? (json['watched_seconds'] as num).toDouble()
          : double.tryParse(json['watched_seconds']?.toString() ?? '0') ?? 0.0,
      youtubeUrl: json['youtube_url'] as String?,
      instruction: json['instruction'] != null
          ? TaskInstruction.fromJson(json['instruction'] as Map<String, dynamic>)
          : null,
    );
  }
}
