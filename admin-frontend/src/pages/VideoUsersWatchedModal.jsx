import React, { useEffect, useState } from 'react';
import {
  Users,
  Search,
  Timer,
  PlayCircle,
  CheckCircle2,
  AlertCircle,
  Radio,
  ExternalLink,
  Coins,
  Clock,
  RefreshCw,
} from 'lucide-react';
import { adminApi } from '../api/adminApi';
import { Modal } from '../components/ui/Modal';
import { Badge } from '../components/ui/Badge';
import { formatWatchDuration } from '../utils/timeFormat';

export function VideoUsersWatchedModal({ isOpen, onClose, videoTask }) {
  const [viewers, setViewers] = useState([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState('');
  const [statusFilter, setStatusFilter] = useState('all'); // 'all', 'live', 'completed', 'not_watching'
  const [timeUnit, setTimeUnit] = useState('minutes'); // 'seconds', 'minutes', 'hours'
  const [refreshing, setRefreshing] = useState(false);

  const loadViewers = async (isManual = false) => {
    if (!videoTask?.id) return;
    if (isManual) setRefreshing(true);
    try {
      const data = await adminApi.getVideoViewers(videoTask.id);
      setViewers(data.viewers || []);
    } catch (err) {
      console.error('Failed to load video viewers', err);
    } finally {
      setLoading(false);
      if (isManual) setTimeout(() => setRefreshing(false), 500);
    }
  };

  useEffect(() => {
    if (isOpen && videoTask?.id) {
      setLoading(true);
      loadViewers();
      const interval = setInterval(() => {
        loadViewers();
      }, 3000); // 3s live polling
      return () => clearInterval(interval);
    }
  }, [isOpen, videoTask?.id]);

  if (!videoTask) return null;

  const filteredViewers = viewers.filter((v) => {
    const q = search.toLowerCase();
    const matchSearch =
      (v.username || '').toLowerCase().includes(q) ||
      (v.email || '').toLowerCase().includes(q);

    if (!matchSearch) return false;

    if (statusFilter === 'live') return v.is_live;
    if (statusFilter === 'completed') return v.is_completed;
    if (statusFilter === 'not_watching') return !v.is_live && !v.is_completed;
    return true;
  });

  const liveCount = viewers.filter((v) => v.is_live).length;
  const completedCount = viewers.filter((v) => v.is_completed).length;

  return (
    <Modal
      isOpen={isOpen}
      onClose={onClose}
      title="Video Watch Telemetry & Viewers"
      maxWidth="880px"
    >
      <div style={{ display: 'flex', flexDirection: 'column', gap: '20px' }}>
        {/* Video Summary Banner */}
        <div
          style={{
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'space-between',
            gap: '16px',
            padding: '16px',
            backgroundColor: 'var(--bg-tertiary)',
            borderRadius: 'var(--card-radius)',
            border: '1px solid var(--border-subtle)',
            flexWrap: 'wrap',
          }}
        >
          <div style={{ display: 'flex', alignItems: 'center', gap: '14px' }}>
            <img
              src={videoTask.thumbnail_url || `https://img.youtube.com/vi/${videoTask.video_id}/hqdefault.jpg`}
              alt={videoTask.title}
              style={{
                width: '80px',
                height: '52px',
                borderRadius: '6px',
                objectFit: 'cover',
                border: '1px solid var(--border-subtle)',
              }}
            />
            <div style={{ maxWidth: '420px' }}>
              <div style={{ fontWeight: '700', fontSize: '15px', color: 'var(--text-primary)' }}>
                {videoTask.title}
              </div>
              <div style={{ display: 'flex', alignItems: 'center', gap: '8px', marginTop: '4px' }}>
                <span style={{ fontSize: '12px', fontFamily: 'var(--font-mono)', color: 'var(--text-tertiary)' }}>
                  {videoTask.video_id}
                </span>
                <a
                  href={videoTask.youtube_url || `https://www.youtube.com/watch?v=${videoTask.video_id}`}
                  target="_blank"
                  rel="noreferrer"
                  style={{ color: 'var(--primary)', display: 'flex', alignItems: 'center', gap: '2px', fontSize: '12px' }}
                >
                  <span>Open Video</span>
                  <ExternalLink size={12} />
                </a>
              </div>
            </div>
          </div>

          {/* Quick Metrics Badges */}
          <div style={{ display: 'flex', alignItems: 'center', gap: '10px', flexWrap: 'wrap' }}>
            {liveCount > 0 ? (
              <Badge variant="rose" size="md">
                🔴 {liveCount} Watching Live
              </Badge>
            ) : (
              <Badge variant="default" size="md">
                ⏸ 0 Watching Live
              </Badge>
            )}

            <Badge variant="indigo" size="md">
              👥 {viewers.length} Total Viewers
            </Badge>

            <Badge variant="emerald" size="md">
              ✓ {completedCount} Completed
            </Badge>
          </div>
        </div>

        {/* Filters and Controls */}
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', gap: '12px', flexWrap: 'wrap' }}>
          {/* Search */}
          <div style={{ position: 'relative', flex: 1, minWidth: '220px' }}>
            <Search size={16} style={{ position: 'absolute', left: '12px', top: '50%', transform: 'translateY(-50%)', color: 'var(--text-tertiary)' }} />
            <input
              type="text"
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              placeholder="Search viewers..."
              style={{
                width: '100%',
                padding: '8px 12px 8px 36px',
                borderRadius: 'var(--input-radius)',
                backgroundColor: 'var(--bg-secondary)',
                border: '1px solid var(--border-card)',
                color: 'var(--text-primary)',
                fontSize: '13px',
              }}
            />
          </div>

          {/* Status Filter Tabs */}
          <div
            style={{
              display: 'flex',
              backgroundColor: 'var(--bg-tertiary)',
              borderRadius: 'var(--btn-radius)',
              padding: '3px',
              border: '1px solid var(--border-card)',
            }}
          >
            <button
              onClick={() => setStatusFilter('all')}
              style={{
                padding: '5px 10px',
                borderRadius: '5px',
                border: 'none',
                backgroundColor: statusFilter === 'all' ? 'var(--bg-card)' : 'transparent',
                color: statusFilter === 'all' ? 'var(--primary)' : 'var(--text-secondary)',
                fontWeight: statusFilter === 'all' ? '700' : '500',
                fontSize: '12px',
                cursor: 'pointer',
              }}
            >
              All ({viewers.length})
            </button>
            <button
              onClick={() => setStatusFilter('live')}
              style={{
                padding: '5px 10px',
                borderRadius: '5px',
                border: 'none',
                backgroundColor: statusFilter === 'live' ? 'var(--bg-card)' : 'transparent',
                color: statusFilter === 'live' ? 'var(--accent-rose)' : 'var(--text-secondary)',
                fontWeight: statusFilter === 'live' ? '700' : '500',
                fontSize: '12px',
                cursor: 'pointer',
              }}
            >
              Live ({liveCount})
            </button>
            <button
              onClick={() => setStatusFilter('completed')}
              style={{
                padding: '5px 10px',
                borderRadius: '5px',
                border: 'none',
                backgroundColor: statusFilter === 'completed' ? 'var(--bg-card)' : 'transparent',
                color: statusFilter === 'completed' ? 'var(--accent-emerald)' : 'var(--text-secondary)',
                fontWeight: statusFilter === 'completed' ? '700' : '500',
                fontSize: '12px',
                cursor: 'pointer',
              }}
            >
              Completed ({completedCount})
            </button>
            <button
              onClick={() => setStatusFilter('not_watching')}
              style={{
                padding: '5px 10px',
                borderRadius: '5px',
                border: 'none',
                backgroundColor: statusFilter === 'not_watching' ? 'var(--bg-card)' : 'transparent',
                color: statusFilter === 'not_watching' ? 'var(--accent-amber)' : 'var(--text-secondary)',
                fontWeight: statusFilter === 'not_watching' ? '700' : '500',
                fontSize: '12px',
                cursor: 'pointer',
              }}
            >
              Not Watching ({viewers.length - liveCount - completedCount})
            </button>
          </div>

          {/* Time Unit Selector */}
          <div
            style={{
              display: 'flex',
              alignItems: 'center',
              backgroundColor: 'var(--bg-tertiary)',
              borderRadius: 'var(--btn-radius)',
              padding: '3px',
              border: '1px solid var(--border-card)',
            }}
          >
            <span style={{ fontSize: '11px', fontWeight: '600', color: 'var(--text-tertiary)', padding: '0 6px' }}>
              Unit:
            </span>
            <button
              onClick={() => setTimeUnit('seconds')}
              style={{
                padding: '4px 8px',
                borderRadius: '4px',
                border: 'none',
                backgroundColor: timeUnit === 'seconds' ? 'var(--bg-card)' : 'transparent',
                color: timeUnit === 'seconds' ? 'var(--primary)' : 'var(--text-secondary)',
                fontWeight: timeUnit === 'seconds' ? '700' : '500',
                fontSize: '11px',
                cursor: 'pointer',
              }}
            >
              Seconds
            </button>
            <button
              onClick={() => setTimeUnit('minutes')}
              style={{
                padding: '4px 8px',
                borderRadius: '4px',
                border: 'none',
                backgroundColor: timeUnit === 'minutes' ? 'var(--bg-card)' : 'transparent',
                color: timeUnit === 'minutes' ? 'var(--primary)' : 'var(--text-secondary)',
                fontWeight: timeUnit === 'minutes' ? '700' : '500',
                fontSize: '11px',
                cursor: 'pointer',
              }}
            >
              Minutes
            </button>
            <button
              onClick={() => setTimeUnit('hours')}
              style={{
                padding: '4px 8px',
                borderRadius: '4px',
                border: 'none',
                backgroundColor: timeUnit === 'hours' ? 'var(--bg-card)' : 'transparent',
                color: timeUnit === 'hours' ? 'var(--primary)' : 'var(--text-secondary)',
                fontWeight: timeUnit === 'hours' ? '700' : '500',
                fontSize: '11px',
                cursor: 'pointer',
              }}
            >
              Hours
            </button>
          </div>

          <button
            onClick={() => loadViewers(true)}
            style={{
              padding: '8px 12px',
              borderRadius: 'var(--btn-radius)',
              backgroundColor: 'var(--bg-secondary)',
              border: '1px solid var(--border-card)',
              color: 'var(--text-primary)',
              fontSize: '12px',
              cursor: 'pointer',
              display: 'flex',
              alignItems: 'center',
              gap: '4px',
            }}
          >
            <RefreshCw size={13} className={refreshing ? 'pulse-badge' : ''} />
            <span>Sync</span>
          </button>
        </div>

        {/* Viewers Detail Table */}
        <div style={{ border: '1px solid var(--border-subtle)', borderRadius: 'var(--input-radius)', overflow: 'hidden' }}>
          {loading && viewers.length === 0 ? (
            <div style={{ padding: '36px', textAlign: 'center', color: 'var(--text-secondary)' }}>
              Loading viewers data...
            </div>
          ) : filteredViewers.length === 0 ? (
            <div style={{ padding: '36px', textAlign: 'center', color: 'var(--text-tertiary)' }}>
              No viewers match current filter criteria.
            </div>
          ) : (
            <div style={{ maxHeight: '380px', overflowY: 'auto' }}>
              <table style={{ width: '100%', borderCollapse: 'collapse', textAlign: 'left', fontSize: '13px' }}>
                <thead>
                  <tr style={{ borderBottom: '1px solid var(--border-subtle)', color: 'var(--text-tertiary)', backgroundColor: 'var(--bg-tertiary)' }}>
                    <th style={{ padding: '12px 14px', fontWeight: '600' }}>User</th>
                    <th style={{ padding: '12px 14px', fontWeight: '600' }}>Live State</th>
                    <th style={{ padding: '12px 14px', fontWeight: '600' }}>Watched Duration</th>
                    <th style={{ padding: '12px 14px', fontWeight: '600' }}>Playback Position</th>
                    <th style={{ padding: '12px 14px', fontWeight: '600' }}>Coins Earned</th>
                    <th style={{ padding: '12px 14px', fontWeight: '600' }}>Last Active</th>
                  </tr>
                </thead>
                <tbody>
                  {filteredViewers.map((v) => (
                    <tr
                      key={v.session_id}
                      style={{
                        borderBottom: '1px solid var(--border-subtle)',
                        color: 'var(--text-primary)',
                      }}
                    >
                      <td style={{ padding: '12px 14px' }}>
                        <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                          <div
                            style={{
                              width: '28px',
                              height: '28px',
                              borderRadius: '50%',
                              backgroundColor: 'var(--primary-light)',
                              color: 'var(--primary)',
                              display: 'flex',
                              alignItems: 'center',
                              justifyContent: 'center',
                              fontWeight: '700',
                              fontSize: '12px',
                            }}
                          >
                            {v.username?.[0]?.toUpperCase() || 'U'}
                          </div>
                          <div>
                            <div style={{ fontWeight: '700' }}>{v.username}</div>
                            <div style={{ fontSize: '11px', color: 'var(--text-tertiary)' }}>{v.email}</div>
                          </div>
                        </div>
                      </td>

                      <td style={{ padding: '12px 14px' }}>
                        {v.is_live ? (
                          <Badge variant="rose">🔴 Watching Live</Badge>
                        ) : v.is_completed ? (
                          <Badge variant="emerald">✓ Completed</Badge>
                        ) : (
                          <Badge variant="amber">⏸ Not Watching</Badge>
                        )}
                      </td>

                      <td style={{ padding: '12px 14px' }}>
                        <span style={{ fontFamily: 'var(--font-mono)', fontWeight: '700', color: 'var(--primary)' }}>
                          {formatWatchDuration(v.total_watched_seconds, timeUnit)}
                        </span>
                      </td>

                      <td style={{ padding: '12px 14px' }}>
                        <span style={{ fontFamily: 'var(--font-mono)', color: 'var(--text-secondary)' }}>
                          {formatWatchDuration(v.current_position_seconds, timeUnit)}
                        </span>
                      </td>

                      <td style={{ padding: '12px 14px' }}>
                        <span style={{ fontFamily: 'var(--font-mono)', fontWeight: '700', color: 'var(--accent-amber)' }}>
                          💰 +{v.coins_earned}
                        </span>
                      </td>

                      <td style={{ padding: '12px 14px', color: 'var(--text-tertiary)', fontSize: '12px' }}>
                        {new Date(v.last_watched_at).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit', second: '2-digit' })}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </div>
      </div>
    </Modal>
  );
}
