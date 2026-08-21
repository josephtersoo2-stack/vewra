import 'dart:async';
import 'dart:collection';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import 'package:provider/provider.dart';
import 'package:mobile/core/constants/app_colors.dart';
import 'package:mobile/core/utils/formatters.dart';
import 'package:mobile/features/auth/presentation/auth_provider.dart';

import 'package:mobile/features/tasks/domain/video_task_model.dart';
import 'package:mobile/features/tasks/domain/watch_session_model.dart';
import 'package:mobile/features/tasks/presentation/tasks_provider.dart';
import 'package:mobile/features/tasks/data/task_repository.dart';
import 'package:mobile/features/browser/tracking/youtube_js_tracker.dart';
import 'package:mobile/features/browser/presentation/widgets/tracking_hud_overlay.dart';

class YouTubeBrowserScreen extends StatefulWidget {
  final VideoTaskModel task;
  final WatchSessionModel session;

  const YouTubeBrowserScreen({
    super.key,
    required this.task,
    required this.session,
  });

  @override
  State<YouTubeBrowserScreen> createState() => _YouTubeBrowserScreenState();
}

class _YouTubeBrowserScreenState extends State<YouTubeBrowserScreen> {
  InAppWebViewController? _webViewController;
  final TaskRepository _taskRepo = TaskRepository();

  bool _isTargetDetected = false;
  bool _isPlaying = false;
  bool _isCompleted = false;
  double _totalWatchedSeconds = 0.0;
  double _sessionCoinsEarned = 0.0;
  double _lastReportedCurrentTime = 0.0;
  DateTime _lastProgressPingTime = DateTime.now();

