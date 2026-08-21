import 'dart:async';
import 'dart:collection';
import 'package:flutter/foundation.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:provider/provider.dart';
import 'package:mobile/core/constants/app_colors.dart';
import 'package:mobile/features/auth/presentation/auth_provider.dart';
import 'package:mobile/features/tasks/presentation/tasks_provider.dart';
import 'package:mobile/features/tasks/domain/video_task_model.dart';
import 'package:mobile/features/tasks/domain/watch_session_model.dart';
import 'package:mobile/features/tasks/data/task_repository.dart';
import 'package:mobile/features/browser/tracking/youtube_js_tracker.dart';
import 'package:mobile/features/browser/presentation/widgets/tracking_hud_overlay.dart';

class BrowserTab {
  final String id;
  String url;
  String title;
  InAppWebViewController? controller;
  double progress;
  bool isHomePage;
  bool canGoBack;
  bool canGoForward;

  // Video Tracking State
  VideoTaskModel? detectedTask;
  WatchSessionModel? session;
  bool isTargetDetected;
  bool isPlaying;
  bool isGoogleLoggedIn;
  double totalWatchedSeconds;
  double sessionCoinsEarned;
  bool isCompleted;
  DateTime lastProgressPingTime;
  double lastReportedCurrentTime;

  BrowserTab({
    required this.id,
    this.url = '',
    this.title = 'New Tab',
    this.controller,
    this.progress = 0.0,
    this.isHomePage = true,
    this.canGoBack = false,
    this.canGoForward = false,
    this.detectedTask,
    this.session,
    this.isTargetDetected = false,
    this.isPlaying = false,
    this.isGoogleLoggedIn = false,
    this.totalWatchedSeconds = 0.0,
    this.sessionCoinsEarned = 0.0,
    this.isCompleted = false,
    DateTime? lastProgressPingTime,
    this.lastReportedCurrentTime = 0.0,
  }) : lastProgressPingTime = lastProgressPingTime ?? DateTime.now();
}

class GeneralBrowserScreen extends StatefulWidget {
  final String? initialUrl;

  const GeneralBrowserScreen({super.key, this.initialUrl});

  @override
  State<GeneralBrowserScreen> createState() => _GeneralBrowserScreenState();
}

class _GeneralBrowserScreenState extends State<GeneralBrowserScreen> {
  final TaskRepository _taskRepo = TaskRepository();
  final TextEditingController _urlController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  final List<BrowserTab> _tabs = [];
  int _activeTabIndex = 0;

  // Bookmarks list
  final List<Map<String, String>> _bookmarks = [
    {
      'title': 'Google',
      'url': 'https://www.google.com',
      'icon': '🔍',
      'color': '0xFF4285F4',
    },
    {
      'title': 'YouTube',
      'url': 'https://m.youtube.com',
      'icon': '▶️',
      'color': '0xFFFF0000',
    },
    {
      'title': 'Wikipedia',
      'url': 'https://www.wikipedia.org',
      'icon': '📚',
      'color': '0xFF636466',
    },
    {
      'title': 'Bing',
      'url': 'https://www.bing.com',
      'icon': '🌐',
      'color': '0xFF00809D',
    },
  ];

  BrowserTab get _currentTab {
    if (_tabs.isEmpty) {
      _addNewTab(url: widget.initialUrl);
    }
    if (_activeTabIndex >= _tabs.length) {
      _activeTabIndex = _tabs.length - 1;
    }
    return _tabs[_activeTabIndex];
  }

  @override
  void initState() {
    super.initState();
    _addNewTab(url: widget.initialUrl);
  }

