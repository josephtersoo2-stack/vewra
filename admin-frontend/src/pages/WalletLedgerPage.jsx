import React, { useEffect, useState } from 'react';
import {
  Wallet,
  Search,
  ArrowDownLeft,
  ArrowUpRight,
  ShieldCheck,
  Coins,
  FileSpreadsheet,
} from 'lucide-react';
import { adminApi } from '../api/adminApi';
import { Badge } from '../components/ui/Badge';

export function WalletLedgerPage() {
  const [transactions, setTransactions] = useState([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState('');
  const [filterType, setFilterType] = useState('');

  const loadTransactions = async () => {
    try {
      const data = await adminApi.getWalletTransactions({
        search,
        type: filterType || undefined,
      });
      setTransactions(data);
    } catch (err) {
      console.error('Failed to load wallet transactions', err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadTransactions();
  }, [search, filterType]);

  const filtered = transactions.filter((tx) => {
    const q = search.toLowerCase();
    return (
      (tx.username || '').toLowerCase().includes(q) ||
      (tx.description || '').toLowerCase().includes(q) ||
      (tx.reference_id || '').toLowerCase().includes(q)
    );
  });

  const getTxTypeBadge = (type) => {
    switch (type) {
      case 'watch_reward':
      case 'earned_watch':
        return <Badge variant="emerald">Watch Reward</Badge>;
      case 'admin_credit':
        return <Badge variant="indigo">Admin Grant</Badge>;
      case 'admin_debit':
        return <Badge variant="rose">Admin Deduct</Badge>;
      case 'withdrawal':
        return <Badge variant="amber">Withdrawal</Badge>;
      default:
        return <Badge variant="default">{type}</Badge>;
    }
  };

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: '28px' }}>
      {/* Header */}
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', flexWrap: 'wrap', gap: '16px' }}>
        <div>
          <h1 style={{ fontSize: '26px', fontWeight: '800', color: 'var(--text-primary)' }}>
            Financial Ledger & Transactions
          </h1>
          <p style={{ fontSize: '14px', color: 'var(--text-secondary)', marginTop: '4px' }}>
            Immutable audit record of all coin distributions, grants, deductions, and reward payouts
          </p>
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
              placeholder="Search by username, description, ref ID..."
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

          <select
            value={filterType}
            onChange={(e) => setFilterType(e.target.value)}
            style={{
              padding: '10px 14px',
              borderRadius: 'var(--btn-radius)',
              backgroundColor: 'var(--bg-tertiary)',
              border: '1px solid var(--border-card)',
              color: 'var(--text-primary)',
              fontSize: '13px',
            }}
          >
            <option value="">All Transaction Types</option>
            <option value="watch_reward">Watch Reward</option>
            <option value="admin_credit">Admin Grant</option>
            <option value="admin_debit">Admin Deduct</option>
            <option value="withdrawal">Withdrawal</option>
          </select>

          <Badge variant="indigo" size="md">
            {filtered.length} Ledger Records
          </Badge>
        </div>
      </div>

      {/* Transactions Table */}
      <div className="card" style={{ padding: '0', overflow: 'hidden' }}>
        {loading ? (
          <div style={{ padding: '48px', textAlign: 'center', color: 'var(--text-secondary)' }}>
            Loading financial ledger...
          </div>
        ) : filtered.length === 0 ? (
          <div style={{ padding: '48px', textAlign: 'center', color: 'var(--text-tertiary)' }}>
            No financial transactions found.
          </div>
        ) : (
          <div style={{ overflowX: 'auto' }}>
            <table style={{ width: '100%', borderCollapse: 'collapse', textAlign: 'left', fontSize: '13px' }}>
              <thead>
                <tr style={{ borderBottom: '1px solid var(--border-subtle)', color: 'var(--text-tertiary)', backgroundColor: 'var(--bg-tertiary)' }}>
                  <th style={{ padding: '14px 18px', fontWeight: '600' }}>User</th>
                  <th style={{ padding: '14px 18px', fontWeight: '600' }}>Type</th>
                  <th style={{ padding: '14px 18px', fontWeight: '600' }}>Amount</th>
                  <th style={{ padding: '14px 18px', fontWeight: '600' }}>Balance After</th>
                  <th style={{ padding: '14px 18px', fontWeight: '600' }}>Description & Audit Reference</th>
                  <th style={{ padding: '14px 18px', fontWeight: '600' }}>Date & Time</th>
                </tr>
              </thead>
              <tbody>
                {filtered.map((tx) => {
                  const isPositive = Number(tx.amount) >= 0;
                  return (
                    <tr
                      key={tx.id}
                      style={{
                        borderBottom: '1px solid var(--border-subtle)',
                        color: 'var(--text-primary)',
                      }}
                    >
                      <td style={{ padding: '16px 18px', fontWeight: '700' }}>
                        {tx.username}
                      </td>

                      <td style={{ padding: '16px 18px' }}>
                        {getTxTypeBadge(tx.transaction_type)}
                      </td>

                      <td style={{ padding: '16px 18px' }}>
                        <span
                          style={{
                            fontFamily: 'var(--font-mono)',
                            fontWeight: '700',
                            fontSize: '14px',
                            color: isPositive ? 'var(--accent-emerald)' : 'var(--accent-rose)',
                          }}
                        >
                          {isPositive ? `+${tx.amount}` : tx.amount} coins
                        </span>
                      </td>

                      <td style={{ padding: '16px 18px' }}>
                        <span style={{ fontFamily: 'var(--font-mono)', color: 'var(--text-secondary)' }}>
                          💰 {tx.balance_after}
                        </span>
                      </td>

                      <td style={{ padding: '16px 18px', maxWidth: '300px' }}>
                        <div style={{ color: 'var(--text-primary)' }}>{tx.description}</div>
                        {tx.reference_id && (
                          <div style={{ fontSize: '11px', fontFamily: 'var(--font-mono)', color: 'var(--text-tertiary)', marginTop: '2px' }}>
                            Ref: {tx.reference_id}
                          </div>
                        )}
                      </td>

                      <td style={{ padding: '16px 18px', color: 'var(--text-tertiary)' }}>
                        {new Date(tx.created_at).toLocaleString()}
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>
        )}
      </div>
    </div>
  );
}
