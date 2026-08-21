class YouTubeJsTracker {
  /// Comprehensive JavaScript injected into YouTube WebView to detect video ID,
  /// listen for HTML5 video playback, track timeupdate events, and communicate with Flutter.
  static const String trackingScript = """
(function() {
  if (window.__VEWRA_TRACKER_INITIALIZED__) return;
  window.__VEWRA_TRACKER_INITIALIZED__ = true;

  console.log('[Vewra] YouTube Tracker injected.');

  var currentVideoId = null;
  var lastReportedTime = 0;
  var lastReportedTimestamp = Date.now();
  var videoElement = null;
  var trackingInterval = null;

  function extractVideoId(url) {
    if (!url) url = window.location.href;
    try {
      // 1. Check query parameter v=
      var urlObj = new URL(url);
      var vParam = urlObj.searchParams.get('v');
      if (vParam && vParam.length === 11) {
        return vParam;
      }
      // 2. Check /shorts/
      var shortsMatch = url.match(/\\/shorts\\/([a-zA-Z0-9_-]{11})/);
      if (shortsMatch) {
        return shortsMatch[1];
      }
      // 3. Check /embed/ or youtu.be
      var embedMatch = url.match(/(?:embed\\/|youtu\\.be\\/)([a-zA-Z0-9_-]{11})/);
      if (embedMatch) {
        return embedMatch[1];
      }
    } catch(e) {}
    return null;
  }

  function notifyFlutter(payload) {
    if (window.flutter_inappwebview && window.flutter_inappwebview.callHandler) {
      window.flutter_inappwebview.callHandler('YouTubeTracker', payload);
    }
  }

  function checkUrlChange() {
    var detectedId = extractVideoId(window.location.href);
    if (detectedId !== currentVideoId) {
      currentVideoId = detectedId;
      console.log('[Vewra] Video changed:', currentVideoId);
      notifyFlutter({
        eventType: 'video_detected',
        videoId: currentVideoId,
        url: window.location.href,
        currentTime: videoElement ? videoElement.currentTime : 0,
        duration: videoElement ? videoElement.duration : 0,
        isPlaying: videoElement ? !videoElement.paused : false
      });
      attachVideoListeners();
    }
  }

  function attachVideoListeners() {
    var video = document.querySelector('video');
    if (video && video !== videoElement) {
      videoElement = video;
      console.log('[Vewra] Video element bound.');

      videoElement.addEventListener('play', function() {
        notifyFlutter({
          eventType: 'play',
          videoId: currentVideoId,
          currentTime: videoElement.currentTime,
          duration: videoElement.duration,
          isPlaying: true
        });
      });

      videoElement.addEventListener('pause', function() {
        notifyFlutter({
          eventType: 'pause',
          videoId: currentVideoId,
          currentTime: videoElement.currentTime,
          duration: videoElement.duration,
          isPlaying: false
        });
      });

      videoElement.addEventListener('ended', function() {
        notifyFlutter({
          eventType: 'ended',
          videoId: currentVideoId,
          currentTime: videoElement.currentTime,
          duration: videoElement.duration,
          isPlaying: false
        });
      });

      videoElement.addEventListener('timeupdate', function() {
        var now = Date.now();
        // Send updates at least every 3 seconds while playing
        if (now - lastReportedTimestamp >= 3000) {
          lastReportedTimestamp = now;
          notifyFlutter({
            eventType: 'timeupdate',
            videoId: currentVideoId,
            currentTime: videoElement.currentTime,
            duration: videoElement.duration || 0,
            isPlaying: !videoElement.paused
          });
        }
      });
    }
  }

  // Intercept history.pushState & replaceState for YouTube SPA
  var origPushState = history.pushState;
  history.pushState = function() {
    origPushState.apply(this, arguments);
    checkUrlChange();
  };

  var origReplaceState = history.replaceState;
  history.replaceState = function() {
    origReplaceState.apply(this, arguments);
    checkUrlChange();
  };

  window.addEventListener('popstate', checkUrlChange);
  window.addEventListener('yt-navigate-finish', checkUrlChange);
  window.addEventListener('yt-page-data-updated', checkUrlChange);

  // Polling fallback every 1 second to handle lazy loaded videos and dynamic URL changes
  setInterval(function() {
    checkUrlChange();
    if (!videoElement || !document.contains(videoElement)) {
      attachVideoListeners();
    }
  }, 1000);

  // Initial check
  checkUrlChange();
})();
""";
}
