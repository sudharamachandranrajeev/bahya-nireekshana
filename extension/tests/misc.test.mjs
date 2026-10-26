import { test } from 'node:test';
import assert from 'node:assert/strict';
import { formatBytes, formatCount, formatPercent, MB, parseBudgetMB } from '../src/lib/format.js';
import { escapeCell, toCsv, usageCsv, usageJson } from '../src/lib/csv.js';
import { checkBudgets } from '../src/lib/alerts.js';
import { barLayout, niceBytesMax, niceMax, sparkPoints } from '../src/lib/chart.js';
import { BROWSER_SITE } from '../src/lib/domain.js';
import { OTHER_HOSTS } from '../src/lib/usage.js';

test('formatBytes', () => {
  assert.equal(formatBytes(0), '0 B');
  assert.equal(formatBytes(-1), '0 B');
  assert.equal(formatBytes(NaN), '0 B');
  assert.equal(formatBytes('x'), '0 B');
  assert.equal(formatBytes(512), '512 B');
  assert.equal(formatBytes(1023), '1023 B');
  assert.equal(formatBytes(1024), '1.0 KB');
  assert.equal(formatBytes(1536), '1.5 KB');
  assert.equal(formatBytes(150 * 1024), '150 KB');
  assert.equal(formatBytes(5 * MB), '5.0 MB');
  assert.equal(formatBytes(3.25 * 1024 ** 3), '3.3 GB');
  assert.equal(formatBytes(2 * 1024 ** 6), '2048 PB');
});

test('formatCount and formatPercent', () => {
  assert.equal(formatCount(0), '0');
  assert.equal(formatCount(999), '999');
  assert.equal(formatCount(1234), '1.2k');
  assert.equal(formatCount(45678), '46k');
  assert.equal(formatCount(2500000), '2.5M');
  assert.equal(formatCount(25000000), '25M');
  assert.equal(formatPercent(0), '0%');
  assert.equal(formatPercent(0.004), '<1%');
  assert.equal(formatPercent(0.126), '13%');
  assert.equal(formatPercent(1), '100%');
});

test('parseBudgetMB', () => {
  assert.equal(parseBudgetMB(''), null);
  assert.equal(parseBudgetMB('0'), null);
  assert.equal(parseBudgetMB(' 500 '), 500);
  assert.equal(parseBudgetMB('1.256'), 1.26);
  assert.equal(parseBudgetMB(undefined), null);
  assert.equal(parseBudgetMB('-5'), undefined);
  assert.equal(parseBudgetMB('5MB'), undefined);
  assert.equal(parseBudgetMB('1e3'), undefined);
  assert.equal(parseBudgetMB('99999999'), undefined);
});

test('escapeCell quotes and defuses formulas', () => {
  assert.equal(escapeCell('plain'), 'plain');
  assert.equal(escapeCell('a,b'), '"a,b"');
  assert.equal(escapeCell('say "hi"'), '"say ""hi"""');
  assert.equal(escapeCell('line\nbreak'), '"line\nbreak"');
  assert.equal(escapeCell('=1+1'), "'=1+1");
  assert.equal(escapeCell('@cmd'), "'@cmd");
  assert.equal(escapeCell('-2'), "'-2");
  assert.equal(escapeCell(null), '');
  assert.equal(escapeCell(42), '42');
  assert.equal(toCsv(['a', 'b'], [[1, 'x,y']]), 'a,b\r\n1,"x,y"\r\n');
});

const days = {
  '2026-10-26': {
    'small.com': { r: 10, s: 0, n: 1, t: {} },
    'big.com': { r: 900, s: 100, n: 3, t: { 'cdn.x.net': [500, 2], [OTHER_HOSTS]: [10, 1] } },
  },
  '2026-10-25': { [BROWSER_SITE]: { r: 5, s: 1, n: 2, t: {} } },
};

test('usageCsv orders by day then size and counts third parties', () => {
  const lines = usageCsv(days).trim().split('\r\n');
  assert.deepEqual(lines, [
    'date,site,received_bytes,sent_bytes,requests,third_party_hosts',
    '2026-10-25,Browser & extensions,5,1,2,0',
    '2026-10-26,big.com,900,100,3,1',
    '2026-10-26,small.com,10,0,1,0',
  ]);
  assert.equal(usageCsv({}), 'date,site,received_bytes,sent_bytes,requests,third_party_hosts\r\n');
});

