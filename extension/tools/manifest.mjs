// Generates the Chrome and Firefox manifests from manifest.template.json.
//
//   node tools/manifest.mjs version                 print the template version
//   node tools/manifest.mjs write <target> <version> <out.json>

import { readFileSync, writeFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';

export const EXT_DIR = join(dirname(fileURLToPath(import.meta.url)), '..');
export const TEMPLATE_PATH = join(EXT_DIR, 'manifest.template.json');

export const GECKO_ID = 'nireekshana@brahma.dev';
export const FIREFOX_MIN = '140.0';
export const CHROME_MIN = '116';

const VERSION_RE = /^\d{1,5}(\.\d{1,5}){0,3}$/;

export function readTemplate() {
  return JSON.parse(readFileSync(TEMPLATE_PATH, 'utf8'));
}

/** "v0.2.0" -> "0.2.0". Throws when the result is not a valid extension version. */
export function cleanVersion(v) {
  const s = String(v ?? '').trim().replace(/^v/, '');
  if (!VERSION_RE.test(s)) throw new Error(`Not a valid extension version: "${v}" (use numbers like 0.1.0)`);
  return s;
}

export function makeManifest(template, target, version = template.version) {
  const m = structuredClone(template);
  m.version = cleanVersion(version);
  const entry = m.background?.entry ?? 'background.js';
  if (target === 'chrome') {
    m.background = { service_worker: entry, type: 'module' };
    m.minimum_chrome_version = CHROME_MIN;
  } else if (target === 'firefox') {
    m.background = { scripts: [entry], type: 'module' };
    m.browser_specific_settings = {
      gecko: {
        id: GECKO_ID,
        strict_min_version: FIREFOX_MIN,
        data_collection_permissions: { required: ['none'] },
      },
    };
  } else {
    throw new Error(`Unknown target: ${target}`);
  }
  return m;
}

/** Every file path a manifest points at. */
export function referencedFiles(m) {
  const out = new Set();
  for (const p of Object.values(m.icons || {})) out.add(p);
  for (const p of Object.values(m.action?.default_icon || {})) out.add(p);
  if (m.action?.default_popup) out.add(m.action.default_popup);
  if (m.options_ui?.page) out.add(m.options_ui.page);
  if (m.background?.service_worker) out.add(m.background.service_worker);
  for (const p of m.background?.scripts || []) out.add(p);
  return [...out];
}

/** Where a packaged path comes from in the source tree. */
export function sourceFor(path) {
  if (path.startsWith('icons/')) return join(EXT_DIR, path);
  if (path === 'themes/builtin.json') return join(EXT_DIR, '..', 'themes', 'builtin.json');
  return join(EXT_DIR, 'src', path);
}

if (process.argv[1] && fileURLToPath(import.meta.url) === process.argv[1]) {
  const [cmd, ...args] = process.argv.slice(2);
  if (cmd === 'version') {
    process.stdout.write(`${readTemplate().version}\n`);
  } else if (cmd === 'write') {
    const [target, version, out] = args;
    writeFileSync(out, `${JSON.stringify(makeManifest(readTemplate(), target, version), null, 2)}\n`);
  } else {
    console.error('usage: manifest.mjs version | write <chrome|firefox> <version> <out.json>');
    process.exit(2);
  }
}
