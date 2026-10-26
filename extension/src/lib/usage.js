// Usage records and rollups.
//
// One record per local day, stored under the key "u:YYYY-MM-DD":
//   { [site]: { r: bytesReceived, s: bytesSent, n: requests,
//               t: { [thirdPartyHost]: [bytesReceived, requests] } } }
// Short field names keep 400 days of history small.

import { isThirdParty, registrableDomain, BROWSER_SITE } from './domain.js';
import { retentionCutoff, rangeKeys } from './dates.js';

export const DAY_PREFIX = 'u:';
export const KEEP_DAYS = 400;
export const MAX_HOSTS_PER_SITE = 60;
export const OTHER_HOSTS = '(other hosts)';

export const dayStorageKey = (day) => DAY_PREFIX + day;

export function dayFromStorageKey(key) {
  return typeof key === 'string' && key.startsWith(DAY_PREFIX) ? key.slice(DAY_PREFIX.length) : null;
}

function entryFor(record, site) {
  let e = record[site];
  if (!e) {
    e = { r: 0, s: 0, n: 0, t: {} };
    record[site] = e;
  }
  if (!e.t) e.t = {};
  return e;
}

/**
 * Add one completed request to an in-memory pending map ({day: record}).
 * Mutates and returns `pending`.
 */
export function addSample(pending, { day, site, host, rx = 0, tx = 0 }) {
  if (!day || !site) return pending;
  const record = (pending[day] ??= {});
  const e = entryFor(record, site);
  e.r += rx;
  e.s += tx;
  e.n += 1;
  if (host && isThirdParty(host, site)) {
    const t = (e.t[host] ??= [0, 0]);
    t[0] += rx;
    t[1] += 1;
  }
  return pending;
}

/** Keep the busiest hosts and fold the rest into one "(other hosts)" row. */
export function capHosts(hosts, max = MAX_HOSTS_PER_SITE) {
  const names = Object.keys(hosts);
  if (names.length <= max) return hosts;
  const ranked = names
    .filter((h) => h !== OTHER_HOSTS)
    .sort((a, b) => hosts[b][0] - hosts[a][0] || hosts[b][1] - hosts[a][1] || (a < b ? -1 : 1));
  const keep = ranked.slice(0, max - 1);
  const out = {};
  for (const h of keep) out[h] = hosts[h];
  const other = [0, 0];
  for (const h of names) {
    if (out[h]) continue;
    other[0] += hosts[h][0];
    other[1] += hosts[h][1];
  }
  out[OTHER_HOSTS] = other;
  return out;
}

/** Merge a delta day record into a stored one. Returns a new record. */
export function mergeDay(stored, delta, maxHosts = MAX_HOSTS_PER_SITE) {
  const out = {};
  for (const [site, e] of Object.entries(stored || {})) {
    out[site] = { r: e.r || 0, s: e.s || 0, n: e.n || 0, t: { ...(e.t || {}) } };
    for (const h of Object.keys(out[site].t)) out[site].t[h] = [...out[site].t[h]];
  }
  for (const [site, d] of Object.entries(delta || {})) {
    const e = entryFor(out, site);
    e.r += d.r || 0;
    e.s += d.s || 0;
    e.n += d.n || 0;
    for (const [h, [r, n]] of Object.entries(d.t || {})) {
      const t = (e.t[h] ??= [0, 0]);
      t[0] += r;
      t[1] += n;
    }
    e.t = capHosts(e.t, maxHosts);
  }
  return out;
}

/** Merge a whole pending map into another (used to put back a failed flush). */
export function mergePending(into, from) {
  for (const [day, rec] of Object.entries(from)) {
    into[day] = mergeDay(into[day], rec, Infinity);
  }
  return into;
}

export function dayTotals(record) {
  const t = { r: 0, s: 0, n: 0 };
  for (const e of Object.values(record || {})) {
    t.r += e.r || 0;
    t.s += e.s || 0;
    t.n += e.n || 0;
  }
  return t;
}

/** Days ({day: record}) within an inclusive key range. */
export function filterDays(days, { from, to }) {
  const out = {};
  for (const [day, rec] of Object.entries(days || {})) {
    if (day >= from && day <= to) out[day] = rec;
  }
  return out;
}

export function earliestDay(days) {
  const keys = Object.keys(days || {}).sort();
  return keys[0] ?? null;
}

/**
 * Per-site totals across days, busiest first.
 * Each row: { site, r, s, n, total, hosts: {host: {r, n}}, tpCount, share }
 */
