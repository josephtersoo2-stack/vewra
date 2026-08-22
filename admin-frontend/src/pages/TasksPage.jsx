import React, { useEffect, useState } from 'react';
import {
  Plus,
  Search,
  Video,
  Edit2,
  Trash2,
  RefreshCw,
  Sparkles,
  ExternalLink,
  CheckCircle2,
  XCircle,
  Eye,
  Timer,
} from 'lucide-react';
import { adminApi } from '../api/adminApi';
import { TaskModal } from './TaskModal';
import { Badge } from '../components/ui/Badge';
import { useTheme } from '../theme/ThemeContext';
import { formatWatchDuration } from '../utils/timeFormat';

export function TasksPage() {
  const [tasks, setTasks] = useState([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState('');
  const [timeUnit, setTimeUnit] = useState('minutes'); // 'seconds', 'minutes', 'hours'
  const [selectedTask, setSelectedTask] = useState(null);
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [regeneratingId, setRegeneratingId] = useState(null);

  const loadTasks = async () => {
    try {
      const data = await adminApi.getVideoTasks();
      setTasks(data);
    } catch (err) {
      console.error('Failed to load video tasks', err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadTasks();
  }, []);

  const handleOpenCreate = () => {
    setSelectedTask(null);
    setIsModalOpen(true);
  };

  const handleOpenEdit = (task) => {
    setSelectedTask(task);
    setIsModalOpen(true);
  };

  const handleDelete = async (task) => {
    if (!window.confirm(`Are you sure you want to delete task "${task.title}"?`)) return;
    try {
      await adminApi.deleteVideoTask(task.id);
      loadTasks();
    } catch (err) {
      alert('Failed to delete task: ' + err.message);
    }
  };

  const handleToggleActive = async (task) => {
    try {
      await adminApi.updateVideoTask(task.id, { is_active: !task.is_active });
      loadTasks();
    } catch (err) {
      alert('Failed to update task: ' + err.message);
    }
  };

  const handleQuickRegenerate = async (task) => {
    setRegeneratingId(task.id);
    try {
      const res = await adminApi.regenerateKeywords(task.id);
      alert(res.message || 'Keywords refreshed!');
      loadTasks();
    } catch (err) {
      alert('Failed to regenerate keywords: ' + err.message);
    } finally {
      setRegeneratingId(null);
    }
  };

  const filteredTasks = tasks.filter((t) => {
    const q = search.toLowerCase();
    return (
      (t.title || '').toLowerCase().includes(q) ||
      (t.video_id || '').toLowerCase().includes(q)
    );
  });

  const formatReward = (task) => {
    const cfg = task.reward_config || {};
    if (task.reward_type === 'per_time') {
      return `+${cfg.coins || 10} coins / ${cfg.seconds || 60}s`;
    } else if (task.reward_type === 'watch_all') {
      return `+${cfg.coins || 150} coins (Full Watch)`;
    } else if (task.reward_type === 'target') {
      return `+${cfg.coins || 100} coins (${cfg.target_seconds || 300}s)`;
    }
    return 'Reward';
  };

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: '28px' }}>
      {/* Header & Create Button */}
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', flexWrap: 'wrap', gap: '16px' }}>
        <div>
          <h1 style={{ fontSize: '26px', fontWeight: '800', color: 'var(--text-primary)' }}>
            Video Tasks & Watch Times
          </h1>
          <p style={{ fontSize: '14px', color: 'var(--text-secondary)', marginTop: '4px' }}>
            Configure active video watching tasks, inspect cumulative view durations, and manage AI keyword pools
          </p>
        </div>

        <button
          onClick={handleOpenCreate}
          style={{
            display: 'flex',
            alignItems: 'center',
            gap: '8px',
            padding: '10px 20px',
            borderRadius: 'var(--btn-radius)',
            backgroundColor: 'var(--primary)',
            color: '#FFFFFF',
            border: 'none',
            fontSize: '14px',
            fontWeight: '700',
            cursor: 'pointer',
            boxShadow: '0 4px 12px var(--primary-glow)',
          }}
        >
          <Plus size={18} />
          <span>Add New Video Task</span>
        </button>
      </div>

      {/* Filter, Search & Time Unit Bar */}
      <div className="card" style={{ padding: '16px' }}>
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', gap: '16px', flexWrap: 'wrap' }}>
          <div style={{ position: 'relative', flex: 1, minWidth: '240px' }}>
            <Search size={18} style={{ position: 'absolute', left: '14px', top: '50%', transform: 'translateY(-50%)', color: 'var(--text-tertiary)' }} />
            <input
              type="text"
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              placeholder="Search tasks by title, video ID..."
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

          <Badge variant="indigo" size="md">
            {filteredTasks.length} Tasks Listed
          </Badge>
        </div>
      </div>

      {/* Tasks Table */}
      <div className="card" style={{ padding: '0', overflow: 'hidden' }}>
        {loading ? (
          <div style={{ padding: '48px', textAlign: 'center', color: 'var(--text-secondary)' }}>
            Loading tasks catalog...
          </div>
        ) : filteredTasks.length === 0 ? (
          <div style={{ padding: '48px', textAlign: 'center', color: 'var(--text-tertiary)' }}>
            No video tasks found. Click "Add New Video Task" to create one.
          </div>
        ) : (
          <div style={{ overflowX: 'auto' }}>
            <table style={{ width: '100%', borderCollapse: 'collapse', textAlign: 'left', fontSize: '13px' }}>
              <thead>
                <tr style={{ borderBottom: '1px solid var(--border-subtle)', color: 'var(--text-tertiary)', backgroundColor: 'var(--bg-tertiary)' }}>
                  <th style={{ padding: '14px 18px', fontWeight: '600' }}>Video</th>
                  <th style={{ padding: '14px 18px', fontWeight: '600' }}>Reward Model</th>
                  <th style={{ padding: '14px 18px', fontWeight: '600' }}>
                    <div style={{ display: 'flex', alignItems: 'center', gap: '4px' }}>
                      <Timer size={14} style={{ color: 'var(--primary)' }} />
                      <span>Total Watched ({timeUnit === 'hours' ? 'hrs' : timeUnit === 'minutes' ? 'mins' : 's'})</span>
                    </div>
                  </th>
                  <th style={{ padding: '14px 18px', fontWeight: '600' }}>Saved Keywords Pool</th>
                  <th style={{ padding: '14px 18px', fontWeight: '600' }}>Sessions</th>
                  <th style={{ padding: '14px 18px', fontWeight: '600' }}>Status</th>
                  <th style={{ padding: '14px 18px', fontWeight: '600', textAlign: 'right' }}>Actions</th>
                </tr>
              </thead>
              <tbody>
                {filteredTasks.map((t) => {
                  const kwList = Array.isArray(t.keywords) ? t.keywords : [];
                  return (
                    <tr
                      key={t.id}
                      style={{
                        borderBottom: '1px solid var(--border-subtle)',
                        color: 'var(--text-primary)',
                      }}
                    >
                      {/* Video info + Thumbnail */}
                      <td style={{ padding: '16px 18px' }}>
                        <div style={{ display: 'flex', alignItems: 'center', gap: '14px' }}>
                          <img
                            src={t.thumbnail_url || `https://img.youtube.com/vi/${t.video_id}/hqdefault.jpg`}
                            alt={t.title}
                            style={{
                              width: '72px',
                              height: '46px',
                              borderRadius: '6px',
                              objectFit: 'cover',
                              border: '1px solid var(--border-subtle)',
                            }}
                          />
                          <div style={{ maxWidth: '300px' }}>
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

                      {/* Reward Badge */}
                      <td style={{ padding: '16px 18px' }}>
                        <Badge variant="amber" size="md">
                          💰 {formatReward(t)}
                        </Badge>
                      </td>

                      {/* Total Watched per Task */}
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

                      {/* Keyword pool chips */}
                      <td style={{ padding: '16px 18px', maxWidth: '260px' }}>
                        <div style={{ display: 'flex', flexWrap: 'wrap', gap: '4px' }}>
                          {kwList.slice(0, 3).map((kw, i) => (
                            <span
                              key={i}
                              style={{
                                fontSize: '11px',
                                padding: '2px 8px',
                                borderRadius: '12px',
                                backgroundColor: 'var(--bg-tertiary)',
                                color: 'var(--text-secondary)',
                                border: '1px solid var(--border-subtle)',
                                whiteSpace: 'nowrap',
                              }}
                            >
                              {kw}
                            </span>
                          ))}
                          {kwList.length > 3 && (
                            <Badge variant="indigo" size="xs">
                              +{kwList.length - 3} more
                            </Badge>
                          )}
                          {kwList.length === 0 && (
                            <span style={{ fontSize: '12px', color: 'var(--text-tertiary)' }}>
                              No keywords
                            </span>
                          )}
                        </div>
                      </td>

                      {/* Sessions count */}
                      <td style={{ padding: '16px 18px', fontWeight: '600' }}>
                        {t.sessions_count || 0}
                      </td>

                      {/* Active Status */}
                      <td style={{ padding: '16px 18px' }}>
                        <button
                          onClick={() => handleToggleActive(t)}
                          style={{
                            background: 'transparent',
                            border: 'none',
                            cursor: 'pointer',
                          }}
                        >
                          {t.is_active ? (
                            <Badge variant="emerald">Active</Badge>
                          ) : (
                            <Badge variant="rose">Inactive</Badge>
                          )}
                        </button>
                      </td>

                      {/* Actions */}
                      <td style={{ padding: '16px 18px', textAlign: 'right' }}>
                        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'flex-end', gap: '8px' }}>
                          <button
                            onClick={() => handleQuickRegenerate(t)}
                            disabled={regeneratingId === t.id}
                            style={{
                              padding: '6px 10px',
                              borderRadius: 'var(--btn-radius)',
                              backgroundColor: 'var(--bg-tertiary)',
                              border: '1px solid var(--border-card)',
                              color: 'var(--primary)',
                              fontSize: '12px',
                              fontWeight: '600',
                              cursor: regeneratingId === t.id ? 'not-allowed' : 'pointer',
                              display: 'flex',
                              alignItems: 'center',
                              gap: '4px',
                            }}
                            title="Regenerate AI Keyword Pool"
                          >
                            <Sparkles size={13} className={regeneratingId === t.id ? 'pulse-badge' : ''} />
                            <span>AI Pool</span>
                          </button>

                          <button
                            onClick={() => handleOpenEdit(t)}
                            style={{
                              padding: '6px 10px',
                              borderRadius: 'var(--btn-radius)',
                              backgroundColor: 'var(--bg-tertiary)',
                              border: '1px solid var(--border-card)',
                              color: 'var(--text-primary)',
                              fontSize: '12px',
                              cursor: 'pointer',
                              display: 'flex',
                              alignItems: 'center',
                            }}
                            title="Edit Task"
                          >
                            <Edit2 size={14} />
                          </button>

                          <button
                            onClick={() => handleDelete(t)}
                            style={{
                              padding: '6px 10px',
                              borderRadius: 'var(--btn-radius)',
                              backgroundColor: 'var(--badge-rose-bg)',
                              border: '1px solid rgba(244, 63, 94, 0.3)',
                              color: 'var(--accent-rose)',
                              fontSize: '12px',
                              cursor: 'pointer',
                              display: 'flex',
                              alignItems: 'center',
                            }}
                            title="Delete Task"
                          >
                            <Trash2 size={14} />
                          </button>
                        </div>
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>
        )}
      </div>

      {/* Task Creation & Editing Modal */}
      <TaskModal
        isOpen={isModalOpen}
        onClose={() => setIsModalOpen(false)}
        task={selectedTask}
        onSaved={loadTasks}
      />
    </div>
  );
}
