import { api, isFirefox, measurement } from '../shim.js';
import { h, $, clear, downloadText } from '../ui/dom.js';
import { applyVars, initTheme, systemDark, themeState } from '../ui/theme-apply.js';
import { barChart } from '../ui/charts.js';
import { accessBanner } from '../ui/access.js';
import { dateKey, periodRange, PERIODS, PERIOD_LABELS, shortDayLabel } from '../lib/dates.js';
import { BROWSER_SITE, displaySite, registrableDomain } from '../lib/domain.js';
import {
  dailySeries,
  earliestDay,
  filterDays,
  hostList,
  DAY_PREFIX,
  OTHER_HOSTS,
  rollupSites,
  searchSites,
  sortSites,
  totalsOf,
} from '../lib/usage.js';
import { formatBytes, formatCount, formatPercent, parseBudgetMB } from '../lib/format.js';
import { isBlocked, normalizeDomain } from '../lib/dnr.js';
import { deriveVars, exportTheme, parseThemeImport, resolveMode } from '../lib/theme.js';
import { usageCsv, usageJson } from '../lib/csv.js';
import {
  ask,
  getBlocklist,
  getSettings,
  loadAllDays,
  saveCustomThemes,
  updateSettings,
  getCustomThemes,
} from '../platform/store.js';
import { blockDomain, ruleCount, unblockDomain } from '../platform/blocklist.js';

setTimeout(() => document.documentElement.classList.add('themed'), 400);

const state = {
  days: {},
  blocklist: [],
  period: '7d',
  search: '',
  sort: { key: 'total', dir: 'desc' },
  site: null,
  view: 'usage',
};

try {
  state.period = PERIODS.includes(localStorage.getItem('period')) ? localStorage.getItem('period') : '7d';
} catch {
  // Per-viewer preference only.
}

// Navigation --------------------------------------------------------------

const VIEWS = ['usage', 'blocklist', 'alerts', 'appearance', 'data'];

function showView() {
  const v = location.hash.slice(1);
  state.view = VIEWS.includes(v) ? v : 'usage';
  for (const name of VIEWS) $(`#view-${name}`).hidden = name !== state.view;
  for (const a of document.querySelectorAll('.tabs a')) {
    if (a.dataset.view === state.view) a.setAttribute('aria-current', 'page');
    else a.removeAttribute('aria-current');
  }
  renderView();
}

window.addEventListener('hashchange', showView);

function renderView() {
  if (state.view === 'usage') renderUsage();
  else if (state.view === 'blocklist') renderBlocklist();
  else if (state.view === 'alerts') renderAlerts();
  else if (state.view === 'appearance') renderAppearance();
  else if (state.view === 'data') renderData();
}

// Usage -------------------------------------------------------------------

function range() {
  return periodRange(state.period, dateKey(), earliestDay(state.days));
}

function renderPeriods() {
  const box = clear($('#periods'));
  for (const p of PERIODS) {
    box.append(
      h('button', {
        type: 'button',
        'aria-pressed': String(p === state.period),
        onclick: () => {
          state.period = p;
          try {
            localStorage.setItem('period', p);
          } catch {
            // Ignore.
          }
          renderUsage();
          if (state.site) openDrawer(state.site);
        },
      }, PERIOD_LABELS[p]),
    );
  }
}

function totalCard(value, caption, cls = '') {
  return h('div', { class: 'card' }, h('div', { class: `value num ${cls}` }, value), h('div', { class: 'caption' }, caption));
}

function splitBar(r, s, max) {
  const pct = (v) => `${max > 0 ? (v / max) * 100 : 0}%`;
  return h('div', { class: 'bar-track' }, h('div', { class: 'down', style: { width: pct(r) } }), h('div', { class: 'up', style: { width: pct(s) } }));
}

const COLUMNS = [
  { key: 'site', label: 'Site', dir: 'asc' },
  { key: 'total', label: 'Data', dir: 'desc' },
  { key: 'requests', label: 'Requests', dir: 'desc', right: true },
  { key: 'share', label: 'Share', dir: 'desc', right: true },
  { key: 'thirdParties', label: 'Third parties', dir: 'desc', right: true },
];

