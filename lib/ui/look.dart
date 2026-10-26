import 'dart:math' as math;

import 'package:brahma_core/brahma_core.dart';
import 'package:flutter/material.dart';

import '../domain/themes.dart';

// Bahya Nireekshana's look: an instrument panel. Every colour comes from the
// chosen theme (domain/themes.dart): its background, a seed that tints the
// surfaces, an accent, and fixed colours for data coming in and going out
// so the charts read the same on every page. A faint radar grid sits behind
// the pages. Motion stops when the system asks for reduced motion.

const headingFont = 'PlusJakartaSans';
const bodyFont = 'Inter';
const _monoFallback = ['monospace', 'Consolas', 'DejaVu Sans Mono', 'Menlo'];

/// The theme's own colours, beside the Material scheme.
class NetColors extends ThemeExtension<NetColors> {
  const NetColors({
    required this.download,
    required this.upload,
    required this.accent,
    required this.grid,
    required this.line,
    required this.radius,
  });

  final Color download;
  final Color upload;
  final Color accent;

  /// Chart grid lines and the radar behind the pages.
  final Color grid;

  /// Hairline borders.
  final Color line;
  final double radius;

  static NetColors of(BuildContext context) => Theme.of(context).extension<NetColors>()!;

  @override
  NetColors copyWith({
    Color? download,
    Color? upload,
    Color? accent,
    Color? grid,
    Color? line,
    double? radius,
  }) => NetColors(
    download: download ?? this.download,
    upload: upload ?? this.upload,
    accent: accent ?? this.accent,
    grid: grid ?? this.grid,
    line: line ?? this.line,
    radius: radius ?? this.radius,
  );

  @override
  NetColors lerp(NetColors? other, double t) => other == null
      ? this
      : NetColors(
          download: Color.lerp(download, other.download, t)!,
          upload: Color.lerp(upload, other.upload, t)!,
          accent: Color.lerp(accent, other.accent, t)!,
          grid: Color.lerp(grid, other.grid, t)!,
          line: Color.lerp(line, other.line, t)!,
          radius: radius + (other.radius - radius) * t,
        );
}

Color _mix(Color base, Color over, double amount) => Color.alphaBlend(over.withValues(alpha: amount), base);

