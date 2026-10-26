// Blocklist storage plus declarativeNetRequest dynamic rules.

import { api } from '../shim.js';
import { addToList, removeFromList, planUpdate } from '../lib/dnr.js';
import { getBlocklist, saveBlocklist } from './store.js';

/** Make the dynamic rules match the list exactly. */
export async function applyRules(list) {
  const existing = await api.declarativeNetRequest.getDynamicRules();
  await api.declarativeNetRequest.updateDynamicRules(planUpdate(existing, list));
}

export async function ruleCount() {
  return (await api.declarativeNetRequest.getDynamicRules()).length;
}

/** @returns {{ok: true, domain} | {ok: false, error}} */
export async function blockDomain(input) {
  const result = addToList(await getBlocklist(), input);
  if (!result.ok) return result;
  await applyRules(result.list);
  await saveBlocklist(result.list);
  return { ok: true, domain: result.domain };
}

export async function unblockDomain(domain) {
  const list = removeFromList(await getBlocklist(), domain);
  await applyRules(list);
  await saveBlocklist(list);
}

/** Called at startup so rules always follow the stored list. */
export async function reconcileRules() {
  await applyRules(await getBlocklist());
}