function renderUsage() {
  renderPeriods();
  const rng = range();
  const days = filterDays(state.days, rng);
  const totals = totalsOf(days);

  clear($('#totals')).append(
    totalCard(formatBytes(totals.r + totals.s), `Total, ${PERIOD_LABELS[state.period].toLowerCase()}`),
    totalCard(formatBytes(totals.r), 'Downloaded', 'down-text'),
    totalCard(formatBytes(totals.s), 'Uploaded', 'up-text'),
    totalCard(formatCount(totals.n), 'Requests'),
    totalCard(String(totals.sites), 'Sites'),
  );

  const series = dailySeries(state.days, rng);
  const { svg, max } = barChart(series, { width: 900, height: 190 });
  clear($('#chart')).append(svg);
  $('#chart-max').textContent = max > 0 ? `Top line ${formatBytes(max)}` : '';

  const all = rollupSites(days);
  const rows = sortSites(searchSites(all, state.search, displaySite), state.sort.key, state.sort.dir);
  $('#site-count').textContent = state.search ? `${rows.length} of ${all.length} sites` : `${all.length} sites`;
  const maxTotal = Math.max(0, ...all.map((r) => r.total));

  const head = h('tr', {});
  for (const c of COLUMNS) {
    const active = state.sort.key === c.key;
    head.append(
      h('th', {
        class: c.right ? 'r' : '',
        scope: 'col',
        'aria-sort': active ? (state.sort.dir === 'asc' ? 'ascending' : 'descending') : null,
      },
      h('button', {
        type: 'button',
        onclick: () => {
          state.sort = active ? { key: c.key, dir: state.sort.dir === 'asc' ? 'desc' : 'asc' } : { key: c.key, dir: c.dir };
          renderUsage();
        },
      }, c.label)),
    );
  }
  const body = h('tbody', {});
  for (const r of rows) {
    body.append(
      h('tr', {
        tabindex: '0',
        onclick: () => openDrawer(r.site),
        onkeydown: (e) => {
          if (e.key === 'Enter' || e.key === ' ') {
            e.preventDefault();
            openDrawer(r.site);
          }
        },
      },
      h('td', { class: 'site-cell', title: displaySite(r.site) }, displaySite(r.site)),
      h('td', { class: 'data-cell' }, h('span', { class: 'num' }, formatBytes(r.total)), h('span', { class: 'muted small num' }, `  ${formatBytes(r.r)} down, ${formatBytes(r.s)} up`), splitBar(r.r, r.s, maxTotal)),
      h('td', { class: 'r num' }, formatCount(r.n)),
      h('td', { class: 'r num' }, formatPercent(r.share)),
      h('td', { class: 'r num' }, r.site === BROWSER_SITE ? '' : String(r.tpCount))),
    );
  }
  if (!rows.length) {
    body.append(h('tr', {}, h('td', { class: 'empty', colspan: COLUMNS.length }, state.search ? 'No sites match.' : 'No data for this period yet.')));
  }
  clear($('#sites')).append(h('thead', {}, head), body);
}

$('#search').addEventListener('input', (e) => {
  state.search = e.target.value;
  renderUsage();
});

// Site drawer -------------------------------------------------------------

function closeDrawer() {
  state.site = null;
  $('#drawer').hidden = true;
  $('#drawer-backdrop').hidden = true;
}

$('#drawer-backdrop').addEventListener('click', closeDrawer);
document.addEventListener('keydown', (e) => {
  if (e.key === 'Escape' && state.site) closeDrawer();
});