test('usageJson uses readable names', () => {
  const j = usageJson(days, { exportedAt: '2026-10-26T00:00:00.000Z', measurement: 'measured', version: '0.1.0' });
  assert.equal(j.format, 'nireekshana-usage');
  assert.equal(j.measurement, 'measured');
  assert.deepEqual(Object.keys(j.days), ['2026-10-25', '2026-10-26']);
  assert.deepEqual(j.days['2026-10-26']['big.com'].thirdParties['cdn.x.net'], { receivedBytes: 500, requests: 2 });
  assert.ok(j.days['2026-10-25']['Browser & extensions']);
});

test('checkBudgets fires once per day per budget', () => {
  const record = { 'a.com': { r: 3 * MB, s: 0 }, 'b.com': { r: 1 * MB, s: 0.5 * MB } };
  const budgets = { browserMB: 4, sites: { 'a.com': 2, 'b.com': 10, 'c.com': 1 } };
  const first = checkBudgets({ day: 'D', record, budgets, alerted: null });
  assert.deepEqual(first.fire.map((f) => f.kind + ':' + f.site), ['browser:null', 'site:a.com']);
  assert.equal(first.fire[0].used, 4.5 * MB);
  assert.deepEqual(first.alerted, { day: 'D', browser: true, sites: ['a.com'] });
  assert.equal(first.changed, true);

  const again = checkBudgets({ day: 'D', record, budgets, alerted: first.alerted });
  assert.deepEqual(again.fire, []);
  assert.equal(again.changed, false);

  const nextDay = checkBudgets({ day: 'E', record, budgets, alerted: first.alerted });
  assert.equal(nextDay.fire.length, 2);
});

test('checkBudgets ignores budgets that are off or not reached', () => {
  const record = { 'a.com': { r: 10, s: 0 } };
  const r = checkBudgets({ day: 'D', record, budgets: { browserMB: null, sites: { 'a.com': 0, 'b.com': 1 } }, alerted: { day: 'D', browser: false, sites: [] } });
  assert.deepEqual(r.fire, []);
  assert.equal(r.changed, false);
  assert.deepEqual(checkBudgets({ day: 'D', record: undefined, budgets: undefined, alerted: null }).fire, []);
});

test('niceMax', () => {
  assert.equal(niceMax(0), 0);
  assert.equal(niceMax(-3), 0);
  assert.equal(niceMax(7), 10);
  assert.equal(niceMax(1), 1);
  assert.equal(niceMax(1.5), 2);
  assert.equal(niceMax(23), 25);
  assert.equal(niceMax(420), 500);
  assert.equal(niceMax(5001), 10000);
});

test('niceBytesMax rounds within binary units', () => {
  assert.equal(niceBytesMax(0), 0);
  assert.equal(niceBytesMax(700), 1000);
  assert.equal(niceBytesMax(70.7 * 1024), 100 * 1024);
  assert.equal(niceBytesMax(3 * MB), 5 * MB);
  assert.equal(niceBytesMax(1024), 1024);
});

test('barLayout stacks upload on download', () => {
  const series = [{ day: 'a', r: 50, s: 50 }, { day: 'b', r: 0, s: 0 }];
  const bars = barLayout(series, { width: 100, height: 100, gap: 0 });
  assert.equal(bars.length, 2);
  assert.deepEqual(bars[0].down, { y: 50, h: 50 });
  assert.deepEqual(bars[0].up, { y: 0, h: 50 });
  assert.equal(bars[1].down.h, 0);
  assert.equal(bars[1].x, 50);
  assert.deepEqual(barLayout([], { width: 1, height: 1 }), []);
  const scaled = barLayout([{ day: 'a', r: 10, s: 0 }], { width: 10, height: 100, max: 100 });
  assert.equal(scaled[0].down.h, 10);
});

test('sparkPoints', () => {
  assert.equal(sparkPoints([], 100, 10), '');
  assert.equal(sparkPoints([0, 0], 100, 10, 0), '0,10 100,10');
  assert.equal(sparkPoints([0, 5, 10], 100, 10, 0), '0,10 50,5 100,0');
  assert.equal(sparkPoints([3], 100, 10, 0), '0,0');
});
