import { test } from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import {
  contrast,
  cssText,
  deriveVars,
  ensureContrast,
  exportTheme,
  findTheme,
  FONT_STACKS,
  hexToRgb,
  luminance,
  mix,
  parseBuiltins,
  parseThemeImport,
  resolveMode,
  rgbToHex,
  validateTheme,
} from '../src/lib/theme.js';

const builtinJson = JSON.parse(readFileSync(fileURLToPath(new URL('../../themes/builtin.json', import.meta.url)), 'utf8'));

const good = {
  format: 'nireekshana-theme',
  version: 1,
  id: 'my-theme',
  name: 'My theme',
  seed: '#0fa3b1',
  accent: '#FFB020',
  download: '#1FB5E0',
  upload: '#FF7A45',
  light: { background: '#F3F7F8' },
  dark: { background: '#0B1214' },
  radius: 18,
  font: 'sans',
};

test('every built-in theme is valid and ids are unique', () => {
  const list = parseBuiltins(builtinJson);
  assert.equal(list.length, builtinJson.themes.length);
  assert.ok(list.length >= 1);
  assert.equal(new Set(list.map((t) => t.id)).size, list.length);
});

test('parseBuiltins skips invalid entries and duplicates', () => {
  const t = builtinJson.themes[0];
  const list = parseBuiltins({ format: 'nireekshana-themes', version: 1, themes: [t, t, { id: 'x' }] });
  assert.equal(list.length, 1);
  assert.deepEqual(parseBuiltins({ format: 'other', themes: [t] }), []);
  assert.deepEqual(parseBuiltins(null), []);
});

test('parseThemeImport accepts a good export and normalises colours', () => {
  const r = parseThemeImport(JSON.stringify(good));
  assert.equal(r.ok, true);
  assert.equal(r.theme.seed, '#0FA3B1');
  assert.equal('format' in r.theme, false);
});

test('parseThemeImport drops unknown keys', () => {
  const r = parseThemeImport(JSON.stringify({ ...good, extra: 'x' }));
  assert.equal(r.ok, true);
  assert.equal('extra' in r.theme, false);
});

test('parseThemeImport rejects wrong format, version and JSON', () => {
  assert.equal(parseThemeImport('').ok, false);
  assert.equal(parseThemeImport('{').ok, false);
  assert.equal(parseThemeImport('[]').ok, false);
  assert.equal(parseThemeImport(JSON.stringify({ ...good, format: 'nireekshana-themes' })).ok, false);
  assert.equal(parseThemeImport(JSON.stringify({ ...good, version: 2 })).ok, false);
  assert.equal(parseThemeImport(JSON.stringify({ ...good, version: '1' })).ok, false);
  assert.equal(parseThemeImport('x'.repeat(30000)).ok, false);
});

test('validateTheme checks every field', () => {
  const cases = [
    { id: 'Bad' },
    { id: '' },
    { id: 'a'.repeat(41) },
    { id: 'has space' },
    { name: '' },
    { name: '   ' },
    { name: 'x'.repeat(41) },
    { seed: '#FFF' },
    { accent: 'red' },
    { download: '#GGGGGG' },
    { upload: '#1234567' },
    { light: { background: 'white' } },
    { dark: null },
    { light: '#FFFFFF' },
    { radius: -1 },
    { radius: 33 },
    { radius: 4.5 },
    { radius: '8' },
    { font: 'serif' },
  ];
  for (const patch of cases) {
    const r = validateTheme({ ...good, ...patch });
    assert.equal(r.ok, false, `should reject ${JSON.stringify(patch)}`);
    assert.ok(r.errors.length >= 1);
  }
  assert.equal(validateTheme({ ...good, radius: 0, font: 'mono' }).ok, true);
  assert.equal(validateTheme({ ...good, radius: 32, name: 'x'.repeat(40) }).ok, true);
  assert.equal(validateTheme(null).ok, false);
  assert.equal(validateTheme([]).ok, false);
});

test('exportTheme round trips through parseThemeImport', () => {
  const t = parseThemeImport(JSON.stringify(good)).theme;
  const text = exportTheme(t);
  const obj = JSON.parse(text);
  assert.deepEqual(Object.keys(obj).slice(0, 3), ['format', 'version', 'id']);
  assert.deepEqual(parseThemeImport(text).theme, t);
  assert.throws(() => exportTheme({ id: 'x' }));
});

