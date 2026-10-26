import { test } from 'node:test';
import assert from 'node:assert/strict';
import {
  addDays,
  dateKey,
  daysBetween,
  isDateKey,
  periodRange,
  PERIODS,
  rangeKeys,
  retentionCutoff,
  shortDayLabel,
} from '../src/lib/dates.js';

test('dateKey uses the local calendar day', () => {
  assert.equal(dateKey(new Date(2026, 0, 5, 23, 59)), '2026-01-05');
  assert.equal(dateKey(new Date(2026, 11, 31, 0, 0).getTime()), '2026-12-31');
});

test('isDateKey', () => {
  assert.equal(isDateKey('2026-02-28'), true);
  assert.equal(isDateKey('2028-02-29'), true);
  assert.equal(isDateKey('2026-02-29'), false);
  assert.equal(isDateKey('2026-13-01'), false);
  assert.equal(isDateKey('26-1-1'), false);
  assert.equal(isDateKey(20260101), false);
});

test('addDays crosses months, years and leap days', () => {
  assert.equal(addDays('2026-10-26', 1), '2026-10-27');
  assert.equal(addDays('2026-10-31', 1), '2026-11-01');
  assert.equal(addDays('2026-12-31', 1), '2027-01-01');
  assert.equal(addDays('2028-03-01', -1), '2028-02-29');
  assert.equal(addDays('2026-03-29', 0), '2026-03-29');
  assert.equal(addDays('2026-01-01', -365), '2025-01-01');
});

test('daysBetween and rangeKeys', () => {
  assert.equal(daysBetween('2026-10-20', '2026-10-26'), 6);
  assert.equal(daysBetween('2026-10-26', '2026-10-20'), -6);
  assert.deepEqual(rangeKeys('2026-02-27', '2026-03-02'), ['2026-02-27', '2026-02-28', '2026-03-01', '2026-03-02']);
  assert.deepEqual(rangeKeys('2026-03-02', '2026-03-01'), []);
  assert.deepEqual(rangeKeys('2026-03-02', '2026-03-02'), ['2026-03-02']);
});

test('periodRange for every period', () => {
  const today = '2026-10-26';
  assert.deepEqual(periodRange('today', today), { from: today, to: today });
  assert.deepEqual(periodRange('7d', today), { from: '2026-10-20', to: today });
  assert.deepEqual(periodRange('30d', today), { from: '2026-09-27', to: today });
  assert.deepEqual(periodRange('month', today), { from: '2026-10-01', to: today });
  assert.deepEqual(periodRange('month', '2026-11-01'), { from: '2026-11-01', to: '2026-11-01' });
  assert.deepEqual(periodRange('all', today, '2025-12-01'), { from: '2025-12-01', to: today });
  assert.deepEqual(periodRange('all', today, null), { from: today, to: today });
  // Data dated in the future (clock change) does not flip the range.
  assert.deepEqual(periodRange('all', today, '2026-11-02'), { from: today, to: today });
  assert.throws(() => periodRange('year', today));
  assert.equal(rangeKeys(...Object.values(periodRange('7d', today))).length, 7);
  assert.equal(rangeKeys(...Object.values(periodRange('30d', today))).length, 30);
  assert.equal(PERIODS.length, 5);
});

test('retentionCutoff and labels', () => {
  assert.equal(retentionCutoff('2026-10-26', 400), '2025-09-22');
  assert.equal(retentionCutoff('2026-10-26', 1), '2026-10-26');
  assert.equal(shortDayLabel('2026-10-06'), '6 Oct');
  assert.equal(shortDayLabel('2026-01-31'), '31 Jan');
});
