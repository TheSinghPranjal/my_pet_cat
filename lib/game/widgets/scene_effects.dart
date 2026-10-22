import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../models/cat_game_state.dart';
import '../models/game_positions.dart';
import '../sketch/sketch.dart';

/// Draws every running [SceneEffect]. Each effect is a pure function of its
/// time, using a few fixed paths rather than a particle system.
class SceneEffectsPainter extends CustomPainter {
  SceneEffectsPainter({required this.effects, required this.layout});

  final List<SceneEffect> effects;
  final GameLayout layout;

  @override
  void paint(Canvas canvas, Size size) {
    final k = layout.unit / 100;
    for (final e in effects) {
      if (e.fade <= 0) continue;
      final anchor = layout.toPixels(e.anchor);
      canvas.save();
      canvas.translate(anchor.dx, anchor.dy);
      canvas.scale(k);
      final pen = SketchPen(canvas, pxPerUnit: k);
      switch (e.kind) {
        case EffectKind.bubbles:
          _bubbles(pen, e);
        case EffectKind.splash:
          _splash(pen, e);
        case EffectKind.sparkles:
          _sparkles(pen, e);
        case EffectKind.droplets:
          _droplets(pen, e);
        case EffectKind.leaves:
          _leaves(pen, e);
        case EffectKind.puff:
          _puff(pen, e);
        case EffectKind.aroma:
          _curls(pen, e, SketchColors.sunEdge, period: 1.6);
        case EffectKind.steam:
          _curls(pen, e, SketchColors.inkSoft, period: 1.2);
        case EffectKind.heat:
          _heat(pen, e);
        case EffectKind.scratches:
          _scratches(pen, e);
        case EffectKind.impact:
          _impact(pen, e);
        case EffectKind.hearts:
          _hearts(pen, e);
        case EffectKind.timer:
          _timer(pen, e);
        case EffectKind.zap:
          _zap(pen, e);
        case EffectKind.feathers:
          _feathers(pen, e);
        case EffectKind.purr:
          _purr(pen, e);
        case EffectKind.quack:
          _quack(pen, e);
        case EffectKind.leafBurst:
          _leafBurst(pen, e);
      }
      canvas.restore();
    }
  }

  /// A silly cartoon zap: yellow zigzag bolts flickering around the cat.
  void _zap(SketchPen pen, SceneEffect e) {
    final flicker = (e.time * 16).floor();
    for (var i = 0; i < 7; i++) {
      if ((i + flicker).isOdd && i > 1) continue;
      final a = -math.pi + i / 6 * math.pi + (flicker.isEven ? 0.12 : -0.12);
      final d = Offset(math.cos(a), math.sin(a) * 0.85);
      final n = Offset(-d.dy, d.dx);
      final from = d * 11;
      final bolt = Path()..moveTo(from.dx, from.dy);
      for (var j = 1; j <= 3; j++) {
        final p = d * (11 + j * 2.6) + n * (j.isOdd ? 1.4 : -1.4);
        bolt.lineTo(p.dx, p.dy);
      }
      pen.stroke(bolt, _a(SketchColors.sun, e.fade), width: 1.6, sketchy: false, wobble: 0);
      pen.stroke(bolt, _a(SketchColors.sunEdge, e.fade), width: 0.6, sketchy: false, wobble: 0);
    }
    for (final (i, o) in const [Offset(-13, -9), Offset(12, -11), Offset(0, -16)].indexed) {
      final pulse = (math.sin(e.time * 20 + i * 2) + 1) / 2;
      pen.star(o, 1 + pulse * 1.4, _a(SketchColors.sunEdge, e.fade), width: 0.6);
    }
  }

  /// A few feathers bursting up from a pillow and drifting down.
  void _feathers(SketchPen pen, SceneEffect e) {
    for (var i = 0; i < 6; i++) {
      final t = e.time - i * 0.12;
      if (t < 0) continue;
      final up = math.min(t / 0.4, 1.0);
      final fall = math.max(0.0, t - 0.4);
      final c = Offset((i - 2.5) * 3.2 * up + math.sin(fall * 4 + i) * 2.5, -9 * up + fall * 5);
      final canvas = pen.canvas;
      canvas.save();
      canvas.translate(c.dx, c.dy);
      canvas.rotate(math.sin(fall * 3 + i) * 0.7);
      final feather = Path()
        ..moveTo(0, -2.4)
        ..quadraticBezierTo(1.4, 0, 0, 2.4)
        ..quadraticBezierTo(-1.4, 0, 0, -2.4)
        ..close();
      final alpha = e.fade * (1 - (fall / 2).clamp(0.0, 1.0));
      pen.fill(feather, _a(SketchColors.white, alpha));
      pen.stroke(feather, _a(SketchColors.graphite, alpha), width: 0.35, sketchy: false, wobble: 0);
      pen.line(const Offset(0, -2), const Offset(0, 2.6), _a(SketchColors.graphite, alpha), width: 0.3, sketchy: false);
      canvas.restore();
    }
  }

