import React, { useEffect, useState } from 'react';
import {
  ShieldAlert,
  KeyRound,
  Ban,
  Clock,
  CheckCircle2,
  RefreshCw,
  AlertTriangle,
} from 'lucide-react';
import { adminApi } from '../api/adminApi';
import { Badge } from '../components/ui/Badge';

export function SecurityPage() {
  const [tokensData, setTokensData] = useState({ outstanding_tokens: [], blacklisted_tokens: [] });
  const [loading, setLoading] = useState(true);
  const [revokingId, setRevokingId] = useState(null);

  const loadTokens = async () => {
    try {
      const data = await adminApi.getTokens();
      setTokensData(data);
    } catch (err) {
      console.error('Failed to load tokens', err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadTokens();
  }, []);

  const handleRevokeToken = async (tokenId) => {
    if (!window.confirm('Are you sure you want to revoke and blacklist this session token? The user will be immediately logged out.')) return;
    setRevokingId(tokenId);
    try {
      await adminApi.blacklistToken(tokenId);
      alert('Token revoked and blacklisted.');
      loadTokens();
    } catch (err) {
      alert('Failed to revoke token: ' + err.message);
    } finally {
      setRevokingId(null);
    }
  };

  const outstanding = tokensData.outstanding_tokens || [];
  const blacklisted = tokensData.blacklisted_tokens || [];

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: '28px' }}>
      {/* Header */}
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', flexWrap: 'wrap', gap: '16px' }}>
        <div>
          <h1 style={{ fontSize: '26px', fontWeight: '800', color: 'var(--text-primary)' }}>
            Security & Token Blacklist
          </h1>
          <p style={{ fontSize: '14px', color: 'var(--text-secondary)', marginTop: '4px' }}>
            Manage active JWT authentication sessions and revoke compromised or suspect tokens
          </p>
        </div>

        <button
          onClick={loadTokens}
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
          <RefreshCw size={14} />
          <span>Refresh</span>
        </button>
      </div>

      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(460px, 1fr))', gap: '24px' }}>
        {/* Outstanding Active Tokens */}
        <div className="card" style={{ padding: '0', overflow: 'hidden' }}>
          <div style={{ padding: '20px', borderBottom: '1px solid var(--border-subtle)', display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
              <KeyRound size={20} style={{ color: 'var(--primary)' }} />
              <h3 style={{ fontSize: '17px', fontWeight: '700', color: 'var(--text-primary)' }}>
                Active Outstanding Tokens
              </h3>
            </div>
            <Badge variant="indigo">{outstanding.length} Active</Badge>
          </div>

          <div style={{ maxHeight: '420px', overflowY: 'auto' }}>
            {outstanding.length === 0 ? (
              <p style={{ padding: '32px', textAlign: 'center', color: 'var(--text-tertiary)', fontSize: '13px' }}>
                No active outstanding tokens found.
              </p>
            ) : (
              <table style={{ width: '100%', borderCollapse: 'collapse', textAlign: 'left', fontSize: '12px' }}>
                <thead>
                  <tr style={{ borderBottom: '1px solid var(--border-subtle)', color: 'var(--text-tertiary)', backgroundColor: 'var(--bg-tertiary)' }}>
                    <th style={{ padding: '10px 14px', fontWeight: '600' }}>User</th>
                    <th style={{ padding: '10px 14px', fontWeight: '600' }}>Token JTI</th>
                    <th style={{ padding: '10px 14px', fontWeight: '600' }}>Expires</th>
                    <th style={{ padding: '10px 14px', fontWeight: '600', textAlign: 'right' }}>Action</th>
                  </tr>
                </thead>
                <tbody>
                  {outstanding.map((t) => (
                    <tr key={t.id} style={{ borderBottom: '1px solid var(--border-subtle)' }}>
                      <td style={{ padding: '12px 14px', fontWeight: '700' }}>{t.username}</td>
                      <td style={{ padding: '12px 14px', fontFamily: 'var(--font-mono)', color: 'var(--text-tertiary)' }}>
                        {t.jti.substring(0, 10)}...
                      </td>
                      <td style={{ padding: '12px 14px', color: 'var(--text-secondary)' }}>
                        {new Date(t.expires_at).toLocaleDateString()}
                      </td>
                      <td style={{ padding: '12px 14px', textAlign: 'right' }}>
                        <button
                          onClick={() => handleRevokeToken(t.id)}
                          disabled={revokingId === t.id}
                          style={{
                            padding: '4px 8px',
                            borderRadius: 'var(--btn-radius)',
                            backgroundColor: 'var(--badge-rose-bg)',
                            border: '1px solid rgba(244, 63, 94, 0.3)',
                            color: 'var(--accent-rose)',
                            fontSize: '11px',
                            fontWeight: '600',
                            cursor: revokingId === t.id ? 'not-allowed' : 'pointer',
                          }}
                        >
                          Revoke
                        </button>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            )}
          </div>
        </div>

        {/* Blacklisted Revoked Tokens */}
        <div className="card" style={{ padding: '0', overflow: 'hidden' }}>
          <div style={{ padding: '20px', borderBottom: '1px solid var(--border-subtle)', display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
              <Ban size={20} style={{ color: 'var(--accent-rose)' }} />
              <h3 style={{ fontSize: '17px', fontWeight: '700', color: 'var(--text-primary)' }}>
                Blacklisted / Revoked Tokens
              </h3>
            </div>
            <Badge variant="rose">{blacklisted.length} Revoked</Badge>
          </div>

          <div style={{ maxHeight: '420px', overflowY: 'auto' }}>
            {blacklisted.length === 0 ? (
              <p style={{ padding: '32px', textAlign: 'center', color: 'var(--text-tertiary)', fontSize: '13px' }}>
                No blacklisted tokens recorded yet.
              </p>
            ) : (
              <table style={{ width: '100%', borderCollapse: 'collapse', textAlign: 'left', fontSize: '12px' }}>
                <thead>
                  <tr style={{ borderBottom: '1px solid var(--border-subtle)', color: 'var(--text-tertiary)', backgroundColor: 'var(--bg-tertiary)' }}>
                    <th style={{ padding: '10px 14px', fontWeight: '600' }}>User</th>
                    <th style={{ padding: '10px 14px', fontWeight: '600' }}>Token ID</th>
                    <th style={{ padding: '10px 14px', fontWeight: '600' }}>Revoked At</th>
                  </tr>
                </thead>
                <tbody>
                  {blacklisted.map((b) => (
                    <tr key={b.id} style={{ borderBottom: '1px solid var(--border-subtle)' }}>
                      <td style={{ padding: '12px 14px', fontWeight: '700' }}>{b.username}</td>
                      <td style={{ padding: '12px 14px', fontFamily: 'var(--font-mono)', color: 'var(--text-tertiary)' }}>
                        #{b.token_id}
                      </td>
                      <td style={{ padding: '12px 14px', color: 'var(--accent-rose)' }}>
                        {new Date(b.blacklisted_at).toLocaleString()}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            )}
          </div>
        </div>
      </div>
    </div>
  );
}