export function rollupSites(days) {
  const map = new Map();
  for (const rec of Object.values(days || {})) {
    for (const [site, e] of Object.entries(rec)) {
      let row = map.get(site);
      if (!row) {
        row = { site, r: 0, s: 0, n: 0, hosts: {} };
        map.set(site, row);
      }
      row.r += e.r || 0;
      row.s += e.s || 0;
      row.n += e.n || 0;
      for (const [h, [r, n]] of Object.entries(e.t || {})) {
        const t = (row.hosts[h] ??= { r: 0, n: 0 });
        t.r += r;
        t.n += n;
      }
    }
  }
  const rows = [...map.values()];
  const grand = rows.reduce((a, x) => a + x.r + x.s, 0);
  for (const row of rows) {
    row.total = row.r + row.s;
    row.tpCount = Object.keys(row.hosts).filter((h) => h !== OTHER_HOSTS).length;
    row.share = grand > 0 ? row.total / grand : 0;
  }
  return sortSites(rows, 'total', 'desc');
}

export function totalsOf(days) {
  const t = { r: 0, s: 0, n: 0, sites: 0 };
  const sites = new Set();
  for (const rec of Object.values(days || {})) {
    const d = dayTotals(rec);
    t.r += d.r;
    t.s += d.s;
    t.n += d.n;
    for (const s of Object.keys(rec)) sites.add(s);
  }
  t.sites = sites.size;
  return t;
}

const SORTERS = {
  site: (a, b) => (a.site < b.site ? -1 : a.site > b.site ? 1 : 0),
  total: (a, b) => a.total - b.total,
  requests: (a, b) => a.n - b.n,
  share: (a, b) => a.share - b.share,
  thirdParties: (a, b) => a.tpCount - b.tpCount,
  received: (a, b) => a.r - b.r,
  sent: (a, b) => a.s - b.s,
};

export const SORT_KEYS = Object.keys(SORTERS);

/** Stable sort on a copy. Ties fall back to site name. */
export function sortSites(rows, key = 'total', dir = 'desc') {
  const cmp = SORTERS[key] ?? SORTERS.total;
  const sign = dir === 'asc' ? 1 : -1;
  return [...rows].sort((a, b) => sign * cmp(a, b) || SORTERS.site(a, b));
}

/** Case-insensitive match on the site, its label, or one of its hosts. */
export function searchSites(rows, query, labelOf = (s) => s) {
  const q = String(query || '').trim().toLowerCase();
  if (!q) return rows;
  return rows.filter(
    (row) =>
      row.site.toLowerCase().includes(q) ||
      labelOf(row.site).toLowerCase().includes(q) ||
      Object.keys(row.hosts || {}).some((h) => h.includes(q)),
  );
}

/** One point per day in the range, zero-filled. Optional site filter. */
export function dailySeries(days, { from, to }, site = null) {
  return rangeKeys(from, to).map((day) => {
    const rec = days?.[day];
    if (!rec) return { day, r: 0, s: 0, n: 0 };
    if (site) {
      const e = rec[site];
      return { day, r: e?.r || 0, s: e?.s || 0, n: e?.n || 0 };
    }
    return { day, ...dayTotals(rec) };
  });
}

/** Third-party hosts of one row, busiest first: [{host, r, n}]. */
export function hostList(row) {
  return Object.entries(row?.hosts || {})
    .map(([host, v]) => ({ host, r: v.r, n: v.n }))
    .sort((a, b) => b.r - a.r || b.n - a.n || (a.host < b.host ? -1 : 1));
}

/** Third-party hosts grouped by registrable domain: [{domain, r, n, hosts}]. */
export function thirdPartyDomains(row) {
  const map = new Map();
  for (const { host, r, n } of hostList(row)) {
    if (host === OTHER_HOSTS) continue;
    const domain = registrableDomain(host);
    let d = map.get(domain);
    if (!d) {
      d = { domain, r: 0, n: 0, hosts: [] };
      map.set(domain, d);
    }
    d.r += r;
    d.n += n;
    d.hosts.push(host);
  }
  return [...map.values()].sort((a, b) => b.r - a.r || b.n - a.n || (a.domain < b.domain ? -1 : 1));
}

/** Storage keys of day records older than the retention window. */
export function prunableKeys(storageKeys, today, keepDays = KEEP_DAYS) {
  const cutoff = retentionCutoff(today, keepDays);
  return storageKeys.filter((k) => {
    const day = dayFromStorageKey(k);
    return day !== null && day < cutoff;
  });
}

/** Pull day records out of a storage.get(null) result. */
export function daysFromStorage(items) {
  const out = {};
  for (const [k, v] of Object.entries(items || {})) {
    const day = dayFromStorageKey(k);
    if (day && v && typeof v === 'object') out[day] = v;
  }
  return out;
}

export { BROWSER_SITE };