  @override
  void dispose() {
    _urlController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _addNewTab({String? url}) {
    final String initial = url != null && url.isNotEmpty ? _normalizeUrl(url) : '';
    final newTab = BrowserTab(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      url: initial,
      title: initial.isNotEmpty ? initial : 'New Tab',
      isHomePage: initial.isEmpty,
    );

    setState(() {
      _tabs.add(newTab);
      _activeTabIndex = _tabs.length - 1;
      _urlController.text = newTab.url;
    });
  }

  void _closeTab(int index) {
    if (_tabs.length <= 1) {
      // If only one tab left, reset it to home
      setState(() {
        _tabs[0].url = '';
        _tabs[0].title = 'New Tab';
        _tabs[0].isHomePage = true;
        _tabs[0].isTargetDetected = false;
        _tabs[0].detectedTask = null;
        _urlController.clear();
      });
      return;
    }

    setState(() {
      _tabs.removeAt(index);
      if (_activeTabIndex >= _tabs.length) {
        _activeTabIndex = _tabs.length - 1;
      }
      _urlController.text = _currentTab.isHomePage ? '' : _currentTab.url;
    });
  }

  void _switchTab(int index) {
    setState(() {
      _activeTabIndex = index;
      _urlController.text = _currentTab.isHomePage ? '' : _currentTab.url;
    });
  }

  String _normalizeUrl(String input) {
    String trimmed = input.trim();
    if (trimmed.isEmpty) return 'https://www.google.com';

    // If it looks like a URL (has dots, no spaces)
    if (!trimmed.contains(' ') && (trimmed.contains('.') || trimmed.startsWith('localhost'))) {
      if (!trimmed.startsWith('http://') && !trimmed.startsWith('https://')) {
        return 'https://$trimmed';
      }
      return trimmed;
    }

    // Otherwise treat as Google search
    return 'https://www.google.com/search?q=${Uri.encodeComponent(trimmed)}';
  }

  void _loadUrl(String url) {
    final normalized = _normalizeUrl(url);
    final tab = _currentTab;

    setState(() {
      tab.url = normalized;
      tab.isHomePage = false;
      tab.title = normalized;
      _urlController.text = normalized;
    });
    _focusNode.unfocus();

    if (tab.controller != null && !kIsWeb) {
      tab.controller!.loadUrl(
        urlRequest: URLRequest(url: WebUri(normalized)),
      );
    }
  }

  void _goHome() {
    final tab = _currentTab;
    setState(() {
      tab.isHomePage = true;
      tab.url = '';
      tab.title = 'New Tab';
      tab.isTargetDetected = false;
      tab.detectedTask = null;
      _urlController.clear();
    });
    _focusNode.unfocus();
  }

  // --- Universal YouTube Tracker Handler for General Browser ---
  void _handleTrackerMessage(List<dynamic> args, BrowserTab tab) {
    if (args.isEmpty || args[0] is! Map) return;

    final data = Map<String, dynamic>.from(args[0] as Map);
    final eventType = data['eventType']?.toString() ?? 'timeupdate';
    final videoId = data['videoId']?.toString();
    final currentTime = (data['currentTime'] is num) ? (data['currentTime'] as num).toDouble() : 0.0;
    final isPlaying = data['isPlaying'] == true;
    final bool? isGoogleLoggedIn = data['isGoogleLoggedIn'] as bool?;

    // Check if videoId matches ANY active VideoTask from TasksProvider
    final tasksProvider = Provider.of<TasksProvider>(context, listen: false);
    VideoTaskModel? matchedTask;
    for (final t in tasksProvider.tasks) {
      if (videoId != null && t.videoId == videoId) {
        matchedTask = t;
        break;
      }
    }

    setState(() {
      if (isGoogleLoggedIn != null) {
        tab.isGoogleLoggedIn = isGoogleLoggedIn;
      }
      if (matchedTask != null) {
        tab.detectedTask = matchedTask;
        tab.isTargetDetected = true;
        tab.isPlaying = isPlaying;
      } else if (tab.isTargetDetected) {
        tab.isTargetDetected = false;
        tab.isPlaying = false;
      }
    });

    if (matchedTask != null) {
      // Initialize session if not started
      if (tab.session == null) {
        _startSessionForTab(tab, matchedTask);
      } else {
        _processPlaybackUpdate(tab, eventType: eventType, currentTime: currentTime, isPlaying: isPlaying);
      }
    }
  }

  Future<void> _startSessionForTab(BrowserTab tab, VideoTaskModel task) async {
    try {
      final session = await _taskRepo.startTask(task.id);
      setState(() {
        tab.session = session;
        tab.totalWatchedSeconds = session.totalWatchedSeconds;
        tab.isCompleted = session.isCompleted;
        tab.lastProgressPingTime = DateTime.now();
        tab.lastReportedCurrentTime = session.currentPosition;
      });
    } catch (e) {
      debugPrint('[GeneralBrowser] Failed to start watch session: $e');
    }
  }

  void _processPlaybackUpdate(
    BrowserTab tab, {
    required String eventType,
    required double currentTime,
    required bool isPlaying,
  }) {
    if (tab.isCompleted || !tab.isTargetDetected || tab.session == null) return;

    // Do not accumulate / send watch progress if not logged in to Google account
    if (!tab.isGoogleLoggedIn && !kIsWeb) return;

    final now = DateTime.now();
    final elapsedWallTime = now.difference(tab.lastProgressPingTime).inMilliseconds / 1000.0;

    double deltaSeconds = 0.0;
    if (tab.lastReportedCurrentTime > 0 && currentTime > tab.lastReportedCurrentTime) {
      final timeDiff = currentTime - tab.lastReportedCurrentTime;
      deltaSeconds = timeDiff.clamp(0.0, 15.0);
    } else if (isPlaying && elapsedWallTime >= 2.5) {
      deltaSeconds = elapsedWallTime.clamp(0.0, 15.0);
    }

    if (elapsedWallTime >= 3.0 || eventType == 'pause' || eventType == 'ended') {
      if (deltaSeconds > 0 || currentTime > tab.lastReportedCurrentTime) {
        _sendProgress(tab, deltaSeconds, currentTime);
      }
    }
  }

  Future<void> _sendProgress(BrowserTab tab, double deltaSeconds, double currentTime) async {
    if (tab.isCompleted || !tab.isTargetDetected || tab.session == null || (!tab.isGoogleLoggedIn && !kIsWeb)) return;

    final double safeDelta = deltaSeconds.clamp(0.0, 15.0);
    final double effectiveDelta = safeDelta > 0 ? safeDelta : 2.5;

    tab.lastProgressPingTime = DateTime.now();
    tab.lastReportedCurrentTime = currentTime;

    try {
      final res = await _taskRepo.sendWatchProgress(
        sessionId: tab.session!.id,
        deltaSeconds: effectiveDelta,
        currentTime: currentTime,
      );

      final totalSeconds = (res['total_watched_seconds'] is num)
          ? (res['total_watched_seconds'] as num).toDouble()
          : tab.totalWatchedSeconds + effectiveDelta;
      final coinsEarned = (res['coins_earned'] is num)
          ? (res['coins_earned'] as num).toDouble()
          : 0.0;
      final completed = res['is_completed'] == true;

      setState(() {
        tab.totalWatchedSeconds = totalSeconds;
        tab.sessionCoinsEarned += coinsEarned;
        tab.isCompleted = completed;
      });

      if (coinsEarned > 0 && mounted) {
        Provider.of<AuthProvider>(context, listen: false).refreshUser();
      }
    } catch (e) {
      debugPrint('[GeneralBrowser] Progress send failed: $e');
    }
  }

  void _showTabSwitcher() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.background,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Container(
                padding: const EdgeInsets.all(20),
                height: MediaQuery.of(context).size.height * 0.7,
                child: Column(
                  children: [
                    // Header with New Tab action
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Open Tabs (${_tabs.length})',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                        ),
                        Row(
                          children: [
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: () {
                                Navigator.pop(ctx);
                                _addNewTab();
                              },
                              icon: const Icon(CupertinoIcons.plus, size: 16),
                              label: const Text('New Tab'),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(CupertinoIcons.xmark, size: 20),
                              onPressed: () => Navigator.pop(ctx),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const Divider(color: AppColors.divider, height: 24),

                    // Grid of Tabs
                    Expanded(
                      child: GridView.builder(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 14,
                          mainAxisSpacing: 14,
                          childAspectRatio: 0.85,
                        ),
                        itemCount: _tabs.length,
                        itemBuilder: (context, idx) {
                          final t = _tabs[idx];
                          final isSelected = idx == _activeTabIndex;

                          return GestureDetector(
                            onTap: () {
                              _switchTab(idx);
                              Navigator.pop(ctx);
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppColors.surfaceCard,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isSelected ? AppColors.primary : AppColors.border,
                                  width: isSelected ? 2.0 : 1.0,
                                ),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: AppColors.primary.withOpacity(0.3),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // Tab Top Bar
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? AppColors.primary.withOpacity(0.15)
                                          : AppColors.surface,
                                      borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          t.isTargetDetected
                                              ? CupertinoIcons.play_rectangle_fill
                                              : CupertinoIcons.globe,
                                          size: 14,
                                          color: t.isTargetDetected
                                              ? AppColors.success
                                              : (isSelected ? AppColors.primary : AppColors.textSecondary),
                                        ),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            t.isHomePage ? 'Home' : t.title,
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                              color: isSelected ? AppColors.primary : AppColors.textPrimary,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        GestureDetector(
                                          onTap: () {
                                            _closeTab(idx);
                                            setModalState(() {});
                                            if (_tabs.isEmpty) {
                                              Navigator.pop(ctx);
                                            }
                                          },
                                          child: const Icon(CupertinoIcons.xmark, size: 14, color: AppColors.textMuted),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Tab Preview Card
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            t.isHomePage
                                                ? CupertinoIcons.compass
                                                : (t.isTargetDetected ? CupertinoIcons.play_circle_fill : CupertinoIcons.globe),
                                            size: 32,
                                            color: t.isTargetDetected
                                                ? AppColors.success
                                                : (isSelected ? AppColors.primary : AppColors.textMuted),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            t.isHomePage
                                                ? 'Start Page'
                                                : (t.detectedTask?.title ?? t.url),
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          if (t.isTargetDetected) ...[
                                            const SizedBox(height: 4),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: AppColors.success.withOpacity(0.2),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: const Text(
                                                'Tracking Active',
                                                style: TextStyle(fontSize: 9, color: AppColors.success, fontWeight: FontWeight.bold),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final tab = _currentTab;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 8,
        title: Container(
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.border, width: 1),
          ),
          child: Row(
            children: [
              const SizedBox(width: 12),
              const Icon(CupertinoIcons.globe, size: 18, color: AppColors.textSecondary),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _urlController,
                  focusNode: _focusNode,
                  keyboardType: TextInputType.url,
                  textInputAction: TextInputAction.go,
                  style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: tab.isHomePage ? 'Search or enter website address...' : tab.title,
                    hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  onSubmitted: _loadUrl,
                ),
              ),
              if (_urlController.text.isNotEmpty)
                IconButton(
                  icon: const Icon(CupertinoIcons.clear_circled_solid, size: 16, color: AppColors.textMuted),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  onPressed: () {
                    setState(() {
                      _urlController.clear();
                    });
                  },
                ),
              IconButton(
                icon: const Icon(CupertinoIcons.arrow_right_circle_fill, size: 22, color: AppColors.primary),
                padding: const EdgeInsets.only(right: 8),
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                onPressed: () => _loadUrl(_urlController.text),
              ),
            ],
          ),
        ),
        actions: [
          // Tab Switcher Button with open tabs count
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: InkWell(
              onTap: _showTabSwitcher,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.primary, width: 1.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    '${_tabs.length}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(CupertinoIcons.plus, size: 22),
            tooltip: 'New Tab',
            onPressed: () => _addNewTab(),
          ),
          const SizedBox(width: 4),
        ],
        bottom: tab.progress > 0 && tab.progress < 1.0 && !tab.isHomePage
            ? PreferredSize(
                preferredSize: const Size.fromHeight(2),
                child: LinearProgressIndicator(
                  value: tab.progress,
                  backgroundColor: Colors.transparent,
                  color: AppColors.primary,
                  minHeight: 2,
                ),
              )
            : null,
      ),
      body: Stack(
        children: [
          // IndexedStack of open Tab WebViews to preserve state
          IndexedStack(
            index: _activeTabIndex,
            children: _tabs.map((t) {
              if (t.isHomePage) {
                return _buildBookmarksView();
              }
              if (kIsWeb) {
                return _buildWebFallbackView(t);
              }
              return InAppWebView(
                key: ValueKey(t.id),
                initialUrlRequest: URLRequest(url: WebUri(t.url)),
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
                  t.controller = controller;
                  controller.addJavaScriptHandler(
                    handlerName: 'YouTubeTracker',
                    callback: (args) => _handleTrackerMessage(args, t),
                  );
                },
                onLoadStart: (controller, url) {
                  setState(() {
                    t.url = url?.toString() ?? '';
                    if (t == _currentTab) {
                      _urlController.text = t.url;
                    }
                    t.progress = 0.2;
                  });
                },
                onProgressChanged: (controller, progress) {
                  setState(() {
                    t.progress = progress / 100.0;
                  });
                },
                onLoadStop: (controller, url) async {
                  await controller.evaluateJavascript(source: YouTubeJsTracker.trackingScript);
                  final title = await controller.getTitle();
                  final canBack = await controller.canGoBack();
                  final canForward = await controller.canGoForward();
                  setState(() {
                    t.url = url?.toString() ?? '';
                    t.title = title ?? 'Webpage';
                    t.canGoBack = canBack;
                    t.canGoForward = canForward;
                    t.progress = 1.0;
                    if (t == _currentTab) {
                      _urlController.text = t.url;
                    }
                  });
                },
                onTitleChanged: (controller, title) {
                  if (title != null && title.isNotEmpty) {
                    setState(() {
                      t.title = title;
                    });
                  }
                },
              );
            }).toList(),
          ),

          // Google Login Required Notice Banner (Auto-dismisses when user logs in)
          if (!tab.isHomePage && !tab.isGoogleLoggedIn && !kIsWeb)
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
                        tab.controller?.loadUrl(
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

          // Universal Tracking HUD Overlay (Appears ONLY when active tab is on target video)
          if (tab.isTargetDetected && tab.detectedTask != null)
            TrackingHudOverlay(
              task: tab.detectedTask!,
              isTargetDetected: tab.isTargetDetected,
              isTracking: tab.isPlaying,
              totalWatchedSeconds: tab.totalWatchedSeconds,
              sessionCoinsEarned: tab.sessionCoinsEarned,
              isCompleted: tab.isCompleted,
              isGoogleLoggedIn: tab.isGoogleLoggedIn,
              onSignInTap: () {
                tab.controller?.loadUrl(
                  urlRequest: URLRequest(
                    url: WebUri('https://accounts.google.com/ServiceLogin?service=youtube&continue=https://m.youtube.com'),
                  ),
                );
              },
            ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.fromLTRB(16, 8, 16, 8 + MediaQuery.paddingOf(context).bottom),
        decoration: const BoxDecoration(
          color: AppColors.surfaceCard,
          border: Border(top: BorderSide(color: AppColors.border, width: 0.8)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              icon: const Icon(CupertinoIcons.back),
              color: tab.canGoBack ? AppColors.textPrimary : AppColors.textMuted,
              onPressed: tab.canGoBack && !kIsWeb
                  ? () => tab.controller?.goBack()
                  : null,
            ),
            IconButton(
              icon: const Icon(CupertinoIcons.forward),
              color: tab.canGoForward ? AppColors.textPrimary : AppColors.textMuted,
              onPressed: tab.canGoForward && !kIsWeb
                  ? () => tab.controller?.goForward()
                  : null,
            ),
            IconButton(
              icon: const Icon(CupertinoIcons.house_fill),
              color: tab.isHomePage ? AppColors.primary : AppColors.textSecondary,
              onPressed: _goHome,
            ),
            IconButton(
              icon: const Icon(CupertinoIcons.refresh),
              color: !tab.isHomePage ? AppColors.textPrimary : AppColors.textMuted,
              onPressed: !tab.isHomePage && !kIsWeb
                  ? () => tab.controller?.reload()
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookmarksView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome Hero
          Center(
            child: Column(
              children: [
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(CupertinoIcons.compass, size: 48, color: AppColors.primary),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Web Browser',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Enter any URL or tap a quick bookmark below',
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 36),

          // Bookmarks Section Header
          const Row(
            children: [
              Icon(CupertinoIcons.bookmark_fill, size: 18, color: AppColors.secondary),
              SizedBox(width: 8),
              Text(
                'Quick Bookmarks',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Bookmark Tiles Grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: 2.3,
            ),
            itemCount: _bookmarks.length,
            itemBuilder: (context, index) {
              final b = _bookmarks[index];
              return InkWell(
                onTap: () => _loadUrl(b['url']!),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceCard,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      Text(
                        b['icon']!,
                        style: const TextStyle(fontSize: 22),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              b['title']!,
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              b['url']!.replaceAll('https://', ''),
                              style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const Icon(CupertinoIcons.chevron_right, size: 14, color: AppColors.textMuted),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildWebFallbackView(BrowserTab tab) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(CupertinoIcons.globe, size: 48, color: AppColors.primary),
            const SizedBox(height: 16),
            Text(
              'Browsing: ${tab.url}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            const Text(
              'Interactive InAppWebView with universal YouTube tracking operates on native Android/iOS mobile builds.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
