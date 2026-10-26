// Date keys are local calendar days written as YYYY-MM-DD.
// Arithmetic on keys uses UTC so daylight saving changes never skip a day.

const KEY_RE = /^\d{4}-\d{2}-\d{2}$/;

const pad = (n) => String(n).padStart(2, '0');

/** Local date key for a Date or a millisecond timestamp. */
export function dateKey(when = new Date()) {
  const d = when instanceof Date ? when : new Date(when);
  return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}`;
}

export function isDateKey(s) {
  if (typeof s !== 'string' || !KEY_RE.test(s)) return false;
  const [y, m, d] = s.split('-').map(Number);
  const t = new Date(Date.UTC(y, m - 1, d));
  return t.getUTCFullYear() === y && t.getUTCMonth() === m - 1 && t.getUTCDate() === d;
}

function toUtc(key) {
  const [y, m, d] = key.split('-').map(Number);
  return Date.UTC(y, m - 1, d);
}

function fromUtc(ms) {
  const d = new Date(ms);
  return `${d.getUTCFullYear()}-${pad(d.getUTCMonth() + 1)}-${pad(d.getUTCDate())}`;
}

export function addDays(key, n) {
  return fromUtc(toUtc(key) + n * 86400000);
}

/** Whole days from a to b (b - a). */
export function daysBetween(a, b) {
  return Math.round((toUtc(b) - toUtc(a)) / 86400000);
}

/** Every key from `from` to `to`, inclusive. Empty when from > to. */
export function rangeKeys(from, to) {
  const out = [];
  if (from > to) return out;
  for (let k = from; k <= to; k = addDays(k, 1)) out.push(k);
  return out;
}

export const PERIODS = ['today', '7d', '30d', 'month', 'all'];

export const PERIOD_LABELS = {
  today: 'Today',
  '7d': '7 days',
  '30d': '30 days',
  month: 'This month',
  all: 'All',
};

/**
 * Inclusive key range for a period ending today.
 * `earliest` is the oldest day with data, used for "all".
 */
export function periodRange(period, today, earliest) {
  switch (period) {
    case 'today':
      return { from: today, to: today };
    case '7d':
      return { from: addDays(today, -6), to: today };
    case '30d':
      return { from: addDays(today, -29), to: today };
    case 'month':
      return { from: `${today.slice(0, 8)}01`, to: today };
    case 'all':
      return { from: earliest && earliest < today ? earliest : today, to: today };
    default:
      throw new Error(`Unknown period: ${period}`);
  }
}

/** Oldest key that survives pruning when keeping `keepDays` days including today. */
export function retentionCutoff(today, keepDays = 400) {
  return addDays(today, -(keepDays - 1));
}

const MONTHS = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

/** "26 Oct" style label. */
export function shortDayLabel(key) {
  const [, m, d] = key.split('-').map(Number);
  return `${d} ${MONTHS[m - 1]}`;
}
