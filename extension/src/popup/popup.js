import { api, isFirefox } from '../shim.js';
import { h, $, clear } from '../ui/dom.js';
import { initTheme } from '../ui/theme-apply.js';
import { sparkline } from '../ui/charts.js';
import { addDays, dateKey, rangeKeys } from '../lib/dates.js';
import { displaySite, siteForUrl } from '../lib/domain.js';
import { dailySeries, dayTotals, filterDays, rollupSites, thirdPartyDomains } from '../lib/usage.js';
import { formatBytes, formatCount } from '../lib/format.js';
import { isBlocked } from '../lib/dnr.js';
import { ask, getBlocklist, loadDays } from '../platform/store.js';
import { blockDomain } from '../platform/blocklist.js';
import { accessBanner } from '../ui/access.js';

setTimeout(() => document.documentElement.classList.add('themed'), 400);
initTheme().catch(() => document.documentElement.classList.add('themed'));

$('#open-dashboard').addEventListener('click', () => {
  api.runtime.openOptionsPage();
  window.close();
});

accessBanner($('#access'));

async function currentSite() {
  try {
    const [tab] = await api.tabs.query({ active: true, currentWindow: true });
    return siteForUrl(tab?.url);
  } catch {
    return null;
  }
}

function splitBar(r, s, max) {
  const pct = (v) => `${max > 0 ? (v / max) * 100 : 0}%`;
  return h('div', { class: 'bar-track' }, h('div', { class: 'down', style: { width: pct(r) } }), h('div', { class: 'up', style: { width: pct(s) } }));
}

function todayCard(today) {
  const t = dayTotals(today);
  return h(
    'section',
    { class: 'card today' },
    h('div', { class: 'label' }, 'Today in this browser'),
    h('div', { class: 'big num' }, formatBytes(t.r + t.s)),
    h(
      'div',
      { class: 'split' },
      h('span', {}, h('span', { class: 'dot down' }), ' ', h('span', { class: 'num' }, formatBytes(t.r)), ' down'),
      h('span', {}, h('span', { class: 'dot up' }), ' ', h('span', { class: 'num' }, formatBytes(t.s)), ' up'),
      h('span', { class: 'muted' }, h('span', { class: 'num' }, formatCount(t.n)), ' requests'),
    ),
  );
}

function siteCard(site, days, todayKey, blocklist, rerender) {
  const todayRow = rollupSites(filterDays(days, { from: todayKey, to: todayKey })).find((r) => r.site === site);
  const weekRow = rollupSites(filterDays(days, { from: addDays(todayKey, -6), to: todayKey })).find((r) => r.site === site);
  const domains = thirdPartyDomains(todayRow);
  const list = h('ul', { class: 'tp-list' });
  for (const d of domains.slice(0, 6)) {
    const blocked = isBlocked(blocklist, d.domain);
    const button = blocked
      ? h('span', { class: 'blocked' }, 'Blocked')
      : h('button', {
          class: 'small',
          title: `Block ${d.domain} and its subdomains everywhere`,
          onclick: async (e) => {
            e.target.disabled = true;
            const r = await blockDomain(d.domain);
            if (!r.ok) e.target.title = r.error;
            rerender();
          },
        }, 'Block');
    list.append(h('li', {}, h('span', { class: 'host', title: d.hosts.join(', ') }, d.domain), h('span', { class: 'size num' }, formatBytes(d.r)), button));
  }
  return h(
    'section',
    { class: 'card site' },
    h('div', { class: 'label' }, 'This site'),
    h('div', { class: 'name' }, displaySite(site)),
    h(
      'div',
      { class: 'stats' },
      h('div', {}, h('b', { class: 'num' }, formatBytes(todayRow ? todayRow.total : 0)), h('span', {}, 'Today')),
      h('div', {}, h('b', { class: 'num' }, formatBytes(weekRow ? weekRow.total : 0)), h('span', {}, '7 days')),
      h('div', {}, h('b', { class: 'num' }, String(todayRow ? todayRow.tpCount : 0)), h('span', {}, 'Third parties')),
    ),
    domains.length ? list : h('p', { class: 'muted small' }, 'No third-party requests today.'),
    domains.length > 6 ? h('p', { class: 'muted small' }, `${domains.length - 6} more in the dashboard.`) : null,
  );
}

function topSitesCard(todayKey, today) {
  const rows = rollupSites({ [todayKey]: today }).slice(0, 6);
  const max = rows[0]?.total ?? 0;
  const list = h('ul', { class: 'top-sites' });
  for (const r of rows) {
    list.append(
      h('li', {}, h('div', { class: 'row' }, h('span', {}, displaySite(r.site)), h('span', { class: 'num muted' }, formatBytes(r.total))), splitBar(r.r, r.s, max)),
    );
  }
  return h('section', { class: 'card' }, h('div', { class: 'label' }, 'Top sites today'), rows.length ? list : h('p', { class: 'muted small' }, 'Nothing yet today.'));
}

function trendCard(days, todayKey) {
  const from = addDays(todayKey, -13);
  const series = dailySeries(days, { from, to: todayKey });
  const total = series.reduce((a, p) => a + p.r + p.s, 0);
  return h(
    'section',
    { class: 'card' },
    h('div', { class: 'label' }, 'Last 14 days'),
    sparkline(series.map((p) => p.r + p.s), { width: 320, height: 44 }),
    h('div', { class: 'spark-meta' }, h('span', {}, '14 days ago'), h('span', { class: 'num' }, `${formatBytes(total)} in total`), h('span', {}, 'Today')),
  );
}

async function render() {
  await ask({ type: 'flush' }, 800);
  const todayKey = dateKey();
  const [days, site, blocklist] = await Promise.all([
    loadDays(rangeKeys(addDays(todayKey, -13), todayKey)),
    currentSite(),
    getBlocklist(),
  ]);
  const today = days[todayKey] || {};
  const main = clear($('#main'));
  main.append(todayCard(today));
  if (site) main.append(siteCard(site, days, todayKey, blocklist, render));
  main.append(topSitesCard(todayKey, today), trendCard(days, todayKey));
  main.append(
    h(
      'p',
      { class: 'foot muted' },
      isFirefox
        ? 'Sizes are reported by Firefox. Cached responses are not counted.'
        : 'Estimates. Chrome does not report exact sizes, so these come from the Content-Length header.',
    ),
  );
}

render();