  /// Soft "purr" squiggles rising and fading.
  void _purr(SketchPen pen, SceneEffect e) {
    for (var i = 0; i < 3; i++) {
      final ph = (e.time / 1.6 + i / 3) % 1;
      final o = Offset(-8 + i * 7, -ph * 14);
      final wave = Path()..moveTo(o.dx - 4, o.dy);
      for (var j = 0; j < 4; j++) {
        wave.quadraticBezierTo(o.dx - 3 + j * 2, o.dy + (j.isEven ? -1.4 : 1.4), o.dx - 2 + j * 2, o.dy);
      }
      pen.stroke(wave, _a(SketchColors.pinkDeep, e.fade * (1 - ph)), width: 0.8, sketchy: false, wobble: 0);
    }
  }

  /// A loud "quack": sound arcs bursting from the duck's beak.
  void _quack(SketchPen pen, SceneEffect e) {
    final t = (e.time / (e.duration ?? 1.0)).clamp(0.0, 1.0);
    for (var i = 0; i < 3; i++) {
      final r = 3 + i * 3 + t * 4;
      final alpha = e.fade * (1 - t) * (1 - i * 0.2);
      pen.stroke(Path()..addArc(Rect.fromCircle(center: Offset.zero, radius: r), -2.4, 1.6),
          _a(SketchColors.sunEdge, alpha), width: 1.0, sketchy: false, wobble: 0);
    }
    pen.popMarks(const Offset(-6, -6), 5, t, _a(SketchColors.ink, e.fade), width: 0.7);
  }

  /// Autumn leaves bursting up out of a pile and floating down.
  void _leafBurst(SketchPen pen, SceneEffect e) {
    const colors = [SketchColors.coral, SketchColors.sunEdge, SketchColors.wool, SketchColors.kibble];
    for (var i = 0; i < 10; i++) {
      final up = math.min(e.time / 0.45, 1.0);
      final fall = math.max(0.0, e.time - 0.45);
      final spread = (i - 4.5) * 2.6;
      final c = Offset(spread * up + math.sin(fall * 3 + i) * 3, -(14 + (i % 3) * 4) * up + fall * 7);
      final canvas = pen.canvas;
      canvas.save();
      canvas.translate(c.dx, c.dy);
      canvas.rotate(i + fall * 2.5);
      final leaf = Path()
        ..moveTo(-2.2, 0)
        ..quadraticBezierTo(0, -1.8, 2.2, 0)
        ..quadraticBezierTo(0, 1.8, -2.2, 0)
        ..close();
      final alpha = e.fade * (1 - (fall / 2.2).clamp(0.0, 1.0));
      pen.fill(leaf, _a(colors[i % colors.length], alpha * 0.85));
      pen.stroke(leaf, _a(SketchColors.kibbleDark, alpha), width: 0.35, sketchy: false, wobble: 0);
      canvas.restore();
    }
  }

  Color _a(Color c, double alpha) => c.withValues(alpha: (c.a * alpha).clamp(0.0, 1.0));

  void _bubbles(SketchPen pen, SceneEffect e) {
    for (var i = 0; i < 8; i++) {
      final ph = (e.time / 2.2 + i * 0.137) % 1;
      final c = Offset(-12 + i * 3.4 + math.sin(ph * 7 + i) * 1.8, -ph * 26);
      final r = (1.4 + (i % 3) * 0.7) * (0.6 + ph * 0.6);
      final alpha = e.fade * math.sqrt(1 - ph);
      pen.stroke(ovalPath(c, r * 2, r * 2), _a(SketchColors.inkSoft, alpha),
          width: 0.45, sketchy: false, wobble: 0.05);
      pen.fill(ovalPath(c + Offset(-r * 0.4, -r * 0.4), r * 0.5, r * 0.5), _a(SketchColors.inkWash, alpha));
    }
  }

