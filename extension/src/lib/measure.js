// Turns webRequest event details into byte counts.
//
// Firefox: onCompleted details carry `responseSize` (bytes transferred,
// headers included, after compression) and `requestSize` (request headers
// plus body). These are treated as measured values.
//
// Chrome: there are no size fields. Received bytes come from the
// Content-Length response header, which is missing on chunked responses.
// Sent bytes are the request body size seen in onBeforeRequest. Headers
// are not counted. These are estimates.

/** Case-insensitive header lookup in a webRequest header array. */
export function headerValue(headers, name) {
  if (!Array.isArray(headers)) return null;
  const want = name.toLowerCase();
  for (const h of headers) {
    if (h && typeof h.name === 'string' && h.name.toLowerCase() === want) {
      if (typeof h.value === 'string') return h.value;
      if (h.binaryValue) return String.fromCharCode(...h.binaryValue);
      return null;
    }
  }
  return null;
}

/** Content-Length as a non-negative integer, or null. */
export function contentLength(headers) {
  const v = headerValue(headers, 'content-length');
  if (v === null) return null;
  const t = v.trim();
  if (!/^\d+$/.test(t)) return null;
  const n = Number(t);
  return Number.isSafeInteger(n) ? n : null;
}

function byteLength(x) {
  if (!x) return 0;
  if (typeof x.byteLength === 'number') return x.byteLength;
  if (typeof x === 'string') return x.length;
  return 0;
}

/** Approximate size of a webRequest requestBody object. */
export function requestBodySize(body) {
  if (!body || typeof body !== 'object' || body.error) return 0;
  let total = 0;
  if (Array.isArray(body.raw)) {
    for (const part of body.raw) {
      if (!part) continue;
      total += byteLength(part.bytes);
      // File uploads only give a path; their size is unknown here.
    }
  }
  if (body.formData && typeof body.formData === 'object') {
    for (const [key, values] of Object.entries(body.formData)) {
      const list = Array.isArray(values) ? values : [values];
      for (const v of list) {
        // key=value plus a separator, as in urlencoded form bodies.
        total += key.length + 2 + (typeof v === 'string' ? v.length : 0);
      }
    }
  }
  return total;
}

const finite = (n) => typeof n === 'number' && Number.isFinite(n) && n >= 0;

/**
 * Bytes for a completed request.
 * @param details onCompleted details
 * @param opts.exact true on Firefox (use responseSize/requestSize)
 * @param opts.bodyBytes request body size recorded earlier, if any
 * @returns {{skip: true} | {skip: false, rx: number, tx: number}}
 */
export function measureCompleted(details, { exact = false, bodyBytes = 0 } = {}) {
  if (!details || details.fromCache) return { skip: true };
  const status = details.statusCode;
  const method = typeof details.method === 'string' ? details.method.toUpperCase() : 'GET';
  const noBody = status === 204 || status === 304 || method === 'HEAD';

  let rx = 0;
  let tx = finite(bodyBytes) ? bodyBytes : 0;

  if (exact && finite(details.responseSize)) {
    rx = details.responseSize;
  } else if (!noBody) {
    rx = contentLength(details.responseHeaders) ?? 0;
  }
  if (exact && finite(details.requestSize)) {
    tx = details.requestSize;
  }
  return { skip: false, rx, tx };
}
