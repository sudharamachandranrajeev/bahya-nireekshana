// SVG charts drawn with theme colours.

import { s } from './dom.js';
import { barLayout, niceBytesMax, sparkPoints } from '../lib/chart.js';
import { formatBytes } from '../lib/format.js';
import { shortDayLabel } from '../lib/dates.js';

/** Stacked daily bars: download at the bottom, upload on top. */
export function barChart(series, { width = 720, height = 180, labelEvery = null } = {}) {
  const axis = 18;
  const max = niceBytesMax(Math.max(0, ...series.map((p) => p.r + p.s)));
  const plotH = height - axis;
  const bars = barLayout(series, { width, height: plotH, gap: series.length > 60 ? 1 : 3, max: max || null });
  const svg = s('svg', {
    class: 'bar-chart',
    viewBox: `0 0 ${width} ${height}`,
    preserveAspectRatio: 'none',
    role: 'img',
    'aria-label': 'Data used per day',
  });
  for (const f of [0.5, 1]) {
    const y = plotH - plotH * f;
    svg.append(s('line', { class: 'grid', x1: 0, x2: width, y1: y, y2: y }));
  }
  bars.forEach((b, i) => {
    const p = series[i];
    const g = s(
      'g',
      { class: 'bar' },
      s('title', {}, `${shortDayLabel(p.day)}: ${formatBytes(p.r)} down, ${formatBytes(p.s)} up, ${p.n} requests`),
      s('rect', { class: 'hit', x: i * (width / series.length), y: 0, width: width / series.length, height: plotH }),
    );
    if (b.down.h > 0) g.append(s('rect', { class: 'down', x: b.x, y: b.down.y, width: b.w, height: b.down.h }));
    if (b.up.h > 0) g.append(s('rect', { class: 'up', x: b.x, y: b.up.y, width: b.w, height: b.up.h }));
    svg.append(g);
  });
  const every = labelEvery ?? Math.max(1, Math.ceil(series.length / 8));
  series.forEach((p, i) => {
    if (i % every !== 0 && i !== series.length - 1) return;
    if (i !== series.length - 1 && series.length - 1 - i < every / 2) return;
    const x = i * (width / series.length) + width / series.length / 2;
    svg.append(s('text', { class: 'axis', x, y: height - 4, 'text-anchor': 'middle' }, shortDayLabel(p.day)));
  });
  return { svg, max };
}

/** Small area sparkline. */
export function sparkline(values, { width = 300, height = 44 } = {}) {
  const pts = sparkPoints(values, width, height);
  const svg = s('svg', { class: 'sparkline', viewBox: `0 0 ${width} ${height}`, preserveAspectRatio: 'none', 'aria-hidden': 'true' });
  if (!pts) return svg;
  const first = pts.split(' ')[0].split(',')[0];
  const last = pts.split(' ').at(-1).split(',')[0];
  svg.append(
    s('polygon', { class: 'area', points: `${first},${height} ${pts} ${last},${height}` }),
    s('polyline', { class: 'line', points: pts }),
  );
  return svg;
}