function openDrawer(site) {
  const wasOpen = !!state.site;
  state.site = site;
  const rng = range();
  const row = rollupSites(filterDays(state.days, rng)).find((r) => r.site === site) ?? { r: 0, s: 0, n: 0, total: 0, hosts: {} };
  const series = dailySeries(state.days, rng, site);
  const hosts = hostList(row);
  const drawer = clear($('#drawer'));

  const hostTable = h('table', { class: 'table' });
  hostTable.append(h('thead', {}, h('tr', {}, h('th', {}, 'Host'), h('th', { class: 'r' }, 'Data'), h('th', { class: 'r' }, 'Requests'), h('th', {}, ''))));
  const tb = h('tbody', {});
  for (const x of hosts) {
    const domain = x.host === OTHER_HOSTS ? null : registrableDomain(x.host);
    let action = '';
    if (domain) {
      action = isBlocked(state.blocklist, x.host)
        ? h('span', { class: 'muted small' }, 'Blocked')
        : h('button', {
            class: 'small',
            type: 'button',
            title: `Block ${domain} and its subdomains everywhere`,
            onclick: async (e) => {
              e.target.disabled = true;
              await blockDomain(domain);
              state.blocklist = await getBlocklist();
              openDrawer(site);
            },
          }, `Block ${domain}`);
    }
    tb.append(h('tr', {}, h('td', { class: 'site-cell', title: x.host }, x.host), h('td', { class: 'r num' }, formatBytes(x.r)), h('td', { class: 'r num' }, formatCount(x.n)), h('td', { class: 'r' }, action)));
  }
  hostTable.append(tb);

  drawer.append(
    h('div', { class: 'head' },
      h('div', {}, h('h2', { id: 'drawer-title' }, displaySite(site)), h('p', { class: 'muted small' }, `${PERIOD_LABELS[state.period]}, ${shortDayLabel(rng.from)} to ${shortDayLabel(rng.to)}`)),
      h('button', { type: 'button', id: 'drawer-close', onclick: closeDrawer }, 'Close')),
    h('div', { class: 'mini' },
      h('div', { class: 'card' }, h('b', { class: 'num down-text' }, formatBytes(row.r)), h('span', {}, 'Downloaded')),
      h('div', { class: 'card' }, h('b', { class: 'num up-text' }, formatBytes(row.s)), h('span', {}, 'Uploaded')),
      h('div', { class: 'card' }, h('b', { class: 'num' }, formatCount(row.n)), h('span', {}, 'Requests'))),
    h('section', { class: 'card' }, h('h2', {}, 'Per day'), barChart(series, { width: 480, height: 150 }).svg),
    site === BROWSER_SITE
      ? h('p', { class: 'muted' }, 'Requests that do not come from a web page: other extensions, browser updates and similar.')
      : h('section', { class: 'card' },
          h('h2', {}, `Third-party hosts (${row.tpCount ?? 0})`),
          h('p', { class: 'muted small' }, 'Hosts on other domains that this site loaded. Blocking applies everywhere.'),
          hosts.length ? h('div', { class: 'table-wrap' }, hostTable) : h('p', { class: 'muted' }, 'None in this period.')),
  );
  $('#drawer').hidden = false;
  $('#drawer-backdrop').hidden = false;
  if (!wasOpen) $('#drawer-close').focus();
}

// Blocklist ---------------------------------------------------------------

async function renderBlocklist() {
  state.blocklist = await getBlocklist();
  let rules = 0;
  try {
    rules = await ruleCount();
  } catch {
    rules = 0;
  }
  const n = state.blocklist.length;
  $('#block-count').textContent = `${n} ${n === 1 ? 'domain' : 'domains'}, ${rules} ${rules === 1 ? 'rule' : 'rules'} active.`;
  const list = clear($('#block-list'));
  for (const d of state.blocklist) {
    list.append(
      h('li', {}, h('span', {}, d), h('button', {
        class: 'small',
        type: 'button',
        onclick: async () => {
          await unblockDomain(d);
          renderBlocklist();
        },
      }, 'Remove')),
    );
  }
  if (!n) list.append(h('li', { class: 'muted' }, 'Nothing blocked.'));
}

$('#block-form').addEventListener('submit', async (e) => {
  e.preventDefault();
  const input = $('#block-input');
  const r = await blockDomain(input.value);
  $('#block-error').textContent = r.ok ? '' : r.error;
  if (r.ok) input.value = '';
  renderBlocklist();
});

// Alerts ------------------------------------------------------------------

async function renderAlerts() {
  const settings = await getSettings();
  $('#browser-budget').value = settings.browserBudgetMB ?? '';
  const list = clear($('#site-budget-list'));
  const entries = Object.entries(settings.siteBudgets).sort(([a], [b]) => (a < b ? -1 : 1));
  for (const [site, mb] of entries) {
    list.append(
      h('li', {}, h('span', {}, `${displaySite(site)}: `, h('span', { class: 'num' }, `${mb} MB`), ' per day'), h('button', {
        class: 'small',
        type: 'button',
        onclick: async () => {
          const s = await getSettings();
          delete s.siteBudgets[site];
          await updateSettings({ siteBudgets: s.siteBudgets });
          renderAlerts();
        },
      }, 'Remove')),
    );
  }
  if (!entries.length) list.append(h('li', { class: 'muted' }, 'No site budgets.'));
}

