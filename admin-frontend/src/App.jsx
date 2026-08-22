import React from 'react';
import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import { ThemeProvider } from './theme/ThemeContext';
import { AuthProvider, useAuth } from './context/AuthContext';
import { AdminLayout } from './components/layout/AdminLayout';

// Pages
import { LoginPage } from './pages/LoginPage';
import { DashboardPage } from './pages/DashboardPage';
import { AISettingsPage } from './pages/AISettingsPage';
import { TasksPage } from './pages/TasksPage';
import { WatchSessionsPage } from './pages/WatchSessionsPage';
import { UsersPage } from './pages/UsersPage';
import { WalletLedgerPage } from './pages/WalletLedgerPage';
import { SecurityPage } from './pages/SecurityPage';

function ProtectedRoute({ children }) {
  const { isAuthenticated, isAdmin } = useAuth();
  if (!isAuthenticated || !isAdmin) {
    return <Navigate to="/login" replace />;
  }
  return children;
}

export function App() {
  return (
    <ThemeProvider>
      <AuthProvider>
        <BrowserRouter>
          <Routes>
            <Route path="/login" element={<LoginPage />} />

            <Route
              path="/"
              element={
                <ProtectedRoute>
                  <AdminLayout />
                </ProtectedRoute>
              }
            >
              <Route index element={<DashboardPage />} />
              <Route path="ai-studio" element={<AISettingsPage />} />
              <Route path="tasks" element={<TasksPage />} />
              <Route path="sessions" element={<WatchSessionsPage />} />
              <Route path="users" element={<UsersPage />} />
              <Route path="ledger" element={<WalletLedgerPage />} />
              <Route path="security" element={<SecurityPage />} />
            </Route>

            <Route path="*" element={<Navigate to="/" replace />} />
          </Routes>
        </BrowserRouter>
      </AuthProvider>
    </ThemeProvider>
  );
}

export default App;
