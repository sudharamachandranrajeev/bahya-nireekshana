// Chart geometry. Rendering lives in ui/charts.js.

/** Round up to 1, 2, 2.5 or 5 times a power of ten. 0 stays 0. */
export function niceMax(v) {
  const n = Number(v);
  if (!Number.isFinite(n) || n <= 0) return 0;
  const p = 10 ** Math.floor(Math.log10(n));
  for (const m of [1, 2, 2.5, 5, 10]) {
    if (n <= m * p) return m * p;
  }
  return 10 * p;
}

/** Like niceMax, but rounds within 1024-based units so labels read "100 KB", not "97.7 KB". */
export function niceBytesMax(bytes) {
  const n = Number(bytes);
  if (!Number.isFinite(n) || n <= 0) return 0;
  const unit = 1024 ** Math.max(0, Math.floor(Math.log(n) / Math.log(1024)));
  return niceMax(n / unit) * unit;
}

/**
 * Stacked bar rectangles for a daily series.
 * @returns [{day, x, w, down: {y, h}, up: {y, h}}]
 */
export function barLayout(series, { width, height, gap = 2, max = null }) {
  const count = series.length;
  if (count === 0) return [];
  const top = max ?? Math.max(0, ...series.map((p) => p.r + p.s));
  const slot = width / count;
  const g = Math.min(gap, slot * 0.4);
  const w = Math.max(0.5, slot - g);
  return series.map((p, i) => {
    const hDown = top > 0 ? (p.r / top) * height : 0;
    const hUp = top > 0 ? (p.s / top) * height : 0;
    return {
      day: p.day,
      x: i * slot + g / 2,
      w,
      down: { y: height - hDown, h: hDown },
      up: { y: height - hDown - hUp, h: hUp },
    };
  });
}

/** Polyline points for a sparkline, with a little padding. */
export function sparkPoints(values, width, height, pad = 2) {
  if (!values.length) return '';
  const max = Math.max(...values, 0);
  const innerH = height - pad * 2;
  const step = values.length > 1 ? (width - pad * 2) / (values.length - 1) : 0;
  return values
    .map((v, i) => {
      const x = pad + i * step;
      const y = max > 0 ? pad + innerH - (v / max) * innerH : pad + innerH;
      return `${+x.toFixed(2)},${+y.toFixed(2)}`;
    })
    .join(' ');
}