$('#browser-budget-form').addEventListener('submit', async (e) => {
  e.preventDefault();
  const v = parseBudgetMB($('#browser-budget').value);
  const msg = $('#browser-budget-msg');
  if (v === undefined) {
    msg.className = 'small error';
    msg.textContent = 'Enter a number of megabytes, or leave it empty.';
    return;
  }
  await updateSettings({ browserBudgetMB: v });
  msg.className = 'small muted';
  msg.textContent = v === null ? 'Browser budget is off.' : `Saved. You will get a notification after ${v} MB in a day.`;
});

$('#site-budget-form').addEventListener('submit', async (e) => {
  e.preventDefault();
  const err = $('#site-budget-error');
  const raw = $('#site-budget-site').value;
  const d = normalizeDomain(raw);
  if (!d.ok) {
    err.textContent = d.error;
    return;
  }
  const mb = parseBudgetMB($('#site-budget-mb').value);
  if (!mb) {
    err.textContent = 'Enter a budget in megabytes.';
    return;
  }
  const site = registrableDomain(d.domain);
  const s = await getSettings();
  s.siteBudgets[site] = mb;
  await updateSettings({ siteBudgets: s.siteBudgets });
  err.textContent = '';
  $('#site-budget-site').value = '';
  $('#site-budget-mb').value = '';
  renderAlerts();
});

// Appearance --------------------------------------------------------------

async function renderAppearance() {
  const ts = await themeState();
  const modes = clear($('#modes'));
  for (const [m, label] of [['system', 'System'], ['light', 'Light'], ['dark', 'Dark']]) {
    modes.append(h('button', { type: 'button', 'aria-pressed': String(ts.settings.mode === m), onclick: () => updateSettings({ mode: m }) }, label));
  }
  const mode = resolveMode(ts.settings.mode, systemDark());
  const grid = clear($('#theme-grid'));
  const customIds = new Set(ts.custom.map((t) => t.id));
  const all = [...ts.builtins, ...ts.custom.filter((t) => !ts.builtins.some((b) => b.id === t.id))];
  for (const theme of all) {
    const card = h('div', { class: `theme-card${ts.theme?.id === theme.id ? ' selected' : ''}` });
    applyVars(card, deriveVars(theme, mode));
    card.append(
      h('button', {
        class: 'pick',
        type: 'button',
        'aria-pressed': String(ts.theme?.id === theme.id),
        onclick: () => updateSettings({ themeId: theme.id }),
      },
      h('div', { class: 'swatch' },
        h('div', { class: 'bars' }, ...[5, 8, 4, 9, 6, 7].map((v, i) => h('span', { class: i % 2 ? 'u' : 'd', style: { height: `${v * 10}%` } }))),
        h('div', { class: 'chips' }, h('span', { class: 'chip p' }), h('span', { class: 'chip a' }), h('span', { class: 'aa' }, 'Aa'))),
      h('div', { class: 'tname' }, theme.name, h('span', { class: 'tag' }, customIds.has(theme.id) ? 'Imported' : theme.font === 'mono' ? 'Mono' : ''))),
    );
    if (customIds.has(theme.id)) {
      card.append(
        h('button', {
          class: 'del small',
          type: 'button',
          title: `Delete ${theme.name}`,
          onclick: async () => {
            const custom = (await getCustomThemes()).filter((t) => t.id !== theme.id);
            await saveCustomThemes(custom);
            const s = await getSettings();
            if (s.themeId === theme.id) await updateSettings({ themeId: ts.builtins[0]?.id ?? 'radar' });
          },
        }, 'Delete'),
      );
    }
    grid.append(card);
  }
}

