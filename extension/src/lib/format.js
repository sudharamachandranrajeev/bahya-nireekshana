// Number formatting. Sizes use 1024-based units.

const UNITS = ['B', 'KB', 'MB', 'GB', 'TB', 'PB'];
export const MB = 1024 * 1024;

export function formatBytes(bytes, digits = 1) {
  const n = Number(bytes);
  if (!Number.isFinite(n) || n <= 0) return '0 B';
  let i = 0;
  let v = n;
  while (v >= 1024 && i < UNITS.length - 1) {
    v /= 1024;
    i += 1;
  }
  if (i === 0) return `${Math.round(v)} B`;
  const d = v >= 100 ? 0 : digits;
  return `${v.toFixed(d)} ${UNITS[i]}`;
}

export function formatCount(n) {
  const v = Number(n);
  if (!Number.isFinite(v) || v <= 0) return '0';
  if (v < 1000) return String(Math.round(v));
  if (v < 1e6) return `${(v / 1e3).toFixed(v < 1e4 ? 1 : 0)}k`;
  return `${(v / 1e6).toFixed(v < 1e7 ? 1 : 0)}M`;
}

/** 0.123 -> "12%", tiny non-zero shares -> "<1%". */
export function formatPercent(fraction) {
  const v = Number(fraction);
  if (!Number.isFinite(v) || v <= 0) return '0%';
  if (v < 0.01) return '<1%';
  return `${Math.round(v * 100)}%`;
}

/**
 * Parse a megabyte budget typed by the user.
 * Empty or 0 turns the budget off (null). Returns undefined when invalid.
 */
export function parseBudgetMB(input) {
  const s = String(input ?? '').trim();
  if (s === '' || s === '0') return null;
  if (!/^\d+(\.\d+)?$/.test(s)) return undefined;
  const v = Number(s);
  if (!Number.isFinite(v) || v <= 0 || v > 10_000_000) return undefined;
  return Math.round(v * 100) / 100;
}
