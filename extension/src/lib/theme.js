// Shared theme format (same as the app) and CSS variable derivation.

export const THEME_FORMAT = 'nireekshana-theme';
export const THEMES_FORMAT = 'nireekshana-themes';
export const THEME_VERSION = 1;
export const MAX_IMPORT_CHARS = 20000;

const HEX_RE = /^#[0-9a-fA-F]{6}$/;
const ID_RE = /^[a-z0-9-]{1,40}$/;

export const FONT_STACKS = {
  sans: 'system-ui, -apple-system, "Segoe UI", Roboto, "Noto Sans", Ubuntu, Cantarell, "Helvetica Neue", Arial, sans-serif',
  mono: 'ui-monospace, "SFMono-Regular", "Cascadia Mono", "Segoe UI Mono", "Roboto Mono", Menlo, Consolas, "Liberation Mono", monospace',
};

export const isHex = (c) => typeof c === 'string' && HEX_RE.test(c);

const isPlainObject = (x) => x !== null && typeof x === 'object' && !Array.isArray(x);

/**
 * Check a theme object. Unknown keys are dropped.
 * @returns {{ok: true, theme: object} | {ok: false, errors: string[]}}
 */
export function validateTheme(obj) {
  const errors = [];
  if (!isPlainObject(obj)) return { ok: false, errors: ['A theme must be a JSON object.'] };

  if (typeof obj.id !== 'string' || !ID_RE.test(obj.id)) {
    errors.push('id must be 1 to 40 characters: lowercase letters, digits and hyphens.');
  }
  const name = typeof obj.name === 'string' ? obj.name.trim() : '';
  if (name === '' || name.length > 40) errors.push('name must be 1 to 40 characters.');

  for (const key of ['seed', 'accent', 'download', 'upload']) {
    if (!isHex(obj[key])) errors.push(`${key} must be a colour like #1A2B3C.`);
  }
  for (const mode of ['light', 'dark']) {
    if (!isPlainObject(obj[mode]) || !isHex(obj[mode].background)) {
      errors.push(`${mode}.background must be a colour like #1A2B3C.`);
    }
  }
  if (!Number.isInteger(obj.radius) || obj.radius < 0 || obj.radius > 32) {
    errors.push('radius must be a whole number from 0 to 32.');
  }
  if (obj.font !== 'sans' && obj.font !== 'mono') errors.push('font must be "sans" or "mono".');

  if (errors.length) return { ok: false, errors };
  const up = (c) => c.toUpperCase();
  return {
    ok: true,
    theme: {
      id: obj.id,
      name,
      seed: up(obj.seed),
      accent: up(obj.accent),
      download: up(obj.download),
      upload: up(obj.upload),
      light: { background: up(obj.light.background) },
      dark: { background: up(obj.dark.background) },
      radius: obj.radius,
      font: obj.font,
    },
  };
}

/** Parse a single-theme export from the app. */
export function parseThemeImport(text) {
  if (typeof text !== 'string' || text.trim() === '') return { ok: false, errors: ['Paste a theme first.'] };
  if (text.length > MAX_IMPORT_CHARS) return { ok: false, errors: ['That file is too large to be a theme.'] };
  let obj;
  try {
    obj = JSON.parse(text);
  } catch {
    return { ok: false, errors: ['That is not valid JSON.'] };
  }
  if (!isPlainObject(obj)) return { ok: false, errors: ['A theme must be a JSON object.'] };
  if (obj.format !== THEME_FORMAT) return { ok: false, errors: [`format must be "${THEME_FORMAT}".`] };
  if (obj.version !== THEME_VERSION) return { ok: false, errors: [`version must be ${THEME_VERSION}.`] };
  return validateTheme(obj);
}

/** The single-theme export format, as pretty JSON. */
export function exportTheme(theme) {
  const t = validateTheme(theme);
  if (!t.ok) throw new Error(t.errors.join(' '));
  return `${JSON.stringify({ format: THEME_FORMAT, version: THEME_VERSION, ...t.theme }, null, 2)}\n`;
}

