import { test } from 'node:test';
import assert from 'node:assert/strict';
import {
  addToList,
  buildRules,
  cleanList,
  domainsFromRules,
  isBlocked,
  MAX_BLOCKED,
  normalizeDomain,
  planUpdate,
  removeFromList,
} from '../src/lib/dnr.js';

test('normalizeDomain accepts domains in common shapes', () => {
  assert.deepEqual(normalizeDomain('Example.COM'), { ok: true, domain: 'example.com' });
  assert.deepEqual(normalizeDomain('  ads.example.com  '), { ok: true, domain: 'ads.example.com' });
  assert.deepEqual(normalizeDomain('*.doubleclick.net'), { ok: true, domain: 'doubleclick.net' });
  assert.deepEqual(normalizeDomain('.tracker.io'), { ok: true, domain: 'tracker.io' });
  assert.deepEqual(normalizeDomain('https://cdn.example.org/path?x=1'), { ok: true, domain: 'cdn.example.org' });
  assert.deepEqual(normalizeDomain('example.com:8080'), { ok: true, domain: 'example.com' });
  assert.deepEqual(normalizeDomain('example.com.'), { ok: true, domain: 'example.com' });
  assert.deepEqual(normalizeDomain('10.0.0.8'), { ok: true, domain: '10.0.0.8' });
  assert.deepEqual(normalizeDomain('xn--bcher-kva.example'), { ok: true, domain: 'xn--bcher-kva.example' });
});

test('normalizeDomain converts Unicode to punycode', () => {
  assert.deepEqual(normalizeDomain('bücher.de'), { ok: true, domain: 'xn--bcher-kva.de' });
});

test('normalizeDomain rejects bad input', () => {
  for (const bad of ['', '   ', 'localhost', 'exa mple.com', '-bad.com', 'bad-.com', 'a_b.com', 'http://user:pw@x.com', '[::1]', '1.2.3', 'foo.123', `${'a'.repeat(64)}.com`, `${'abc.'.repeat(64)}com`, null, 42]) {
    assert.equal(normalizeDomain(bad).ok, false, `should reject ${String(bad)}`);
  }
});

test('cleanList sorts, dedupes and drops invalid entries', () => {
  assert.deepEqual(cleanList(['b.com', 'A.com', 'a.com', 'nope', 7]), ['a.com', 'b.com']);
  assert.deepEqual(cleanList(undefined), []);
});

test('addToList and removeFromList', () => {
  const r = addToList(['b.com'], 'https://A.com/');
  assert.deepEqual(r, { ok: true, domain: 'a.com', list: ['a.com', 'b.com'] });
  assert.equal(addToList(['a.com'], 'A.com').ok, false);
  assert.equal(addToList([], 'x').ok, false);
  assert.deepEqual(removeFromList(['a.com', 'b.com'], 'a.com'), ['b.com']);
  assert.deepEqual(removeFromList(['a.com'], 'z.com'), ['a.com']);
});

test('addToList refuses a full list', () => {
  const full = Array.from({ length: MAX_BLOCKED }, (_, i) => `d${i}.com`);
  const r = addToList(full, 'one-more.com');
  assert.equal(r.ok, false);
  assert.match(r.error, /full/);
});

test('isBlocked matches the domain and subdomains only', () => {
  const list = ['tracker.net'];
  assert.equal(isBlocked(list, 'tracker.net'), true);
  assert.equal(isBlocked(list, 'a.b.tracker.net'), true);
  assert.equal(isBlocked(list, 'TRACKER.NET'), true);
  assert.equal(isBlocked(list, 'nottracker.net'), false);
  assert.equal(isBlocked(list, 'tracker.net.evil.com'), false);
  assert.equal(isBlocked(list, ''), false);
  assert.equal(isBlocked(undefined, 'a.com'), false);
});

test('buildRules makes one block rule per domain with ids from 1', () => {
  assert.deepEqual(buildRules(['b.com', 'a.com', 'a.com']), [
    { id: 1, priority: 1, action: { type: 'block' }, condition: { requestDomains: ['a.com'] } },
    { id: 2, priority: 1, action: { type: 'block' }, condition: { requestDomains: ['b.com'] } },
  ]);
  assert.deepEqual(buildRules([]), []);
});

test('planUpdate removes every existing rule and adds the new set', () => {
  const existing = [{ id: 1 }, { id: 7 }];
  const plan = planUpdate(existing, ['x.com']);
  assert.deepEqual(plan.removeRuleIds, [1, 7]);
  assert.equal(plan.addRules.length, 1);
  assert.deepEqual(planUpdate(undefined, []), { removeRuleIds: [], addRules: [] });
});

test('domainsFromRules reads block rules back', () => {
  const rules = [...buildRules(['a.com', 'b.com']), { id: 9, action: { type: 'allow' }, condition: { requestDomains: ['c.com'] } }];
  assert.deepEqual(domainsFromRules(rules), ['a.com', 'b.com']);
});
