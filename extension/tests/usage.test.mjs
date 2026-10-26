import { test } from 'node:test';
import assert from 'node:assert/strict';
import {
  addSample,
  capHosts,
  dailySeries,
  dayFromStorageKey,
  dayStorageKey,
  daysFromStorage,
  dayTotals,
  earliestDay,
  filterDays,
  hostList,
  mergeDay,
  mergePending,
  OTHER_HOSTS,
  prunableKeys,
  rollupSites,
  searchSites,
  sortSites,
  thirdPartyDomains,
  totalsOf,
} from '../src/lib/usage.js';
import { BROWSER_SITE, displaySite } from '../src/lib/domain.js';

const D1 = '2026-10-25';
const D2 = '2026-10-26';

function sample() {
  const p = {};
  addSample(p, { day: D1, site: 'example.com', host: 'www.example.com', rx: 1000, tx: 100 });
  addSample(p, { day: D1, site: 'example.com', host: 'cdn.tracker.net', rx: 500, tx: 0 });
  addSample(p, { day: D1, site: 'example.com', host: 'cdn.tracker.net', rx: 250, tx: 10 });
  addSample(p, { day: D1, site: 'example.com', host: 'ads.tracker.net', rx: 50, tx: 0 });
  addSample(p, { day: D2, site: 'news.co.uk', host: 'img.news.co.uk', rx: 4000, tx: 0 });
  addSample(p, { day: D2, site: BROWSER_SITE, host: 'update.browser.com', rx: 9000, tx: 0 });
  return p;
}

test('storage keys round trip', () => {
  assert.equal(dayStorageKey(D1), 'u:2026-10-25');
  assert.equal(dayFromStorageKey('u:2026-10-25'), D1);
  assert.equal(dayFromStorageKey('settings'), null);
  assert.equal(dayFromStorageKey(undefined), null);
});

test('addSample sums bytes, requests and third parties', () => {
  const p = sample();
  const e = p[D1]['example.com'];
  assert.equal(e.r, 1800);
  assert.equal(e.s, 110);
  assert.equal(e.n, 4);
  assert.deepEqual(e.t, { 'cdn.tracker.net': [750, 2], 'ads.tracker.net': [50, 1] });
  assert.deepEqual(p[D2]['news.co.uk'].t, {});
  // The browser bucket never records third parties.
  assert.deepEqual(p[D2][BROWSER_SITE].t, {});
});

test('addSample ignores samples without a day or site', () => {
  const p = {};
  addSample(p, { day: '', site: 'a.com', rx: 1 });
  addSample(p, { day: D1, site: null, rx: 1 });
  assert.deepEqual(p, {});
});

test('mergeDay adds into stored data without changing it', () => {
  const stored = { 'example.com': { r: 10, s: 1, n: 1, t: { 'cdn.tracker.net': [5, 1] } } };
  const copy = structuredClone(stored);
  const merged = mergeDay(stored, sample()[D1]);
  assert.deepEqual(stored, copy);
  assert.equal(merged['example.com'].r, 1810);
  assert.equal(merged['example.com'].n, 5);
  assert.deepEqual(merged['example.com'].t['cdn.tracker.net'], [755, 3]);
});

test('mergeDay handles empty and malformed input', () => {
  assert.deepEqual(mergeDay(undefined, {}), {});
  const m = mergeDay({ 'a.com': { r: 1 } }, { 'a.com': { n: 2 } });
  assert.deepEqual(m['a.com'], { r: 1, s: 0, n: 2, t: {} });
});

test('capHosts keeps the busiest hosts and folds the rest', () => {
  const hosts = {};
  for (let i = 0; i < 10; i++) hosts[`h${i}.com`] = [i * 100, 1];
  const capped = capHosts(hosts, 4);
  assert.deepEqual(Object.keys(capped).sort(), ['h7.com', 'h8.com', 'h9.com', OTHER_HOSTS].sort());
  assert.deepEqual(capped[OTHER_HOSTS], [0 + 100 + 200 + 300 + 400 + 500 + 600, 7]);
  assert.equal(capHosts({ 'a.com': [1, 1] }, 4)['a.com'][0], 1);
});

test('capHosts keeps an existing other-hosts row in the fold', () => {
  const hosts = { 'a.com': [100, 1], 'b.com': [50, 1], 'c.com': [10, 1], [OTHER_HOSTS]: [1000, 9] };
  const capped = capHosts(hosts, 3);
  assert.deepEqual(capped, { 'a.com': [100, 1], 'b.com': [50, 1], [OTHER_HOSTS]: [1010, 10] });
});

test('mergeDay caps hosts per site', () => {
  const delta = { 'a.com': { r: 0, s: 0, n: 0, t: {} } };
  for (let i = 0; i < 70; i++) delta['a.com'].t[`x${i}.net`] = [i, 1];
  const m = mergeDay({}, delta, 60);
  assert.equal(Object.keys(m['a.com'].t).length, 60);
  assert.ok(m['a.com'].t[OTHER_HOSTS]);
});

test('mergePending restores a failed flush', () => {
  const into = {};
  addSample(into, { day: D1, site: 'a.com', rx: 1 });
  const from = {};
  addSample(from, { day: D1, site: 'a.com', rx: 2 });
  addSample(from, { day: D2, site: 'b.com', rx: 3 });
  mergePending(into, from);
  assert.equal(into[D1]['a.com'].r, 3);
  assert.equal(into[D2]['b.com'].r, 3);
});