/** Validated themes from the built-in themes file. Invalid entries are skipped. */
export function parseBuiltins(json) {
  if (!isPlainObject(json) || json.format !== THEMES_FORMAT || !Array.isArray(json.themes)) return [];
  const seen = new Set();
  const out = [];
  for (const t of json.themes) {
    const r = validateTheme(t);
    if (r.ok && !seen.has(r.theme.id)) {
      seen.add(r.theme.id);
      out.push(r.theme);
    }
  }
  return out;
}

/** Theme by id, falling back to the first built-in. */
export function findTheme(id, builtins, custom = []) {
  return custom.find((t) => t.id === id) ?? builtins.find((t) => t.id === id) ?? builtins[0] ?? null;
}

// Colour maths -----------------------------------------------------------

export function hexToRgb(hex) {
  const n = parseInt(hex.slice(1), 16);
  return [(n >> 16) & 255, (n >> 8) & 255, n & 255];
}

export function rgbToHex([r, g, b]) {
  const c = (v) => Math.max(0, Math.min(255, Math.round(v))).toString(16).padStart(2, '0');
  return `#${c(r)}${c(g)}${c(b)}`.toUpperCase();
}

/** Mix a toward b by t (0 = a, 1 = b). */
export function mix(a, b, t) {
  const x = hexToRgb(a);
  const y = hexToRgb(b);
  return rgbToHex(x.map((v, i) => v + (y[i] - v) * t));
}

export function luminance(hex) {
  const lin = (v) => {
    const s = v / 255;
    return s <= 0.03928 ? s / 12.92 : ((s + 0.055) / 1.055) ** 2.4;
  };
  const [r, g, b] = hexToRgb(hex).map(lin);
  return 0.2126 * r + 0.7152 * g + 0.0722 * b;
}

export function contrast(a, b) {
  const la = luminance(a);
  const lb = luminance(b);
  return (Math.max(la, lb) + 0.05) / (Math.min(la, lb) + 0.05);
}

/** Move a colour toward `toward` until it reaches the target contrast on bg. */
export function ensureContrast(color, bg, toward, target = 3) {
  let c = color;
  for (let t = 0.1; contrast(c, bg) < target && t <= 1.0001; t += 0.1) c = mix(color, toward, t);
  return c;
}

export const isDarkColor = (hex) => luminance(hex) < 0.2;

/** "light" or "dark" from the user's choice and the system preference. */
export function resolveMode(pref, systemDark) {
  if (pref === 'light' || pref === 'dark') return pref;
  return systemDark ? 'dark' : 'light';
}

/** CSS custom properties for a theme in one mode. */
export function deriveVars(theme, mode) {
  const bg = mode === 'dark' ? theme.dark.background : theme.light.background;
  const darkBg = isDarkColor(bg);
  const text = darkBg ? mix('#FFFFFF', theme.seed, 0.06) : mix('#000000', theme.seed, 0.12);
  const muted = mix(text, bg, 0.42);
  const primary = ensureContrast(theme.seed, bg, text, 3);
  const accent = ensureContrast(theme.accent, bg, text, 2.5);
  const download = ensureContrast(theme.download, bg, text, 2);
  const upload = ensureContrast(theme.upload, bg, text, 2);
  const onPrimary = contrast('#FFFFFF', primary) >= contrast('#000000', primary) ? '#FFFFFF' : '#000000';
  return {
    '--bg': bg,
    '--surface': mix(bg, text, darkBg ? 0.07 : 0.045),
    '--surface-2': mix(bg, text, darkBg ? 0.12 : 0.085),
    '--border': mix(bg, text, darkBg ? 0.18 : 0.14),
    '--text': text,
    '--muted': muted,
    '--primary': primary,
    '--on-primary': onPrimary,
    '--primary-soft': mix(bg, primary, darkBg ? 0.22 : 0.14),
    '--accent': accent,
    '--download': download,
    '--upload': upload,
    '--danger': darkBg ? '#FF6B6B' : '#C62828',
    '--radius': `${theme.radius}px`,
    '--radius-sm': `${Math.round(theme.radius / 2)}px`,
    '--font': FONT_STACKS[theme.font] ?? FONT_STACKS.sans,
    '--font-mono': FONT_STACKS.mono,
    'color-scheme': mode,
  };
}

/** Variables as a CSS declaration list. */
export function cssText(vars) {
  return Object.entries(vars)
    .map(([k, v]) => `${k}: ${v};`)
    .join(' ');
}
