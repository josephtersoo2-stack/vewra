import React from 'react';
import { Sun, Moon, Radio, ShieldCheck } from 'lucide-react';
import { useTheme } from '../../theme/ThemeContext';
import { useAuth } from '../../context/AuthContext';

export function Header({ title }) {
  const { isDark, toggleTheme } = useTheme();
  const { user } = useAuth();

  return (
    <header
      style={{
        height: '72px',
        backgroundColor: 'var(--bg-glass)',
        backdropFilter: 'blur(12px)',
        WebkitBackdropFilter: 'blur(12px)',
        borderBottom: '1px solid var(--border-subtle)',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'space-between',
        padding: '0 32px',
        position: 'sticky',
        top: 0,
        zIndex: 90,
      }}
    >
      {/* Title & Live Status */}
      <div style={{ display: 'flex', alignItems: 'center', gap: '16px' }}>
        <h2 style={{ fontSize: '20px', fontWeight: '800', color: 'var(--text-primary)' }}>
          {title}
        </h2>
        <div
          style={{
            display: 'flex',
            alignItems: 'center',
            gap: '6px',
            padding: '4px 10px',
            borderRadius: '20px',
            backgroundColor: 'var(--badge-emerald-bg)',
            color: 'var(--badge-emerald-text)',
            fontSize: '12px',
            fontWeight: '600',
          }}
        >
          <span
            style={{
              width: '8px',
              height: '8px',
              borderRadius: '50%',
              backgroundColor: 'var(--accent-emerald)',
              boxShadow: '0 0 8px var(--accent-emerald)',
            }}
          />
          Live API (0.0.0.0:8001)
        </div>
      </div>

      {/* Action Controls & User Badge */}
      <div style={{ display: 'flex', alignItems: 'center', gap: '16px' }}>
        {/* Light / Dark Mode Toggle Button */}
        <button
          onClick={toggleTheme}
          style={{
            width: '40px',
            height: '40px',
            borderRadius: '12px',
            backgroundColor: 'var(--bg-secondary)',
            border: '1px solid var(--border-card)',
            color: isDark ? 'var(--accent-amber)' : 'var(--primary)',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            cursor: 'pointer',
            boxShadow: 'var(--shadow-sm)',
          }}
          title={`Switch to ${isDark ? 'Light' : 'Dark'} Mode`}
        >
          {isDark ? <Sun size={20} /> : <Moon size={20} />}
        </button>

        {/* Admin Profile Chip */}
        <div
          style={{
            display: 'flex',
            alignItems: 'center',
            gap: '10px',
            padding: '6px 14px',
            backgroundColor: 'var(--bg-secondary)',
            border: '1px solid var(--border-card)',
            borderRadius: '24px',
          }}
        >
          <div
            style={{
              width: '30px',
              height: '30px',
              borderRadius: '50%',
              backgroundColor: 'var(--primary-light)',
              color: 'var(--primary)',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              fontWeight: '700',
              fontSize: '13px',
            }}
          >
            {user?.username?.[0]?.toUpperCase() || 'A'}
          </div>
          <div style={{ display: 'flex', flexDirection: 'column' }}>
            <span style={{ fontSize: '13px', fontWeight: '700', color: 'var(--text-primary)' }}>
              {user?.username || 'Admin'}
            </span>
            <span style={{ fontSize: '11px', color: 'var(--accent-emerald)', display: 'flex', alignItems: 'center', gap: '3px' }}>
              <ShieldCheck size={11} /> Superuser
            </span>
          </div>
        </div>
      </div>
    </header>
  );
}