async function importTheme(text) {
  const errors = clear($('#theme-errors'));
  const r = parseThemeImport(text);
  if (!r.ok) {
    for (const e of r.errors) errors.append(h('li', {}, e));
    return;
  }
  const ts = await themeState();
  if (ts.builtins.some((b) => b.id === r.theme.id)) {
    errors.append(h('li', {}, `The id "${r.theme.id}" belongs to a built-in theme. Change the id and try again.`));
    return;
  }
  const custom = (await getCustomThemes()).filter((t) => t.id !== r.theme.id);
  custom.push(r.theme);
  await saveCustomThemes(custom);
  await updateSettings({ themeId: r.theme.id });
  $('#theme-text').value = '';
}

$('#theme-import').addEventListener('click', () => importTheme($('#theme-text').value));
$('#theme-file').addEventListener('change', async (e) => {
  const file = e.target.files?.[0];
  e.target.value = '';
  if (!file) return;
  if (file.size > 20000) {
    clear($('#theme-errors')).append(h('li', {}, 'That file is too large to be a theme.'));
    return;
  }
  const text = await file.text();
  $('#theme-text').value = text;
  importTheme(text);
});
$('#export-theme').addEventListener('click', async () => {
  const { theme } = await themeState();
  if (theme) downloadText(`${theme.id}.nireekshana-theme.json`, exportTheme(theme));
});

// Data --------------------------------------------------------------------

function renderData() {
  const keys = Object.keys(state.days).sort();
  const t = totalsOf(state.days);
  $('#data-summary').textContent = keys.length
    ? `${keys.length} days from ${keys[0]} to ${keys.at(-1)}. ${formatBytes(t.r + t.s)} across ${t.sites} sites. History older than 400 days is removed.`
    : 'No usage data yet.';
  renderClear(false);
}

function renderClear(confirming) {
  const area = clear($('#clear-area'));
  if (!confirming) {
    area.append(h('button', { class: 'danger', type: 'button', onclick: () => renderClear(true) }, 'Clear all usage data'));
    return;
  }
  area.append(
    h('span', {}, 'This cannot be undone.'),
    h('button', {
      class: 'danger solid',
      type: 'button',
      onclick: async () => {
        await ask({ type: 'clear' }, 5000);
        state.days = await loadAllDays();
        renderData();
      },
    }, 'Yes, delete everything'),
    h('button', { type: 'button', onclick: () => renderClear(false) }, 'Cancel'),
  );
}

function stamp() {
  return dateKey();
}

$('#export-json').addEventListener('click', () => {
  const data = usageJson(state.days, { measurement, version: api.runtime.getManifest().version });
  downloadText(`nireekshana-usage-${stamp()}.json`, `${JSON.stringify(data, null, 2)}\n`);
});
$('#export-csv').addEventListener('click', () => {
  downloadText(`nireekshana-usage-${stamp()}.csv`, usageCsv(state.days), 'text/csv');
});

// Start -------------------------------------------------------------------

$('#measure-note').textContent = isFirefox
  ? 'Sizes come from Firefox and include headers. Cached responses are not counted.'
  : 'These numbers are estimates. Chrome does not report transfer sizes, so received data comes from the Content-Length header and sent data from request bodies. Cached responses are not counted.';

let reloadTimer = null;
api.storage.onChanged.addListener((changes, area) => {
  if (area !== 'local') return;
  const keys = Object.keys(changes);
  if (keys.some((k) => k.startsWith(DAY_PREFIX))) {
    clearTimeout(reloadTimer);
    reloadTimer = setTimeout(async () => {
      state.days = await loadAllDays();
      if (state.view === 'usage') {
        renderUsage();
        if (state.site) openDrawer(state.site);
      } else if (state.view === 'data') renderData();
    }, 1000);
  }
  if (changes.blocklist) {
    getBlocklist().then((list) => {
      state.blocklist = list;
      if (state.view === 'blocklist') renderBlocklist();
    });
  }
  if (changes.settings && state.view === 'alerts') renderAlerts();
});

async function start() {
  await initTheme(() => {
    if (state.view === 'appearance') renderAppearance();
  }).catch(() => document.documentElement.classList.add('themed'));
  accessBanner($('#access'));
  await ask({ type: 'flush' }, 1500);
  [state.days, state.blocklist] = await Promise.all([loadAllDays(), getBlocklist()]);
  showView();
}

start();
