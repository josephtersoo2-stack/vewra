import React, { useEffect, useState } from 'react';
import {
  PlayCircle,
  Search,
  RefreshCw,
  Clock,
  Radio,
  Users,
  Timer,
  ExternalLink,
  Coins,
  CheckCircle2,
  Eye,
} from 'lucide-react';
import { adminApi } from '../api/adminApi';
import { Badge } from '../components/ui/Badge';
import { VideoUsersWatchedModal } from './VideoUsersWatchedModal';
import { formatWatchDuration, formatViewerCount } from '../utils/timeFormat';

export function WatchSessionsPage() {
  const [videoTasks, setVideoTasks] = useState([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState('');
  const [filterMode, setFilterMode] = useState('all'); // 'all', 'live', 'idle'
  const [timeUnit, setTimeUnit] = useState('minutes'); // 'seconds', 'minutes', 'hours'
  const [refreshing, setRefreshing] = useState(false);
  const [lastRefreshedAt, setLastRefreshedAt] = useState('');

  // Selected video for the Users Watched popup modal
  const [selectedTaskForModal, setSelectedTaskForModal] = useState(null);

  const loadTelemetry = async (isManual = false) => {
    if (isManual) setRefreshing(true);
    try {
      const data = await adminApi.getVideoTelemetry({ search });
      setVideoTasks(data || []);
      setLastRefreshedAt(new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit', second: '2-digit' }));
    } catch (err) {
      console.error('Failed to load video telemetry', err);
    } finally {
      setLoading(false);
      if (isManual) setTimeout(() => setRefreshing(false), 500);
    }
  };

  useEffect(() => {
    loadTelemetry();
    const interval = setInterval(() => {
      loadTelemetry();
    }, 3000); // 3s live polling
    return () => clearInterval(interval);
  }, [search]);

  const filteredTasks = videoTasks.filter((t) => {
    const q = search.toLowerCase();
    const matchSearch =
      (t.title || '').toLowerCase().includes(q) ||
      (t.video_id || '').toLowerCase().includes(q);

    if (!matchSearch) return false;

    if (filterMode === 'live') return t.live_viewers_count > 0;
    if (filterMode === 'idle') return t.live_viewers_count === 0;
    return true;
  });

  const totalLiveViewers = videoTasks.reduce((acc, t) => acc + (t.live_viewers_count || 0), 0);
  const liveVideosCount = videoTasks.filter((t) => t.live_viewers_count > 0).length;

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: '28px' }}>
      {/* Header & Controls */}
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', flexWrap: 'wrap', gap: '16px' }}>
        <div>
          <h1 style={{ fontSize: '26px', fontWeight: '800', color: 'var(--text-primary)' }}>
            Watch Sessions & Telemetry
          </h1>
          <p style={{ fontSize: '14px', color: 'var(--text-secondary)', marginTop: '4px' }}>
            Real-time playback telemetry per video with 15-second inactivity tracking
          </p>
        </div>

        <div style={{ display: 'flex', alignItems: 'center', gap: '12px', flexWrap: 'wrap' }}>
          {/* Live vs Idle Filter Tabs */}
          <div
            style={{
              display: 'flex',
              backgroundColor: 'var(--bg-tertiary)',
              borderRadius: 'var(--btn-radius)',
              padding: '4px',
              border: '1px solid var(--border-card)',
            }}
          >
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
              All Videos ({videoTasks.length})
            </button>
            <button
              onClick={() => setFilterMode('live')}
              style={{
                padding: '6px 14px',
                borderRadius: '6px',
                border: 'none',
                backgroundColor: filterMode === 'live' ? 'var(--bg-card)' : 'transparent',
                color: filterMode === 'live' ? 'var(--accent-rose)' : 'var(--text-secondary)',
                fontWeight: filterMode === 'live' ? '700' : '500',
                fontSize: '13px',
                cursor: 'pointer',
                display: 'flex',
                alignItems: 'center',
                gap: '6px',
              }}
            >
              <Radio size={14} className={liveVideosCount > 0 ? 'pulse-badge' : ''} />
              <span>Watching Live ({liveVideosCount})</span>
            </button>
            <button
              onClick={() => setFilterMode('idle')}
              style={{
                padding: '6px 14px',
                borderRadius: '6px',
                border: 'none',
                backgroundColor: filterMode === 'idle' ? 'var(--bg-card)' : 'transparent',
                color: filterMode === 'idle' ? 'var(--accent-amber)' : 'var(--text-secondary)',
                fontWeight: filterMode === 'idle' ? '700' : '500',
                fontSize: '13px',
                cursor: 'pointer',
              }}
            >
              Not Watching ({videoTasks.length - liveVideosCount})
            </button>
          </div>

          {/* Time Unit Filter Pills */}
          <div
            style={{
              display: 'flex',
              alignItems: 'center',
              backgroundColor: 'var(--bg-tertiary)',
              borderRadius: 'var(--btn-radius)',
              padding: '4px',
              border: '1px solid var(--border-card)',
            }}
          >
            <span style={{ fontSize: '12px', fontWeight: '600', color: 'var(--text-tertiary)', padding: '0 8px' }}>
              Unit:
            </span>
            <button
              onClick={() => setTimeUnit('seconds')}
              style={{
                padding: '5px 10px',
                borderRadius: '6px',
                border: 'none',
                backgroundColor: timeUnit === 'seconds' ? 'var(--bg-card)' : 'transparent',
                color: timeUnit === 'seconds' ? 'var(--primary)' : 'var(--text-secondary)',
                fontWeight: timeUnit === 'seconds' ? '700' : '500',
                fontSize: '12px',
                cursor: 'pointer',
              }}
            >
              Seconds (s)
            </button>
            <button
              onClick={() => setTimeUnit('minutes')}
              style={{
                padding: '5px 10px',
                borderRadius: '6px',
                border: 'none',
                backgroundColor: timeUnit === 'minutes' ? 'var(--bg-card)' : 'transparent',
                color: timeUnit === 'minutes' ? 'var(--primary)' : 'var(--text-secondary)',
                fontWeight: timeUnit === 'minutes' ? '700' : '500',
                fontSize: '12px',
                cursor: 'pointer',
              }}
            >
              Minutes (m)
            </button>
            <button
              onClick={() => setTimeUnit('hours')}
              style={{
                padding: '5px 10px',
                borderRadius: '6px',
                border: 'none',
                backgroundColor: timeUnit === 'hours' ? 'var(--bg-card)' : 'transparent',
                color: timeUnit === 'hours' ? 'var(--primary)' : 'var(--text-secondary)',
                fontWeight: timeUnit === 'hours' ? '700' : '500',
                fontSize: '12px',
                cursor: 'pointer',
              }}
            >
              Hours (hrs)
            </button>
          </div>

          <div style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
            <button
              onClick={() => loadTelemetry(true)}
              disabled={refreshing}
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
                cursor: refreshing ? 'not-allowed' : 'pointer',
              }}
            >
              <RefreshCw
                size={14}
                style={{
                  animation: refreshing ? 'spin 0.8s linear infinite' : 'none',
                  color: refreshing ? 'var(--primary)' : 'inherit',
                }}
              />
              <span>{refreshing ? 'Syncing...' : 'Sync'}</span>
            </button>
          </div>
        </div>
      </div>

      {/* Filter and Search Bar */}
      <div className="card" style={{ padding: '16px' }}>
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', gap: '16px', flexWrap: 'wrap' }}>
          <div style={{ position: 'relative', flex: 1, minWidth: '280px' }}>
            <Search size={18} style={{ position: 'absolute', left: '14px', top: '50%', transform: 'translateY(-50%)', color: 'var(--text-tertiary)' }} />
            <input
              type="text"
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              placeholder="Search by video task title, YouTube ID..."
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

          <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
            <Badge variant="rose" size="md">
              🔴 {formatViewerCount(totalLiveViewers)} Total Watching Live
            </Badge>
            <Badge variant="indigo" size="md">
              {filteredTasks.length} Tasks Monitored
            </Badge>
          </div>
        </div>
      </div>

      {/* Video-Based Telemetry Table */}
      <div className="card" style={{ padding: '0', overflow: 'hidden' }}>
        {loading && videoTasks.length === 0 ? (
          <div style={{ padding: '48px', textAlign: 'center', color: 'var(--text-secondary)' }}>
            Loading video telemetry stream...
          </div>
        ) : filteredTasks.length === 0 ? (
          <div style={{ padding: '48px', textAlign: 'center', color: 'var(--text-tertiary)' }}>
            {filterMode === 'live'
              ? 'No videos currently have active live viewers in the last 15 seconds.'
              : 'No video tasks found matching query.'}
          </div>
        ) : (
          <div style={{ overflowX: 'auto' }}>
            <table style={{ width: '100%', borderCollapse: 'collapse', textAlign: 'left', fontSize: '13px' }}>
              <thead>
                <tr style={{ borderBottom: '1px solid var(--border-subtle)', color: 'var(--text-tertiary)', backgroundColor: 'var(--bg-tertiary)' }}>
                  <th style={{ padding: '14px 18px', fontWeight: '600' }}>Video Task</th>
                  <th style={{ padding: '14px 18px', fontWeight: '600' }}>Live Viewers (Realtime)</th>
                  <th style={{ padding: '14px 18px', fontWeight: '600' }}>Total Users Watched</th>
                  <th style={{ padding: '14px 18px', fontWeight: '600' }}>
                    <div style={{ display: 'flex', alignItems: 'center', gap: '4px' }}>
                      <Timer size={14} style={{ color: 'var(--primary)' }} />
                      <span>Total Watched ({timeUnit === 'hours' ? 'hrs' : timeUnit === 'minutes' ? 'mins' : 's'})</span>
                    </div>
                  </th>
                  <th style={{ padding: '14px 18px', fontWeight: '600' }}>Completed Count</th>
                  <th style={{ padding: '14px 18px', fontWeight: '600', textAlign: 'right' }}>Telemetry Action</th>
                </tr>
              </thead>
              <tbody>
                {filteredTasks.map((t) => (
                  <tr
                    key={t.id}
                    style={{
                      borderBottom: '1px solid var(--border-subtle)',
                      color: 'var(--text-primary)',
                      backgroundColor: t.live_viewers_count > 0 ? 'var(--primary-light)' : 'transparent',
                    }}
                  >
                    {/* Video Info */}
                    <td style={{ padding: '16px 18px' }}>
                      <div style={{ display: 'flex', alignItems: 'center', gap: '14px' }}>
                        <img
                          src={t.thumbnail_url || `https://img.youtube.com/vi/${t.video_id}/hqdefault.jpg`}
                          alt={t.title}
                          style={{
                            width: '74px',
                            height: '48px',
                            borderRadius: '6px',
                            objectFit: 'cover',
                            border: '1px solid var(--border-subtle)',
                          }}
                        />
                        <div style={{ maxWidth: '320px' }}>
                          <div style={{ fontWeight: '700', fontSize: '14px', color: 'var(--text-primary)', lineHeight: '1.3' }}>
                            {t.title}
                          </div>
                          <div style={{ display: 'flex', alignItems: 'center', gap: '6px', marginTop: '4px' }}>
                            <span style={{ fontSize: '11px', fontFamily: 'var(--font-mono)', color: 'var(--text-tertiary)' }}>
                              {t.video_id}
                            </span>
                            <a
                              href={t.youtube_url || `https://www.youtube.com/watch?v=${t.video_id}`}
                              target="_blank"
                              rel="noreferrer"
                              style={{ color: 'var(--text-tertiary)', display: 'flex', alignItems: 'center' }}
                            >
                              <ExternalLink size={12} />
                            </a>
                          </div>
                        </div>
                      </div>
                    </td>

                    {/* Real-Time Live Viewers */}
                    <td style={{ padding: '16px 18px' }}>
                      {t.live_viewers_count > 0 ? (
                        <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                          <Badge variant="rose" size="md">
                            🔴 {formatViewerCount(t.live_viewers_count)} Watching Live
                          </Badge>
                        </div>
                      ) : (
                        <div style={{ display: 'flex', alignItems: 'center', gap: '6px', color: 'var(--text-tertiary)' }}>
                          <Badge variant="amber" size="sm">
                            ⏸ Not Watching (0 live)
                          </Badge>
                        </div>
                      )}
                    </td>

                    {/* Total Users Watched */}
                    <td style={{ padding: '16px 18px' }}>
                      <div style={{ display: 'flex', alignItems: 'center', gap: '6px', fontWeight: '700', fontSize: '14px' }}>
                        <Users size={15} style={{ color: 'var(--primary)' }} />
                        <span>{formatViewerCount(t.total_unique_users_watched)} users</span>
                      </div>
                    </td>

                    {/* Total Watched Duration */}
                    <td style={{ padding: '16px 18px' }}>
                      <span
                        style={{
                          fontFamily: 'var(--font-mono)',
                          fontWeight: '700',
                          color: Number(t.total_watch_seconds) > 0 ? 'var(--primary)' : 'var(--text-tertiary)',
                          fontSize: '14px',
                        }}
                      >
                        {formatWatchDuration(t.total_watch_seconds || 0, timeUnit)}
                      </span>
                    </td>

                    {/* Completed Count */}
                    <td style={{ padding: '16px 18px' }}>
                      <span style={{ fontWeight: '600', color: 'var(--accent-emerald)' }}>
                        ✓ {t.completed_count || 0} finished
                      </span>
                    </td>

                    {/* Action: Users Watched Popup */}
                    <td style={{ padding: '16px 18px', textAlign: 'right' }}>
                      <button
                        onClick={() => setSelectedTaskForModal(t)}
                        style={{
                          padding: '8px 16px',
                          borderRadius: 'var(--btn-radius)',
                          backgroundColor: 'var(--primary)',
                          color: '#FFFFFF',
                          border: 'none',
                          fontSize: '13px',
                          fontWeight: '700',
                          cursor: 'pointer',
                          display: 'inline-flex',
                          alignItems: 'center',
                          gap: '6px',
                          boxShadow: '0 2px 8px var(--primary-glow)',
                        }}
                      >
                        <Eye size={14} />
                        <span>Users Watched ({t.total_unique_users_watched})</span>
                      </button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>

      {/* Users Watched Detail Modal Popup */}
      <VideoUsersWatchedModal
        isOpen={!!selectedTaskForModal}
        onClose={() => setSelectedTaskForModal(null)}
        videoTask={selectedTaskForModal}
      />
    </div>
  );
}
