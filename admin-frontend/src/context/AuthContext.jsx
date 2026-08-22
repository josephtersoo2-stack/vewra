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
      if (!data.user?.is_staff && !data.user?.is_superuser) {
        throw new Error('Access denied. Administrator privileges required.');
      }
      localStorage.setItem('vewra_admin_token', data.access);
      localStorage.setItem('vewra_admin_refresh_token', data.refresh);
      localStorage.setItem('vewra_admin_user', JSON.stringify(data.user));
      setToken(data.access);
      setUser(data.user);
      return data;
    } finally {
      setLoading(false);
    }
  };

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
        isAdmin: user?.is_staff || user?.is_superuser,
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
