// Site and host helpers. No Public Suffix List: a short built-in list of
// common multi-part suffixes covers most real sites.

/** Key for requests that do not belong to a web page. */
export const BROWSER_SITE = '__browser__';
export const BROWSER_SITE_LABEL = 'Browser & extensions';

// Suffixes where the registrable domain has three labels (example.co.uk).
// Also a few hosting suffixes where each subdomain is a separate site.
export const MULTI_PART_SUFFIXES = new Set([
  // United Kingdom
  'co.uk', 'org.uk', 'ac.uk', 'gov.uk', 'ltd.uk', 'plc.uk', 'me.uk', 'net.uk', 'nhs.uk', 'sch.uk', 'police.uk',
  // Australia, New Zealand
  'com.au', 'net.au', 'org.au', 'edu.au', 'gov.au', 'asn.au', 'id.au',
  'co.nz', 'org.nz', 'net.nz', 'ac.nz', 'govt.nz', 'geek.nz',
  // India
  'co.in', 'net.in', 'org.in', 'gov.in', 'ac.in', 'edu.in', 'res.in', 'firm.in', 'gen.in', 'ind.in', 'nic.in',
  // Japan, Korea, China, Taiwan, Hong Kong
  'co.jp', 'ne.jp', 'or.jp', 'ac.jp', 'go.jp', 'ed.jp', 'gr.jp', 'lg.jp',
  'co.kr', 'or.kr', 'ne.kr', 'go.kr', 'ac.kr',
  'com.cn', 'net.cn', 'org.cn', 'gov.cn', 'edu.cn', 'ac.cn',
  'com.tw', 'org.tw', 'net.tw', 'edu.tw', 'gov.tw',
  'com.hk', 'org.hk', 'net.hk', 'edu.hk', 'gov.hk',
  // South and South East Asia
  'com.sg', 'edu.sg', 'gov.sg', 'org.sg', 'net.sg',
  'com.my', 'org.my', 'gov.my', 'edu.my',
  'co.id', 'or.id', 'ac.id', 'go.id', 'web.id',
  'com.ph', 'org.ph', 'gov.ph', 'edu.ph',
  'co.th', 'ac.th', 'go.th', 'in.th', 'or.th',
  'com.vn', 'net.vn', 'org.vn', 'gov.vn', 'edu.vn',
  'com.pk', 'org.pk', 'gov.pk', 'edu.pk',
  'com.bd', 'org.bd', 'gov.bd',
  'com.lk', 'org.lk', 'gov.lk',
  'com.np', 'org.np',
  // Americas
  'com.br', 'net.br', 'org.br', 'gov.br', 'edu.br',
  'com.mx', 'org.mx', 'gob.mx', 'edu.mx',
  'com.ar', 'org.ar', 'gob.ar',
  'com.co', 'org.co', 'gov.co',
  'com.pe', 'gob.pe', 'com.ve', 'com.uy', 'com.ec', 'com.bo', 'com.py',
  // Europe, Middle East, Africa
  'com.tr', 'org.tr', 'gov.tr', 'edu.tr',
  'com.ua', 'org.ua', 'gov.ua',
  'com.pl', 'net.pl', 'org.pl',
  'co.il', 'org.il', 'ac.il', 'gov.il',
  'com.sa', 'org.sa', 'gov.sa', 'edu.sa',
  'com.eg', 'gov.eg', 'edu.eg',
  'co.za', 'org.za', 'gov.za', 'ac.za', 'web.za',
  'com.ng', 'org.ng', 'gov.ng',
  'co.ke', 'or.ke', 'go.ke',
  'com.gh', 'com.qa', 'com.kw', 'com.om', 'com.bh', 'co.ae',
  // Hosting where each subdomain belongs to a different owner
  'github.io', 'gitlab.io', 'pages.dev', 'workers.dev', 'netlify.app', 'vercel.app',
  'web.app', 'firebaseapp.com', 'herokuapp.com', 'blogspot.com', 'appspot.com',
]);

const IPV4_RE = /^(?:(?:25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)\.){3}(?:25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)$/;

export function isIPv4(host) {
  return IPV4_RE.test(host);
}

export function isIpAddress(host) {
  if (typeof host !== 'string') return false;
  return isIPv4(host) || host.startsWith('[') || host.includes(':');
}

const WEB_PROTOCOLS = new Set(['http:', 'https:', 'ws:', 'wss:', 'ftp:']);

/** Lowercase hostname of a web URL, or null for other schemes and junk. */
export function hostFromUrl(url) {
  if (typeof url !== 'string' || url === '') return null;
  let u;
  try {
    u = new URL(url);
  } catch {
    return null;
  }
  if (!WEB_PROTOCOLS.has(u.protocol)) return null;
  const host = u.hostname.toLowerCase().replace(/\.$/, '');
  return host || null;
}

/**
 * Registrable domain ("site") of a host.
 * IP addresses and single-label hosts such as localhost stay as they are.
 */
export function registrableDomain(host) {
  if (typeof host !== 'string' || host === '') return null;
  const h = host.toLowerCase().replace(/\.$/, '');
  if (h === '' || isIpAddress(h)) return h || null;
  const labels = h.split('.');
  if (labels.some((l) => l === '')) return h;
  if (labels.length <= 2) return h;
  const lastTwo = labels.slice(-2).join('.');
  if (MULTI_PART_SUFFIXES.has(lastTwo)) return labels.slice(-3).join('.');
  return lastTwo;
}

/** Site of a web URL, or null when the URL is not a web page. */
export function siteForUrl(url) {
  return registrableDomain(hostFromUrl(url));
}

/** True when the host belongs to a different site. */
export function isThirdParty(host, site) {
  if (!host || !site || site === BROWSER_SITE) return false;
  return registrableDomain(host) !== site;
}

export function displaySite(site) {
  return site === BROWSER_SITE ? BROWSER_SITE_LABEL : site;
}
