// Storage access shared by the background script and the pages.

import { api } from '../shim.js';
import { daysFromStorage, dayStorageKey, DAY_PREFIX } from '../lib/usage.js';
import { cleanList } from '../lib/dnr.js';
import { validateTheme } from '../lib/theme.js';

export const KEYS = {
  settings: 'settings',
  blocklist: 'blocklist',
  customThemes: 'customThemes',
  alerted: 'alerted',
};

export const DEFAULT_SETTINGS = {
  themeId: 'radar',
  mode: 'system', // "system" | "light" | "dark"
  browserBudgetMB: null,
  siteBudgets: {},
};

const local = () => api.storage.local;

export async function getSettings() {
  const { [KEYS.settings]: s } = await local().get(KEYS.settings);
  return { ...DEFAULT_SETTINGS, ...(s || {}), siteBudgets: { ...(s?.siteBudgets || {}) } };
}

export async function updateSettings(patch) {
  const next = { ...(await getSettings()), ...patch };
  await local().set({ [KEYS.settings]: next });
  return next;
}

export async function getBlocklist() {
  const { [KEYS.blocklist]: list } = await local().get(KEYS.blocklist);
  return cleanList(list);
}

export async function saveBlocklist(list) {
  await local().set({ [KEYS.blocklist]: cleanList(list) });
}

export async function getCustomThemes() {
  const { [KEYS.customThemes]: list } = await local().get(KEYS.customThemes);
  return (Array.isArray(list) ? list : []).map(validateTheme).filter((r) => r.ok).map((r) => r.theme);
}

export async function saveCustomThemes(list) {
  await local().set({ [KEYS.customThemes]: list });
}

/** Every stored day record: { day: record }. */
export async function loadAllDays() {
  return daysFromStorage(await local().get(null));
}

/** Records for the given day keys (missing days are absent). */
export async function loadDays(dayKeys) {
  return daysFromStorage(await local().get(dayKeys.map(dayStorageKey)));
}

export async function usageStorageKeys() {
  const all = await local().get(null);
  return Object.keys(all).filter((k) => k.startsWith(DAY_PREFIX));
}

/** Ask the background script something. Resolves null if it does not answer. */
export async function ask(message, timeoutMs = 1500) {
  try {
    return await Promise.race([
      api.runtime.sendMessage(message),
      new Promise((resolve) => setTimeout(() => resolve(null), timeoutMs)),
    ]);
  } catch {
    return null;
  }
}
