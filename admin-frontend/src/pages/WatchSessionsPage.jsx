import React, { useEffect, useState } from 'react';
import {
  PlayCircle,
  Search,
  RefreshCw,
  CheckCircle2,
  Clock,
  ShieldAlert,
  User,
  Radio,
} from 'lucide-react';
import { adminApi } from '../api/adminApi';
import { Badge } from '../components/ui/Badge';

export function WatchSessionsPage() {
  const [sessions, setSessions] = useState([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState('');
  const [filterMode, setFilterMode] = useState('all'); // 'all' or 'live'
  const [refreshing, setRefreshing] = useState(false);

  const loadSessions = async (isManual = false) => {
    if (isManual) setRefreshing(true);
    try {
      let data = [];
      if (filterMode === 'live') {
        data = await adminApi.getLiveWatchSessions();
      } else {
        data = await adminApi.getWatchSessions({ search });
      }
      setSessions(data);
    } catch (err) {
      console.error('Failed to load watch sessions', err);
    } finally {
      setLoading(false);
      if (isManual) setRefreshing(false);
    }
  };

  useEffect(() => {
    loadSessions();
    const interval = setInterval(() => {
      loadSessions();
    }, 4000); // 4s live polling
    return () => clearInterval(interval);
  }, [filterMode, search]);

  const filteredSessions = sessions.filter((s) => {
    const q = search.toLowerCase();
    return (
      (s.username || '').toLowerCase().includes(q) ||
      (s.video_task_title || '').toLowerCase().includes(q) ||
      (s.video_task_id || '').toLowerCase().includes(q)
    );
  });

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: '28px' }}>
      {/* Header & Controls */}
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', flexWrap: 'wrap', gap: '16px' }}>
        <div>
          <h1 style={{ fontSize: '26px', fontWeight: '800', color: 'var(--text-primary)' }}>
            Watch Sessions & Progress
          </h1>
          <p style={{ fontSize: '14px', color: 'var(--text-secondary)', marginTop: '4px' }}>
            Inspect real-time viewer playback positions, watch time verification, and completion status
          </p>
        </div>

        <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
          {/* Tab Filter Mode */}
          <div style={{ display: 'flex', backgroundColor: 'var(--bg-tertiary)', borderRadius: 'var(--btn-radius)', padding: '4px', border: '1px solid var(--border-card)' }}>
            <button
              onClick={() => setFilterMode('all')}
              style={{
                padding: '6px 14px',
                borderRadius: '6px',
                border: 'none',
                backgroundColor: filterMode === 'all' ? 'var(--bg-card)' : 'transparent',
                color: filterMode === 'all' ? 'var(--primary)' : 'var(--text-secondary)',
                fontWeight: filterMode === 'all' ? '700' : '500',
                fontSize: '13px',
                cursor: 'pointer',
              }}
            >
              All Sessions
            </button>
            <button
              onClick={() => setFilterMode('live')}
              style={{
                padding: '6px 14px',
                borderRadius: '6px',
                border: 'none',
                backgroundColor: filterMode === 'live' ? 'var(--bg-card)' : 'transparent',
                color: filterMode === 'live' ? 'var(--accent-emerald)' : 'var(--text-secondary)',
                fontWeight: filterMode === 'live' ? '700' : '500',
                fontSize: '13px',
                cursor: 'pointer',
                display: 'flex',
                alignItems: 'center',
                gap: '6px',
              }}
            >
              <span style={{ width: '6px', height: '6px', borderRadius: '50%', backgroundColor: 'var(--accent-emerald)' }} />
              <span>Live Watching</span>
            </button>
          </div>

          <button
            onClick={() => loadSessions(true)}
            style={{
              display: 'flex',
              alignItems: 'center',
              gap: '6px',
              padding: '8px 14px',
              borderRadius: 'var(--btn-radius)',
              backgroundColor: 'var(--bg-secondary)',
              border: '1px solid var(--border-card)',
              color: 'var(--text-primary)',
              fontSize: '13px',
              fontWeight: '600',
              cursor: 'pointer',
            }}
          >
            <RefreshCw size={14} className={refreshing ? 'pulse-badge' : ''} />
            <span>Sync</span>
          </button>
        </div>
      </div>

      {/* Filter and Search Bar */}
      <div className="card" style={{ padding: '16px' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: '16px', flexWrap: 'wrap' }}>
          <div style={{ position: 'relative', flex: 1, minWidth: '280px' }}>
            <Search size={18} style={{ position: 'absolute', left: '14px', top: '50%', transform: 'translateY(-50%)', color: 'var(--text-tertiary)' }} />
            <input
              type="text"
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              placeholder="Filter by username, video title..."
              style={{
                width: '100%',
                padding: '10px 14px 10px 42px',
                borderRadius: 'var(--input-radius)',
                backgroundColor: 'var(--bg-tertiary)',
                border: '1px solid var(--border-card)',
                color: 'var(--text-primary)',
                fontSize: '13px',
              }}
            />
          </div>

          <Badge variant={filterMode === 'live' ? 'emerald' : 'indigo'} size="md">
            {filteredSessions.length} {filterMode === 'live' ? 'Active Streams' : 'Sessions Total'}
          </Badge>
        </div>
      </div>

      {/* Sessions Table */}
      <div className="card" style={{ padding: '0', overflow: 'hidden' }}>
        {loading && sessions.length === 0 ? (
          <div style={{ padding: '48px', textAlign: 'center', color: 'var(--text-secondary)' }}>
            Loading watch sessions...
          </div>
        ) : filteredSessions.length === 0 ? (
          <div style={{ padding: '48px', textAlign: 'center', color: 'var(--text-tertiary)' }}>
            {filterMode === 'live' ? 'No active live watching streams right now.' : 'No watch sessions recorded yet.'}
          </div>
        ) : (
          <div style={{ overflowX: 'auto' }}>
            <table style={{ width: '100%', borderCollapse: 'collapse', textAlign: 'left', fontSize: '13px' }}>
              <thead>
                <tr style={{ borderBottom: '1px solid var(--border-subtle)', color: 'var(--text-tertiary)', backgroundColor: 'var(--bg-tertiary)' }}>
                  <th style={{ padding: '14px 18px', fontWeight: '600' }}>User</th>
                  <th style={{ padding: '14px 18px', fontWeight: '600' }}>Target Video</th>
                  <th style={{ padding: '14px 18px', fontWeight: '600' }}>Watched Time</th>
                  <th style={{ padding: '14px 18px', fontWeight: '600' }}>Highest Position</th>
                  <th style={{ padding: '14px 18px', fontWeight: '600' }}>Status</th>
                  <th style={{ padding: '14px 18px', fontWeight: '600' }}>Last Active</th>
                </tr>
              </thead>
              <tbody>
                {filteredSessions.map((s) => (
                  <tr
                    key={s.id}
                    style={{
                      borderBottom: '1px solid var(--border-subtle)',
                      color: 'var(--text-primary)',
                    }}
                  >
                    <td style={{ padding: '16px 18px' }}>
                      <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
                        <div
                          style={{
                            width: '32px',
                            height: '32px',
                            borderRadius: '50%',
                            backgroundColor: 'var(--primary-light)',
                            color: 'var(--primary)',
                            display: 'flex',
                            alignItems: 'center',
                            justifyContent: 'center',
                            fontWeight: '700',
                          }}
                        >
                          {s.username?.[0]?.toUpperCase() || 'U'}
                        </div>
                        <div>
                          <div style={{ fontWeight: '700', color: 'var(--text-primary)' }}>
                            {s.username}
                          </div>
                          <div style={{ fontSize: '11px', color: 'var(--text-tertiary)' }}>
                            ID #{s.user}
                          </div>
                        </div>
                      </div>
                    </td>

                    <td style={{ padding: '16px 18px', maxWidth: '320px' }}>
                      <div style={{ fontWeight: '600', color: 'var(--text-primary)', lineHeight: '1.3' }}>
                        {s.video_task_title}
                      </div>
                      <div style={{ fontSize: '11px', fontFamily: 'var(--font-mono)', color: 'var(--text-tertiary)', marginTop: '2px' }}>
                        {s.video_task_id}
                      </div>
                    </td>

                    <td style={{ padding: '16px 18px' }}>
                      <span style={{ fontFamily: 'var(--font-mono)', fontWeight: '700', color: 'var(--text-primary)', fontSize: '14px' }}>
                        {Number(s.total_watched_seconds).toFixed(1)}s
                      </span>
                    </td>

                    <td style={{ padding: '16px 18px' }}>
                      <span style={{ fontFamily: 'var(--font-mono)', color: 'var(--text-secondary)' }}>
                        {Number(s.current_position).toFixed(1)}s
                      </span>
                    </td>

                    <td style={{ padding: '16px 18px' }}>
                      {s.is_completed ? (
                        <Badge variant="emerald">
                          <CheckCircle2 size={12} /> Completed
                        </Badge>
                      ) : (
                        <Badge variant="amber">
                          <Clock size={12} /> In Progress
                        </Badge>
                      )}
                    </td>

                    <td style={{ padding: '16px 18px', color: 'var(--text-tertiary)' }}>
                      {new Date(s.updated_at).toLocaleString()}
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
