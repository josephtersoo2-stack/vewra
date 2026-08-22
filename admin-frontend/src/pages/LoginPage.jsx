import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { ShieldCheck, Lock, User, AlertCircle, Sun, Moon } from 'lucide-react';
import { useAuth } from '../context/AuthContext';
import { useTheme } from '../theme/ThemeContext';

export function LoginPage() {
  const [username, setUsername] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  const { login, loading } = useAuth();
  const { isDark, toggleTheme } = useTheme();
  const navigate = useNavigate();

  const handleSubmit = async (e) => {
    e.preventDefault();
    setError('');
    try {
      await login(username, password);
      navigate('/');
    } catch (err) {
      setError(err.response?.data?.detail || err.message || 'Login failed. Please check credentials.');
    }
  };

  return (
    <div
      style={{
        minHeight: '100vh',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        backgroundColor: 'var(--bg-primary)',
        padding: '24px',
        position: 'relative',
      }}
    >
      {/* Theme Toggle Top Right */}
      <button
        onClick={toggleTheme}
        style={{
          position: 'absolute',
          top: '24px',
          right: '24px',
          width: '42px',
          height: '42px',
          borderRadius: '12px',
          backgroundColor: 'var(--bg-secondary)',
          border: '1px solid var(--border-card)',
          color: isDark ? 'var(--accent-amber)' : 'var(--primary)',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          cursor: 'pointer',
        }}
      >
        {isDark ? <Sun size={20} /> : <Moon size={20} />}
      </button>

      <div
        style={{
          width: '100%',
          maxWidth: '440px',
          backgroundColor: 'var(--bg-secondary)',
          border: '1px solid var(--border-card)',
          borderRadius: 'var(--card-radius)',
          boxShadow: 'var(--shadow-lg)',
          padding: '40px',
          display: 'flex',
          flexDirection: 'column',
          gap: '28px',
        }}
      >
        {/* Brand Header */}
        <div style={{ textAlign: 'center', display: 'flex', flexDirection: 'column', alignItems: 'center', gap: '12px' }}>
          <div
            style={{
              width: '56px',
              height: '56px',
              borderRadius: '16px',
              background: 'linear-gradient(135deg, #6366F1 0%, #4F46E5 100%)',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              boxShadow: '0 8px 20px rgba(99, 102, 241, 0.4)',
              color: '#FFFFFF',
              fontWeight: '800',
              fontSize: '28px',
            }}
          >
            V
          </div>
          <h2 style={{ fontSize: '24px', fontWeight: '800', color: 'var(--text-primary)', letterSpacing: '-0.03em' }}>
            Vewra Admin
          </h2>
          <p style={{ fontSize: '14px', color: 'var(--text-secondary)' }}>
            Sign in to access platform management
          </p>
        </div>

        {/* Error Alert */}
        {error && (
          <div
            style={{
              padding: '12px 16px',
              borderRadius: 'var(--btn-radius)',
              backgroundColor: 'var(--badge-rose-bg)',
              color: 'var(--badge-rose-text)',
              border: '1px solid rgba(244, 63, 94, 0.3)',
              fontSize: '13px',
              display: 'flex',
              alignItems: 'center',
              gap: '10px',
            }}
          >
            <AlertCircle size={18} />
            <span>{error}</span>
          </div>
        )}

        {/* Login Form */}
        <form onSubmit={handleSubmit} style={{ display: 'flex', flexDirection: 'column', gap: '18px' }}>
          <div style={{ display: 'flex', flexDirection: 'column', gap: '6px' }}>
            <label style={{ fontSize: '13px', fontWeight: '600', color: 'var(--text-secondary)' }}>
              Username
            </label>
            <div style={{ position: 'relative' }}>
              <User
                size={18}
                style={{
                  position: 'absolute',
                  left: '14px',
                  top: '50%',
                  transform: 'translateY(-50%)',
                  color: 'var(--text-tertiary)',
                }}
              />
              <input
                type="text"
                required
                value={username}
                onChange={(e) => setUsername(e.target.value)}
                placeholder="admin"
                style={{
                  width: '100%',
                  padding: '12px 14px 12px 42px',
                  borderRadius: 'var(--input-radius)',
                  backgroundColor: 'var(--bg-tertiary)',
                  border: '1px solid var(--border-card)',
                  color: 'var(--text-primary)',
                  fontSize: '14px',
                  outline: 'none',
                }}
              />
            </div>
          </div>

          <div style={{ display: 'flex', flexDirection: 'column', gap: '6px' }}>
            <label style={{ fontSize: '13px', fontWeight: '600', color: 'var(--text-secondary)' }}>
              Password
            </label>
            <div style={{ position: 'relative' }}>
              <Lock
                size={18}
                style={{
                  position: 'absolute',
                  left: '14px',
                  top: '50%',
                  transform: 'translateY(-50%)',
                  color: 'var(--text-tertiary)',
                }}
              />
              <input
                type="password"
                required
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                placeholder="••••••••"
                style={{
                  width: '100%',
                  padding: '12px 14px 12px 42px',
                  borderRadius: 'var(--input-radius)',
                  backgroundColor: 'var(--bg-tertiary)',
                  border: '1px solid var(--border-card)',
                  color: 'var(--text-primary)',
                  fontSize: '14px',
                  outline: 'none',
                }}
              />
            </div>
          </div>

          <button
            type="submit"
            disabled={loading}
            style={{
              marginTop: '8px',
              padding: '14px',
              borderRadius: 'var(--btn-radius)',
              backgroundColor: 'var(--primary)',
              color: '#FFFFFF',
              border: 'none',
              fontSize: '15px',
              fontWeight: '700',
              cursor: loading ? 'not-allowed' : 'pointer',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              gap: '10px',
              boxShadow: '0 4px 14px var(--primary-glow)',
            }}
          >
            {loading ? 'Authenticating...' : 'Sign In as Administrator'}
          </button>
        </form>
      </div>
    </div>
  );
}
