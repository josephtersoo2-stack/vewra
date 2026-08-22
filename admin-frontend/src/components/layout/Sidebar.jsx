import React from 'react';
import { NavLink } from 'react-router-dom';
import {
  LayoutDashboard,
  Sparkles,
  Video,
  PlayCircle,
  Users,
  Wallet,
  ShieldAlert,
  LogOut,
  ChevronLeft,
  ChevronRight,
} from 'lucide-react';
import { useAuth } from '../../context/AuthContext';

export function Sidebar({ isCollapsed, setIsCollapsed }) {
  const { logout } = useAuth();

  const navItems = [
    { to: '/', label: 'Dashboard', icon: LayoutDashboard },
    { to: '/ai-studio', label: 'AI Keyword Studio', icon: Sparkles },
    { to: '/tasks', label: 'Video Tasks', icon: Video },
    { to: '/sessions', label: 'Watch Sessions', icon: PlayCircle },
    { to: '/users', label: 'Users & Accounts', icon: Users },
    { to: '/ledger', label: 'Financial Ledger', icon: Wallet },
    { to: '/security', label: 'Token Security', icon: ShieldAlert },
  ];

  return (
    <aside
      style={{
        width: isCollapsed ? '80px' : '260px',
        backgroundColor: 'var(--bg-secondary)',
        borderRight: '1px solid var(--border-subtle)',
        display: 'flex',
        flexDirection: 'column',
        height: '100vh',
        position: 'sticky',
        top: 0,
        zIndex: 100,
        transition: 'width 0.25s cubic-bezier(0.2, 0, 0, 1)',
      }}
    >
      {/* Brand Logo Header */}
      <div
        style={{
          padding: '24px',
          display: 'flex',
          alignItems: 'center',
          justifyContent: isCollapsed ? 'center' : 'space-between',
          borderBottom: '1px solid var(--border-subtle)',
        }}
      >
        <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
          <div
            style={{
              width: '38px',
              height: '38px',
              borderRadius: '10px',
              background: 'linear-gradient(135deg, #6366F1 0%, #4F46E5 100%)',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              boxShadow: '0 4px 12px rgba(99, 102, 241, 0.4)',
              color: '#FFFFFF',
              fontWeight: '800',
              fontSize: '20px',
            }}
          >
            V
          </div>
          {!isCollapsed && (
            <div>
              <h1 style={{ fontSize: '18px', fontWeight: '800', color: 'var(--text-primary)', letterSpacing: '-0.03em' }}>
                Vewra <span style={{ color: 'var(--primary)', fontSize: '12px', fontWeight: '700' }}>ADMIN</span>
              </h1>
              <p style={{ fontSize: '11px', color: 'var(--text-tertiary)' }}>Command Center</p>
            </div>
          )}
        </div>
      </div>

      {/* Navigation Items */}
      <nav style={{ flex: 1, padding: '16px 12px', display: 'flex', flexDirection: 'column', gap: '6px' }}>
        {navItems.map((item) => {
          const Icon = item.icon;
          return (
            <NavLink
              key={item.to}
              to={item.to}
              style={({ isActive }) => ({
                display: 'flex',
                alignItems: 'center',
                gap: '14px',
                padding: '12px 14px',
                borderRadius: 'var(--btn-radius)',
                textDecoration: 'none',
                fontSize: '14px',
                fontWeight: isActive ? '700' : '500',
                color: isActive ? 'var(--primary)' : 'var(--text-secondary)',
                backgroundColor: isActive ? 'var(--primary-light)' : 'transparent',
                border: isActive ? '1px solid var(--border-active)' : '1px solid transparent',
                justifyContent: isCollapsed ? 'center' : 'flex-start',
                transition: 'all 0.15s ease',
              })}
              title={isCollapsed ? item.label : undefined}
            >
              <Icon size={20} />
              {!isCollapsed && <span>{item.label}</span>}
            </NavLink>
          );
        })}
      </nav>

      {/* Collapse Toggle & Logout */}
      <div
        style={{
          padding: '16px 12px',
          borderTop: '1px solid var(--border-subtle)',
          display: 'flex',
          flexDirection: 'column',
          gap: '8px',
        }}
      >
        <button
          onClick={() => setIsCollapsed(!isCollapsed)}
          style={{
            display: 'flex',
            alignItems: 'center',
            justifyContent: isCollapsed ? 'center' : 'flex-start',
            gap: '12px',
            width: '100%',
            padding: '10px 14px',
            background: 'transparent',
            border: 'none',
            color: 'var(--text-tertiary)',
            borderRadius: 'var(--btn-radius)',
            cursor: 'pointer',
            fontSize: '13px',
          }}
        >
          {isCollapsed ? <ChevronRight size={18} /> : <><ChevronLeft size={18} /><span>Collapse Menu</span></>}
        </button>

        <button
          onClick={logout}
          style={{
            display: 'flex',
            alignItems: 'center',
            justifyContent: isCollapsed ? 'center' : 'flex-start',
            gap: '12px',
            width: '100%',
            padding: '10px 14px',
            background: 'transparent',
            border: 'none',
            color: 'var(--accent-rose)',
            borderRadius: 'var(--btn-radius)',
            cursor: 'pointer',
            fontSize: '13px',
            fontWeight: '600',
          }}
          title={isCollapsed ? 'Sign Out' : undefined}
        >
          <LogOut size={18} />
          {!isCollapsed && <span>Sign Out</span>}
        </button>
      </div>
    </aside>
  );
}
