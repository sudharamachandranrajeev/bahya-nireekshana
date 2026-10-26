// Loads the built-in themes and the user's choice, and applies CSS variables.

import { api } from '../shim.js';
import { deriveVars, findTheme, parseBuiltins, resolveMode } from '../lib/theme.js';
import { getCustomThemes, getSettings, KEYS } from '../platform/store.js';

const media = globalThis.matchMedia?.('(prefers-color-scheme: dark)');

let builtinsPromise = null;

export function loadBuiltins() {
  builtinsPromise ??= fetch(api.runtime.getURL('themes/builtin.json'))
    .then((r) => r.json())
    .then(parseBuiltins)
    .catch(() => []);
  return builtinsPromise;
}

export function systemDark() {
  return !!media?.matches;
}

export function applyVars(el, vars) {
  for (const [k, v] of Object.entries(vars)) {
    if (k === 'color-scheme') el.style.colorScheme = v;
    else el.style.setProperty(k, v);
  }
}

/** Current state: { builtins, custom, settings, theme, mode }. */
export async function themeState() {
  const [builtins, custom, settings] = await Promise.all([loadBuiltins(), getCustomThemes(), getSettings()]);
  const theme = findTheme(settings.themeId, builtins, custom);
  const mode = resolveMode(settings.mode, systemDark());
  return { builtins, custom, settings, theme, mode };
}

export async function applyTheme() {
  const state = await themeState();
  if (state.theme) {
    applyVars(document.documentElement, deriveVars(state.theme, state.mode));
    document.documentElement.dataset.font = state.theme.font;
  }
  document.documentElement.classList.add('themed');
  return state;
}

/** Apply now and again whenever the choice or the system mode changes. */
export async function initTheme(onChange = () => {}) {
  const state = await applyTheme();
  media?.addEventListener?.('change', () => applyTheme().then(onChange));
  api.storage.onChanged.addListener((changes, area) => {
    if (area === 'local' && (changes[KEYS.settings] || changes[KEYS.customThemes])) applyTheme().then(onChange);
  });
  return state;
}
