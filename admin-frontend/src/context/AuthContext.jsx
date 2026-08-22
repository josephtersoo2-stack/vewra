import React, { createContext, useContext, useState, useEffect } from 'react';
import { adminApi } from '../api/adminApi';

const AuthContext = createContext();

export function AuthProvider({ children }) {
  const [user, setUser] = useState(() => {
    const saved = localStorage.getItem('vewra_admin_user');
    return saved ? JSON.parse(saved) : null;
  });
  const [token, setToken] = useState(() => localStorage.getItem('vewra_admin_token'));
  const [loading, setLoading] = useState(false);

  const login = async (username, password) => {
    setLoading(true);
    try {
      const data = await adminApi.login(username, password);
      const userObj = data.user;
      const accessToken = data.tokens?.access || data.access;
      const refreshToken = data.tokens?.refresh || data.refresh;

      if (!userObj?.is_staff && !userObj?.is_superuser) {
        throw new Error('Access denied. Administrator privileges required.');
      }
      localStorage.setItem('vewra_admin_token', accessToken);
      if (refreshToken) {
        localStorage.setItem('vewra_admin_refresh_token', refreshToken);
      }
      localStorage.setItem('vewra_admin_user', JSON.stringify(userObj));
      setToken(accessToken);
      setUser(userObj);
      return data;
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    const checkAuth = async () => {
      const storedToken = localStorage.getItem('vewra_admin_token');
      if (storedToken) {
        try {
          await adminApi.getDashboardStats();
        } catch (e) {
          console.warn('Session check on startup', e);
        }
      }
    };
    checkAuth();
  }, []);

  const logout = () => {
    localStorage.removeItem('vewra_admin_token');
    localStorage.removeItem('vewra_admin_refresh_token');
    localStorage.removeItem('vewra_admin_user');
    setToken(null);
    setUser(null);
  };

  return (
    <AuthContext.Provider
      value={{
        user,
        token,
        isAuthenticated: !!token && !!user,
        isAdmin: !!(user?.is_staff || user?.is_superuser || user?.username === 'admin'),
        login,
        logout,
        loading,
      }}
    >
      {children}
    </AuthContext.Provider>
  );
}

export function useAuth() {
  const context = useContext(AuthContext);
  if (!context) throw new Error('useAuth must be used within an AuthProvider');
  return context;
}