ThemeData nirTheme(NetTheme t, Brightness b) {
  final dark = b == Brightness.dark;
  final base = buildTheme(b, seed: t.seed, accent: t.accent);
  final bg = dark ? t.darkBackground : t.lightBackground;
  final ink = dark ? const Color(0xFFE8EEF0) : const Color(0xFF14191B);
  final scheme = base.colorScheme.copyWith(
    surface: bg,
    surfaceContainerLowest: _mix(bg, t.seed, 0.02),
    surfaceContainerLow: _mix(bg, t.seed, dark ? 0.06 : 0.035),
    surfaceContainer: _mix(bg, t.seed, dark ? 0.09 : 0.06),
    surfaceContainerHigh: _mix(bg, t.seed, dark ? 0.12 : 0.08),
    surfaceContainerHighest: _mix(bg, t.seed, dark ? 0.16 : 0.11),
    onSurface: ink,
    onSurfaceVariant: _mix(ink, bg, 0.38),
    tertiary: t.accent,
  );
  final line = _mix(bg, ink, dark ? 0.12 : 0.1);
  final mono = t.font == 'mono';
  final text = base.textTheme.apply(
    fontFamily: mono ? 'monospace' : bodyFont,
    fontFamilyFallback: mono ? _monoFallback : null,
    bodyColor: scheme.onSurface,
    displayColor: scheme.onSurface,
  );
  TextStyle? heading(TextStyle? s, FontWeight w, [double spacing = -0.3]) => mono
      ? s?.copyWith(fontWeight: w)
      : s?.copyWith(fontFamily: headingFont, fontWeight: w, letterSpacing: spacing);
  final type = text.copyWith(
    displaySmall: heading(text.displaySmall, FontWeight.w700, -0.8),
    headlineMedium: heading(text.headlineMedium, FontWeight.w700, -0.6),
    headlineSmall: heading(text.headlineSmall, FontWeight.w700),
    titleLarge: heading(text.titleLarge, FontWeight.w700),
    titleMedium: text.titleMedium?.copyWith(fontWeight: FontWeight.w600),
  );
  final radius = BorderRadius.circular(t.radius);
  final controlShape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(math.min(t.radius, 14)));
  return base.copyWith(
    colorScheme: scheme,
    textTheme: type,
    listTileTheme: ListTileThemeData(leadingAndTrailingTextStyle: type.bodyLarge),
    scaffoldBackgroundColor: Colors.transparent,
    canvasColor: scheme.surface,
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: scheme.onSurface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: type.headlineSmall?.copyWith(fontSize: 22),
    ),
    cardTheme: CardThemeData(
      color: scheme.surfaceContainerLow.withValues(alpha: dark ? 0.82 : 0.9),
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(color: line),
      ),
    ),
    dividerTheme: DividerThemeData(color: line, space: 1),
    chipTheme: base.chipTheme.copyWith(
      shape: controlShape,
      side: BorderSide(color: line),
      backgroundColor: Colors.transparent,
      selectedColor: t.seed.withValues(alpha: 0.2),
      checkmarkColor: dark ? Colors.white : t.seed,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape: controlShape,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        shape: controlShape,
        side: BorderSide(color: line),
      ),
    ),
    textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(shape: controlShape)),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: SegmentedButton.styleFrom(
        shape: controlShape,
        side: BorderSide(color: line),
        selectedBackgroundColor: t.seed.withValues(alpha: 0.22),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: scheme.primary,
      foregroundColor: scheme.onPrimary,
      shape: controlShape,
    ),
    inputDecorationTheme: base.inputDecorationTheme.copyWith(
      filled: true,
      fillColor: scheme.surfaceContainer,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(math.min(t.radius, 14))),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(math.min(t.radius, 14)),
        borderSide: BorderSide(color: line),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: _mix(dark ? bg : const Color(0xFF12181A), t.seed, 0.14),
      surfaceTintColor: Colors.transparent,
      indicatorColor: t.seed,
      indicatorShape: controlShape,
      elevation: 0,
      height: 64,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
      iconTheme: WidgetStateProperty.resolveWith(
        (s) => IconThemeData(color: s.contains(WidgetState.selected) ? Colors.white : Colors.white70),
      ),
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: Colors.transparent,
      indicatorColor: t.seed.withValues(alpha: 0.22),
      indicatorShape: controlShape,
      selectedIconTheme: IconThemeData(color: dark ? Colors.white : t.seed),
      selectedLabelTextStyle: type.labelLarge?.copyWith(color: scheme.onSurface),
      unselectedLabelTextStyle: type.labelLarge?.copyWith(color: scheme.onSurfaceVariant),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: scheme.surfaceContainer,
      shape: RoundedRectangleBorder(borderRadius: radius),
    ),
    extensions: [
      NetColors(
        download: t.download,
        upload: t.upload,
        accent: t.accent,
        grid: _mix(bg, t.seed, dark ? 0.16 : 0.12),
        line: line,
        radius: t.radius,
      ),
    ],
  );
}

/// The canvas behind every page: the background, a glow of the seed colour
/// in one corner and a faint radar of rings and spokes.
class Backdrop extends StatelessWidget {
  const Backdrop({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final net = NetColors.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(color: scheme.surface),
      child: CustomPaint(painter: _Radar(scheme.primary, net.grid), child: child),
    );
  }
}

class _Radar extends CustomPainter {
  _Radar(this.glow, this.grid);
  final Color glow;
  final Color grid;