  double _loadingProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _totalWatchedSeconds = widget.session.totalWatchedSeconds;
    _lastReportedCurrentTime = widget.session.currentPosition;
    _isCompleted = widget.session.isCompleted;
  }

  @override
  void dispose() {
    _flushRemainingProgress();
    super.dispose();
  }

  void _flushRemainingProgress() {
    // Attempt one last progress update if needed
    if (_isTargetDetected && !_isCompleted && _lastReportedCurrentTime > 0) {
      _sendProgress(0.0, _lastReportedCurrentTime);
    }
  }

  void _handleTrackerMessage(List<dynamic> args) {
    if (args.isEmpty || args.first is! Map) return;

    final data = Map<String, dynamic>.from(args.first as Map);
    final eventType = data['eventType'] as String? ?? '';
    final videoId = data['videoId'] as String?;
    final currentTime = (data['currentTime'] is num) ? (data['currentTime'] as num).toDouble() : 0.0;
    final isPlaying = data['isPlaying'] as bool? ?? false;

    final isTarget = (videoId != null && videoId == widget.task.videoId);

    setState(() {
      _isTargetDetected = isTarget;
      _isPlaying = isPlaying;
    });

    if (isTarget) {
      _processPlaybackUpdate(eventType: eventType, currentTime: currentTime, isPlaying: isPlaying);
    }
  }

  void _processPlaybackUpdate({
    required String eventType,
    required double currentTime,
    required bool isPlaying,
  }) {
    if (_isCompleted || !_isTargetDetected) return;

    final now = DateTime.now();
    final elapsedWallTime = now.difference(_lastProgressPingTime).inMilliseconds / 1000.0;

    // Calculate sensible delta seconds safely
    double deltaSeconds = 0.0;
    if (_lastReportedCurrentTime > 0 && currentTime > _lastReportedCurrentTime) {
      final timeDiff = currentTime - _lastReportedCurrentTime;
      // Filter out forward seeks/jumps: cap max incremental chunk to 15s
      deltaSeconds = timeDiff.clamp(0.0, 15.0);
    } else if (isPlaying && elapsedWallTime >= 2.5) {
      deltaSeconds = elapsedWallTime.clamp(0.0, 15.0);
    }

    if (elapsedWallTime >= 3.0 || eventType == 'pause' || eventType == 'ended') {
      if (deltaSeconds > 0 || currentTime > _lastReportedCurrentTime) {
        _sendProgress(deltaSeconds, currentTime);
      }
    }
  }

  Future<void> _sendProgress(double deltaSeconds, double currentTime) async {
    // Strictly verify target video is detected and session is not completed
    if (_isCompleted || !_isTargetDetected) return;

    // Ensure delta is never negative and capped at 15.0 seconds
    final double safeDelta = deltaSeconds.clamp(0.0, 15.0);
    final double effectiveDelta = safeDelta > 0 ? safeDelta : 2.5;

    _lastProgressPingTime = DateTime.now();
    _lastReportedCurrentTime = currentTime;

    debugPrint(
      '[Vewra Tracker] Sending progress ping: sessionId=${widget.session.id}, targetId=${widget.task.videoId}, currentTime=$currentTime, deltaSeconds=$effectiveDelta',
    );

    try {
      final res = await _taskRepo.sendWatchProgress(
        sessionId: widget.session.id,
        currentTime: currentTime,
        deltaSeconds: effectiveDelta,
      );

      final coinsEarned = (res['coins_earned'] is num) ? (res['coins_earned'] as num).toDouble() : 0.0;
      final totalWatched = (res['total_watched_seconds'] is num)
          ? (res['total_watched_seconds'] as num).toDouble()
          : _totalWatchedSeconds + effectiveDelta;
      final completed = res['is_completed'] as bool? ?? false;
      final walletBal = (res['wallet_balance'] is num) ? (res['wallet_balance'] as num).toDouble() : null;

      if (!mounted) return;


      setState(() {
        _totalWatchedSeconds = totalWatched;
        _isCompleted = completed;
        if (coinsEarned > 0) {
          _sessionCoinsEarned += coinsEarned;
        }
      });

      // Update global providers
      if (walletBal != null) {
        Provider.of<AuthProvider>(context, listen: false).updateBalance(walletBal);
      }
      Provider.of<TasksProvider>(context, listen: false).updateSessionProgress(
        currentPosition: currentTime,
        totalWatched: totalWatched,
        isCompleted: completed,
      );

      if (coinsEarned > 0) {
        _showCoinRewardSnackBar(coinsEarned);
      }

      if (completed) {
        _showCompletionDialog();
      }
    } catch (_) {}
  }

  void _showCoinRewardSnackBar(double coins) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(CupertinoIcons.circle_filled, color: AppColors.coinGold, size: 18),
            const SizedBox(width: 8),
            Text(
              '+${Formatters.formatCoins(coins)} Coins Earned!',
              style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.white),
            ),
          ],
        ),
        backgroundColor: AppColors.surfaceLight,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(CupertinoIcons.star_circle_fill, color: AppColors.coinGold, size: 30),
            SizedBox(width: 10),
            Text('Task Complete! 🎉', style: TextStyle(fontWeight: FontWeight.w800)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You successfully watched "${widget.task.title}" and earned your rewards!',
              style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total Earned:', style: TextStyle(fontWeight: FontWeight.w600)),
                  Text(
                    '+${Formatters.formatCoins(_sessionCoinsEarned)} Coins',
                    style: const TextStyle(
                      color: AppColors.coinGold,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context); // return to tasks
            },
            child: const Text('Back to Tasks'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final initialUrl = widget.task.instruction?.searchQuery.isNotEmpty == true
        ? 'https://m.youtube.com/results?search_query=${Uri.encodeComponent(widget.task.instruction!.searchQuery)}'
        : 'https://m.youtube.com';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isTargetDetected ? '🟢 Tracking: ${widget.task.title}' : 'YouTube Browser',
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.refresh, size: 20),
            tooltip: 'Reload Page',
            onPressed: () => _webViewController?.reload(),
          ),
        ],
        bottom: _loadingProgress < 1.0
            ? PreferredSize(
                preferredSize: const Size.fromHeight(2),
                child: LinearProgressIndicator(
                  value: _loadingProgress,
                  backgroundColor: Colors.transparent,
                  color: AppColors.primary,
                  minHeight: 2,
                ),
              )
            : null,
      ),
      body: Stack(
        children: [
          InAppWebView(
            initialUrlRequest: URLRequest(url: WebUri(initialUrl)),
            initialSettings: InAppWebViewSettings(
              javaScriptEnabled: true,
              mediaPlaybackRequiresUserGesture: false,
              allowsInlineMediaPlayback: true,
              isElementFullscreenEnabled: true,
              supportMultipleWindows: false,
            ),
            initialUserScripts: UnmodifiableListView<UserScript>([
              UserScript(
                source: YouTubeJsTracker.trackingScript,
                injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START,
              ),
              UserScript(
                source: YouTubeJsTracker.trackingScript,
                injectionTime: UserScriptInjectionTime.AT_DOCUMENT_END,
              ),
            ]),
            onWebViewCreated: (controller) {
              _webViewController = controller;
              controller.addJavaScriptHandler(
                handlerName: 'YouTubeTracker',
                callback: _handleTrackerMessage,
              );
            },
            onLoadStop: (controller, url) async {
              setState(() => _loadingProgress = 1.0);
              await controller.evaluateJavascript(source: YouTubeJsTracker.trackingScript);
            },
            onProgressChanged: (controller, progress) {
              setState(() {
                _loadingProgress = progress / 100.0;
              });
            },
          ),

          // Floating Tracking HUD Overlay
          TrackingHudOverlay(
            task: widget.task,
            isTargetDetected: _isTargetDetected,
            isTracking: _isPlaying,
            totalWatchedSeconds: _totalWatchedSeconds,
            sessionCoinsEarned: _sessionCoinsEarned,
            isCompleted: _isCompleted,
          ),
        ],
      ),
    );
  }
}
