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
      }
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

  @override
  bool shouldRepaint(SceneEffectsPainter oldDelegate) => true;
}
