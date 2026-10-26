// Checks the generated manifests and the files they point at, without a browser.

import { test } from 'node:test';
import assert from 'node:assert/strict';
import { existsSync, readdirSync, readFileSync, statSync } from 'node:fs';
import { join, dirname, resolve, relative } from 'node:path';
import {
  cleanVersion,
  EXT_DIR,
  GECKO_ID,
  makeManifest,
  readTemplate,
  referencedFiles,
  sourceFor,
} from '../tools/manifest.mjs';

const SRC = join(EXT_DIR, 'src');

/** Code with comment lines removed, so prose in comments does not trip the checks. */
function codeOf(file) {
  return readFileSync(file, 'utf8')
    .replace(/\/\*[\s\S]*?\*\//g, '')
    .split('\n')
    .filter((line) => !/^\s*\/\//.test(line))
    .join('\n');
}

function walk(dir) {
  return readdirSync(dir).flatMap((n) => {
    const p = join(dir, n);
    return statSync(p).isDirectory() ? walk(p) : [p];
  });
}

test('template is valid JSON with a usable version', () => {
  const t = readTemplate();
  assert.equal(t.manifest_version, 3);
  assert.equal(cleanVersion(t.version), t.version);
});

test('cleanVersion', () => {
  assert.equal(cleanVersion('v1.2.3'), '1.2.3');
  assert.equal(cleanVersion('0.1'), '0.1');
  for (const bad of ['', '1.2.3-beta', '1.2.3.4.5', 'abc', '1..2']) assert.throws(() => cleanVersion(bad));
});

for (const target of ['chrome', 'firefox']) {
  test(`${target} manifest follows MV3 rules`, () => {
    const m = makeManifest(readTemplate(), target, '1.2.3');
    JSON.parse(JSON.stringify(m));
    assert.equal(m.manifest_version, 3);
    assert.equal(m.version, '1.2.3');
    assert.ok(m.name.length <= 45);
    assert.ok(m.short_name.length <= 12);
    assert.ok(m.description.length <= 132);
    assert.equal(m.background.type, 'module');
    assert.equal('entry' in m.background, false);
    // MV3: no persistent background, no remote code, no blocking webRequest.
    assert.equal('persistent' in m.background, false);
    assert.equal(m.permissions.includes('webRequestBlocking'), false);
    assert.equal(m.content_security_policy, undefined);
    assert.deepEqual(m.host_permissions, ['<all_urls>']);
    // Host patterns belong in host_permissions in MV3.
    assert.ok(m.permissions.every((p) => !p.includes('://') && p !== '<all_urls>'));
    assert.deepEqual([...m.permissions].sort(), ['declarativeNetRequest', 'notifications', 'storage', 'unlimitedStorage', 'webRequest']);
    if (target === 'chrome') {
      assert.equal(m.background.service_worker, 'background.js');
      assert.equal(m.background.scripts, undefined);
      assert.equal(m.browser_specific_settings, undefined);
    } else {
      assert.deepEqual(m.background.scripts, ['background.js']);
      assert.equal(m.background.service_worker, undefined);
      assert.equal(m.browser_specific_settings.gecko.id, GECKO_ID);
      assert.match(m.browser_specific_settings.gecko.strict_min_version, /^\d+\.\d+$/);
      assert.equal(m.minimum_chrome_version, undefined);
    }
  });

  test(`${target} manifest only references files that exist`, () => {
    const m = makeManifest(readTemplate(), target);
    for (const p of referencedFiles(m)) assert.ok(existsSync(sourceFor(p)), `missing ${p}`);
  });
}

test('icons are PNG files of the right size', () => {
  for (const size of [16, 32, 48, 128]) {
    const buf = readFileSync(join(EXT_DIR, 'icons', `icon-${size}.png`));
    assert.equal(buf.subarray(1, 4).toString('latin1'), 'PNG');
    assert.equal(buf.readUInt32BE(16), size);
    assert.equal(buf.readUInt32BE(20), size);
  }
});

test('the built-in themes file exists where the build copies it from', () => {
  JSON.parse(readFileSync(sourceFor('themes/builtin.json'), 'utf8'));
});

test('every relative import and page asset resolves', () => {
  const files = walk(SRC);
  for (const f of files.filter((x) => x.endsWith('.js'))) {
    const code = readFileSync(f, 'utf8');
    for (const [, spec] of code.matchAll(/(?:import|export)[^'"]*?from\s+['"]([^'"]+)['"]/g)) {
      assert.ok(spec.startsWith('.'), `${relative(SRC, f)} imports a bare module ${spec}`);
      assert.ok(existsSync(resolve(dirname(f), spec)), `${relative(SRC, f)} imports missing ${spec}`);
    }
  }
  for (const f of files.filter((x) => x.endsWith('.html'))) {
    const html = readFileSync(f, 'utf8');
    for (const [, ref] of html.matchAll(/(?:src|href)="([^"#]+)"/g)) {
      if (/^[a-z]+:/.test(ref)) assert.fail(`${relative(SRC, f)} loads a remote resource ${ref}`);
      const rel = relative(SRC, resolve(dirname(f), ref));
      assert.ok(existsSync(sourceFor(rel)), `${relative(SRC, f)} references missing ${ref}`);
    }
  }
});

test('pages are CSP safe: no inline scripts or handlers', () => {
  for (const f of walk(SRC).filter((x) => x.endsWith('.html'))) {
    const html = readFileSync(f, 'utf8');
    for (const [tag] of html.matchAll(/<script\b[^>]*>/g)) assert.match(tag, /\bsrc="/, `${f} has an inline script`);
    assert.doesNotMatch(html, /\son[a-z]+="/i, `${f} has an inline event handler`);
    assert.doesNotMatch(html, /javascript:/i);
  }
});

test('no eval, remote code or network calls in the code', () => {
  for (const f of walk(SRC).filter((x) => x.endsWith('.js'))) {
    const code = codeOf(f);
    assert.doesNotMatch(code, /\beval\s*\(|new Function\s*\(/, `${f} uses eval`);
    assert.doesNotMatch(code, /https?:\/\/(?!www\.w3\.org\/2000\/svg|\$\{)/, `${f} contains a URL`);
    assert.doesNotMatch(code, /XMLHttpRequest|WebSocket\(|sendBeacon/, `${f} talks to the network`);
    assert.doesNotMatch(code, /\.innerHTML\s*=|insertAdjacentHTML/, `${f} writes raw HTML`);
    for (const [, url] of code.matchAll(/fetch\(([^)]*)\)/g)) assert.match(url, /getURL\(/, `${f} fetches something other than a packaged file`);
  }
});

test('lib modules import nothing browser specific', () => {
  for (const f of walk(join(SRC, 'lib'))) {
    const code = codeOf(f);
    assert.doesNotMatch(code, /\b(chrome|browser)\.[a-z]/, `${f} uses a browser API`);
    assert.doesNotMatch(code, /\b(document|window|localStorage)\b/, `${f} uses the DOM`);
    for (const [, spec] of code.matchAll(/from\s+['"]([^'"]+)['"]/g)) {
      assert.match(spec, /^\.\/[a-z]+\.js$/, `${f} imports ${spec} from outside lib`);
    }
  }
});
