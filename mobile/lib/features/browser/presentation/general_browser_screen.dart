import 'package:flutter/foundation.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:mobile/core/constants/app_colors.dart';

class GeneralBrowserScreen extends StatefulWidget {
  final String? initialUrl;

  const GeneralBrowserScreen({super.key, this.initialUrl});

  @override
  State<GeneralBrowserScreen> createState() => _GeneralBrowserScreenState();
}

class _GeneralBrowserScreenState extends State<GeneralBrowserScreen> {
  final TextEditingController _urlController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  InAppWebViewController? _webViewController;
  double _progress = 0;
  String _currentUrl = '';
  String _pageTitle = 'Vewra Browser';
  bool _canGoBack = false;
  bool _canGoForward = false;
  bool _isHomePage = true;

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

  @override
  void initState() {
    super.initState();
    if (widget.initialUrl != null && widget.initialUrl!.isNotEmpty) {
      _currentUrl = _normalizeUrl(widget.initialUrl!);
      _urlController.text = _currentUrl;
      _isHomePage = false;
    } else {
      _urlController.text = '';
      _isHomePage = true;
    }
  }

  @override
  void dispose() {
    _urlController.dispose();
    _focusNode.dispose();
    super.dispose();
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
    setState(() {
      _currentUrl = normalized;
      _urlController.text = normalized;
      _isHomePage = false;
    });
    _focusNode.unfocus();

    if (_webViewController != null && !kIsWeb) {
      _webViewController!.loadUrl(
        urlRequest: URLRequest(url: WebUri(normalized)),
      );
    }
  }

  void _goHome() {
    setState(() {
      _isHomePage = true;
      _currentUrl = '';
      _urlController.text = '';
      _pageTitle = 'Vewra Browser';
    });
    _focusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
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
                    hintText: _isHomePage ? 'Search or enter website address...' : _pageTitle,
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
        bottom: _progress > 0 && _progress < 1.0 && !_isHomePage
            ? PreferredSize(
                preferredSize: const Size.fromHeight(2),
                child: LinearProgressIndicator(
                  value: _progress,
                  backgroundColor: Colors.transparent,
                  color: AppColors.primary,
                  minHeight: 2,
                ),
              )
            : null,
      ),
      body: Column(
        children: [
          // Main Body (Bookmarks or WebView)
          Expanded(
            child: _isHomePage
                ? _buildBookmarksView()
                : kIsWeb
                    ? _buildWebFallbackView()
                    : InAppWebView(
                        initialUrlRequest: URLRequest(url: WebUri(_currentUrl)),
                        initialSettings: InAppWebViewSettings(
                          javaScriptEnabled: true,
                          mediaPlaybackRequiresUserGesture: false,
                          allowsInlineMediaPlayback: true,
                          isElementFullscreenEnabled: true,
                          supportMultipleWindows: false,
                        ),
                        onWebViewCreated: (controller) {
                          _webViewController = controller;
                        },
                        onLoadStart: (controller, url) {
                          setState(() {
                            _currentUrl = url?.toString() ?? '';
                            _urlController.text = _currentUrl;
                            _progress = 0.2;
                          });
                        },
                        onProgressChanged: (controller, progress) {
                          setState(() {
                            _progress = progress / 100.0;
                          });
                        },
                        onLoadStop: (controller, url) async {
                          final title = await controller.getTitle();
                          final canBack = await controller.canGoBack();
                          final canForward = await controller.canGoForward();
                          setState(() {
                            _currentUrl = url?.toString() ?? '';
                            _urlController.text = _currentUrl;
                            _pageTitle = title ?? 'Webpage';
                            _canGoBack = canBack;
                            _canGoForward = canForward;
                            _progress = 1.0;
                          });
                        },
                        onTitleChanged: (controller, title) {
                          if (title != null && title.isNotEmpty) {
                            setState(() {
                              _pageTitle = title;
                            });
                          }
                        },
                      ),
          ),

          // Bottom Browser Control Toolbar (with SafeArea protection)
          Container(
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
                  color: _canGoBack ? AppColors.textPrimary : AppColors.textMuted,
                  onPressed: _canGoBack && !kIsWeb
                      ? () => _webViewController?.goBack()
                      : null,
                ),
                IconButton(
                  icon: const Icon(CupertinoIcons.forward),
                  color: _canGoForward ? AppColors.textPrimary : AppColors.textMuted,
                  onPressed: _canGoForward && !kIsWeb
                      ? () => _webViewController?.goForward()
                      : null,
                ),
                IconButton(
                  icon: const Icon(CupertinoIcons.house_fill),
                  color: _isHomePage ? AppColors.primary : AppColors.textSecondary,
                  onPressed: _goHome,
                ),
                IconButton(
                  icon: const Icon(CupertinoIcons.refresh),
                  color: !_isHomePage ? AppColors.textPrimary : AppColors.textMuted,
                  onPressed: !_isHomePage && !kIsWeb
                      ? () => _webViewController?.reload()
                      : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookmarksView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome / Search Hero
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

  Widget _buildWebFallbackView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(CupertinoIcons.globe, size: 48, color: AppColors.primary),
            const SizedBox(height: 16),
            Text(
              'Browsing: $_currentUrl',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            const Text(
              'Interactive InAppWebView operates on native Android/iOS mobile builds.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
