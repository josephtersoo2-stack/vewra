import React, { useEffect, useState } from 'react';
import {
  Sparkles,
  Key,
  Cpu,
  RefreshCw,
  Play,
  Save,
  CheckCircle2,
  AlertCircle,
  Clock,
  Eye,
  EyeOff,
  Search,
} from 'lucide-react';
import { adminApi } from '../api/adminApi';
import { Badge } from '../components/ui/Badge';
import { useTheme } from '../theme/ThemeContext';

export function AISettingsPage() {
  const [settings, setSettings] = useState(null);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [saveSuccess, setSaveSuccess] = useState(false);

  // Form states
  const [activeProvider, setActiveProvider] = useState('gemini');
  const [geminiKey, setGeminiKey] = useState('');
  const [openrouterKey, setOpenrouterKey] = useState('');
  const [selectedModel, setSelectedModel] = useState('');
  const [customPrompt, setCustomPrompt] = useState('');
  const [isActive, setIsActive] = useState(true);

  // Show/Hide Keys
  const [showGeminiKey, setShowGeminiKey] = useState(false);
  const [showORKey, setShowORKey] = useState(false);

  // Dynamic Models
  const [models, setModels] = useState([]);
  const [fetchingModels, setFetchingModels] = useState(false);
  const [modelSearch, setModelSearch] = useState('');

  // Sandbox Tester states
  const [testUrl, setTestUrl] = useState('https://www.youtube.com/watch?v=dQw4w9WgXcQ');
  const [testing, setTesting] = useState(false);
  const [testResult, setTestResult] = useState(null);
  const [testError, setTestError] = useState('');

  const loadSettings = async () => {
    try {
      const data = await adminApi.getAISettings();
      setSettings(data);
      setActiveProvider(data.active_provider || 'gemini');
      setGeminiKey(data.gemini_api_key || '');
      setOpenrouterKey(data.openrouter_api_key || '');
      setSelectedModel(data.selected_model || '');
      setCustomPrompt(data.custom_system_prompt || '');
      setIsActive(data.is_active ?? true);
      
      // Fetch models for active provider
      loadModels(data.active_provider || 'gemini');
    } catch (err) {
      console.error('Failed to load AI settings', err);
    } finally {
      setLoading(false);
    }
  };

  const [modelFeedback, setModelFeedback] = useState('');

  const loadModels = async (provider, customKey = '') => {
    setFetchingModels(true);
    setModelFeedback('');
    try {
      const keyToUse = customKey || (provider === 'gemini' ? geminiKey : openrouterKey);
      const res = await adminApi.fetchAIModels(provider, keyToUse);
      const list = res.models || [];
      setModels(list);
      setModelFeedback(`✓ Discovered ${list.length} models for ${provider === 'gemini' ? 'Google Gemini' : 'OpenRouter'}`);
      setTimeout(() => setModelFeedback(''), 4000);
    } catch (err) {
      console.error('Failed to fetch models', err);
      setModelFeedback(`Error: ${err.response?.data?.error || err.message}`);
    } finally {
      setFetchingModels(false);
    }
  };

  useEffect(() => {
    loadSettings();
  }, []);

  const handleProviderChange = (provider) => {
    setActiveProvider(provider);
    loadModels(provider);
  };

  const handleSaveSettings = async (e) => {
    e.preventDefault();
    setSaving(true);
    setSaveSuccess(false);
    try {
      const updated = await adminApi.updateAISettings({
        active_provider: activeProvider,
        gemini_api_key: geminiKey,
        openrouter_api_key: openrouterKey,
        selected_model: selectedModel,
        custom_system_prompt: customPrompt,
        is_active: isActive,
      });
      setSettings(updated);
      setSaveSuccess(true);
      setTimeout(() => setSaveSuccess(false), 3000);
    } catch (err) {
      alert('Failed to save settings: ' + (err.response?.data?.error || err.message));
    } finally {
      setSaving(false);
    }
  };

  const handleRunSandboxTest = async (e) => {
    e.preventDefault();
    if (!testUrl) return;
    setTesting(true);
    setTestResult(null);
    setTestError('');
    try {
      const res = await adminApi.testAISandbox({
        youtube_url: testUrl,
        provider: activeProvider,
        model_name: selectedModel,
        custom_prompt: customPrompt,
      });
      setTestResult(res);
    } catch (err) {
      setTestError(err.response?.data?.error || err.message || 'Sandbox test failed');
    } finally {
      setTesting(false);
    }
  };

  if (loading) {
    return (
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', minHeight: '60vh' }}>
        <p style={{ color: 'var(--text-secondary)' }}>Loading AI Studio configuration...</p>
      </div>
    );
  }

  const filteredModels = models.filter((m) => {
    const id = (typeof m === 'string' ? m : m.id || m.name || '').toLowerCase();
    return id.includes(modelSearch.toLowerCase());
  });

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: '32px' }}>
      {/* Header */}
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', flexWrap: 'wrap', gap: '16px' }}>
        <div>
          <h1 style={{ fontSize: '26px', fontWeight: '800', color: 'var(--text-primary)' }}>
            AI Keyword Studio & Models
          </h1>
          <p style={{ fontSize: '14px', color: 'var(--text-secondary)', marginTop: '4px' }}>
            Configure LLM providers, discover dynamic models, and test prompt generation
          </p>
        </div>

        <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
          {saveSuccess && (
            <Badge variant="emerald" size="md">
              <CheckCircle2 size={16} /> Settings Saved
            </Badge>
          )}
          <button
            onClick={handleSaveSettings}
            disabled={saving}
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
              cursor: saving ? 'not-allowed' : 'pointer',
              boxShadow: '0 4px 12px var(--primary-glow)',
            }}
          >
            <Save size={16} />
            <span>{saving ? 'Saving...' : 'Save Configuration'}</span>
          </button>
        </div>
      </div>

      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(460px, 1fr))', gap: '24px' }}>
        {/* Left Column: Provider & Keys */}
        <div style={{ display: 'flex', flexDirection: 'column', gap: '24px' }}>
          {/* Active Provider Selector */}
          <div className="card">
            <h3 style={{ fontSize: '17px', fontWeight: '700', color: 'var(--text-primary)', marginBottom: '16px' }}>
              Active AI Provider
            </h3>

            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '14px' }}>
              {/* Google Gemini Option */}
              <div
                onClick={() => handleProviderChange('gemini')}
                style={{
                  padding: '16px',
                  borderRadius: 'var(--btn-radius)',
                  border: activeProvider === 'gemini' ? '2px solid var(--primary)' : '1px solid var(--border-card)',
                  backgroundColor: activeProvider === 'gemini' ? 'var(--primary-light)' : 'var(--bg-tertiary)',
                  cursor: 'pointer',
                  display: 'flex',
                  flexDirection: 'column',
                  gap: '8px',
                }}
              >
                <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
                  <span style={{ fontWeight: '700', fontSize: '15px', color: 'var(--text-primary)' }}>
                    Google Gemini
                  </span>
                  {activeProvider === 'gemini' && <Badge variant="indigo">Active</Badge>}
                </div>
                <p style={{ fontSize: '12px', color: 'var(--text-secondary)' }}>
                  Ultra-fast response time with official Gemini API keys
                </p>
              </div>

              {/* OpenRouter Option */}
              <div
                onClick={() => handleProviderChange('openrouter')}
                style={{
                  padding: '16px',
                  borderRadius: 'var(--btn-radius)',
                  border: activeProvider === 'openrouter' ? '2px solid var(--primary)' : '1px solid var(--border-card)',
                  backgroundColor: activeProvider === 'openrouter' ? 'var(--primary-light)' : 'var(--bg-tertiary)',
                  cursor: 'pointer',
                  display: 'flex',
                  flexDirection: 'column',
                  gap: '8px',
                }}
              >
                <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
                  <span style={{ fontWeight: '700', fontSize: '15px', color: 'var(--text-primary)' }}>
                    OpenRouter Hub
                  </span>
                  {activeProvider === 'openrouter' && <Badge variant="indigo">Active</Badge>}
                </div>
                <p style={{ fontSize: '12px', color: 'var(--text-secondary)' }}>
                  Access to 400+ top open & commercial LLM models
                </p>
              </div>
            </div>

            {/* API Keys Configuration */}
            <div style={{ marginTop: '24px', display: 'flex', flexDirection: 'column', gap: '16px' }}>
              <div>
                <label style={{ fontSize: '13px', fontWeight: '600', color: 'var(--text-secondary)', display: 'block', marginBottom: '6px' }}>
                  Google Gemini API Key
                </label>
                <div style={{ position: 'relative' }}>
                  <input
                    type={showGeminiKey ? 'text' : 'password'}
                    value={geminiKey}
                    onChange={(e) => setGeminiKey(e.target.value)}
                    placeholder="AIzaSy..."
                    style={{
                      width: '100%',
                      padding: '12px 42px 12px 14px',
                      borderRadius: 'var(--input-radius)',
                      backgroundColor: 'var(--bg-tertiary)',
                      border: '1px solid var(--border-card)',
                      color: 'var(--text-primary)',
                      fontSize: '13px',
                      fontFamily: 'var(--font-mono)',
                    }}
                  />
                  <button
                    type="button"
                    onClick={() => setShowGeminiKey(!showGeminiKey)}
                    style={{
                      position: 'absolute',
                      right: '12px',
                      top: '50%',
                      transform: 'translateY(-50%)',
                      background: 'transparent',
                      border: 'none',
                      color: 'var(--text-tertiary)',
                      cursor: 'pointer',
                    }}
                  >
                    {showGeminiKey ? <EyeOff size={16} /> : <Eye size={16} />}
                  </button>
                </div>
              </div>

              <div>
                <label style={{ fontSize: '13px', fontWeight: '600', color: 'var(--text-secondary)', display: 'block', marginBottom: '6px' }}>
                  OpenRouter API Key
                </label>
                <div style={{ position: 'relative' }}>
                  <input
                    type={showORKey ? 'text' : 'password'}
                    value={openrouterKey}
                    onChange={(e) => setOpenrouterKey(e.target.value)}
                    placeholder="sk-or-v1-..."
                    style={{
                      width: '100%',
                      padding: '12px 42px 12px 14px',
                      borderRadius: 'var(--input-radius)',
                      backgroundColor: 'var(--bg-tertiary)',
                      border: '1px solid var(--border-card)',
                      color: 'var(--text-primary)',
                      fontSize: '13px',
                      fontFamily: 'var(--font-mono)',
                    }}
                  />
                  <button
                    type="button"
                    onClick={() => setShowORKey(!showORKey)}
                    style={{
                      position: 'absolute',
                      right: '12px',
                      top: '50%',
                      transform: 'translateY(-50%)',
                      background: 'transparent',
                      border: 'none',
                      color: 'var(--text-tertiary)',
                      cursor: 'pointer',
                    }}
                  >
                    {showORKey ? <EyeOff size={16} /> : <Eye size={16} />}
                  </button>
                </div>
              </div>
            </div>
          </div>

          {/* Dynamic Model Picker */}
          <div className="card">
            <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: '14px' }}>
              <div>
                <h3 style={{ fontSize: '17px', fontWeight: '700', color: 'var(--text-primary)' }}>
                  Select Model ({activeProvider === 'gemini' ? 'Google Gemini' : 'OpenRouter'})
                </h3>
                <p style={{ fontSize: '12px', color: 'var(--text-secondary)' }}>
                  Currently Selected: <code style={{ color: 'var(--primary)', fontWeight: '700' }}>{selectedModel || 'Default'}</code>
                </p>
              </div>

              <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                {modelFeedback && (
                  <span style={{ fontSize: '11px', fontWeight: '600', color: modelFeedback.startsWith('✓') ? 'var(--accent-emerald)' : 'var(--accent-rose)' }}>
                    {modelFeedback}
                  </span>
                )}
                <button
                  onClick={() => loadModels(activeProvider)}
                  disabled={fetchingModels}
                  style={{
                    display: 'flex',
                    alignItems: 'center',
                    gap: '6px',
                    padding: '6px 12px',
                    borderRadius: 'var(--btn-radius)',
                    backgroundColor: 'var(--bg-tertiary)',
                    border: '1px solid var(--border-card)',
                    color: 'var(--text-primary)',
                    fontSize: '12px',
                    cursor: 'pointer',
                  }}
                >
                  <RefreshCw size={14} className={fetchingModels ? 'pulse-badge' : ''} />
                  <span>{fetchingModels ? 'Fetching...' : 'Discover'}</span>
                </button>
              </div>
            </div>

            {/* Model Search Box */}
            <div style={{ position: 'relative', marginBottom: '12px' }}>
              <Search size={16} style={{ position: 'absolute', left: '12px', top: '50%', transform: 'translateY(-50%)', color: 'var(--text-tertiary)' }} />
              <input
                type="text"
                value={modelSearch}
                onChange={(e) => setModelSearch(e.target.value)}
                placeholder="Search models (e.g. flash, llama, sonnet)..."
                style={{
                  width: '100%',
                  padding: '10px 12px 10px 36px',
                  borderRadius: 'var(--input-radius)',
                  backgroundColor: 'var(--bg-tertiary)',
                  border: '1px solid var(--border-card)',
                  color: 'var(--text-primary)',
                  fontSize: '13px',
                }}
              />
            </div>

            {/* Models Scrollable List */}
            <div
              style={{
                maxHeight: '220px',
                overflowY: 'auto',
                border: '1px solid var(--border-subtle)',
                borderRadius: 'var(--input-radius)',
                padding: '6px',
                display: 'flex',
                flexDirection: 'column',
                gap: '4px',
              }}
            >
              {filteredModels.length === 0 ? (
                <p style={{ padding: '16px', textAlign: 'center', fontSize: '13px', color: 'var(--text-tertiary)' }}>
                  {fetchingModels ? 'Loading available models...' : 'No models matching search.'}
                </p>
              ) : (
                filteredModels.map((m) => {
                  const id = typeof m === 'string' ? m : m.id || m.name;
                  const isSelected = selectedModel === id;
                  return (
                    <div
                      key={id}
                      onClick={() => setSelectedModel(id)}
                      style={{
                        padding: '8px 12px',
                        borderRadius: '6px',
                        backgroundColor: isSelected ? 'var(--primary-light)' : 'transparent',
                        border: isSelected ? '1px solid var(--border-active)' : '1px solid transparent',
                        color: isSelected ? 'var(--primary)' : 'var(--text-primary)',
                        fontWeight: isSelected ? '700' : '500',
                        fontSize: '13px',
                        cursor: 'pointer',
                        display: 'flex',
                        alignItems: 'center',
                        justifyContent: 'space-between',
                      }}
                    >
                      <span style={{ fontFamily: 'var(--font-mono)' }}>{id}</span>
                      {isSelected && <CheckCircle2 size={16} />}
                    </div>
                  );
                })
              )}
            </div>
          </div>
        </div>

        {/* Right Column: Prompt Editor & Interactive Sandbox */}
        <div style={{ display: 'flex', flexDirection: 'column', gap: '24px' }}>
          {/* Prompt Editor */}
          <div className="card">
            <h3 style={{ fontSize: '17px', fontWeight: '700', color: 'var(--text-primary)', marginBottom: '12px' }}>
              System Prompt Template
            </h3>
            <p style={{ fontSize: '13px', color: 'var(--text-secondary)', marginBottom: '12px' }}>
              Instruction given to the model for generating verified YouTube search phrases.
            </p>

            <textarea
              rows={8}
              value={customPrompt}
              onChange={(e) => setCustomPrompt(e.target.value)}
              style={{
                width: '100%',
                padding: '14px',
                borderRadius: 'var(--input-radius)',
                backgroundColor: 'var(--bg-tertiary)',
                border: '1px solid var(--border-card)',
                color: 'var(--text-primary)',
                fontFamily: 'var(--font-mono)',
                fontSize: '12px',
                lineHeight: '1.5',
                resize: 'vertical',
              }}
            />
          </div>

          {/* Real-time Sandbox Tester */}
          <div className="card" style={{ border: '1px solid var(--border-active)' }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: '10px', marginBottom: '12px' }}>
              <Sparkles size={20} style={{ color: 'var(--primary)' }} />
              <h3 style={{ fontSize: '17px', fontWeight: '700', color: 'var(--text-primary)' }}>
                Live Keyword Sandbox Tester
              </h3>
            </div>
            <p style={{ fontSize: '13px', color: 'var(--text-secondary)', marginBottom: '16px' }}>
              Test keyword extraction on any YouTube link with your current active model in real time.
            </p>

            <form onSubmit={handleRunSandboxTest} style={{ display: 'flex', gap: '10px' }}>
              <input
                type="text"
                value={testUrl}
                onChange={(e) => setTestUrl(e.target.value)}
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
                type="submit"
                disabled={testing}
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
                  cursor: testing ? 'not-allowed' : 'pointer',
                }}
              >
                <Play size={14} />
                <span>{testing ? 'Testing...' : 'Run Test'}</span>
              </button>
            </form>

            {testError && (
              <div
                style={{
                  marginTop: '16px',
                  padding: '12px',
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
                <span>{testError}</span>
              </div>
            )}

            {testResult && (
              <div style={{ marginTop: '20px', display: 'flex', flexDirection: 'column', gap: '14px' }}>
                <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
                  <span style={{ fontSize: '13px', fontWeight: '700', color: 'var(--text-primary)' }}>
                    {testResult.metadata?.title || 'YouTube Video'}
                  </span>
                  <div style={{ display: 'flex', gap: '6px' }}>
                    <Badge variant="indigo">{testResult.provider_used}</Badge>
                    <Badge variant="emerald">{testResult.latency_ms}ms</Badge>
                  </div>
                </div>

                <div style={{ display: 'flex', flexWrap: 'wrap', gap: '8px' }}>
                  {testResult.keywords?.map((kw, i) => (
                    <Badge key={i} variant="amber" size="md">
                      🔍 {kw}
                    </Badge>
                  ))}
                </div>
              </div>
            )}
          </div>
        </div>
      </div>
    </div>
  );
}