  @override
  void paint(Canvas canvas, Size size) {
    final centre = Offset(size.width * 0.92, size.height * 0.05);
    final reach = size.longestSide * 0.9;
    canvas.drawCircle(
      centre,
      reach,
      Paint()
        ..shader = RadialGradient(colors: [glow.withValues(alpha: 0.13), glow.withValues(alpha: 0)])
            .createShader(Rect.fromCircle(center: centre, radius: reach)),
    );
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = grid.withValues(alpha: 0.55);
    for (var r = 120.0; r < reach; r += 120) {
      canvas.drawCircle(centre, r, ring);
    }
    for (var a = 0; a < 12; a++) {
      final angle = a * math.pi / 6;
      canvas.drawLine(centre, centre + Offset(math.cos(angle), math.sin(angle)) * reach, ring);
    }
  }

  @override
  bool shouldRepaint(_Radar old) => old.glow != glow || old.grid != grid;
}

/// A round gauge for a speed: an arc filled on a logarithmic scale from
/// 1 kbps to [max] bits per second, the value in the middle.
class SpeedGauge extends StatelessWidget {
  const SpeedGauge({
    super.key,
    required this.label,
    required this.value,
    required this.text,
    required this.color,
    this.icon,
    this.size = 180,
    this.max = 1e9,
  });

  final String label;

  /// Bits per second.
  final double value;
  final String text;
  final Color color;
  final IconData? icon;
  final double size;
  final double max;

