// Blocklist handling and declarativeNetRequest rule generation.
// A rule with `requestDomains: [d]` matches d and every subdomain of d.

import { isIPv4 } from './domain.js';

export const MAX_BLOCKED = 5000;

const LABEL_RE = /^[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?$/;

/**
 * Turn user input into a domain the rules can use.
 * Accepts "example.com", "*.example.com", "https://ads.example.com/path".
 * @returns {{ok: true, domain: string} | {ok: false, error: string}}
 */
export function normalizeDomain(input) {
  if (typeof input !== 'string') return { ok: false, error: 'Enter a domain.' };
  let s = input.trim().toLowerCase();
  if (s === '') return { ok: false, error: 'Enter a domain.' };
  if (/\s/.test(s)) return { ok: false, error: 'A domain cannot contain spaces.' };
  s = s.replace(/^\*\./, '').replace(/^\./, '');
  let host;
  try {
    const url = new URL(s.includes('://') ? s : `http://${s}`);
    if (url.username || url.password) return { ok: false, error: 'Enter a domain, not a login.' };
    host = url.hostname;
  } catch {
    return { ok: false, error: 'That is not a valid domain.' };
  }
  host = host.replace(/\.$/, '');
  if (host.startsWith('[')) return { ok: false, error: 'IPv6 addresses are not supported.' };
  if (host.length > 253) return { ok: false, error: 'That domain is too long.' };
  // URL() expands shorthand like "1.2.3" to "1.2.0.3"; only accept what was typed.
  if (isIPv4(host)) return s.includes(host) ? { ok: true, domain: host } : { ok: false, error: 'That is not a valid IP address.' };
  if (/^[\d.]+$/.test(host)) return { ok: false, error: 'That is not a valid domain.' };
  const labels = host.split('.');
  if (labels.length < 2) return { ok: false, error: 'Use a full domain such as example.com.' };
  if (!labels.every((l) => LABEL_RE.test(l))) return { ok: false, error: 'That is not a valid domain.' };
  if (/^\d+$/.test(labels[labels.length - 1])) return { ok: false, error: 'That is not a valid domain.' };
  return { ok: true, domain: host };
}

/** Sorted list without duplicates or invalid entries. */
export function cleanList(list) {
  const set = new Set();
  for (const item of Array.isArray(list) ? list : []) {
    const r = normalizeDomain(item);
    if (r.ok) set.add(r.domain);
  }
  return [...set].sort();
}

/** @returns {{ok: true, list: string[], domain: string} | {ok: false, error: string}} */
export function addToList(list, input) {
  const r = normalizeDomain(input);
  if (!r.ok) return r;
  const current = cleanList(list);
  if (current.includes(r.domain)) return { ok: false, error: `${r.domain} is already blocked.` };
  if (current.length >= MAX_BLOCKED) return { ok: false, error: `The list is full (${MAX_BLOCKED} domains).` };
  return { ok: true, domain: r.domain, list: [...current, r.domain].sort() };
}

export function removeFromList(list, domain) {
  return cleanList(list).filter((d) => d !== domain);
}

/** True when the host is a blocked domain or a subdomain of one. */
export function isBlocked(list, host) {
  if (!host) return false;
  const h = host.toLowerCase();
  return (list || []).some((d) => h === d || h.endsWith(`.${d}`));
}

/** One block rule per domain, ids from 1. */
export function buildRules(domains) {
  return cleanList(domains).map((domain, i) => ({
    id: i + 1,
    priority: 1,
    action: { type: 'block' },
    condition: { requestDomains: [domain] },
  }));
}

/** Arguments for updateDynamicRules that replace every existing rule. */
export function planUpdate(existingRules, domains) {
  return {
    removeRuleIds: (existingRules || []).map((r) => r.id),
    addRules: buildRules(domains),
  };
}

/** Domains covered by a set of dynamic rules (for reconciling). */
export function domainsFromRules(rules) {
  const out = [];
  for (const r of rules || []) {
    if (r?.action?.type === 'block') out.push(...(r.condition?.requestDomains || []));
  }
  return cleanList(out);
}
