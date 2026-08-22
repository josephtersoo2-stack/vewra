import React, { useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import {
  Users,
  PlayCircle,
  Coins,
  CheckCircle2,
  TrendingUp,
  Sparkles,
  Video,
  RefreshCw,
  Clock,
} from 'lucide-react';
import {
  AreaChart,
  Area,
  BarChart,
  Bar,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
} from 'recharts';
import { adminApi } from '../api/adminApi';
import { StatCard } from '../components/ui/StatCard';
import { Badge } from '../components/ui/Badge';
import { useTheme } from '../theme/ThemeContext';

export function DashboardPage() {
  const [data, setData] = useState(null);
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);
  const { isDark } = useTheme();
  const navigate = useNavigate();

  const fetchStats = async (isManual = false) => {
    if (isManual) setRefreshing(true);
    try {
      const stats = await adminApi.getDashboardStats();
      setData(stats);
    } catch (err) {
      console.error('Failed to fetch dashboard stats', err);
    } finally {
      setLoading(false);
      if (isManual) setRefreshing(false);
    }
  };

  useEffect(() => {
    fetchStats();
    const interval = setInterval(() => {
      fetchStats();
    }, 5000); // 5s live polling
    return () => clearInterval(interval);
  }, []);

  if (loading && !data) {
    return (
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', minHeight: '60vh' }}>
        <p style={{ color: 'var(--text-secondary)', fontSize: '15px' }}>Loading Command Center...</p>
      </div>
    );
  }

  const kpis = data?.kpis || {};
  const trends = data?.daily_trends || [];
  const recent = data?.recent_activity || [];

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: '32px' }}>
      {/* Top Welcome & Quick Actions Bar */}
      <div
        style={{
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'space-between',
          flexWrap: 'wrap',
          gap: '16px',
        }}
      >
        <div>
          <h1 style={{ fontSize: '26px', fontWeight: '800', color: 'var(--text-primary)' }}>
            System Performance
          </h1>
          <p style={{ fontSize: '14px', color: 'var(--text-secondary)', marginTop: '4px' }}>
            Real-time analytics and user watch session metrics
          </p>
        </div>

        <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
          <button
            onClick={() => fetchStats(true)}
            style={{
              display: 'flex',
              alignItems: 'center',
              gap: '8px',
              padding: '10px 16px',
              borderRadius: 'var(--btn-radius)',
              backgroundColor: 'var(--bg-secondary)',
              border: '1px solid var(--border-card)',
              color: 'var(--text-primary)',
              fontSize: '13px',
              fontWeight: '600',
              cursor: 'pointer',
            }}
          >
            <RefreshCw size={16} className={refreshing ? 'pulse-badge' : ''} />
            <span>Refresh</span>
          </button>

          <button
            onClick={() => navigate('/tasks')}
            style={{
              display: 'flex',
              alignItems: 'center',
              gap: '8px',
              padding: '10px 18px',
              borderRadius: 'var(--btn-radius)',
              backgroundColor: 'var(--primary)',
              color: '#FFFFFF',
              border: 'none',
              fontSize: '13px',
              fontWeight: '700',
              cursor: 'pointer',
              boxShadow: '0 4px 12px var(--primary-glow)',
            }}
          >
            <Video size={16} />
            <span>Manage Tasks</span>
          </button>
        </div>
      </div>

      {/* 4 Hero KPI Cards */}
      <div
        style={{
          display: 'grid',
          gridTemplateColumns: 'repeat(auto-fit, minmax(260px, 1fr))',
          gap: '20px',
        }}
      >
        <StatCard
          title="Total Registered Users"
          value={kpis.total_users || 0}
          subtitle={`+${kpis.new_users_today || 0} joined today`}
          icon={Users}
          color="indigo"
        />

        <StatCard
          title="Active Watch Sessions"
          value={kpis.active_sessions_now || 0}
          subtitle="Watching YouTube right now"
          icon={PlayCircle}
          color="emerald"
        />

        <StatCard
          title="Total Coins Earned"
          value={`${kpis.total_coins_distributed || '0.00'}`}
          subtitle={`Liabilities: ${kpis.total_wallet_liabilities || '0'} coins`}
          icon={Coins}
          color="amber"
        />

        <StatCard
          title="Tasks Completed Today"
          value={kpis.tasks_completed_today || 0}
          subtitle={`${kpis.active_tasks_count || 0} active video tasks`}
          icon={CheckCircle2}
          color="cyan"
        />
      </div>

      {/* Analytics Charts Section */}
      <div
        style={{
          display: 'grid',
          gridTemplateColumns: 'repeat(auto-fit, minmax(480px, 1fr))',
          gap: '24px',
        }}
      >
        {/* Watch Time Trend Chart */}
        <div className="card">
          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: '20px' }}>
            <div>
              <h3 style={{ fontSize: '17px', fontWeight: '700', color: 'var(--text-primary)' }}>
                Watch Time Trend (Minutes)
              </h3>
              <p style={{ fontSize: '13px', color: 'var(--text-secondary)', marginTop: '2px' }}>
                Total user view duration across the last 7 days
              </p>
            </div>
            <Badge variant="indigo">7-Day Area</Badge>
          </div>

          <div style={{ height: '260px', width: '100%' }}>
            <ResponsiveContainer width="100%" height="100%">
              <AreaChart data={trends} margin={{ top: 10, right: 10, left: -20, bottom: 0 }}>
                <defs>
                  <linearGradient id="watchGrad" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="5%" stopColor="var(--primary)" stopOpacity={0.4} />
                    <stop offset="95%" stopColor="var(--primary)" stopOpacity={0.0} />
                  </linearGradient>
                </defs>
                <CartesianGrid strokeDasharray="3 3" stroke="var(--border-subtle)" vertical={false} />
                <XAxis dataKey="date" stroke="var(--text-tertiary)" fontSize={12} tickLine={false} />
                <YAxis stroke="var(--text-tertiary)" fontSize={12} tickLine={false} />
                <Tooltip
                  contentStyle={{
                    backgroundColor: 'var(--bg-secondary)',
                    borderColor: 'var(--border-card)',
                    borderRadius: '8px',
                    color: 'var(--text-primary)',
                    boxShadow: 'var(--shadow-md)',
                  }}
                />
                <Area
                  type="monotone"
                  dataKey="watch_minutes"
                  stroke="var(--primary)"
                  strokeWidth={3}
                  fillOpacity={1}
                  fill="url(#watchGrad)"
                  name="Watch Minutes"
                />
              </AreaChart>
            </ResponsiveContainer>
          </div>
        </div>

        {/* Coins Distributed Trend Chart */}
        <div className="card">
          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: '20px' }}>
            <div>
              <h3 style={{ fontSize: '17px', fontWeight: '700', color: 'var(--text-primary)' }}>
                Coin Disbursements
              </h3>
              <p style={{ fontSize: '13px', color: 'var(--text-secondary)', marginTop: '2px' }}>
                Daily coin rewards issued for completed watch sessions
              </p>
            </div>
            <Badge variant="amber">7-Day Bar</Badge>
          </div>

          <div style={{ height: '260px', width: '100%' }}>
            <ResponsiveContainer width="100%" height="100%">
              <BarChart data={trends} margin={{ top: 10, right: 10, left: -20, bottom: 0 }}>
                <CartesianGrid strokeDasharray="3 3" stroke="var(--border-subtle)" vertical={false} />
                <XAxis dataKey="date" stroke="var(--text-tertiary)" fontSize={12} tickLine={false} />
                <YAxis stroke="var(--text-tertiary)" fontSize={12} tickLine={false} />
                <Tooltip
                  contentStyle={{
                    backgroundColor: 'var(--bg-secondary)',
                    borderColor: 'var(--border-card)',
                    borderRadius: '8px',
                    color: 'var(--text-primary)',
                    boxShadow: 'var(--shadow-md)',
                  }}
                />
                <Bar
                  dataKey="coins_earned"
                  fill="var(--accent-amber)"
                  radius={[6, 6, 0, 0]}
                  name="Coins Earned"
                />
              </BarChart>
            </ResponsiveContainer>
          </div>
        </div>
      </div>

      {/* Live Recent Activity Table */}
      <div className="card">
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: '20px' }}>
          <div>
            <h3 style={{ fontSize: '17px', fontWeight: '700', color: 'var(--text-primary)' }}>
              Real-Time Watch Activity
            </h3>
            <p style={{ fontSize: '13px', color: 'var(--text-secondary)', marginTop: '2px' }}>
              Live stream of watch sessions and user progress
            </p>
          </div>
          <button
            onClick={() => navigate('/sessions')}
            style={{
              background: 'transparent',
              border: 'none',
              color: 'var(--primary)',
              fontSize: '13px',
              fontWeight: '700',
              cursor: 'pointer',
            }}
          >
            View All Sessions →
          </button>
        </div>

        {recent.length === 0 ? (
          <div style={{ padding: '32px', textAlign: 'center', color: 'var(--text-tertiary)' }}>
            No recent sessions recorded yet.
          </div>
        ) : (
          <div style={{ overflowX: 'auto' }}>
            <table style={{ width: '100%', borderCollapse: 'collapse', textAlign: 'left', fontSize: '13px' }}>
              <thead>
                <tr style={{ borderBottom: '1px solid var(--border-subtle)', color: 'var(--text-tertiary)' }}>
                  <th style={{ padding: '12px 16px', fontWeight: '600' }}>User</th>
                  <th style={{ padding: '12px 16px', fontWeight: '600' }}>Video Task</th>
                  <th style={{ padding: '12px 16px', fontWeight: '600' }}>Watched Time</th>
                  <th style={{ padding: '12px 16px', fontWeight: '600' }}>Status</th>
                  <th style={{ padding: '12px 16px', fontWeight: '600' }}>Last Active</th>
                </tr>
              </thead>
              <tbody>
                {recent.map((s) => (
                  <tr
                    key={s.id}
                    style={{
                      borderBottom: '1px solid var(--border-subtle)',
                      color: 'var(--text-primary)',
                    }}
                  >
                    <td style={{ padding: '14px 16px', fontWeight: '600' }}>
                      {s.username}
                    </td>
                    <td style={{ padding: '14px 16px', maxWidth: '320px', whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>
                      {s.task_title}
                    </td>
                    <td style={{ padding: '14px 16px' }}>
                      <span style={{ fontFamily: 'var(--font-mono)', fontWeight: '600' }}>
                        {s.watched_seconds}s
                      </span>
                    </td>
                    <td style={{ padding: '14px 16px' }}>
                      {s.is_completed ? (
                        <Badge variant="emerald">Completed</Badge>
                      ) : (
                        <Badge variant="amber">Watching</Badge>
                      )}
                    </td>
                    <td style={{ padding: '14px 16px', color: 'var(--text-tertiary)' }}>
                      {new Date(s.updated_at).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit', second: '2-digit' })}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>
    </div>
  );
}
