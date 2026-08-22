import React from 'react';
import { useTheme } from '../../theme/ThemeContext';

export function StatCard({ title, value, subtitle, icon: Icon, trend, color = 'indigo' }) {
  const { isDark } = useTheme();

  const colorThemes = {
    indigo: {
      bgIcon: 'rgba(99, 102, 241, 0.15)',
      textIcon: 'var(--primary)',
      gradient: 'linear-gradient(135deg, rgba(99, 102, 241, 0.08) 0%, rgba(99, 102, 241, 0.01) 100%)',
      border: 'rgba(99, 102, 241, 0.25)',
    },
    emerald: {
      bgIcon: 'rgba(16, 185, 129, 0.15)',
      textIcon: 'var(--accent-emerald)',
      gradient: 'linear-gradient(135deg, rgba(16, 185, 129, 0.08) 0%, rgba(16, 185, 129, 0.01) 100%)',
      border: 'rgba(16, 185, 129, 0.25)',
    },
    amber: {
      bgIcon: 'rgba(245, 158, 11, 0.15)',
      textIcon: 'var(--accent-amber)',
      gradient: 'linear-gradient(135deg, rgba(245, 158, 11, 0.08) 0%, rgba(245, 158, 11, 0.01) 100%)',
      border: 'rgba(245, 158, 11, 0.25)',
    },
    cyan: {
      bgIcon: 'rgba(6, 182, 212, 0.15)',
      textIcon: 'var(--accent-cyan)',
      gradient: 'linear-gradient(135deg, rgba(6, 182, 212, 0.08) 0%, rgba(6, 182, 212, 0.01) 100%)',
      border: 'rgba(6, 182, 212, 0.25)',
    },
  };

  const themeConfig = colorThemes[color] || colorThemes.indigo;

  return (
    <div
      style={{
        background: isDark ? `var(--bg-card)` : 'var(--bg-secondary)',
        backgroundImage: themeConfig.gradient,
        border: `1px solid ${themeConfig.border}`,
        borderRadius: 'var(--card-radius)',
        padding: '24px',
        boxShadow: 'var(--shadow-sm)',
        display: 'flex',
        flexDirection: 'column',
        gap: '12px',
        position: 'relative',
        overflow: 'hidden',
      }}
    >
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
        <span style={{ fontSize: '13px', fontWeight: '600', color: 'var(--text-secondary)', textTransform: 'uppercase', letterSpacing: '0.05em' }}>
          {title}
        </span>
        {Icon && (
          <div
            style={{
              width: '42px',
              height: '42px',
              borderRadius: '12px',
              backgroundColor: themeConfig.bgIcon,
              color: themeConfig.textIcon,
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
            }}
          >
            <Icon size={22} />
          </div>
        )}
      </div>

      <div style={{ display: 'flex', alignItems: 'baseline', gap: '8px' }}>
        <h3 style={{ fontSize: '28px', fontWeight: '800', color: 'var(--text-primary)', letterSpacing: '-0.03em' }}>
          {value}
        </h3>
        {trend && (
          <span style={{ fontSize: '12px', fontWeight: '600', color: 'var(--accent-emerald)' }}>
            {trend}
          </span>
        )}
      </div>

      {subtitle && (
        <p style={{ fontSize: '13px', color: 'var(--text-tertiary)', marginTop: '-4px' }}>
          {subtitle}
        </p>
      )}
    </div>
  );
}