test('dayTotals and totalsOf', () => {
  const p = sample();
  assert.deepEqual(dayTotals(p[D1]), { r: 1800, s: 110, n: 4 });
  assert.deepEqual(dayTotals(undefined), { r: 0, s: 0, n: 0 });
  assert.deepEqual(totalsOf(p), { r: 14800, s: 110, n: 6, sites: 3 });
});

test('filterDays and earliestDay', () => {
  const p = sample();
  assert.deepEqual(Object.keys(filterDays(p, { from: D2, to: D2 })), [D2]);
  assert.deepEqual(Object.keys(filterDays(p, { from: '2026-01-01', to: '2026-10-24' })), []);
  assert.equal(earliestDay(p), D1);
  assert.equal(earliestDay({}), null);
});

test('rollupSites totals, third-party counts and shares', () => {
  const rows = rollupSites(sample());
  assert.deepEqual(rows.map((r) => r.site), [BROWSER_SITE, 'news.co.uk', 'example.com']);
  const ex = rows.find((r) => r.site === 'example.com');
  assert.equal(ex.total, 1910);
  assert.equal(ex.tpCount, 2);
  const shareSum = rows.reduce((a, r) => a + r.share, 0);
  assert.ok(Math.abs(shareSum - 1) < 1e-9);
  assert.deepEqual(rollupSites({}), []);
});

test('rollupSites does not count the other-hosts row as a third party', () => {
  const days = { [D1]: { 'a.com': { r: 1, s: 0, n: 1, t: { 'x.net': [1, 1], [OTHER_HOSTS]: [5, 5] } } } };
  assert.equal(rollupSites(days)[0].tpCount, 1);
});

test('sortSites by each key, both directions, stable on name', () => {
  const rows = rollupSites(sample());
  assert.deepEqual(sortSites(rows, 'site', 'asc').map((r) => r.site), [BROWSER_SITE, 'example.com', 'news.co.uk']);
  assert.deepEqual(sortSites(rows, 'requests', 'desc').map((r) => r.site), ['example.com', BROWSER_SITE, 'news.co.uk']);
  assert.deepEqual(sortSites(rows, 'thirdParties', 'desc')[0].site, 'example.com');
  assert.deepEqual(sortSites(rows, 'total', 'asc').map((r) => r.site), ['example.com', 'news.co.uk', BROWSER_SITE]);
  // Unknown key falls back to total.
  assert.deepEqual(sortSites(rows, 'nope', 'desc')[0].site, BROWSER_SITE);
  // Ties sort by name.
  const tie = [{ site: 'b.com', total: 1 }, { site: 'a.com', total: 1 }];
  assert.deepEqual(sortSites(tie, 'total', 'desc').map((r) => r.site), ['a.com', 'b.com']);
});

test('searchSites matches site, label and host', () => {
  const rows = rollupSites(sample());
  assert.deepEqual(searchSites(rows, 'NEWS').map((r) => r.site), ['news.co.uk']);
  assert.deepEqual(searchSites(rows, 'tracker').map((r) => r.site), ['example.com']);
  assert.deepEqual(searchSites(rows, 'browser', displaySite).map((r) => r.site), [BROWSER_SITE]);
  assert.equal(searchSites(rows, '  ').length, 3);
});

test('dailySeries fills missing days and filters by site', () => {
  const p = sample();
  const all = dailySeries(p, { from: '2026-10-24', to: D2 });
  assert.deepEqual(all.map((x) => x.day), ['2026-10-24', D1, D2]);
  assert.deepEqual(all[0], { day: '2026-10-24', r: 0, s: 0, n: 0 });
  assert.equal(all[2].r, 13000);
  const one = dailySeries(p, { from: D1, to: D2 }, 'example.com');
  assert.deepEqual(one, [{ day: D1, r: 1800, s: 110, n: 4 }, { day: D2, r: 0, s: 0, n: 0 }]);
});

test('hostList and thirdPartyDomains', () => {
  const row = rollupSites(sample()).find((r) => r.site === 'example.com');
  assert.deepEqual(hostList(row).map((h) => h.host), ['cdn.tracker.net', 'ads.tracker.net']);
  const doms = thirdPartyDomains(row);
  assert.deepEqual(doms, [{ domain: 'tracker.net', r: 800, n: 3, hosts: ['cdn.tracker.net', 'ads.tracker.net'] }]);
  assert.deepEqual(thirdPartyDomains(undefined), []);
});

test('prunableKeys keeps 400 days including today', () => {
  const today = '2026-10-26';
  const keys = ['u:2025-09-21', 'u:2025-09-22', 'u:2026-10-26', 'settings', 'blocklist'];
  // 2025-09-22 is 399 days before 2026-10-26, so it is the oldest kept day.
  assert.deepEqual(prunableKeys(keys, today), ['u:2025-09-21']);
  assert.deepEqual(prunableKeys(keys, today, 1), ['u:2025-09-21', 'u:2025-09-22']);
});

test('daysFromStorage picks day records only', () => {
  const items = { 'u:2026-10-26': { 'a.com': { r: 1, s: 0, n: 1, t: {} } }, settings: {}, 'u:bad': null };
  assert.deepEqual(Object.keys(daysFromStorage(items)), ['2026-10-26']);
  assert.deepEqual(daysFromStorage(undefined), {});
});