  void _splash(SketchPen pen, SceneEffect e) {
    final ph = (e.time % 0.9) / 0.9;
    for (final (dx, up) in const [(-1.0, 1.0), (0.2, 1.3), (1.1, 0.9)]) {
      final p = Offset(dx * 9 * ph, -10 * up * ph + 14 * ph * ph);
      final drop = Path()
        ..moveTo(p.dx, p.dy - 1.4)
        ..quadraticBezierTo(p.dx + 1, p.dy + 0.2, p.dx, p.dy + 0.7)
        ..quadraticBezierTo(p.dx - 1, p.dy + 0.2, p.dx, p.dy - 1.4)
        ..close();
      pen.fill(drop, _a(SketchColors.inkWash, e.fade * (1 - ph)));
      pen.stroke(drop, _a(SketchColors.inkSoft, e.fade * (1 - ph)), width: 0.35, sketchy: false, wobble: 0);
    }
  }

  void _sparkles(SketchPen pen, SceneEffect e) {
    const spots = [Offset(-8, -4), Offset(6, -9), Offset(10, 2), Offset(-2, -12)];
    const colors = [SketchColors.sunEdge, SketchColors.ink, SketchColors.pinkDeep, SketchColors.sunEdge];
    for (var i = 0; i < spots.length; i++) {
      final pulse = (math.sin(e.time * 6 + i * 1.7) + 1) / 2;
      pen.star(spots[i], 0.8 + 1.4 * pulse, _a(colors[i], e.fade), width: 0.6);
    }
  }

  void _droplets(SketchPen pen, SceneEffect e) {
    final ph = (e.time % 0.6) / 0.6;
    for (var i = 0; i < 8; i++) {
      final a = -math.pi + i / 7 * math.pi;
      final dir = Offset(math.cos(a), math.sin(a) * 0.8);
      final p = dir * (5 + ph * 13) + Offset(0, ph * ph * 7);
      final r = 2.0 * (1 - ph * 0.5);
      final alpha = e.fade * (1 - ph * ph);
      pen.fill(ovalPath(p, r * 1.4, r * 1.9), _a(SketchColors.inkWash, alpha));
      pen.stroke(ovalPath(p, r * 1.4, r * 1.9), _a(SketchColors.ink, alpha),
          width: 0.5, sketchy: false, wobble: 0);
    }
  }

  void _leaves(SketchPen pen, SceneEffect e) {
    for (var i = 0; i < 5; i++) {
      final t = e.time - i * 0.5;
      if (t < 0) continue;
      final ph = (t / 2.6) % 1;
      final c = Offset(-10 + i * 5 + math.sin(ph * 6 + i) * 4, ph * 32);
      final canvas = pen.canvas;
      canvas.save();
      canvas.translate(c.dx, c.dy);
      canvas.rotate(math.sin(ph * 5 + i) * 0.8);
      final leaf = Path()
        ..moveTo(-2.2, 0)
        ..quadraticBezierTo(0, -1.6, 2.2, 0)
        ..quadraticBezierTo(0, 1.6, -2.2, 0)
        ..close();
      final alpha = e.fade * (ph < 0.85 ? 1 : (1 - ph) / 0.15);
      pen.fill(leaf, _a(SketchColors.leaf, alpha * 0.8));
      pen.stroke(leaf, _a(SketchColors.leafDark, alpha), width: 0.4, sketchy: false, wobble: 0);
      canvas.restore();
    }
  }

  void _puff(SketchPen pen, SceneEffect e) {
    final t = (e.time / (e.duration ?? 0.45)).clamp(0.0, 1.0);
    for (final (i, o) in const [Offset(-2.5, -1.5), Offset(2.5, -2), Offset(0, -4)].indexed) {
      final r = 1.5 + t * (2.5 + i * 0.5);
      pen.stroke(ovalPath(o * (1 + t), r * 2, r * 2), _a(SketchColors.graphite, e.fade * (1 - t)),
          width: 0.5, sketchy: false, wobble: 0.1);
    }
    pen.popMarks(const Offset(0, -2), 6, t, _a(SketchColors.ink, e.fade), width: 0.6);
  }

