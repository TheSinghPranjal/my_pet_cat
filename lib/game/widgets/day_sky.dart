import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../models/day_phase.dart';
import '../sketch/sketch.dart';

/// Skies and light for each [DayPhase], in the notebook style: coloured
/// pencil fills and hatching, a sun or moon, clouds or stars.
abstract final class DaySky {
  static const _morning = Color(0xFFFFEFD2);
  static const _morningEdge = Color(0xFFF7C68A);
  static const _noon = Color(0xFFC9E6FF);
  static const _dusk = [Color(0xFFB7A0E6), Color(0xFFF6A3BA), Color(0xFFFFC27A)];
  static const _night = Color(0xFF232A63);
  static const _nightDeep = Color(0xFF131840);
  static const _moon = Color(0xFFFFF0B3);

  /// The colour wash laid over a whole scene: warm morning light, a
  /// glaring hot noon, a rosy evening, and a deep blue night.
  static (Color, double) wash(DayPhase phase, {required bool outdoors}) => switch (phase) {
    DayPhase.morning => (const Color(0xFFFFE6A8), 0.07),
    DayPhase.noon => (const Color(0xFFFFB627), 0.17),
    DayPhase.evening => (const Color(0xFFFF8E6E), 0.15),
    DayPhase.night => (const Color(0xFF1B2470), outdoors ? 0.32 : 0.42),
  };

  /// What a window shows, clipped to [glass].
  static void window(SketchPen pen, Rect glass, DayPhase phase, {int seed = 0}) {
    final canvas = pen.canvas;
    canvas.save();
    canvas.clipRect(glass);
    final s = glass.shortestSide / 26;
    switch (phase) {
      case DayPhase.morning:
        pen.fill(Path()..addRect(glass), _morning);
        pen.hatch(Path()..addRect(glass), _morningEdge.withValues(alpha: 0.5), spacing: 2.6, angle: -0.6, seed: seed);
        sun(pen, Offset(glass.left + glass.width * 0.3, glass.top + glass.height * 0.62), 3.4 * s, seed + 1, rays: 0.8);
        _cloud(pen, Offset(glass.left + glass.width * 0.5, glass.top + glass.height * 0.3), 0.6 * s, seed + 2);
      case DayPhase.noon:
        pen.fill(Path()..addRect(glass), _noon);
        pen.hatch(
          Path()..addRect(glass),
          SketchColors.inkSoft.withValues(alpha: 0.35),
          spacing: 2.4,
          angle: -0.6,
          seed: seed,
        );
        sun(pen, Offset(glass.left + glass.width * 0.62, glass.top + glass.height * 0.3), 4.6 * s, seed + 1, rays: 1.6);
        heatWaves(pen, Rect.fromLTRB(glass.left, glass.top + glass.height * 0.62, glass.right, glass.bottom), seed + 3);
      case DayPhase.evening:
        _bands(pen, glass, seed);
        final c = Offset(glass.left + glass.width * 0.4, glass.bottom - glass.height * 0.08);
        sun(pen, c, 4.2 * s, seed + 1, rays: 0.5, color: const Color(0xFFFF9A4D), edge: const Color(0xFFE5602E));
        pen.star(
          Offset(glass.right - glass.width * 0.2, glass.top + glass.height * 0.2),
          0.9 * s,
          SketchColors.white,
          width: 0.5,
        );
      case DayPhase.night:
        pen.fill(Path()..addRect(glass), _night);
        pen.hatch(Path()..addRect(glass), _nightDeep, spacing: 1.3, angle: -0.6, seed: seed);
        moon(pen, Offset(glass.left + glass.width * 0.66, glass.top + glass.height * 0.32), 3.4 * s, seed + 1);
        stars(pen, glass, 6, seed + 2, size: s);
    }
    canvas.restore();
  }

  /// The open sky over an outdoor scene, from the top down to [horizon].
  static void open(SketchPen pen, double w, double horizon, DayPhase phase, {int seed = 50}) {
    final sky = Rect.fromLTRB(-1, -1, w + 1, horizon);
    switch (phase) {
      case DayPhase.morning:
        pen.hatch(Path()..addRect(sky), _morningEdge.withValues(alpha: 0.35), spacing: 3.2, angle: -0.5, seed: seed);
        sun(pen, Offset(w * 0.18, horizon * 0.42), 4.8, seed + 1, rays: 0.9);
        _cloud(pen, Offset(w * 0.34, horizon * 0.2), 1.2, seed + 2);
        _cloud(pen, Offset(w * 0.6, horizon * 0.3), 0.9, seed + 3);
      case DayPhase.noon:
        pen.hatch(
          Path()..addRect(sky),
          SketchColors.inkSoft.withValues(alpha: 0.18),
          spacing: 3.0,
          angle: -0.5,
          seed: seed,
        );
        sun(pen, Offset(w * 0.72, horizon * 0.2), 6.4, seed + 1, rays: 1.9);
        _cloud(pen, Offset(w * 0.28, horizon * 0.24), 1.0, seed + 2);
        heatWaves(pen, Rect.fromLTRB(0, horizon * 0.7, w, horizon - 2), seed + 3);
      case DayPhase.evening:
        _bands(pen, sky, seed);
        sun(
          pen,
          Offset(w * 0.76, horizon * 0.86),
          6.2,
          seed + 1,
          rays: 0.6,
          color: const Color(0xFFFF9A4D),
          edge: const Color(0xFFE5602E),
        );
        for (final (x, y) in const [(0.3, 0.3), (0.38, 0.26), (0.5, 0.36)]) {
          _birdMark(pen, Offset(w * x, horizon * y));
        }
      case DayPhase.night:
        pen.fill(Path()..addRect(sky), _night.withValues(alpha: 0.9));
        pen.hatch(Path()..addRect(sky), _nightDeep, spacing: 1.6, angle: -0.5, seed: seed);
        moon(pen, Offset(w * 0.74, horizon * 0.22), 5.2, seed + 1);
        stars(pen, sky, 18, seed + 2, size: 1.3);
    }
  }

