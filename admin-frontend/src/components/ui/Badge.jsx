import React from 'react';

export function Badge({ children, variant = 'default', size = 'sm', className = '' }) {
  const variantStyles = {
    default: {
      bg: 'var(--bg-tertiary)',
      color: 'var(--text-secondary)',
      border: '1px solid var(--border-subtle)',
    },
    emerald: {
      bg: 'var(--badge-emerald-bg)',
      color: 'var(--badge-emerald-text)',
      border: '1px solid rgba(16, 185, 129, 0.3)',
    },
    amber: {
      bg: 'var(--badge-amber-bg)',
      color: 'var(--badge-amber-text)',
      border: '1px solid rgba(245, 158, 11, 0.3)',
    },
    rose: {
      bg: 'var(--badge-rose-bg)',
      color: 'var(--badge-rose-text)',
      border: '1px solid rgba(244, 63, 94, 0.3)',
    },
    indigo: {
      bg: 'var(--badge-indigo-bg)',
      color: 'var(--badge-indigo-text)',
      border: '1px solid rgba(99, 102, 241, 0.3)',
    },
  };

  const sizes = {
    xs: { padding: '2px 6px', fontSize: '11px' },
    sm: { padding: '4px 10px', fontSize: '12px' },
    md: { padding: '6px 12px', fontSize: '13px' },
  };

  const style = {
    display: 'inline-flex',
    alignItems: 'center',
    gap: '4px',
    borderRadius: '20px',
    fontWeight: '600',
    letterSpacing: '0.02em',
    ...variantStyles[variant],
    ...sizes[size],
  };

  return (
    <span style={style} className={className}>
      {children}
    </span>
  );
}
