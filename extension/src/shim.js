// One namespace for Chrome/Edge (`chrome`, promise based in MV3) and
// Firefox (`browser`).

const g = globalThis;

export const api = g.browser ?? g.chrome;

/** Firefox reports exact sizes; Chromium browsers only allow estimates. */
export const isFirefox = typeof g.browser?.runtime?.getBrowserInfo === 'function';

export const measurement = isFirefox ? 'measured' : 'estimate';
