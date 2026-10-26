// Daily data budgets. Each budget alerts at most once per day.

import { MB } from './format.js';

/**
 * @param day today's key
 * @param record today's usage record
 * @param budgets { browserMB: number|null, sites: { [site]: number } }
 * @param alerted { day, browser: bool, sites: string[] } from storage, or null
 * @returns {{ fire: Array<{kind, site, used, limitMB}>, alerted: object, changed: boolean }}
 */
export function checkBudgets({ day, record, budgets, alerted }) {
  const state =
    alerted && alerted.day === day
      ? { day, browser: !!alerted.browser, sites: [...(alerted.sites || [])] }
      : { day, browser: false, sites: [] };
  const fire = [];
  const used = (e) => (e ? (e.r || 0) + (e.s || 0) : 0);

  const browserMB = budgets?.browserMB;
  if (browserMB > 0 && !state.browser) {
    let total = 0;
    for (const e of Object.values(record || {})) total += used(e);
    if (total >= browserMB * MB) {
      fire.push({ kind: 'browser', site: null, used: total, limitMB: browserMB });
      state.browser = true;
    }
  }
  for (const [site, limitMB] of Object.entries(budgets?.sites || {})) {
    if (!(limitMB > 0) || state.sites.includes(site)) continue;
    const u = used(record?.[site]);
    if (u >= limitMB * MB) {
      fire.push({ kind: 'site', site, used: u, limitMB });
      state.sites.push(site);
    }
  }
  const changed = fire.length > 0 || !alerted || alerted.day !== day;
  return { fire, alerted: state, changed };
}
