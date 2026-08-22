import { apiClient } from './client';

export const adminApi = {
  // Auth
  login: async (username, password) => {
    const res = await apiClient.post('/auth/login/', { username, password });
    return res.data;
  },

  // Dashboard KPIs & Trends
  getDashboardStats: async (params = {}) => {
    const res = await apiClient.get('/admin/stats/', { params });
    return res.data;
  },

  // Video Tasks
  getVideoTasks: async () => {
    const res = await apiClient.get('/admin/tasks/');
    return res.data;
  },
  createVideoTask: async (data) => {
    const res = await apiClient.post('/admin/tasks/', data);
    return res.data;
  },
  updateVideoTask: async (id, data) => {
    const res = await apiClient.patch(`/admin/tasks/${id}/`, data);
    return res.data;
  },
  deleteVideoTask: async (id) => {
    const res = await apiClient.delete(`/admin/tasks/${id}/`);
    return res.data;
  },
  regenerateKeywords: async (id) => {
    const res = await apiClient.post(`/admin/tasks/${id}/regenerate-keywords/`);
    return res.data;
  },
  fetchYouTubeMeta: async (url) => {
    const res = await apiClient.post('/admin/tasks/fetch-youtube-meta/', { youtube_url: url });
    return res.data;
  },

  // AI Settings & Sandbox
  getAISettings: async () => {
    const res = await apiClient.get('/admin/ai-settings/');
    return res.data;
  },
  updateAISettings: async (data) => {
    const res = await apiClient.patch('/admin/ai-settings/', data);
    return res.data;
  },
  fetchAIModels: async (provider, apiKey = '') => {
    const q = apiKey ? `provider=${provider}&api_key=${encodeURIComponent(apiKey)}` : `provider=${provider}`;
    const res = await apiClient.get(`/admin/ai-settings/fetch-models/?${q}`);
    return res.data;
  },
  testAISandbox: async (data) => {
    const res = await apiClient.post('/admin/ai-settings/test-sandbox/', data);
    return res.data;
  },

  // Watch Sessions & Telemetry
  getWatchSessions: async (params = {}) => {
    const res = await apiClient.get('/admin/watch-sessions/', { params });
    return res.data;
  },
  getLiveWatchSessions: async () => {
    const res = await apiClient.get('/admin/watch-sessions/live/');
    return res.data;
  },
  getVideoTelemetry: async (params = {}) => {
    const res = await apiClient.get('/admin/watch-sessions/video-telemetry/', { params });
    return res.data;
  },
  getVideoViewers: async (videoTaskId) => {
    const res = await apiClient.get('/admin/watch-sessions/video-viewers/', {
      params: { video_task_id: videoTaskId },
    });
    return res.data;
  },

  // Users
  getUsers: async (params = {}) => {
    const res = await apiClient.get('/admin/users/', { params });
    return res.data;
  },
  adjustUserBalance: async (id, data) => {
    const res = await apiClient.post(`/admin/users/${id}/adjust-balance/`, data);
    return res.data;
  },
  toggleUserStatus: async (id) => {
    const res = await apiClient.post(`/admin/users/${id}/toggle-status/`);
    return res.data;
  },

  // Financial Ledger
  getWalletTransactions: async (params = {}) => {
    const res = await apiClient.get('/admin/wallet-transactions/', { params });
    return res.data;
  },

  // Tokens & Security
  getTokens: async () => {
    const res = await apiClient.get('/admin/tokens/');
    return res.data;
  },
  blacklistToken: async (tokenId) => {
    const res = await apiClient.post('/admin/tokens/', { token_id: tokenId });
    return res.data;
  },
};
