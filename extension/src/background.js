// Background: watches completed requests, adds them up per site and day,
// and writes the totals to storage in batches. Makes no network requests.

import { api, isFirefox } from './shim.js';
import { BROWSER_SITE, displaySite, hostFromUrl, siteForUrl } from './lib/domain.js';
import { measureCompleted, requestBodySize } from './lib/measure.js';
import {
  addSample,
  dayStorageKey,
  mergeDay,
  mergePending,
  prunableKeys,
  DAY_PREFIX,
} from './lib/usage.js';
import { dateKey } from './lib/dates.js';
import { checkBudgets } from './lib/alerts.js';
import { formatBytes } from './lib/format.js';
import { getSettings, KEYS } from './platform/store.js';
import { reconcileRules } from './platform/blocklist.js';

const FLUSH_DELAY_MS = 4000;
const MAX_TRACKED_BODIES = 2000;
const URLS = { urls: ['<all_urls>'] };

let pending = {};
let flushTimer = null;
let flushChain = Promise.resolve();
let lastPruneDay = null;

const tabSites = new Map(); // tabId -> site of the tab's top-level page
const bodies = new Map(); // requestId -> request body bytes (Chrome)

// Tab tracking -------------------------------------------------------------

function setTabSite(tabId, url) {
  if (tabId < 0) return;
  const site = siteForUrl(url);
  if (site) tabSites.set(tabId, site);
  else tabSites.delete(tabId);
  saveTabSitesSoon();
}

let tabSaveTimer = null;
function saveTabSitesSoon() {
  if (!api.storage.session || tabSaveTimer) return;
  tabSaveTimer = setTimeout(() => {
    tabSaveTimer = null;
    api.storage.session.set({ tabSites: Object.fromEntries(tabSites) }).catch(() => {});
  }, 1000);
}

async function init() {
  try {
    if (api.storage.session) {
      const { tabSites: saved } = await api.storage.session.get('tabSites');
      for (const [id, site] of Object.entries(saved || {})) tabSites.set(Number(id), site);
    }
  } catch {
    // Session storage is optional.
  }
  try {
    // With host access, tab URLs are visible without the "tabs" permission.
    for (const tab of await api.tabs.query({})) {
      if (tab.id >= 0 && tab.url) {
        const site = siteForUrl(tab.url);
        if (site) tabSites.set(tab.id, site);
      }
    }
  } catch {
    // Keep what we have.
  }
}

const ready = init();

api.tabs.onUpdated.addListener((tabId, changeInfo) => {
  if (changeInfo.url) setTabSite(tabId, changeInfo.url);
});
api.tabs.onRemoved.addListener((tabId) => {
  tabSites.delete(tabId);
  saveTabSitesSoon();
});
api.tabs.onReplaced?.addListener((added, removed) => {
  tabSites.delete(removed);
  api.tabs.get(added).then((t) => t?.url && setTabSite(added, t.url), () => {});
});

/** Which site a request belongs to. */
function siteOfRequest(d) {
  if (d.tabId >= 0) {
    if (d.type === 'main_frame') return siteForUrl(d.url) ?? BROWSER_SITE;
    const known = tabSites.get(d.tabId);
    if (known) return known;
    // Firefox lists the frame chain; the last entry is the top page.
    const top = Array.isArray(d.frameAncestors) && d.frameAncestors.length ? d.frameAncestors.at(-1).url : null;
    return siteForUrl(top) ?? siteForUrl(d.documentUrl) ?? siteForUrl(d.initiator) ?? siteForUrl(d.originUrl) ?? BROWSER_SITE;
  }
  // No tab: a site's service worker (has a web origin), another extension,
  // or the browser itself.
  return siteForUrl(d.initiator) ?? siteForUrl(d.documentUrl) ?? siteForUrl(d.originUrl) ?? BROWSER_SITE;
}

// Request events -----------------------------------------------------------

api.webRequest.onResponseStarted.addListener((d) => {
  if (d.type === 'main_frame' && d.tabId >= 0) setTabSite(d.tabId, d.url);
}, URLS);

if (!isFirefox) {
  // Chrome has no request size, so note body sizes up front.
  api.webRequest.onBeforeRequest.addListener(
    (d) => {
      if (!d.requestBody) return;
      const size = requestBodySize(d.requestBody);
      if (size <= 0) return;
      if (bodies.size >= MAX_TRACKED_BODIES) bodies.delete(bodies.keys().next().value);
      bodies.set(d.requestId, size);
    },
    URLS,
    ['requestBody'],
  );
}

