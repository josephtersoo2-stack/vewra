import React, { useEffect, useState } from 'react';
import {
  Users,
  Search,
  Coins,
  ShieldCheck,
  UserCheck,
  UserX,
  AlertCircle,
  PlusCircle,
  MinusCircle,
  CheckCircle2,
  Timer,
  ArrowUpDown,
} from 'lucide-react';
import { adminApi } from '../api/adminApi';
import { Badge } from '../components/ui/Badge';
import { Modal } from '../components/ui/Modal';
import { formatWatchDuration } from '../utils/timeFormat';

export function UsersPage() {
  const [users, setUsers] = useState([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState('');
  const [timeUnit, setTimeUnit] = useState('minutes'); // 'seconds', 'minutes', 'hours'
  const [sortBy, setSortBy] = useState('watch_time_desc'); // 'watch_time_desc', 'balance_desc', 'sessions_desc', 'joined_desc'

  // Balance Adjustment Modal
  const [selectedUser, setSelectedUser] = useState(null);
  const [adjustmentAction, setAdjustmentAction] = useState('add'); // 'add' or 'deduct'
  const [adjustmentAmount, setAdjustmentAmount] = useState('');
  const [adjustmentReason, setAdjustmentReason] = useState('');
  const [adjusting, setAdjusting] = useState(false);
  const [adjustError, setAdjustError] = useState('');

  const loadUsers = async () => {
    try {
      const data = await adminApi.getUsers({ search });
      setUsers(data);
    } catch (err) {
      console.error('Failed to load users', err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadUsers();
  }, [search]);

  const handleOpenAdjust = (user, actionType) => {
    setSelectedUser(user);
    setAdjustmentAction(actionType);
    setAdjustmentAmount('');
    setAdjustmentReason('');
    setAdjustError('');
  };

  const handleSaveAdjustment = async (e) => {
    e.preventDefault();
    if (!adjustmentAmount || !adjustmentReason) return;
    setAdjusting(true);
    setAdjustError('');
    try {
      await adminApi.adjustUserBalance(selectedUser.id, {
        amount: Number(adjustmentAmount),
        action: adjustmentAction,
        reason: adjustmentReason,
      });
      setSelectedUser(null);
      loadUsers();
    } catch (err) {
      setAdjustError(err.response?.data?.error || err.message || 'Failed to adjust balance');
    } finally {
      setAdjusting(false);
    }
  };

  const handleToggleStatus = async (user) => {
    if (!window.confirm(`Are you sure you want to ${user.is_active ? 'deactivate/ban' : 'activate'} user ${user.username}?`)) return;
    try {
      await adminApi.toggleUserStatus(user.id);
      loadUsers();
    } catch (err) {
      alert('Failed to toggle status: ' + err.message);
    }
  };

  const filteredUsers = users
    .filter((u) => {
      const q = search.toLowerCase();
      return (
        (u.username || '').toLowerCase().includes(q) ||
        (u.email || '').toLowerCase().includes(q)
      );
    })
    .sort((a, b) => {
      if (sortBy === 'watch_time_desc') {
        return (Number(b.total_watch_seconds) || 0) - (Number(a.total_watch_seconds) || 0);
      }
      if (sortBy === 'balance_desc') {
        return (Number(b.wallet_balance) || 0) - (Number(a.wallet_balance) || 0);
      }
      if (sortBy === 'sessions_desc') {
        return (Number(b.total_sessions) || 0) - (Number(a.total_sessions) || 0);
      }
      if (sortBy === 'joined_desc') {
        return new Date(b.date_joined) - new Date(a.date_joined);
      }
      return 0;
    });

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: '28px' }}>
      {/* Header */}
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', flexWrap: 'wrap', gap: '16px' }}>
        <div>
          <h1 style={{ fontSize: '26px', fontWeight: '800', color: 'var(--text-primary)' }}>
            Users & Watch Durations
          </h1>
          <p style={{ fontSize: '14px', color: 'var(--text-secondary)', marginTop: '4px' }}>
            Monitor member total watch durations, grant/deduct wallet coins, and manage permissions
          </p>
        </div>
      </div>

      {/* Filter & Controls Bar */}
      <div className="card" style={{ padding: '16px' }}>
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', gap: '16px', flexWrap: 'wrap' }}>
          {/* Search Input */}
          <div style={{ position: 'relative', flex: 1, minWidth: '240px' }}>
            <Search size={18} style={{ position: 'absolute', left: '14px', top: '50%', transform: 'translateY(-50%)', color: 'var(--text-tertiary)' }} />
            <input
              type="text"
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              placeholder="Search by username, email..."
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

          {/* Sort Selector */}
          <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
            <span style={{ fontSize: '12px', fontWeight: '600', color: 'var(--text-tertiary)' }}>
              Sort:
            </span>
            <select
              value={sortBy}
              onChange={(e) => setSortBy(e.target.value)}
              style={{
                padding: '8px 12px',
                borderRadius: 'var(--btn-radius)',
                backgroundColor: 'var(--bg-tertiary)',
                border: '1px solid var(--border-card)',
                color: 'var(--text-primary)',
                fontSize: '13px',
                fontWeight: '600',
              }}
            >
              <option value="watch_time_desc">Highest Watch Time</option>
              <option value="balance_desc">Highest Balance</option>
              <option value="sessions_desc">Most Sessions</option>
              <option value="joined_desc">Newest Joined</option>
            </select>
          </div>

          <Badge variant="indigo" size="md">
            {filteredUsers.length} Users
          </Badge>
        </div>
      </div>

      {/* Users Table */}
      <div className="card" style={{ padding: '0', overflow: 'hidden' }}>
        {loading ? (
          <div style={{ padding: '48px', textAlign: 'center', color: 'var(--text-secondary)' }}>
            Loading users list...
          </div>
        ) : filteredUsers.length === 0 ? (
          <div style={{ padding: '48px', textAlign: 'center', color: 'var(--text-tertiary)' }}>
            No users found matching search query.
          </div>
        ) : (
          <div style={{ overflowX: 'auto' }}>
            <table style={{ width: '100%', borderCollapse: 'collapse', textAlign: 'left', fontSize: '13px' }}>
              <thead>
                <tr style={{ borderBottom: '1px solid var(--border-subtle)', color: 'var(--text-tertiary)', backgroundColor: 'var(--bg-tertiary)' }}>
                  <th style={{ padding: '14px 18px', fontWeight: '600' }}>User</th>
                  <th style={{ padding: '14px 18px', fontWeight: '600' }}>Role</th>
                  <th style={{ padding: '14px 18px', fontWeight: '600' }}>
                    <div style={{ display: 'flex', alignItems: 'center', gap: '4px' }}>
                      <Timer size={14} style={{ color: 'var(--primary)' }} />
                      <span>Total Watched ({timeUnit === 'hours' ? 'hrs' : timeUnit === 'minutes' ? 'mins' : 's'})</span>
                    </div>
                  </th>
                  <th style={{ padding: '14px 18px', fontWeight: '600' }}>Wallet Balance</th>
                  <th style={{ padding: '14px 18px', fontWeight: '600' }}>Tasks Watched</th>
                  <th style={{ padding: '14px 18px', fontWeight: '600' }}>Status</th>
                  <th style={{ padding: '14px 18px', fontWeight: '600' }}>Joined</th>
                  <th style={{ padding: '14px 18px', fontWeight: '600', textAlign: 'right' }}>Actions</th>
                </tr>
              </thead>
              <tbody>
                {filteredUsers.map((u) => (
                  <tr
                    key={u.id}
                    style={{
                      borderBottom: '1px solid var(--border-subtle)',
                      color: 'var(--text-primary)',
                    }}
                  >
                    <td style={{ padding: '16px 18px' }}>
                      <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
                        <div
                          style={{
                            width: '34px',
                            height: '34px',
                            borderRadius: '50%',
                            backgroundColor: 'var(--primary-light)',
                            color: 'var(--primary)',
                            display: 'flex',
                            alignItems: 'center',
                            justifyContent: 'center',
                            fontWeight: '700',
                          }}
                        >
                          {u.username?.[0]?.toUpperCase() || 'U'}
                        </div>
                        <div>
                          <div style={{ fontWeight: '700', color: 'var(--text-primary)' }}>
                            {u.username}
                          </div>
                          <div style={{ fontSize: '11px', color: 'var(--text-tertiary)' }}>
                            {u.email || 'No email set'}
                          </div>
                        </div>
                      </div>
                    </td>

                    <td style={{ padding: '16px 18px' }}>
                      {u.is_superuser ? (
                        <Badge variant="indigo">Superuser</Badge>
                      ) : u.is_staff ? (
                        <Badge variant="indigo">Staff</Badge>
                      ) : (
                        <Badge variant="default">Viewer</Badge>
                      )}
                    </td>

                    {/* Total Watched per user */}
                    <td style={{ padding: '16px 18px' }}>
                      <span
                        style={{
                          fontFamily: 'var(--font-mono)',
                          fontWeight: '700',
                          color: Number(u.total_watch_seconds) > 0 ? 'var(--primary)' : 'var(--text-tertiary)',
                          fontSize: '14px',
                        }}
                      >
                        {formatWatchDuration(u.total_watch_seconds || 0, timeUnit)}
                      </span>
                    </td>

                    <td style={{ padding: '16px 18px' }}>
                      <span style={{ fontFamily: 'var(--font-mono)', fontWeight: '700', color: 'var(--accent-amber)', fontSize: '14px' }}>
                        💰 {u.wallet_balance}
                      </span>
                    </td>

                    <td style={{ padding: '16px 18px', fontWeight: '600' }}>
                      {u.total_sessions} sessions
                    </td>

                    <td style={{ padding: '16px 18px' }}>
                      {u.is_active ? (
                        <Badge variant="emerald">Active</Badge>
                      ) : (
                        <Badge variant="rose">Banned</Badge>
                      )}
                    </td>

                    <td style={{ padding: '16px 18px', color: 'var(--text-tertiary)' }}>
                      {new Date(u.date_joined).toLocaleDateString()}
                    </td>

                    <td style={{ padding: '16px 18px', textAlign: 'right' }}>
                      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'flex-end', gap: '8px' }}>
                        <button
                          onClick={() => handleOpenAdjust(u, 'add')}
                          style={{
                            padding: '6px 10px',
                            borderRadius: 'var(--btn-radius)',
                            backgroundColor: 'var(--bg-tertiary)',
                            border: '1px solid var(--border-card)',
                            color: 'var(--accent-emerald)',
                            fontSize: '12px',
                            fontWeight: '600',
                            cursor: 'pointer',
                            display: 'flex',
                            alignItems: 'center',
                            gap: '4px',
                          }}
                          title="Grant Coins"
                        >
                          <PlusCircle size={13} />
                          <span>Grant</span>
                        </button>

                        <button
                          onClick={() => handleOpenAdjust(u, 'deduct')}
                          style={{
                            padding: '6px 10px',
                            borderRadius: 'var(--btn-radius)',
                            backgroundColor: 'var(--bg-tertiary)',
                            border: '1px solid var(--border-card)',
                            color: 'var(--accent-amber)',
                            fontSize: '12px',
                            fontWeight: '600',
                            cursor: 'pointer',
                            display: 'flex',
                            alignItems: 'center',
                            gap: '4px',
                          }}
                          title="Deduct Coins"
                        >
                          <MinusCircle size={13} />
                          <span>Deduct</span>
                        </button>

                        <button
                          onClick={() => handleToggleStatus(u)}
                          style={{
                            padding: '6px 10px',
                            borderRadius: 'var(--btn-radius)',
                            backgroundColor: u.is_active ? 'var(--badge-rose-bg)' : 'var(--badge-emerald-bg)',
                            border: '1px solid var(--border-card)',
                            color: u.is_active ? 'var(--accent-rose)' : 'var(--accent-emerald)',
                            fontSize: '12px',
                            cursor: 'pointer',
                          }}
                          title={u.is_active ? 'Ban User' : 'Activate User'}
                        >
                          {u.is_active ? <UserX size={13} /> : <UserCheck size={13} />}
                        </button>
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>

      {/* Balance Adjustment Modal */}
      <Modal
        isOpen={!!selectedUser}
        onClose={() => setSelectedUser(null)}
        title={`${adjustmentAction === 'add' ? 'Grant Coins to' : 'Deduct Coins from'} ${selectedUser?.username}`}
        maxWidth="500px"
      >
        <form onSubmit={handleSaveAdjustment} style={{ display: 'flex', flexDirection: 'column', gap: '16px' }}>
          {adjustError && (
            <div
              style={{
                padding: '10px 14px',
                borderRadius: 'var(--btn-radius)',
                backgroundColor: 'var(--badge-rose-bg)',
                color: 'var(--badge-rose-text)',
                fontSize: '13px',
                display: 'flex',
                alignItems: 'center',
                gap: '8px',
              }}
            >
              <AlertCircle size={16} />
              <span>{adjustError}</span>
            </div>
          )}

          <div>
            <label style={{ fontSize: '13px', fontWeight: '600', color: 'var(--text-secondary)', display: 'block', marginBottom: '6px' }}>
              Coin Amount
            </label>
            <input
              type="number"
              step="0.01"
              min="0.01"
              required
              value={adjustmentAmount}
              onChange={(e) => setAdjustmentAmount(e.target.value)}
              placeholder="e.g. 50"
              style={{
                width: '100%',
                padding: '10px 14px',
                borderRadius: 'var(--input-radius)',
                backgroundColor: 'var(--bg-tertiary)',
                border: '1px solid var(--border-card)',
                color: 'var(--text-primary)',
                fontSize: '14px',
              }}
            />
          </div>

          <div>
            <label style={{ fontSize: '13px', fontWeight: '600', color: 'var(--text-secondary)', display: 'block', marginBottom: '6px' }}>
              Mandatory Audit Reason
            </label>
            <input
              type="text"
              required
              value={adjustmentReason}
              onChange={(e) => setAdjustmentReason(e.target.value)}
              placeholder="e.g. Compensation for watch glitch"
              style={{
                width: '100%',
                padding: '10px 14px',
                borderRadius: 'var(--input-radius)',
                backgroundColor: 'var(--bg-tertiary)',
                border: '1px solid var(--border-card)',
                color: 'var(--text-primary)',
                fontSize: '14px',
              }}
            />
          </div>

          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'flex-end', gap: '10px', marginTop: '10px' }}>
            <button
              type="button"
              onClick={() => setSelectedUser(null)}
              style={{
                padding: '8px 16px',
                borderRadius: 'var(--btn-radius)',
                backgroundColor: 'transparent',
                border: '1px solid var(--border-card)',
                color: 'var(--text-secondary)',
                fontSize: '13px',
                cursor: 'pointer',
              }}
            >
              Cancel
            </button>
            <button
              type="submit"
              disabled={adjusting}
              style={{
                padding: '8px 20px',
                borderRadius: 'var(--btn-radius)',
                backgroundColor: adjustmentAction === 'add' ? 'var(--accent-emerald)' : 'var(--accent-rose)',
                color: '#FFFFFF',
                border: 'none',
                fontSize: '13px',
                fontWeight: '700',
                cursor: adjusting ? 'not-allowed' : 'pointer',
              }}
            >
              {adjusting ? 'Processing...' : adjustmentAction === 'add' ? 'Confirm Grant' : 'Confirm Deduct'}
            </button>
          </div>
        </form>
      </Modal>
    </div>
  );
}
