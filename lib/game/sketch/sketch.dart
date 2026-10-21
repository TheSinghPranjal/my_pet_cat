import 'dart:math' as math;

import 'package:flutter/painting.dart';

/// The pens and colored pencils used across the whole notebook world.
abstract final class SketchColors {
  static const paper = Color(0xFFFCFBF6);
  static const grid = Color(0xFFD2E1F3);
  static const ink = Color(0xFF2236B5);
  static const inkSoft = Color(0xFF6E86DD);
  static const inkWash = Color(0xFFBFCEF4);
  static const pencil = Color(0xFF26262B);
  static const graphite = Color(0xFF8C8C94);
  static const stripe = Color(0xFF66666E);
  static const pink = Color(0xFFF4A7BA);
  static const pinkDeep = Color(0xFFE0708F);
  static const mouth = Color(0xFFC93A55);
  static const leaf = Color(0xFF45B24F);
  static const leafDark = Color(0xFF247A34);
  static const sun = Color(0xFFFFCB2E);
  static const sunEdge = Color(0xFFF0A20F);
  static const wool = Color(0xFFDD2B2B);
  static const woolDark = Color(0xFFB01C1C);
  static const kibble = Color(0xFFA5642F);
  static const kibbleDark = Color(0xFF6E3E19);
  static const eye = Color(0xFF1A2246);
  static const iris = Color(0xFF3B5FCC);
  static const white = Color(0xFFFFFFFF);
  static const coral = Color(0xFFEE7766);
  static const coralLight = Color(0xFFFBD9D2);
  static const wood = Color(0xFFC58A4E);
  static const woodLight = Color(0xFFF3DDBF);
}

/// Hand-drawn drawing helpers: wobbly doubled ink lines and pencil hatching.
///
/// Drawing happens in "units"; [pxPerUnit] tells the pen how big a unit is on
/// screen so the wobble frequency stays consistent at any scale. Wobble is
/// seeded, so the same shape always gets the same imperfections and lines
/// never "boil" between frames.
class SketchPen {
  SketchPen(this.canvas, {this.pxPerUnit = 1, this.weight = 1});

  final Canvas canvas;
  final double pxPerUnit;

  /// Multiplier for every line width, so large scenes can use a finer pen.
  final double weight;

  Path wobbly(Path source, {double amplitude = 0.5, int seed = 0}) {
    if (amplitude <= 0) return source;
    final out = Path();
    final rnd = math.Random(seed);
    final step = 4 / pxPerUnit;
    for (final metric in source.computeMetrics()) {
      final length = metric.length;
      if (length <= 0) continue;
      final p1 = rnd.nextDouble() * math.pi * 2;
      final p2 = rnd.nextDouble() * math.pi * 2;
      final f1 = (0.04 + rnd.nextDouble() * 0.03) * pxPerUnit;
      final f2 = (0.11 + rnd.nextDouble() * 0.07) * pxPerUnit;
      // Closed shapes overshoot their start a little, like a real pen.
      final overshoot =
          metric.isClosed ? math.min(length * 0.08, 6 / pxPerUnit) : 0.0;
      final total = length + overshoot;
      final n = math.max(2, (total / step).ceil());
      for (var i = 0; i <= n; i++) {
        final d = total * i / n;
        final tangent = metric.getTangentForOffset(d > length ? d - length : d);
        if (tangent == null) continue;
        final normal = Offset(-tangent.vector.dy, tangent.vector.dx);
        final offset =
            amplitude * (0.7 * math.sin(d * f1 + p1) + 0.3 * math.sin(d * f2 + p2));
        final point = tangent.position + normal * offset;
        if (i == 0) {
          out.moveTo(point.dx, point.dy);
        } else {
          out.lineTo(point.dx, point.dy);
        }
      }
    }
    return out;
  }

  Paint _strokePaint(Color color, double width) => Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..color = color
    ..strokeWidth = width * weight;