  static void _bands(SketchPen pen, Rect area, int seed) {
    for (final (i, color) in _dusk.indexed) {
      final band = Rect.fromLTRB(
        area.left,
        area.top + area.height * i / 3,
        area.right,
        area.top + area.height * (i + 1) / 3 + 0.5,
      );
      pen.fill(Path()..addRect(band), color.withValues(alpha: 0.85));
      pen.hatch(Path()..addRect(band), color, spacing: 1.8, angle: -0.3, seed: seed + i);
    }
  }

  /// A sun with rays; [rays] scales their length (long rays = a hot day).
  static void sun(
    SketchPen pen,
    Offset c,
    double r,
    int seed, {
    double rays = 1,
    Color color = SketchColors.sun,
    Color edge = SketchColors.sunEdge,
  }) {
    for (var i = 0; i < 12; i++) {
      final a = i / 12 * math.pi * 2;
      final d = Offset(math.cos(a), math.sin(a));
      pen.line(
        c + d * (r + 1.2),
        c + d * (r + 1.2 + 2.6 * rays * (i.isEven ? 1 : 0.65)),
        edge,
        width: 0.7,
        sketchy: false,
      );
    }
    final disc = ovalPath(c, r * 2, r * 2);
    pen.fill(disc, color);
    pen.hatch(disc, edge, spacing: 0.9, cross: true, seed: seed);
    pen.stroke(disc, edge, width: 0.7, seed: seed);
  }

  /// A crescent moon.
  static void moon(SketchPen pen, Offset c, double r, int seed) {
    final crescent = Path.combine(
      PathOperation.difference,
      ovalPath(c, r * 2, r * 2),
      ovalPath(c + Offset(r * 0.55, -r * 0.3), r * 1.8, r * 1.8),
    );
    pen.fill(crescent, _moon);
    pen.hatch(crescent, SketchColors.sunEdge.withValues(alpha: 0.5), spacing: 0.9, seed: seed);
    pen.stroke(crescent, SketchColors.sunEdge, width: 0.6, sketchy: false, wobble: 0.15);
  }

  /// Little twinkling stars scattered over [area] (fixed seed).
  static void stars(SketchPen pen, Rect area, int count, int seed, {double size = 1}) {
    final rnd = math.Random(seed);
    for (var i = 0; i < count; i++) {
      final p = Offset(
        area.left + area.width * rnd.nextDouble(),
        area.top + area.height * (0.05 + 0.75 * rnd.nextDouble()),
      );
      if (i.isEven) {
        pen.star(p, (0.7 + rnd.nextDouble() * 0.6) * size, _moon, width: 0.45);
      } else {
        pen.fill(ovalPath(p, 0.6 * size, 0.6 * size), _moon);
      }
    }
  }

  /// Wavy shimmer lines rising off a very hot day.
  static void heatWaves(SketchPen pen, Rect area, int seed) {
    final rnd = math.Random(seed);
    for (var i = 0; i < 4; i++) {
      final x = area.left + area.width * (0.12 + 0.22 * i + rnd.nextDouble() * 0.06);
      final path = Path()..moveTo(x, area.bottom);
      for (var y = area.bottom; y > area.top; y -= 2.4) {
        path.quadraticBezierTo(x + (((area.bottom - y) / 2.4).round().isEven ? 1.2 : -1.2), y - 1.2, x, y - 2.4);
      }
      pen.stroke(path, const Color(0xFFFF9A4D).withValues(alpha: 0.7), width: 0.5, sketchy: false, wobble: 0);
    }
  }

  static void _cloud(SketchPen pen, Offset o, double s, int seed) {
    final path = Path()
      ..moveTo(o.dx, o.dy)
      ..quadraticBezierTo(o.dx - 2 * s, o.dy - 3.5 * s, o.dx + 1.8 * s, o.dy - 3.9 * s)
      ..quadraticBezierTo(o.dx + 2.8 * s, o.dy - 7.5 * s, o.dx + 6.6 * s, o.dy - 6.1 * s)
      ..quadraticBezierTo(o.dx + 9.8 * s, o.dy - 7.3 * s, o.dx + 10.4 * s, o.dy - 3.5 * s)
      ..quadraticBezierTo(o.dx + 13.6 * s, o.dy - 2.9 * s, o.dx + 11.8 * s, o.dy)
      ..close();
    pen.fill(path, SketchColors.white);
    pen.stroke(path, SketchColors.ink, width: 0.75, seed: seed);
  }

  static void _birdMark(SketchPen pen, Offset o) {
    pen.stroke(
      Path()
        ..moveTo(o.dx - 2.2, o.dy - 0.8)
        ..quadraticBezierTo(o.dx - 1, o.dy - 1.6, o.dx, o.dy)
        ..quadraticBezierTo(o.dx + 1, o.dy - 1.6, o.dx + 2.2, o.dy - 0.8),
      SketchColors.pencil,
      width: 0.5,
      sketchy: false,
    );
  }
}
