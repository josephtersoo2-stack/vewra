class YouTubeJsTracker {
  /// Hardened JavaScript injected into YouTube WebView to detect video ID,
  /// listen for HTML5 video playback, track timeupdate events, and communicate with Flutter.
  static const String trackingScript = """
(function() {
  if (window.__VEWRA_TRACKER_INITIALIZED__) {
    // If already initialized in this window context, just trigger a check
    if (typeof window.__vewraCheckState === 'function') {
      window.__vewraCheckState();
    }
    return;
  }
  window.__VEWRA_TRACKER_INITIALIZED__ = true;

  console.log('[Vewra] Hardened YouTube Tracker initialized.');

  var currentVideoId = null;
  var lastReportedTimestamp = 0;
  var lastReportedPlayState = null; // 'playing', 'paused', 'ended'
  var videoElement = null;

  function extractVideoId(url) {
    if (!url) url = window.location.href;
    try {
      var urlObj = new URL(url);
      
      // 1. Query parameter ?v= or &v=
      var vParam = urlObj.searchParams.get('v');
      if (vParam && vParam.length === 11) {
        return vParam;
      }

      // 2. /shorts/VIDEO_ID
      var shortsMatch = urlObj.pathname.match(/\\/shorts\\/([a-zA-Z0-9_-]{11})/);
      if (shortsMatch && shortsMatch[1]) {
        return shortsMatch[1];
      }

      // 3. /embed/VIDEO_ID or youtu.be/VIDEO_ID
      var embedMatch = url.match(/(?:embed\\/|youtu\\.be\\/)([a-zA-Z0-9_-]{11})/);
      if (embedMatch && embedMatch[1]) {
        return embedMatch[1];
      }

      // 4. Fallback: Check DOM metadata if on YouTube watch page
      var metaId = document.querySelector('meta[itemprop="videoId"]');
      if (metaId && metaId.content && metaId.content.length === 11) {
        return metaId.content;
      }
    } catch(e) {}
    return null;
  }

  function checkAuthStatus() {
    try {
      if (typeof window.ytcfg !== 'undefined' && typeof window.ytcfg.get === 'function') {
        var ytLoggedIn = window.ytcfg.get('LOGGED_IN');
        if (ytLoggedIn === true) return true;
        if (ytLoggedIn === false) return false;
      }
      if (window.ytcfg && window.ytcfg.data_ && typeof window.ytcfg.data_.LOGGED_IN !== 'undefined') {
        if (window.ytcfg.data_.LOGGED_IN === true) return true;
        if (window.ytcfg.data_.LOGGED_IN === false) return false;
      }
      var cookies = document.cookie || '';
      if (cookies.indexOf('LOGIN_INFO=') !== -1 || cookies.indexOf('SID=') !== -1 || cookies.indexOf('SSID=') !== -1 || cookies.indexOf('HSID=') !== -1 || cookies.indexOf('APISID=') !== -1) {
        return true;
      }
      var avatarBtn = document.querySelector('button.yt-spec-button-shape-next[aria-label*="Account"]') || 
                      document.querySelector('ytm-account-item-renderer') ||
                      document.querySelector('#avatar-btn') ||
                      document.querySelector('ytm-topbar-menu-button-renderer') ||
                      document.querySelector('a[href*="/channel/"]') ||
                      document.querySelector('img[src*="googleusercontent.com"]');
      var signInBtn = document.querySelector('ytm-sign-in-button-renderer') || 
                      document.querySelector('a[href*="accounts.google.com/ServiceLogin"]');
      if (avatarBtn && !signInBtn) return true;
      if (signInBtn) return false;
    } catch(e) {}
    return false;
  }

  function notifyFlutter(payload) {
    if (window.flutter_inappwebview && window.flutter_inappwebview.callHandler) {
      if (typeof payload === 'object' && payload !== null) {
        payload.isGoogleLoggedIn = checkAuthStatus();
      }
      window.flutter_inappwebview.callHandler('YouTubeTracker', payload);
    }
  }

  function checkUrlChange() {
    var detectedId = extractVideoId(window.location.href);
    if (detectedId !== currentVideoId) {
      currentVideoId = detectedId;
      console.log('[Vewra] Video ID detected:', currentVideoId);
      
      notifyFlutter({
        eventType: 'video_detected',
        videoId: currentVideoId,
        url: window.location.href,
        currentTime: videoElement && videoElement.currentTime ? videoElement.currentTime : 0,
        duration: videoElement && videoElement.duration ? videoElement.duration : 0,
        isPlaying: videoElement ? (!videoElement.paused && !videoElement.ended) : false
      });
      
      attachVideoListeners(true);
    }
  }

  function attachVideoListeners(force) {
    var video = document.querySelector('video');
    
    // Check if video element is replaced or detached from DOM
    if (video && (video !== videoElement || force || !videoElement || !videoElement.isConnected)) {
      videoElement = video;
      console.log('[Vewra] Bound to active HTML5 video element.');

      // Detach existing if needed / rebind
      videoElement.removeEventListener('play', onPlay);
      videoElement.removeEventListener('pause', onPause);
      videoElement.removeEventListener('ended', onEnded);
      videoElement.removeEventListener('timeupdate', onTimeUpdate);

      videoElement.addEventListener('play', onPlay);
      videoElement.addEventListener('pause', onPause);
      videoElement.addEventListener('ended', onEnded);
      videoElement.addEventListener('timeupdate', onTimeUpdate);
    }
  }

  function onPlay() {
    if (lastReportedPlayState === 'playing') return; // Deduplicate
    lastReportedPlayState = 'playing';
    notifyFlutter({
      eventType: 'play',
      videoId: currentVideoId,
      currentTime: videoElement ? videoElement.currentTime : 0,
      duration: videoElement ? (videoElement.duration || 0) : 0,
      isPlaying: true
    });
  }

  function onPause() {
    if (lastReportedPlayState === 'paused') return; // Deduplicate
    lastReportedPlayState = 'paused';
    notifyFlutter({
      eventType: 'pause',
      videoId: currentVideoId,
      currentTime: videoElement ? videoElement.currentTime : 0,
      duration: videoElement ? (videoElement.duration || 0) : 0,
      isPlaying: false
    });
  }

  function onEnded() {
    lastReportedPlayState = 'ended';
    notifyFlutter({
      eventType: 'ended',
      videoId: currentVideoId,
      currentTime: videoElement ? videoElement.currentTime : 0,
      duration: videoElement ? (videoElement.duration || 0) : 0,
      isPlaying: false
    });
  }

  function onTimeUpdate() {
    var now = Date.now();
    // Throttle timeupdate to once every ~3000ms while actively playing
    if (now - lastReportedTimestamp >= 3000) {
      lastReportedTimestamp = now;
      if (videoElement && !videoElement.paused) {
        lastReportedPlayState = 'playing';
      }
      notifyFlutter({
        eventType: 'timeupdate',
        videoId: currentVideoId,
        currentTime: videoElement ? videoElement.currentTime : 0,
        duration: videoElement ? (videoElement.duration || 0) : 0,
        isPlaying: videoElement ? (!videoElement.paused && !videoElement.ended) : false
      });
    }
  }

  // Intercept history.pushState & replaceState for SPA navigation
  var origPushState = history.pushState;
  history.pushState = function() {
    origPushState.apply(this, arguments);
    setTimeout(checkUrlChange, 100);
  };

  var origReplaceState = history.replaceState;
  history.replaceState = function() {
    origReplaceState.apply(this, arguments);
    setTimeout(checkUrlChange, 100);
  };

  window.addEventListener('popstate', checkUrlChange);
  window.addEventListener('yt-navigate-finish', checkUrlChange);
  window.addEventListener('yt-page-data-updated', checkUrlChange);

  var lastReportedAuthState = null;

  // Periodic heartbeat every 1000ms: monitors DOM recreation, URL mutations, and Auth state
  window.__vewraCheckState = function() {
    checkUrlChange();
    attachVideoListeners();

    var currentAuth = checkAuthStatus();
    if (currentAuth !== lastReportedAuthState) {
      lastReportedAuthState = currentAuth;
      notifyFlutter({
        eventType: 'auth_state_changed',
        isGoogleLoggedIn: currentAuth,
        videoId: currentVideoId
      });
    }
  };

  setInterval(window.__vewraCheckState, 1000);

  // Initial execution
  checkUrlChange();
  attachVideoListeners();
  lastReportedAuthState = checkAuthStatus();
  notifyFlutter({
    eventType: 'auth_state_changed',
    isGoogleLoggedIn: lastReportedAuthState,
    videoId: currentVideoId
  });
})();
""";
}