api.webRequest.onCompleted.addListener(
  (d) => {
    const bodyBytes = bodies.get(d.requestId) ?? 0;
    bodies.delete(d.requestId);
    const host = hostFromUrl(d.url);
    if (!host) return; // data:, file: and similar never touch the network.
    const m = measureCompleted(d, { exact: isFirefox, bodyBytes });
    if (m.skip) return;
    ready.then(() => {
      addSample(pending, {
        day: dateKey(d.timeStamp ?? Date.now()),
        site: siteOfRequest(d),
        host,
        rx: m.rx,
        tx: m.tx,
      });
      scheduleFlush();
    });
  },
  URLS,
  ['responseHeaders'],
);

api.webRequest.onErrorOccurred.addListener((d) => bodies.delete(d.requestId), URLS);

// Writing to storage -------------------------------------------------------

function scheduleFlush() {
  if (flushTimer) return;
  flushTimer = setTimeout(() => {
    flushTimer = null;
    flush();
  }, FLUSH_DELAY_MS);
}

function flush() {
  if (flushTimer) {
    clearTimeout(flushTimer);
    flushTimer = null;
  }
  flushChain = flushChain.then(writePending).catch((e) => console.error('Nireekshana: flush failed', e));
  return flushChain;
}

async function writePending() {
  const snapshot = pending;
  pending = {};
  const days = Object.keys(snapshot);
  if (days.length > 0) {
    try {
      const keys = days.map(dayStorageKey);
      const stored = await api.storage.local.get(keys);
      const update = {};
      for (const day of days) update[dayStorageKey(day)] = mergeDay(stored[dayStorageKey(day)], snapshot[day]);
      await api.storage.local.set(update);
      const today = dateKey();
      if (update[dayStorageKey(today)]) await checkAlerts(today, update[dayStorageKey(today)]);
    } catch (e) {
      mergePending(pending, snapshot);
      scheduleFlush();
      throw e;
    }
  }
  await pruneOncePerDay();
}

async function pruneOncePerDay() {
  const today = dateKey();
  if (lastPruneDay === today) return;
  lastPruneDay = today;
  const all = await api.storage.local.get(null);
  const old = prunableKeys(Object.keys(all), today);
  if (old.length) await api.storage.local.remove(old);
}

// Data budgets -------------------------------------------------------------

async function checkAlerts(day, record) {
  const settings = await getSettings();
  const { [KEYS.alerted]: alerted } = await api.storage.local.get(KEYS.alerted);
  const result = checkBudgets({
    day,
    record,
    budgets: { browserMB: settings.browserBudgetMB, sites: settings.siteBudgets },
    alerted,
  });
  if (result.changed) await api.storage.local.set({ [KEYS.alerted]: result.alerted });
  for (const a of result.fire) {
    const where = a.kind === 'browser' ? 'This browser' : displaySite(a.site);
    await api.notifications
      .create(`nireekshana-${a.kind}-${a.site ?? 'all'}-${day}`, {
        type: 'basic',
        iconUrl: api.runtime.getURL('icons/icon-128.png'),
        title: 'Daily data budget reached',
        message: `${where} used ${formatBytes(a.used)} today. The budget is ${a.limitMB} MB.`,
      })
      .catch(() => {});
  }
}

api.notifications.onClicked.addListener((id) => {
  if (id.startsWith('nireekshana-')) api.runtime.openOptionsPage();
});

// Messages from the popup and the dashboard --------------------------------

api.runtime.onMessage.addListener((msg, sender, sendResponse) => {
  if (sender.id !== api.runtime.id || !msg || typeof msg.type !== 'string') return false;
  if (msg.type === 'flush') {
    ready.then(flush).then(
      () => sendResponse({ ok: true }),
      () => sendResponse({ ok: false }),
    );
    return true;
  }
  if (msg.type === 'clear') {
    pending = {};
    flushChain = flushChain
      .then(async () => {
        const all = await api.storage.local.get(null);
        const keys = Object.keys(all).filter((k) => k.startsWith(DAY_PREFIX));
        await api.storage.local.remove([...keys, KEYS.alerted]);
      })
      .then(
        () => sendResponse({ ok: true }),
        () => sendResponse({ ok: false }),
      );
    return true;
  }
  return false;
});

// Lifecycle ---------------------------------------------------------------

api.runtime.onInstalled.addListener(() => {
  reconcileRules().catch(() => {});
});
api.runtime.onStartup.addListener(() => {
  reconcileRules().catch(() => {});
});
api.runtime.onSuspend?.addListener(() => {
  flush();
});
