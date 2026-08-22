import React, { useState } from 'react';
import { Outlet, useLocation } from 'react-router-dom';
import { Sidebar } from './Sidebar';
import { Header } from './Header';

export function AdminLayout() {
  const [isCollapsed, setIsCollapsed] = useState(false);
  const location = useLocation();

  const getPageTitle = (pathname) => {
    switch (pathname) {
      case '/': return 'Dashboard Overview';
      case '/ai-studio': return 'AI Keyword Studio & Models';
      case '/tasks': return 'Video Tasks Management';
      case '/sessions': return 'Live Watch Sessions';
      case '/users': return 'User Accounts & Roles';
      case '/ledger': return 'Financial Ledger';
      case '/security': return 'Security & Token Blacklist';
      default: return 'Admin Command Center';
    }
  };

  return (
    <div style={{ display: 'flex', minHeight: '100vh', backgroundColor: 'var(--bg-primary)' }}>
      <Sidebar isCollapsed={isCollapsed} setIsCollapsed={setIsCollapsed} />
      
      <div style={{ flex: 1, display: 'flex', flexDirection: 'column', minWidth: 0 }}>
        <Header title={getPageTitle(location.pathname)} />
        <main style={{ flex: 1, padding: '32px', maxWidth: '1600px', width: '100%', margin: '0 auto', boxSizing: 'border-box' }}>
          <Outlet />
        </main>
      </div>
    </div>
  );
}