  static double fraction(double bitsPerSecond, double max) {
    if (bitsPerSecond < 1000) return 0;
    return (math.log(bitsPerSecond / 1000) / math.log(max / 1000)).clamp(0, 1);
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final target = fraction(value, max);
    return Semantics(
      label: '$label $text',
      child: SizedBox.square(
        dimension: size,
        child: TweenAnimationBuilder<double>(
          tween: Tween(end: target),
          duration: Motion.reduced(context) ? Duration.zero : const Duration(milliseconds: 600),
          curve: Curves.easeOutCubic,
          builder: (context, v, _) => CustomPaint(
            painter: _Gauge(v, color, NetColors.of(context).grid),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) Icon(icon, color: color, size: size * 0.12),
                  FittedBox(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: size * 0.16),
                      child: Text(
                        text,
                        style: t.textTheme.headlineSmall?.merge(tabular).copyWith(fontSize: size * 0.13),
                      ),
                    ),
                  ),
                  Text(
                    label,
                    style: t.textTheme.labelMedium?.copyWith(color: t.colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Gauge extends CustomPainter {
  _Gauge(this.value, this.color, this.track);
  final double value;
  final Color color;
  final Color track;

  static const _start = math.pi * 0.75, _sweep = math.pi * 1.5;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * 0.075;
    final rect = Offset.zero & size;
    final arc = rect.deflate(stroke);
    canvas.drawArc(
      arc,
      _start,
      _sweep,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..color = track,
    );
    // Ticks every decade: 10k, 100k, 1M, 10M, 100M.
    final tick = Paint()
      ..color = track
      ..strokeWidth = 2;
    for (var i = 0; i <= 6; i++) {
      final a = _start + _sweep * i / 6;
      final c = rect.center;
      final r = arc.width / 2 - stroke;
      canvas.drawLine(
        c + Offset(math.cos(a), math.sin(a)) * r,
        c + Offset(math.cos(a), math.sin(a)) * (r - 6),
        tick,
      );
    }
    if (value <= 0) return;
    canvas.drawArc(
      arc,
      _start,
      _sweep * value,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..shader = SweepGradient(
          startAngle: _start,
          endAngle: _start + _sweep,
          colors: [color.withValues(alpha: 0.35), color],
          transform: const GradientRotation(0),
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(_Gauge old) => old.value != value || old.color != color || old.track != track;
}

/// Download above the line, upload mirrored below it, newest on the right.
/// Values are bytes per second; the scale fits the busiest point shown.
class LiveChart extends StatelessWidget {
  const LiveChart({super.key, required this.points, this.height = 180, this.capacity = 120});
  final List<({double rx, double tx})> points;
  final double height;

  /// How many points fill the width; fewer leave the left side empty.
  final int capacity;

  @override
  Widget build(BuildContext context) {
    final net = NetColors.of(context);
    return SizedBox(
      height: height,
      child: CustomPaint(
        size: Size.infinite,
        painter: _Mirror(points, capacity, net.download, net.upload, net.grid),
      ),
    );
  }
}

class _Mirror extends CustomPainter {
  _Mirror(this.points, this.capacity, this.down, this.up, this.grid);
  final List<({double rx, double tx})> points;
  final int capacity;
  final Color down;
  final Color up;
  final Color grid;

  @override
  void paint(Canvas canvas, Size size) {
    final mid = size.height * 0.62;
    canvas.drawLine(Offset(0, mid), Offset(size.width, mid), Paint()..color = grid);
    if (points.length < 2) return;
    var peak = 1.0;
    for (final p in points) {
      peak = math.max(peak, math.max(p.rx, p.tx));
    }
    final step = size.width / (capacity - 1);
    final x0 = size.width - step * (points.length - 1);
    void area(double Function(({double rx, double tx}) p) value, double room, int dir, Color c) {
      final path = Path()..moveTo(x0, mid);
      final edge = Path();
      for (final (i, p) in points.indexed) {
        final y = mid - dir * room * value(p) / peak;
        path.lineTo(x0 + step * i, y);
        i == 0 ? edge.moveTo(x0, y) : edge.lineTo(x0 + step * i, y);
      }
      path
        ..lineTo(x0 + step * (points.length - 1), mid)
        ..close();
      canvas.drawPath(
        path,
        Paint()
          ..shader = LinearGradient(
            begin: dir > 0 ? Alignment.topCenter : Alignment.bottomCenter,
            end: dir > 0 ? Alignment.bottomCenter : Alignment.topCenter,
            colors: [c.withValues(alpha: 0.45), c.withValues(alpha: 0.02)],
          ).createShader(Rect.fromLTWH(0, dir > 0 ? mid - room : mid, size.width, room)),
      );
      canvas.drawPath(
        edge,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = c,
      );
    }

    area((p) => p.rx, mid - 6, 1, down);
    area((p) => p.tx, size.height - mid - 4, -1, up);
  }

  @override
  bool shouldRepaint(_Mirror old) => true;
}

/// Stacked bars, download under upload, one per bucket; tap one to pick it.
class UsageBars extends StatelessWidget {
  const UsageBars({
    super.key,
    required this.values,
    required this.labels,
    this.selected,
    this.onSelect,
    this.height = 200,
  });

  /// (download, upload) per bar.
  final List<({int rx, int tx})> values;
  final List<String> labels;
  final int? selected;
  final ValueChanged<int>? onSelect;
  final double height;

  @override
  Widget build(BuildContext context) {
    final net = NetColors.of(context);
    final t = Theme.of(context);
    final peak = values.fold<int>(1, (m, v) => math.max(m, v.rx + v.tx));
    // Label every bar when they fit, else every few.
    return LayoutBuilder(
      builder: (context, c) {
        final every = math.max(1, (values.length * 52 / c.maxWidth).ceil());
        return SizedBox(
          height: height,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (final (i, v) in values.indexed)
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: onSelect == null ? null : () => onSelect!(i),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: values.length > 40 ? 1 : 3),
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: FractionallySizedBox(
                                widthFactor: 1,
                                heightFactor: ((v.rx + v.tx) / peak).clamp(0.0, 1.0),
                                child: _Bar(
                                  rx: v.rx,
                                  tx: v.tx,
                                  down: net.download,
                                  up: net.upload,
                                  highlight: selected == null || selected == i,
                                  radius: math.min(6, net.radius / 3),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        SizedBox(
                          height: 16,
                          // Counted back from the latest bar, which is always labelled.
                          child: (values.length - 1 - i) % every == 0
                              // The last label ends at the chart's edge rather than past it.
                              ? OverflowBox(
                                  maxWidth: double.infinity,
                                  alignment: i == values.length - 1
                                      ? Alignment.centerRight
                                      : Alignment.center,
                                  child: Text(
                                    labels[i],
                                    maxLines: 1,
                                    overflow: TextOverflow.visible,
                                    softWrap: false,
                                    style: t.textTheme.labelSmall?.copyWith(
                                      color: selected == i
                                          ? t.colorScheme.onSurface
                                          : t.colorScheme.onSurfaceVariant,
                                      fontWeight: selected == i ? FontWeight.w700 : null,
                                    ),
                                  ),
                                )
                              : null,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({
    required this.rx,
    required this.tx,
    required this.down,
    required this.up,
    required this.highlight,
    required this.radius,
  });
  final int rx;
  final int tx;
  final Color down;
  final Color up;
  final bool highlight;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final total = rx + tx;
    if (total == 0) return const SizedBox.shrink();
    final alpha = highlight ? 1.0 : 0.35;
    return ClipRRect(
      borderRadius: BorderRadius.vertical(top: Radius.circular(radius)),
      // Stretched: a ColoredBox with no child is otherwise zero wide.
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (tx > 0)
            Expanded(
              flex: math.max(1, (tx * 1000 / total).round()),
              child: ColoredBox(color: up.withValues(alpha: alpha)),
            ),
          if (rx > 0)
            Expanded(
              flex: math.max(1, (rx * 1000 / total).round()),
              child: ColoredBox(color: down.withValues(alpha: alpha)),
            ),
        ],
      ),
    );
  }
}

/// Shares of a whole as a ring, biggest first, with a legend.
class ShareRing extends StatelessWidget {
  const ShareRing({super.key, required this.parts, this.size = 132, this.centre});
  final List<({String label, int value, Color color})> parts;
  final double size;
  final Widget? centre;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final total = parts.fold<int>(0, (s, p) => s + p.value);
    return Wrap(
      spacing: 24,
      runSpacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SizedBox.square(
          dimension: size,
          child: CustomPaint(
            painter: _Ring(parts, total, NetColors.of(context).grid),
            child: Center(child: centre),
          ),
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final p in parts)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(color: p.color, borderRadius: BorderRadius.circular(3)),
                    ),
                    const SizedBox(width: 8),
                    Text(p.label, style: t.textTheme.bodyMedium),
                    const SizedBox(width: 8),
                    Text(
                      total == 0 ? '' : '${(p.value * 100 / total).round()}%',
                      style: t.textTheme.bodySmall
                          ?.merge(tabular)
                          .copyWith(color: t.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _Ring extends CustomPainter {
  _Ring(this.parts, this.total, this.track);
  final List<({String label, int value, Color color})> parts;
  final int total;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * 0.12;
    final rect = (Offset.zero & size).deflate(stroke / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    canvas.drawArc(rect, 0, math.pi * 2, false, paint..color = track);
    if (total == 0) return;
    var start = -math.pi / 2;
    for (final p in parts) {
      final sweep = math.pi * 2 * p.value / total;
      // A hairline gap between parts.
      canvas.drawArc(rect, start, math.max(0, sweep - 0.02), false, paint..color = p.color);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(_Ring old) => true;
}

/// A thin bar for a share of something (a plan, a list row).
class Meter extends StatelessWidget {
  const Meter({super.key, required this.value, this.color, this.height = 8});
  final double value;
  final Color? color;
  final double height;

  @override
  Widget build(BuildContext context) {
    final net = NetColors.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: LinearProgressIndicator(
        value: value.clamp(0, 1),
        minHeight: height,
        backgroundColor: net.grid,
        color: color ?? Theme.of(context).colorScheme.primary,
      ),
    );
  }
}

/// A small coloured dot and label for chart legends.
class LegendDot extends StatelessWidget {
  const LegendDot(this.color, this.label, {super.key});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: 6),
      Text(label, style: Theme.of(context).textTheme.labelMedium),
    ],
  );
}

/// The colour of a series slot, for breakdowns by device or app.
Color seriesColor(BuildContext context, int i) {
  final c = ChartColors.of(context).series;
  return c[i % c.length];
}
