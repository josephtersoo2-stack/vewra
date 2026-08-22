import 'dart:async';
import 'dart:collection';
import 'package:flutter/foundation.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import 'package:mobile/features/browser/presentation/widgets/reward_celebration_dialog.dart';

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
  bool _isGoogleLoggedIn = false;
  double _totalWatchedSeconds = 0.0;
  double _sessionCoinsEarned = 0.0;
  double _lastReportedCurrentTime = 0.0;
  DateTime _lastProgressPingTime = DateTime.now();

  double _loadingProgress = 0.0;
  Timer? _webPlaybackTimer;

  @override
  void initState() {
    super.initState();
    _totalWatchedSeconds = widget.session.totalWatchedSeconds;
    _lastReportedCurrentTime = widget.session.currentPosition;
    _isCompleted = widget.session.isCompleted;

    if (kIsWeb) {
      // In Web preview mode, auto-detect target video and login initially for convenient testing
      _isTargetDetected = true;
      _isGoogleLoggedIn = true;
    }
  }

  @override
  void dispose() {
    _webPlaybackTimer?.cancel();
    _flushRemainingProgress();
    super.dispose();
  }

  void _flushRemainingProgress() {
    if (_isTargetDetected && !_isCompleted && _lastReportedCurrentTime > 0 && (_isGoogleLoggedIn || kIsWeb)) {
      _sendProgress(0.0, _lastReportedCurrentTime);
    }
  }

  void _handleTrackerMessage(List<dynamic> args) {
    if (args.isEmpty || args.first is! Map) return;

    final Map<dynamic, dynamic> data = args.first as Map<dynamic, dynamic>;
    final eventType = data['eventType']?.toString() ?? '';
    final videoId = data['videoId']?.toString();
    final currentTime = (data['currentTime'] is num) ? (data['currentTime'] as num).toDouble() : 0.0;
    final isPlaying = data['isPlaying'] == true;
    final bool? isGoogleLoggedIn = data['isGoogleLoggedIn'] as bool?;

    final isTarget = (videoId != null && videoId == widget.task.videoId);

    setState(() {
      _isTargetDetected = isTarget;
      _isPlaying = isPlaying;
      if (isGoogleLoggedIn != null) {
        _isGoogleLoggedIn = isGoogleLoggedIn;
      }
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

    // Do not accumulate / send watch progress if not logged in to Google account
    if (!_isGoogleLoggedIn && !kIsWeb) return;

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
    // Strictly verify target video is detected, user is logged in, and session is not completed
    if (!_isTargetDetected || _isCompleted || (!_isGoogleLoggedIn && !kIsWeb)) return;
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

      // Update global user wallet balance
      if (walletBal != null) {
        context.read<AuthProvider>().updateWalletBalance(walletBal);
      }

      // Mark completed in tasks provider if done
      if (completed) {
        context.read<TasksProvider>().markTaskCompleted(widget.task.id);
        _showCompletedDialog();
      } else if (coinsEarned > 0) {
        _showRewardToast(coinsEarned);
      }
    } catch (e) {
      debugPrint('[Vewra Tracker] Failed to send watch progress: $e');
    }
  }

  void _showRewardToast(double coins) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.surfaceCard,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.coinGold),
        ),

        duration: const Duration(seconds: 2),
        content: Row(
          children: [
            const Icon(CupertinoIcons.star_circle_fill, color: AppColors.coinGold, size: 24),
            const SizedBox(width: 12),
            Text(
              '+${Formatters.formatCoins(coins)} Coins Earned!',
              style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.coinGold),
            ),
          ],
        ),
      ),
    );
  }

  void _showCompletedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => RewardCelebrationDialog(
        taskTitle: widget.task.title,
        coinsEarned: _sessionCoinsEarned > 0 ? _sessionCoinsEarned : 50.0,
        watchedSeconds: _totalWatchedSeconds,
        onContinue: () {
          Navigator.of(ctx).pop();
          Navigator.of(context).pop();
        },
        onViewMore: () {
          Navigator.of(ctx).pop();
          Navigator.of(context).pop();
        },
      ),
    );
  }

  // --- Web Preview Simulator Controls ---
  void _toggleWebPlayPause() {
    setState(() {
      _isPlaying = !_isPlaying;
    });

    if (_isPlaying) {
      _webPlaybackTimer?.cancel();
      _webPlaybackTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!_isPlaying || _isCompleted) {
          timer.cancel();
          return;
        }

        final nextTime = _lastReportedCurrentTime + 1.0;
        _processPlaybackUpdate(eventType: 'timeupdate', currentTime: nextTime, isPlaying: true);
      });
    } else {
      _webPlaybackTimer?.cancel();
      _processPlaybackUpdate(eventType: 'pause', currentTime: _lastReportedCurrentTime, isPlaying: false);
    }
  }

  void _simulateFastForward(double seconds) {
    if (_isCompleted) return;
    final nextTime = _lastReportedCurrentTime + seconds;
    _processPlaybackUpdate(eventType: 'timeupdate', currentTime: nextTime, isPlaying: _isPlaying);
  }

  Widget _buildWebSimulatorView() {
    return Container(
      color: AppColors.background,
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 140),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(

              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Info Banner
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceCard,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
                  ),
                  child: const Row(
                    children: [
                      Icon(CupertinoIcons.info_circle_fill, color: AppColors.primary, size: 22),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Web Browser Preview Mode: Native Android/iOS devices use full InAppWebView with automatic JavaScript injection.',
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Video Thumbnail & Player Mockup
                Container(
                  height: 220,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _isTargetDetected ? AppColors.success : AppColors.border, width: 2),
                    image: DecorationImage(
                      image: NetworkImage(
                        (widget.task.thumbnailUrl != null && widget.task.thumbnailUrl!.isNotEmpty)
                            ? widget.task.thumbnailUrl!
                            : 'https://img.youtube.com/vi/${widget.task.videoId}/hqdefault.jpg',
                      ),

                      fit: BoxFit.cover,
                      opacity: _isPlaying ? 0.7 : 0.4,
                    ),
                  ),

                  child: Stack(
                    children: [
                      Center(
                        child: InkWell(
                          onTap: _toggleWebPlayPause,
                          borderRadius: BorderRadius.circular(40),
                          child: Container(
                            width: 68,
                            height: 68,
                            decoration: BoxDecoration(
                              color: (_isPlaying ? AppColors.primary : AppColors.error).withValues(alpha: 0.9),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.5),
                                  blurRadius: 12,
                                ),
                              ],
                            ),
                            child: Icon(
                              _isPlaying ? CupertinoIcons.pause_fill : CupertinoIcons.play_arrow_solid,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 12,
                        left: 12,
                        right: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.8),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: _isPlaying ? AppColors.success : AppColors.textMuted,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    _isPlaying ? 'PLAYING (Tracking Active)' : 'PAUSED',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: _isPlaying ? AppColors.success : AppColors.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                '${Formatters.formatDuration(_lastReportedCurrentTime.toInt())} elapsed',
                                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Simulator Controls Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceCard,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Playback Simulation Controls',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _toggleWebPlayPause,
                              icon: Icon(_isPlaying ? CupertinoIcons.pause : CupertinoIcons.play_arrow_solid, size: 18),
                              label: Text(_isPlaying ? 'Pause' : 'Play Video'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _isPlaying ? AppColors.surface : AppColors.primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _simulateFastForward(10.0),
                              icon: const Icon(CupertinoIcons.forward_fill, size: 18),
                              label: const Text('+10s Forward'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                setState(() {
                                  _isTargetDetected = !_isTargetDetected;
                                });
                              },
                              icon: Icon(
                                _isTargetDetected ? CupertinoIcons.checkmark_alt_circle : CupertinoIcons.xmark_circle,
                                size: 18,
                                color: _isTargetDetected ? AppColors.success : AppColors.error,
                              ),
                              label: Text(_isTargetDetected ? 'Target Detected' : 'Wrong Video'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _simulateFastForward(45.0),
                              icon: const Icon(CupertinoIcons.forward_end_alt_fill, size: 18),
                              label: const Text('Seek +45s (Clamped)'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Open clean YouTube home page without auto-populating search
    const initialUrl = 'https://m.youtube.com';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isTargetDetected ? '🟢 Tracking: ${widget.task.title}' : 'YouTube Browser',
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          if (widget.task.instruction != null)
            IconButton(
              icon: const Icon(CupertinoIcons.doc_on_doc, size: 18),
              tooltip: 'Copy Search Phrase',
              onPressed: () {
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
            ),
          IconButton(
            icon: const Icon(CupertinoIcons.refresh, size: 20),
            tooltip: 'Reload Page',
            onPressed: () => _webViewController?.reload(),
          ),
        ],
        bottom: _loadingProgress < 1.0 && !kIsWeb
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
          if (kIsWeb)
            _buildWebSimulatorView()
          else
            InAppWebView(
              initialUrlRequest: URLRequest(url: WebUri(initialUrl)),
              initialSettings: InAppWebViewSettings(
                javaScriptEnabled: true,
                mediaPlaybackRequiresUserGesture: false,
                allowsInlineMediaPlayback: true,
                isElementFullscreenEnabled: true,
                supportMultipleWindows: true,
                thirdPartyCookiesEnabled: true,
                domStorageEnabled: true,
                databaseEnabled: true,
                saveFormData: true,
                sharedCookiesEnabled: true,
                userAgent: 'Mozilla/5.0 (Linux; Android 13; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/128.0.0.0 Mobile Safari/537.36',
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

          // Google Login Required Notice Banner (Auto-dismisses when user logs in)
          if (!_isGoogleLoggedIn && !kIsWeb)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: const BoxDecoration(
                  color: Color(0xFFD97706), // Amber-600 warning
                  boxShadow: [
                    BoxShadow(color: Colors.black38, blurRadius: 8, offset: Offset(0, 3)),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(CupertinoIcons.exclamationmark_triangle_fill, color: Colors.white, size: 20),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Google Login Required',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          Text(
                            'Sign in to YouTube to start earning coins from watch time.',
                            style: TextStyle(color: Colors.white, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () {
                        _webViewController?.loadUrl(
                          urlRequest: URLRequest(
                            url: WebUri('https://accounts.google.com/ServiceLogin?service=youtube&continue=https://m.youtube.com'),
                          ),
                        );
                      },
                      child: const Text('Sign In', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
                    ),
                  ],
                ),
              ),
            ),

          // Floating Tracking HUD Overlay
          TrackingHudOverlay(
            task: widget.task,
            isTargetDetected: _isTargetDetected,
            isTracking: _isPlaying,
            totalWatchedSeconds: _totalWatchedSeconds,
            sessionCoinsEarned: _sessionCoinsEarned,
            isCompleted: _isCompleted,
            isGoogleLoggedIn: _isGoogleLoggedIn,
            onSignInTap: () {
              _webViewController?.loadUrl(
                urlRequest: URLRequest(
                  url: WebUri('https://accounts.google.com/ServiceLogin?service=youtube&continue=https://m.youtube.com'),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
