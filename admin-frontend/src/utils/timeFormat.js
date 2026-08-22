/**
 * Formats seconds into human-readable duration based on the selected unit.
 * @param {number} totalSeconds
 * @param {'seconds' | 'minutes' | 'hours' | 'auto'} unit
 * @returns {string} formatted string (e.g. "120s", "2.0 mins", "3.45 hrs")
 */
export function formatWatchDuration(totalSeconds, unit = 'auto') {
  const s = Number(totalSeconds) || 0;
  if (unit === 'seconds') {
    return `${Math.round(s)}s`;
  }
  if (unit === 'minutes') {
    return `${(s / 60).toFixed(1)} mins`;
  }
  if (unit === 'hours') {
    return `${(s / 3600).toFixed(2)} hrs`;
  }
  // Auto mode
  if (s < 60) {
    return `${Math.round(s)}s`;
  }
  if (s < 3600) {
    return `${(s / 60).toFixed(1)} mins`;
  }
  return `${(s / 3600).toFixed(2)} hrs`;
}

/**
 * Formats viewer numbers into compact human-readable format (e.g. 10, 100, 1.2k, 5M).
 * @param {number} count
 * @returns {string}
 */
export function formatViewerCount(count) {
  const n = Number(count) || 0;
  if (n >= 1000000) {
    return `${(n / 1000000).toFixed(1).replace(/\.0$/, '')}M`;
  }
  if (n >= 1000) {
    return `${(n / 1000).toFixed(1).replace(/\.0$/, '')}k`;
  }
  return String(n);
}
