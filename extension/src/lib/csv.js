// Export of usage data as CSV and JSON.

import { displaySite } from './domain.js';
import { OTHER_HOSTS } from './usage.js';

export const USAGE_FORMAT = 'nireekshana-usage';

/** Quote a CSV cell. Cells that a spreadsheet would run as a formula get a leading quote. */
export function escapeCell(value) {
  let s = value === null || value === undefined ? '' : String(value);
  if (/^[=+\-@\t\r]/.test(s)) s = `'${s}`;
  if (/[",\n\r]/.test(s)) s = `"${s.replace(/"/g, '""')}"`;
  return s;
}

export function toCsv(header, rows) {
  return [header, ...rows].map((r) => r.map(escapeCell).join(',')).join('\r\n') + '\r\n';
}

/** One line per day per site, oldest day first, busiest site first. */
export function usageCsv(days) {
  const rows = [];
  for (const day of Object.keys(days || {}).sort()) {
    const rec = days[day];
    const sites = Object.keys(rec).sort((a, b) => rec[b].r + rec[b].s - (rec[a].r + rec[a].s) || (a < b ? -1 : 1));
    for (const site of sites) {
      const e = rec[site];
      const tp = Object.keys(e.t || {}).filter((h) => h !== OTHER_HOSTS).length;
      rows.push([day, displaySite(site), e.r || 0, e.s || 0, e.n || 0, tp]);
    }
  }
  return toCsv(['date', 'site', 'received_bytes', 'sent_bytes', 'requests', 'third_party_hosts'], rows);
}

/** Readable JSON export with full field names. */
export function usageJson(days, { exportedAt = new Date().toISOString(), measurement = 'estimate', version = '' } = {}) {
  const out = {};
  for (const day of Object.keys(days || {}).sort()) {
    out[day] = {};
    for (const [site, e] of Object.entries(days[day])) {
      const thirdParties = {};
      for (const [h, [r, n]] of Object.entries(e.t || {})) thirdParties[h] = { receivedBytes: r, requests: n };
      out[day][displaySite(site)] = {
        receivedBytes: e.r || 0,
        sentBytes: e.s || 0,
        requests: e.n || 0,
        thirdParties,
      };
    }
  }
  return {
    format: USAGE_FORMAT,
    version: 1,
    exportedAt,
    extensionVersion: version,
    measurement,
    days: out,
  };
}
