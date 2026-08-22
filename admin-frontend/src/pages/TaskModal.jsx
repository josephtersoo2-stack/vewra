import React, { useState, useEffect } from 'react';
import {
  Sparkles,
  Plus,
  X,
  RefreshCw,
  Video,
  Coins,
  Clock,
  CheckCircle2,
  AlertCircle,
  ExternalLink,
} from 'lucide-react';
import { adminApi } from '../api/adminApi';
import { Modal } from '../components/ui/Modal';
import { Badge } from '../components/ui/Badge';

export function TaskModal({ isOpen, onClose, task, onSaved }) {
  const [youtubeUrl, setYoutubeUrl] = useState('');
  const [videoId, setVideoId] = useState('');
  const [title, setTitle] = useState('');
  const [thumbnailUrl, setThumbnailUrl] = useState('');
  const [rewardType, setRewardType] = useState('per_time');
  const [coins, setCoins] = useState(10);
  const [intervalSeconds, setIntervalSeconds] = useState(60);
  const [durationSeconds, setDurationSeconds] = useState(300);
  const [keywords, setKeywords] = useState([]);
  const [newKeywordInput, setNewKeywordInput] = useState('');
  const [isActive, setIsActive] = useState(true);

  const [loadingMeta, setLoadingMeta] = useState(false);
  const [regeneratingKeywords, setRegeneratingKeywords] = useState(false);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState('');

  useEffect(() => {
    if (task) {
      setYoutubeUrl(task.youtube_url || '');
      setVideoId(task.video_id || '');
      setTitle(task.title || '');
      setThumbnailUrl(task.thumbnail_url || '');
      setRewardType(task.reward_type || 'per_time');
      const cfg = task.reward_config || {};
      setCoins(cfg.coins || 10);
      setIntervalSeconds(cfg.seconds || 60);
      setDurationSeconds(cfg.duration || cfg.target_seconds || 300);
      setKeywords(Array.isArray(task.keywords) ? task.keywords : []);
      setIsActive(task.is_active ?? true);
    } else {
      setYoutubeUrl('');
      setVideoId('');
      setTitle('');
      setThumbnailUrl('');
      setRewardType('per_time');
      setCoins(10);
      setIntervalSeconds(60);
      setDurationSeconds(300);
      setKeywords([]);
      setIsActive(true);
    }
    setError('');
  }, [task, isOpen]);

  const handleFetchMetadata = async () => {
    if (!youtubeUrl) return;
    setLoadingMeta(true);
    setError('');
    try {
      const meta = await adminApi.fetchYouTubeMeta(youtubeUrl);
      if (meta.video_id) setVideoId(meta.video_id);
      if (meta.title) setTitle(meta.title);
      if (meta.thumbnail_url) setThumbnailUrl(meta.thumbnail_url);

      // Auto-generate keywords
      const aiRes = await adminApi.testAISandbox({ youtube_url: youtubeUrl });
      if (aiRes.keywords && aiRes.keywords.length > 0) {
        setKeywords(aiRes.keywords);
      }
    } catch (err) {
      setError(err.response?.data?.error || err.message || 'Failed to auto-fetch video details');
    } finally {
      setLoadingMeta(false);
    }
  };

  const handleRegenerateKeywords = async () => {
    if (!youtubeUrl && !videoId) return;
    setRegeneratingKeywords(true);
    try {
      const aiRes = await adminApi.testAISandbox({
        youtube_url: youtubeUrl || `https://www.youtube.com/watch?v=${videoId}`,
      });
      if (aiRes.keywords && aiRes.keywords.length > 0) {
        setKeywords(aiRes.keywords);
      }
    } catch (err) {
      setError('Failed to regenerate keywords: ' + err.message);
    } finally {
      setRegeneratingKeywords(false);
    }
  };

  const handleAddKeyword = (e) => {
    e.preventDefault();
    const clean = newKeywordInput.trim();
    if (clean && !keywords.includes(clean)) {
      setKeywords([...keywords, clean]);
      setNewKeywordInput('');
    }
  };

  const handleRemoveKeyword = (indexToRemove) => {
    setKeywords(keywords.filter((_, idx) => idx !== indexToRemove));
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    setSaving(true);
    setError('');

    let reward_config = {};
    if (rewardType === 'per_time') {
      reward_config = { coins: Number(coins), seconds: Number(intervalSeconds) };
    } else if (rewardType === 'watch_all') {
      reward_config = { coins: Number(coins), duration: Number(durationSeconds) };
    } else if (rewardType === 'target') {
      reward_config = { coins: Number(coins), target_seconds: Number(durationSeconds) };
    }

    const payload = {
      youtube_url: youtubeUrl,
      video_id: videoId,
      title,
      thumbnail_url: thumbnailUrl,
      reward_type: rewardType,
      reward_config,
      keywords,
      is_active: isActive,
    };

    try {
      if (task) {
        await adminApi.updateVideoTask(task.id, payload);
      } else {
        await adminApi.createVideoTask(payload);
      }
      onSaved();
      onClose();
    } catch (err) {
      setError(err.response?.data?.detail || JSON.stringify(err.response?.data) || err.message);
    } finally {
      setSaving(false);
    }
  };

  return (
    <Modal isOpen={isOpen} onClose={onClose} title={task ? 'Edit Video Task' : 'Create New Video Task'} maxWidth="700px">
      <form onSubmit={handleSubmit} style={{ display: 'flex', flexDirection: 'column', gap: '20px' }}>
        {error && (
          <div
            style={{
              padding: '12px 16px',
              borderRadius: 'var(--btn-radius)',
              backgroundColor: 'var(--badge-rose-bg)',
              color: 'var(--badge-rose-text)',
              fontSize: '13px',
              display: 'flex',
              alignItems: 'center',
              gap: '10px',
            }}
          >
            <AlertCircle size={16} />
            <span>{error}</span>
          </div>
        )}

        {/* YouTube URL & Auto-Fetch Button */}
        <div>
          <label style={{ fontSize: '13px', fontWeight: '600', color: 'var(--text-secondary)', display: 'block', marginBottom: '6px' }}>
            YouTube Video URL
          </label>
          <div style={{ display: 'flex', gap: '10px' }}>
            <input
              type="url"
              required
              value={youtubeUrl}
              onChange={(e) => setYoutubeUrl(e.target.value)}
              placeholder="https://www.youtube.com/watch?v=..."
              style={{
                flex: 1,
                padding: '10px 14px',
                borderRadius: 'var(--input-radius)',
                backgroundColor: 'var(--bg-tertiary)',
                border: '1px solid var(--border-card)',
                color: 'var(--text-primary)',
                fontSize: '13px',
              }}
            />
            <button
              type="button"
              onClick={handleFetchMetadata}
              disabled={loadingMeta || !youtubeUrl}
              style={{
                display: 'flex',
                alignItems: 'center',
                gap: '6px',
                padding: '10px 16px',
                borderRadius: 'var(--btn-radius)',
                backgroundColor: 'var(--primary-light)',
                color: 'var(--primary)',
                border: '1px solid var(--border-active)',
                fontSize: '13px',
                fontWeight: '700',
                cursor: loadingMeta ? 'not-allowed' : 'pointer',
                whiteSpace: 'nowrap',
              }}
            >
              <Sparkles size={14} className={loadingMeta ? 'pulse-badge' : ''} />
              <span>{loadingMeta ? 'Auto Fetching...' : 'Auto-Fetch AI Data'}</span>
            </button>
          </div>
        </div>

        {/* Video Details (Title & Thumbnail Preview) */}
        <div style={{ display: 'grid', gridTemplateColumns: '1fr 120px', gap: '16px' }}>
          <div style={{ display: 'flex', flexDirection: 'column', gap: '12px' }}>
            <div>
              <label style={{ fontSize: '13px', fontWeight: '600', color: 'var(--text-secondary)', display: 'block', marginBottom: '6px' }}>
                Video Title
              </label>
              <input
                type="text"
                required
                value={title}
                onChange={(e) => setTitle(e.target.value)}
                placeholder="Video Title"
                style={{
                  width: '100%',
                  padding: '10px 14px',
                  borderRadius: 'var(--input-radius)',
                  backgroundColor: 'var(--bg-tertiary)',
                  border: '1px solid var(--border-card)',
                  color: 'var(--text-primary)',
                  fontSize: '13px',
                }}
              />
            </div>

            <div>
              <label style={{ fontSize: '13px', fontWeight: '600', color: 'var(--text-secondary)', display: 'block', marginBottom: '6px' }}>
                YouTube Video ID
              </label>
              <input
                type="text"
                required
                value={videoId}
                onChange={(e) => setVideoId(e.target.value)}
                placeholder="dQw4w9WgXcQ"
                style={{
                  width: '100%',
                  padding: '10px 14px',
                  borderRadius: 'var(--input-radius)',
                  backgroundColor: 'var(--bg-tertiary)',
                  border: '1px solid var(--border-card)',
                  color: 'var(--text-primary)',
                  fontSize: '13px',
                  fontFamily: 'var(--font-mono)',
                }}
              />
            </div>
          </div>

          {/* Thumbnail preview */}
          <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center' }}>
            <div
              style={{
                width: '120px',
                height: '80px',
                borderRadius: '8px',
                backgroundColor: 'var(--bg-tertiary)',
                border: '1px solid var(--border-card)',
                backgroundImage: thumbnailUrl ? `url(${thumbnailUrl})` : 'none',
                backgroundSize: 'cover',
                backgroundPosition: 'center',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
              }}
            >
              {!thumbnailUrl && <Video size={24} style={{ color: 'var(--text-tertiary)' }} />}
            </div>
            <span style={{ fontSize: '11px', color: 'var(--text-tertiary)', marginTop: '4px' }}>Preview</span>
          </div>
        </div>

        {/* Reward Model Configuration */}
        <div style={{ padding: '16px', borderRadius: 'var(--input-radius)', backgroundColor: 'var(--bg-tertiary)', border: '1px solid var(--border-card)' }}>
          <h4 style={{ fontSize: '14px', fontWeight: '700', color: 'var(--text-primary)', marginBottom: '12px' }}>
            Reward Configuration
          </h4>

          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(180px, 1fr))', gap: '14px' }}>
            <div>
              <label style={{ fontSize: '12px', fontWeight: '600', color: 'var(--text-secondary)', display: 'block', marginBottom: '4px' }}>
                Reward Type
              </label>
              <select
                value={rewardType}
                onChange={(e) => setRewardType(e.target.value)}
                style={{
                  width: '100%',
                  padding: '8px 12px',
                  borderRadius: 'var(--btn-radius)',
                  backgroundColor: 'var(--bg-card)',
                  border: '1px solid var(--border-card)',
                  color: 'var(--text-primary)',
                  fontSize: '13px',
                }}
              >
                <option value="per_time">Per Time Interval (+Coins / Sec)</option>
                <option value="watch_all">Full Video Watch (+Coins on Completion)</option>
                <option value="target">Target Time (+Coins at Goal)</option>
              </select>
            </div>

            <div>
              <label style={{ fontSize: '12px', fontWeight: '600', color: 'var(--text-secondary)', display: 'block', marginBottom: '4px' }}>
                Coins Awarded
              </label>
              <input
                type="number"
                min="1"
                value={coins}
                onChange={(e) => setCoins(e.target.value)}
                style={{
                  width: '100%',
                  padding: '8px 12px',
                  borderRadius: 'var(--btn-radius)',
                  backgroundColor: 'var(--bg-card)',
                  border: '1px solid var(--border-card)',
                  color: 'var(--text-primary)',
                  fontSize: '13px',
                }}
              />
            </div>

            {rewardType === 'per_time' && (
              <div>
                <label style={{ fontSize: '12px', fontWeight: '600', color: 'var(--text-secondary)', display: 'block', marginBottom: '4px' }}>
                  Interval (Seconds)
                </label>
                <input
                  type="number"
                  min="10"
                  value={intervalSeconds}
                  onChange={(e) => setIntervalSeconds(e.target.value)}
                  style={{
                    width: '100%',
                    padding: '8px 12px',
                    borderRadius: 'var(--btn-radius)',
                    backgroundColor: 'var(--bg-card)',
                    border: '1px solid var(--border-card)',
                    color: 'var(--text-primary)',
                    fontSize: '13px',
                  }}
                />
              </div>
            )}

            {(rewardType === 'watch_all' || rewardType === 'target') && (
              <div>
                <label style={{ fontSize: '12px', fontWeight: '600', color: 'var(--text-secondary)', display: 'block', marginBottom: '4px' }}>
                  Required Duration (Seconds)
                </label>
                <input
                  type="number"
                  min="10"
                  value={durationSeconds}
                  onChange={(e) => setDurationSeconds(e.target.value)}
                  style={{
                    width: '100%',
                    padding: '8px 12px',
                    borderRadius: 'var(--btn-radius)',
                    backgroundColor: 'var(--bg-card)',
                    border: '1px solid var(--border-card)',
                    color: 'var(--text-primary)',
                    fontSize: '13px',
                  }}
                />
              </div>
            )}
          </div>
        </div>

        {/* AI Keyword Tags Pool Manager */}
        <div>
          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: '10px' }}>
            <label style={{ fontSize: '13px', fontWeight: '600', color: 'var(--text-secondary)' }}>
              Saved AI Keyword Search Phrases ({keywords.length})
            </label>
            <button
              type="button"
              onClick={handleRegenerateKeywords}
              disabled={regeneratingKeywords || (!youtubeUrl && !videoId)}
              style={{
                display: 'flex',
                alignItems: 'center',
                gap: '4px',
                background: 'transparent',
                border: 'none',
                color: 'var(--primary)',
                fontSize: '12px',
                fontWeight: '700',
                cursor: regeneratingKeywords ? 'not-allowed' : 'pointer',
              }}
            >
              <RefreshCw size={12} className={regeneratingKeywords ? 'pulse-badge' : ''} />
              <span>{regeneratingKeywords ? 'Regenerating...' : 'Regenerate AI Pool'}</span>
            </button>
          </div>

          {/* Add custom phrase form */}
          <div style={{ display: 'flex', gap: '8px', marginBottom: '12px' }}>
            <input
              type="text"
              value={newKeywordInput}
              onChange={(e) => setNewKeywordInput(e.target.value)}
              placeholder="Type manual keyword search query and press Add..."
              style={{
                flex: 1,
                padding: '8px 12px',
                borderRadius: 'var(--input-radius)',
                backgroundColor: 'var(--bg-tertiary)',
                border: '1px solid var(--border-card)',
                color: 'var(--text-primary)',
                fontSize: '13px',
              }}
            />
            <button
              type="button"
              onClick={handleAddKeyword}
              style={{
                padding: '8px 14px',
                borderRadius: 'var(--btn-radius)',
                backgroundColor: 'var(--bg-secondary)',
                border: '1px solid var(--border-card)',
                color: 'var(--text-primary)',
                fontSize: '12px',
                fontWeight: '600',
                cursor: 'pointer',
              }}
            >
              + Add Phrase
            </button>
          </div>

          {/* Keywords Chips */}
          <div
            style={{
              maxHeight: '130px',
              overflowY: 'auto',
              display: 'flex',
              flexWrap: 'wrap',
              gap: '6px',
              padding: '8px',
              borderRadius: 'var(--input-radius)',
              border: '1px solid var(--border-subtle)',
              backgroundColor: 'var(--bg-tertiary)',
            }}
          >
            {keywords.length === 0 ? (
              <span style={{ fontSize: '12px', color: 'var(--text-tertiary)' }}>
                No keyword search phrases added yet. Click "Auto-Fetch AI Data" or add manually.
              </span>
            ) : (
              keywords.map((kw, i) => (
                <span
                  key={i}
                  style={{
                    display: 'inline-flex',
                    alignItems: 'center',
                    gap: '6px',
                    padding: '4px 10px',
                    borderRadius: '16px',
                    backgroundColor: 'var(--badge-amber-bg)',
                    color: 'var(--badge-amber-text)',
                    fontSize: '12px',
                    fontWeight: '600',
                    border: '1px solid rgba(245, 158, 11, 0.3)',
                  }}
                >
                  🔍 {kw}
                  <X
                    size={13}
                    style={{ cursor: 'pointer', opacity: 0.7 }}
                    onClick={() => handleRemoveKeyword(i)}
                  />
                </span>
              ))
            )}
          </div>
        </div>

        {/* Task Active Status */}
        <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
          <input
            type="checkbox"
            id="task_is_active"
            checked={isActive}
            onChange={(e) => setIsActive(e.target.checked)}
            style={{ width: '16px', height: '16px', accentColor: 'var(--primary)' }}
          />
          <label htmlFor="task_is_active" style={{ fontSize: '13px', fontWeight: '600', color: 'var(--text-primary)', cursor: 'pointer' }}>
            Task is Active (Users can discover and earn coins from this video)
          </label>
        </div>

        {/* Action Buttons */}
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'flex-end', gap: '12px', marginTop: '10px' }}>
          <button
            type="button"
            onClick={onClose}
            style={{
              padding: '10px 18px',
              borderRadius: 'var(--btn-radius)',
              backgroundColor: 'transparent',
              border: '1px solid var(--border-card)',
              color: 'var(--text-secondary)',
              fontSize: '13px',
              fontWeight: '600',
              cursor: 'pointer',
            }}
          >
            Cancel
          </button>
          <button
            type="submit"
            disabled={saving}
            style={{
              padding: '10px 24px',
              borderRadius: 'var(--btn-radius)',
              backgroundColor: 'var(--primary)',
              color: '#FFFFFF',
              border: 'none',
              fontSize: '13px',
              fontWeight: '700',
              cursor: saving ? 'not-allowed' : 'pointer',
              boxShadow: '0 4px 12px var(--primary-glow)',
            }}
          >
            {saving ? 'Saving...' : task ? 'Update Task' : 'Create Task'}
          </button>
        </div>
      </form>
    </Modal>
  );
}