test('colour helpers', () => {
  assert.deepEqual(hexToRgb('#0A0B0C'), [10, 11, 12]);
  assert.equal(rgbToHex([10, 11, 12]), '#0A0B0C');
  assert.equal(rgbToHex([-5, 300, 127.6]), '#00FF80');
  assert.equal(mix('#000000', '#FFFFFF', 0), '#000000');
  assert.equal(mix('#000000', '#FFFFFF', 1), '#FFFFFF');
  assert.equal(mix('#000000', '#FFFFFF', 0.5), '#808080');
  assert.equal(luminance('#FFFFFF'), 1);
  assert.equal(luminance('#000000'), 0);
  assert.ok(Math.abs(contrast('#FFFFFF', '#000000') - 21) < 1e-9);
  assert.equal(contrast('#123456', '#123456'), 1);
});

test('ensureContrast lifts weak colours', () => {
  const c = ensureContrast('#FFFF00', '#FFFFFF', '#000000', 3);
  assert.ok(contrast(c, '#FFFFFF') >= 3);
  assert.equal(ensureContrast('#000000', '#FFFFFF', '#000000', 3), '#000000');
});

test('resolveMode', () => {
  assert.equal(resolveMode('system', true), 'dark');
  assert.equal(resolveMode('system', false), 'light');
  assert.equal(resolveMode('light', true), 'light');
  assert.equal(resolveMode('dark', false), 'dark');
  assert.equal(resolveMode(undefined, true), 'dark');
});

test('deriveVars gives readable text and the theme radius and font', () => {
  for (const theme of parseBuiltins(builtinJson)) {
    for (const mode of ['light', 'dark']) {
      const v = deriveVars(theme, mode);
      const bg = mode === 'dark' ? theme.dark.background : theme.light.background;
      assert.equal(v['--bg'], bg);
      assert.ok(contrast(v['--text'], v['--bg']) >= 7, `${theme.id} ${mode} text contrast`);
      assert.ok(contrast(v['--muted'], v['--bg']) >= 3, `${theme.id} ${mode} muted contrast`);
      assert.ok(contrast(v['--primary'], v['--bg']) >= 3, `${theme.id} ${mode} primary contrast`);
      assert.ok(contrast(v['--on-primary'], v['--primary']) >= 3, `${theme.id} ${mode} on-primary contrast`);
      assert.notEqual(v['--surface'], v['--bg']);
      assert.equal(v['--radius'], `${theme.radius}px`);
      assert.equal(v['--font'], FONT_STACKS[theme.font]);
      assert.equal(v['color-scheme'], mode);
      for (const k of ['--surface', '--surface-2', '--border', '--text', '--muted', '--primary', '--accent', '--download', '--upload']) {
        assert.match(v[k], /^#[0-9A-F]{6}$/, `${k} is a hex colour`);
      }
    }
  }
});

test('deriveVars: surface moves toward the text colour', () => {
  const t = parseThemeImport(JSON.stringify(good)).theme;
  const light = deriveVars(t, 'light');
  assert.ok(luminance(light['--surface']) < luminance(light['--bg']));
  const dark = deriveVars(t, 'dark');
  assert.ok(luminance(dark['--surface']) > luminance(dark['--bg']));
  assert.equal(deriveVars({ ...t, radius: 7 }, 'light')['--radius-sm'], '4px');
});

test('findTheme prefers custom, falls back to the first built-in', () => {
  const builtins = parseBuiltins(builtinJson);
  const custom = [{ ...builtins[1], id: 'mine' }];
  assert.equal(findTheme('mine', builtins, custom).id, 'mine');
  assert.equal(findTheme(builtins[2].id, builtins, custom).id, builtins[2].id);
  assert.equal(findTheme('missing', builtins, custom).id, builtins[0].id);
  assert.equal(findTheme('x', [], []), null);
});

test('cssText', () => {
  assert.equal(cssText({ '--a': '#000000', '--b': '4px' }), '--a: #000000; --b: 4px;');
});
