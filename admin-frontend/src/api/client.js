import axios from 'axios';

const getBaseUrl = () => {
  const host = window.location.hostname;
  return `http://${host}:8001/api/v1`;
};

export const apiClient = axios.create({
  baseURL: getBaseUrl(),
  headers: {
    'Content-Type': 'application/json',
  },
});

apiClient.interceptors.request.use(
  (config) => {
    const token = localStorage.getItem('vewra_admin_token');
    if (token) {
      config.headers.Authorization = `Bearer ${token}`;
    }
    return config;
  },
  (error) => Promise.reject(error)
);

apiClient.interceptors.response.use(
  (response) => response,
  async (error) => {
    if (error.response?.status === 401) {
      // Token expired or invalid
      const refreshToken = localStorage.getItem('vewra_admin_refresh_token');
      if (refreshToken && !error.config._retry) {
        error.config._retry = true;
        try {
          const res = await axios.post(`${getBaseUrl()}/auth/refresh/`, {
            refresh: refreshToken,
          });
          const newToken = res.data.access;
          localStorage.setItem('vewra_admin_token', newToken);
          error.config.headers.Authorization = `Bearer ${newToken}`;
          return apiClient(error.config);
        } catch (refreshErr) {
          localStorage.removeItem('vewra_admin_token');
          localStorage.removeItem('vewra_admin_refresh_token');
          localStorage.removeItem('vewra_admin_user');
          if (window.location.pathname !== '/login') {
            window.location.href = '/login';
          }
        }
      } else {
        localStorage.removeItem('vewra_admin_token');
        localStorage.removeItem('vewra_admin_refresh_token');
        localStorage.removeItem('vewra_admin_user');
        if (window.location.pathname !== '/login') {
          window.location.href = '/login';
        }
      }
    }
    return Promise.reject(error);
  }
);
