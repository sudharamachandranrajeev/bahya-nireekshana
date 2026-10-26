import { test } from 'node:test';
import assert from 'node:assert/strict';
import { contentLength, headerValue, measureCompleted, requestBodySize } from '../src/lib/measure.js';

const headers = (obj) => Object.entries(obj).map(([name, value]) => ({ name, value }));

test('headerValue is case-insensitive and handles binaryValue', () => {
  assert.equal(headerValue(headers({ 'Content-Type': 'text/html' }), 'content-type'), 'text/html');
  assert.equal(headerValue([{ name: 'X-Bin', binaryValue: [104, 105] }], 'x-bin'), 'hi');
  assert.equal(headerValue([{ name: 'X-None' }], 'x-none'), null);
  assert.equal(headerValue(undefined, 'a'), null);
  assert.equal(headerValue(headers({ a: '1' }), 'b'), null);
});

test('contentLength parses only clean integers', () => {
  assert.equal(contentLength(headers({ 'content-length': '1234' })), 1234);
  assert.equal(contentLength(headers({ 'Content-Length': ' 0 ' })), 0);
  assert.equal(contentLength(headers({ 'content-length': '-5' })), null);
  assert.equal(contentLength(headers({ 'content-length': '12abc' })), null);
  assert.equal(contentLength(headers({ 'content-length': '1e5' })), null);
  assert.equal(contentLength(headers({ 'content-length': '99999999999999999999' })), null);
  assert.equal(contentLength([]), null);
});

test('requestBodySize: raw bytes and form data', () => {
  assert.equal(requestBodySize({ raw: [{ bytes: new ArrayBuffer(10) }, { bytes: new Uint8Array(5) }] }), 15);
  assert.equal(requestBodySize({ raw: [{ file: '/tmp/x' }, null] }), 0);
  // "q=abc" + "&" style overhead: key + 2 + value.
  assert.equal(requestBodySize({ formData: { q: ['abc'], tag: ['a', 'bb'] } }), 1 + 2 + 3 + (3 + 2 + 1) + (3 + 2 + 2));
  assert.equal(requestBodySize({ error: 'Unknown error.' }), 0);
  assert.equal(requestBodySize(undefined), 0);
});

test('measureCompleted: cached responses are skipped', () => {
  assert.deepEqual(measureCompleted({ fromCache: true, responseSize: 100 }, { exact: true }), { skip: true });
  assert.deepEqual(measureCompleted({ fromCache: true }), { skip: true });
  assert.deepEqual(measureCompleted(null), { skip: true });
});

test('measureCompleted: Firefox sizes are used when present', () => {
  const d = { fromCache: false, statusCode: 200, responseSize: 5000, requestSize: 700, responseHeaders: headers({ 'content-length': '4000' }) };
  assert.deepEqual(measureCompleted(d, { exact: true }), { skip: false, rx: 5000, tx: 700 });
});

test('measureCompleted: Firefox falls back to Content-Length and body', () => {
  const d = { statusCode: 200, responseHeaders: headers({ 'content-length': '4000' }) };
  assert.deepEqual(measureCompleted(d, { exact: true, bodyBytes: 12 }), { skip: false, rx: 4000, tx: 12 });
  const bad = { statusCode: 200, responseSize: NaN, requestSize: -1 };
  assert.deepEqual(measureCompleted(bad, { exact: true }), { skip: false, rx: 0, tx: 0 });
});

test('measureCompleted: Chrome estimate from Content-Length', () => {
  const d = { statusCode: 200, method: 'POST', responseHeaders: headers({ 'Content-Length': '2048' }), responseSize: 999 };
  assert.deepEqual(measureCompleted(d, { exact: false, bodyBytes: 300 }), { skip: false, rx: 2048, tx: 300 });
});

test('measureCompleted: no Content-Length counts the request with 0 bytes', () => {
  assert.deepEqual(measureCompleted({ statusCode: 200, responseHeaders: [] }), { skip: false, rx: 0, tx: 0 });
});

test('measureCompleted: 304, 204 and HEAD carry no body', () => {
  const cl = headers({ 'content-length': '50000' });
  assert.equal(measureCompleted({ statusCode: 304, responseHeaders: cl }).rx, 0);
  assert.equal(measureCompleted({ statusCode: 204, responseHeaders: cl }).rx, 0);
  assert.equal(measureCompleted({ statusCode: 200, method: 'head', responseHeaders: cl }).rx, 0);
});

test('measureCompleted: bad body sizes are ignored', () => {
  assert.equal(measureCompleted({ statusCode: 200 }, { bodyBytes: -4 }).tx, 0);
  assert.equal(measureCompleted({ statusCode: 200 }, { bodyBytes: Infinity }).tx, 0);
});