  /// Ink outline: one confident line plus a fainter second pass.
  void stroke(
    Path path,
    Color color, {
    double width = 1,
    double wobble = 0.5,
    int seed = 0,
    bool sketchy = true,
  }) {
    final paint = _strokePaint(color, width);
    canvas.drawPath(wobbly(path, amplitude: wobble, seed: seed), paint);
    if (sketchy) {
      paint
        ..color = color.withValues(alpha: color.a * 0.4)
        ..strokeWidth = width * 0.55 * weight;
      canvas.drawPath(
        wobbly(path, amplitude: wobble * 1.4 + 0.15, seed: seed + 97),
        paint,
      );
    }
  }

  void line(
    Offset a,
    Offset b,
    Color color, {
    double width = 1,
    double wobble = 0.3,
    int seed = 0,
    bool sketchy = true,
  }) {
    stroke(
      Path()
        ..moveTo(a.dx, a.dy)
        ..lineTo(b.dx, b.dy),
      color,
      width: width,
      wobble: wobble,
      seed: seed,
      sketchy: sketchy,
    );
  }

  void fill(Path path, Color color) {
    canvas.drawPath(path, Paint()..color = color);
  }

  /// Colored-pencil shading: parallel strokes clipped to [area].
  void hatch(
    Path area,
    Color color, {
    double spacing = 2,
    double angle = -0.9,
    double width = 0.45,
    int seed = 0,
    bool cross = false,
  }) {
    final bounds = area.getBounds();
    if (bounds.isEmpty) return;
    canvas.save();
    canvas.clipPath(area);
    final rnd = math.Random(seed);
    final paint = _strokePaint(color, width)..strokeCap = StrokeCap.butt;
    final center = bounds.center;
    final reach = bounds.size.longestSide * 0.75 + spacing;
    for (final a in cross ? [angle, angle + 1.35] : [angle]) {
      final dir = Offset(math.cos(a), math.sin(a));
      final normal = Offset(-dir.dy, dir.dx);
      for (var k = -reach; k <= reach; k += spacing) {
        final kk = k + (rnd.nextDouble() - 0.5) * spacing * 0.35;
        final base = center + normal * kk;
        paint.color = color.withValues(alpha: color.a * (0.55 + 0.45 * rnd.nextDouble()));
        canvas.drawLine(
          base - dir * reach * (0.85 + rnd.nextDouble() * 0.15),
          base + dir * reach,
          paint,
        );
      }
    }
    canvas.restore();
  }

  /// A soft outlined tube (legs, tails, stems).
  void tube(
    Path centerline, {
    required double width,
    required Color outline,
    required Color fill,
    double lineWidth = 1,
    double wobble = 0.3,
    int seed = 0,
  }) {
    final path = wobbly(centerline, amplitude: wobble, seed: seed);
    canvas.drawPath(path, _strokePaint(outline, width + lineWidth * 2));
    canvas.drawPath(path, _strokePaint(fill, width));
  }

  /// Little burst of radiating pen marks used when props disappear.
  void popMarks(Offset center, double radius, double t, Color color, {double width = 1}) {
    if (t <= 0 || t >= 1) return;
    final fade = color.withValues(alpha: color.a * (1 - t * t));
    const count = 9;
    for (var i = 0; i < count; i++) {
      final angle = i / count * math.pi * 2 + 0.35;
      final dir = Offset(math.cos(angle), math.sin(angle));
      final inner = radius * (0.55 + 0.75 * t);
      final outer = inner + radius * 0.32 * (1 - t * 0.5);
      line(center + dir * inner, center + dir * outer, fade,
          width: width, wobble: 0, sketchy: false);
      if (i.isEven) {
        star(center + dir * (outer + radius * 0.18), radius * 0.07 * (1 - t), fade,
            width: width * 0.8);
      }
    }
  }

  void star(Offset c, double r, Color color, {double width = 1}) {
    if (r <= 0) return;
    final paint = _strokePaint(color, width);
    canvas.drawLine(c - Offset(r, 0), c + Offset(r, 0), paint);
    canvas.drawLine(c - Offset(0, r), c + Offset(0, r), paint);
  }
}

Path rectPath(double l, double t, double r, double b) =>
    Path()..addRect(Rect.fromLTRB(l, t, r, b));

Path ovalPath(Offset center, double width, double height) =>
    Path()..addOval(Rect.fromCenter(center: center, width: width, height: height));

Path polygon(List<Offset> points) => Path()..addPolygon(points, true);
