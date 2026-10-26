import { test } from 'node:test';
import assert from 'node:assert/strict';
import {
  BROWSER_SITE,
  displaySite,
  hostFromUrl,
  isIpAddress,
  isThirdParty,
  registrableDomain,
  siteForUrl,
} from '../src/lib/domain.js';

test('registrableDomain: plain domains', () => {
  assert.equal(registrableDomain('example.com'), 'example.com');
  assert.equal(registrableDomain('www.example.com'), 'example.com');
  assert.equal(registrableDomain('a.b.c.example.com'), 'example.com');
  assert.equal(registrableDomain('WWW.Example.COM'), 'example.com');
  assert.equal(registrableDomain('example.com.'), 'example.com');
});

test('registrableDomain: multi-part suffixes', () => {
  assert.equal(registrableDomain('www.bbc.co.uk'), 'bbc.co.uk');
  assert.equal(registrableDomain('bbc.co.uk'), 'bbc.co.uk');
  assert.equal(registrableDomain('news.gov.uk'), 'news.gov.uk');
  assert.equal(registrableDomain('x.y.abc.com.au'), 'abc.com.au');
  assert.equal(registrableDomain('shop.flipkart.co.in'), 'flipkart.co.in');
  assert.equal(registrableDomain('m.yahoo.co.jp'), 'yahoo.co.jp');
  assert.equal(registrableDomain('www.globo.com.br'), 'globo.com.br');
  assert.equal(registrableDomain('user.github.io'), 'user.github.io');
  assert.equal(registrableDomain('deep.user.github.io'), 'user.github.io');
});

test('registrableDomain: a bare suffix stays as is', () => {
  assert.equal(registrableDomain('co.uk'), 'co.uk');
});

test('registrableDomain: IPs, localhost and junk', () => {
  assert.equal(registrableDomain('192.168.1.10'), '192.168.1.10');
  assert.equal(registrableDomain('[::1]'), '[::1]');
  assert.equal(registrableDomain('localhost'), 'localhost');
  assert.equal(registrableDomain('intranet'), 'intranet');
  assert.equal(registrableDomain(''), null);
  assert.equal(registrableDomain(null), null);
  assert.equal(registrableDomain('a..b.com'), 'a..b.com');
  // Not a valid IPv4: treated as a name.
  assert.equal(registrableDomain('1.2.3.999'), '3.999');
});

test('isIpAddress', () => {
  assert.equal(isIpAddress('10.0.0.1'), true);
  assert.equal(isIpAddress('[2001:db8::1]'), true);
  assert.equal(isIpAddress('256.1.1.1'), false);
  assert.equal(isIpAddress('example.com'), false);
  assert.equal(isIpAddress(undefined), false);
});

test('hostFromUrl only accepts web schemes', () => {
  assert.equal(hostFromUrl('https://Sub.Example.com:8443/a?b#c'), 'sub.example.com');
  assert.equal(hostFromUrl('wss://live.example.com/socket'), 'live.example.com');
  assert.equal(hostFromUrl('http://[::1]:8080/'), '[::1]');
  assert.equal(hostFromUrl('chrome-extension://abc/popup.html'), null);
  assert.equal(hostFromUrl('moz-extension://abc/popup.html'), null);
  assert.equal(hostFromUrl('about:blank'), null);
  assert.equal(hostFromUrl('data:text/plain,hi'), null);
  assert.equal(hostFromUrl('file:///etc/hosts'), null);
  assert.equal(hostFromUrl('not a url'), null);
  assert.equal(hostFromUrl(''), null);
  assert.equal(hostFromUrl(undefined), null);
});

test('siteForUrl', () => {
  assert.equal(siteForUrl('https://www.theguardian.co.uk/news'), 'theguardian.co.uk');
  assert.equal(siteForUrl('http://localhost:3000/'), 'localhost');
  assert.equal(siteForUrl('chrome://newtab'), null);
});

test('isThirdParty', () => {
  assert.equal(isThirdParty('cdn.example.com', 'example.com'), false);
  assert.equal(isThirdParty('example.com', 'example.com'), false);
  assert.equal(isThirdParty('www.google-analytics.com', 'example.com'), true);
  assert.equal(isThirdParty('static.bbc.co.uk', 'bbc.co.uk'), false);
  assert.equal(isThirdParty('other.co.uk', 'bbc.co.uk'), true);
  assert.equal(isThirdParty('anything.com', BROWSER_SITE), false);
  assert.equal(isThirdParty(null, 'example.com'), false);
});

test('displaySite labels the browser bucket', () => {
  assert.equal(displaySite(BROWSER_SITE), 'Browser & extensions');
  assert.equal(displaySite('example.com'), 'example.com');
});