  /// Two or three wavy curls drifting up along fixed paths.
  void _curls(SketchPen pen, SceneEffect e, Color color, {required double period}) {
    for (var i = 0; i < 3; i++) {
      final ph = (e.time / period + i / 3) % 1;
      final x = -4.0 + i * 4;
      final y = -ph * 14;
      final alpha = e.fade * math.sin(ph * math.pi);
      pen.stroke(
        Path()
          ..moveTo(x, y)
          ..quadraticBezierTo(x - 2.2, y - 2.5, x, y - 5)
          ..quadraticBezierTo(x + 2.2, y - 7.5, x, y - 10),
        _a(color, alpha),
        width: 0.7,
        sketchy: false,
        wobble: 0,
      );
    }
  }

  void _heat(SketchPen pen, SceneEffect e) {
    for (var i = 0; i < 4; i++) {
      final flicker = (math.sin(e.time * 11 + i * 1.9) + 1) / 2;
      final x = -6 + i * 4.0;
      pen.line(Offset(x, 1.2), Offset(x + 0.4, 1.2 + 1.2 + flicker * 1.4), _a(SketchColors.sunEdge, e.fade),
          width: 0.6, sketchy: false, wobble: 0);
    }
  }

  void _scratches(SketchPen pen, SceneEffect e) {
    final shown = ((e.time * 6) % 4).floor();
    for (var i = 0; i < 3; i++) {
      if (i > shown) break;
      final x = -2.5 + i * 2.2;
      pen.line(Offset(x, -3), Offset(x - 1.5, 3), _a(SketchColors.ink, e.fade), width: 0.6, sketchy: false, wobble: 0);
    }
  }

  void _impact(SketchPen pen, SceneEffect e) {
    final t = (e.time / (e.duration ?? 0.6)).clamp(0.0, 1.0);
    pen.popMarks(const Offset(0, -2), 5, t, _a(SketchColors.ink, e.fade), width: 0.7);
    pen.star(Offset(-5 - t * 3, -4 - t * 2), 1.4 * (1 - t), _a(SketchColors.sunEdge, e.fade), width: 0.6);
    pen.star(Offset(5 + t * 3, -5 - t * 2), 1.2 * (1 - t), _a(SketchColors.pinkDeep, e.fade), width: 0.6);
  }

  void _hearts(SketchPen pen, SceneEffect e) {
    for (var i = 0; i < 3; i++) {
      final ph = (e.time / 1.4 + i / 3) % 1;
      final c = Offset(-4 + i * 4 + math.sin(ph * 5 + i) * 1.2, -ph * 9);
      final s = 0.5 + 0.3 * (i % 2);
      final heart = Path()
        ..moveTo(c.dx, c.dy + 3 * s)
        ..cubicTo(c.dx - 4.5 * s, c.dy, c.dx - 2.5 * s, c.dy - 3.5 * s, c.dx, c.dy - 1.4 * s)
        ..cubicTo(c.dx + 2.5 * s, c.dy - 3.5 * s, c.dx + 4.5 * s, c.dy, c.dx, c.dy + 3 * s)
        ..close();
      final alpha = e.fade * math.sin(ph * math.pi);
      pen.fill(heart, _a(SketchColors.pink, alpha));
      pen.stroke(heart, _a(SketchColors.pinkDeep, alpha), width: 0.4, sketchy: false, wobble: 0);
    }
  }

  /// A little kitchen-timer doodle whose wedge fills as cooking progresses.
  void _timer(SketchPen pen, SceneEffect e) {
    final t = (e.time / (e.duration ?? 4)).clamp(0.0, 1.0);
    final alpha = e.fade * (t > 0.92 ? (1 - t) / 0.08 : 1);
    final face = ovalPath(Offset.zero, 8, 8);
    pen.fill(face, _a(SketchColors.white, alpha));
    pen.fill(
      Path()
        ..moveTo(0, 0)
        ..arcTo(Rect.fromCircle(center: Offset.zero, radius: 3.4), -math.pi / 2, t * math.pi * 2, false)
        ..close(),
      _a(SketchColors.coral, alpha * 0.8),
    );
    pen.stroke(face, _a(SketchColors.ink, alpha), width: 0.6, sketchy: false, wobble: 0.1);
    pen.line(const Offset(0, -4), const Offset(0, -5.4), _a(SketchColors.ink, alpha), width: 0.8, sketchy: false, wobble: 0);
  }

  @override
  bool shouldRepaint(SceneEffectsPainter oldDelegate) => true;
}
