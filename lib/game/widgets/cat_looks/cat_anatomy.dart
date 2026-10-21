import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../animations/cat_animations.dart';
import '../../sketch/sketch.dart';

part 'cat_face.dart';

/// Fur and line colours of one look.
class CatCoat {
  const CatCoat({
    this.fur = SketchColors.white,
    this.farFur = const Color(0xFFEDEDF0),
    this.line = const Color(0xFF3A3A42),
    Color? faceLine,
    Color? mouthLine,
    Color? whisker,
    this.shade = SketchColors.graphite,
    this.bodyShade = 0.35,
    this.headShade = 0.28,
    this.blush = 0.35,
    Color? tuft,
  }) : faceLine = faceLine ?? line,
       mouthLine = mouthLine ?? line,
       whisker = whisker ?? line,
       tuft = tuft ?? fur;

  /// Near-side fur, and the slightly shaded far-side legs.
  final Color fur;
  final Color farFur;

  /// Outlines of body, head, legs, ears and tufts.
  final Color line;

  /// Eye outlines and closed or happy eye arcs.
  final Color faceLine;
  final Color mouthLine;
  final Color whisker;

  /// Form hatching across the back and crown (lighter than the fur on dark
  /// cats, so light still comes from the top left).
  final Color shade;
  final double bodyShade;
  final double headShade;

  /// Strength of the pink cheek blush.
  final double blush;

  /// Fill of the chest and belly fur tufts.
  final Color tuft;
}

/// Iris colours (the glow is the lighter crescent low in the iris).
class CatEyes {
  const CatEyes({required this.iris, required this.glow});

  static const blue = CatEyes(iris: SketchColors.iris, glow: Color(0xFF7FA6F0));

  final Color iris;
  final Color glow;
}

/// Body proportions. Every build keeps the same paw anchors.
enum CatBuild { kitten, chubby }

enum EarStyle { pointed, bent }

/// The shared cat skeleton: every look draws the same body, legs, tail,
/// head and face from one [CatFrame] in the 100x85 box (facing right,
/// anchored bottom-centre at the paws), and only changes colours,
/// proportions and markings through the hooks below.
abstract class CatAnatomy extends CustomPainter {
  CatAnatomy({required this.frame, required this.facing});

  final CatFrame frame;
  final double facing;

  // Hips and resting feet: far back, near back, far front, near front.
  static const _hips = [Offset(34, 65), Offset(40, 67), Offset(57, 65), Offset(63, 67)];
  static const _feet = [Offset(32, 81), Offset(40, 83.5), Offset(58, 81), nearFrontPawRest];
  static const _lineWidth = 0.75;

  // ---------------------------------------------------------------------------
  // Hooks
  // ---------------------------------------------------------------------------

  CatCoat get coat;
  CatEyes get eyes => CatEyes.blue;
  CatBuild get build => CatBuild.kitten;
  EarStyle get earStyle => EarStyle.pointed;

  /// Fill of leg [i] (0 far back, 1 near back, 2 far front, 3 near front).
  Color legFur(int i, {required bool far}) => far ? coat.farFur : coat.fur;

  /// Fill of paw [i]; white socks and cream toes go here.
  Color pawFur(int i, {required bool far}) => legFur(i, far: far);

  /// Markings inside the body, clipped to it.
  void paintBodyMarks(SketchPen pen, Rect body) {}

  /// Markings inside the head, clipped to it (masks, muzzles, patches).
  void paintHeadInside(SketchPen pen, Offset hc) {}

  /// Markings over the head, unclipped, under the outline (stripes that
  /// poke out like fur).
  void paintHeadMarks(SketchPen pen, Offset hc) {}

  void paintTailMarks(SketchPen pen, Path tail) {}

  void paintLegMarks(SketchPen pen, int i, Offset hip, Offset foot, {required bool far}) {}

  /// Bows and the like, over the finished head.
  void paintAccessories(SketchPen pen, Offset hc) {}

  // ---------------------------------------------------------------------------
  // Drawing
  // ---------------------------------------------------------------------------

  bool get _chubby => build == CatBuild.chubby;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 100;
    final pen = SketchPen(canvas, pxPerUnit: s);
    // Squash through the middle of a turn instead of flipping instantly.
    final flip = facing.abs() < 0.14 ? (facing < 0 ? -0.14 : 0.14) : facing;

    canvas.save();
    canvas.translate(size.width / 2, 0);
    canvas.scale(flip * s, s);
    canvas.translate(-50, 0);

    if (frame.shadow) _shadow(pen);
    canvas.translate(0, frame.bodyLift);
    if (frame.bodyRotation != 0) {
      canvas.translate(48, 62);
      canvas.rotate(frame.bodyRotation);
      canvas.translate(-48, -62);
    }
    _tail(pen);
    _leg(pen, 0, far: true);
    _leg(pen, 2, far: true);
    _body(pen);
    _leg(pen, 1, far: false);
    if (frame.raisedPaw == null) _leg(pen, 3, far: false);
    final headCenter = _head(pen);
    if (frame.raisedPaw != null) _raisedPaw(pen, frame.raisedPaw!);
    _extras(pen, headCenter);

    canvas.restore();
  }

  void _shadow(SketchPen pen) {
    final width = (_chubby ? 60 : 52) + frame.bodyLift * 1.5;
    pen.hatch(
      ovalPath(const Offset(48, 84), width, 6),
      SketchColors.ink.withValues(alpha: 0.75),
      spacing: 0.9,
      angle: -0.2,
      width: 0.5,
      seed: 3,
    );
  }

  void _tail(SketchPen pen) {
    const base = Offset(30, 58);
    final a = frame.tailAngle;
    Offset r(double x, double y) => base + Offset(x * math.cos(a) - y * math.sin(a), x * math.sin(a) + y * math.cos(a));
    final c1 = r(-13, 2), c2 = r(-22, -14), end = r(-15, -31);
    final curlControl = r(-12, -38), tip = r(-6, -33);
    final path = Path()
      ..moveTo(base.dx, base.dy)
      ..cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, end.dx, end.dy)
      ..quadraticBezierTo(curlControl.dx, curlControl.dy, tip.dx, tip.dy);
    pen.tube(path, width: _chubby ? 6.4 : 5.6, outline: coat.line, fill: coat.fur, lineWidth: 0.8, seed: 41);
    paintTailMarks(pen, path);
  }

  void _leg(SketchPen pen, int i, {required bool far}) {
    final hip = _hips[i];
    final foot = _feet[i] + frame.feet[i];
    pen.tube(
      Path()
        ..moveTo(hip.dx, hip.dy)
        ..lineTo(foot.dx, foot.dy - 2),
      width: _chubby ? 7.6 : 6.6,
      outline: coat.line,
      fill: legFur(i, far: far),
      lineWidth: 0.8,
      seed: 11 + i,
    );
    _paw(pen, foot, pawFur(i, far: far), 20 + i);
    paintLegMarks(pen, i, hip, foot, far: far);
  }

  void _paw(SketchPen pen, Offset foot, Color fur, int seed) {
    final paw = ovalPath(foot + const Offset(1, -1.8), _chubby ? 9.4 : 8.6, 5.4);
    pen.fill(paw, fur);
    pen.stroke(paw, coat.line, width: 0.8, wobble: 0.2, seed: seed);
    for (final dx in const [0.6, 3.0]) {
      pen.line(
        foot + Offset(dx, -2.2),
        foot + Offset(dx + 0.2, -0.5),
        coat.line,
        width: 0.5,
        sketchy: false,
        wobble: 0,
      );
    }
  }

  /// The body oval; a chubby cat is wider and her belly hangs a little.
  Rect _bodyRect() {
    final h = 25 * frame.breath;
    if (_chubby) return Rect.fromLTRB(19, 76.5 - h * 1.3, 72, 76.5);
    return Rect.fromLTRB(26, 72 - h, 68, 72);
  }

  void _body(SketchPen pen) {
    final rect = _bodyRect();
    final h = rect.height;
    final body = Path()..addOval(rect);
    pen.fill(body, coat.fur);
    pen.canvas.save();
    pen.canvas.clipPath(body);
    pen.hatch(
      rectPath(20, rect.top, 72, rect.top + h * 0.4),
      coat.shade.withValues(alpha: coat.bodyShade),
      spacing: 1.3,
      angle: -1.0,
      width: 0.4,
      seed: 5,
    );
    paintBodyMarks(pen, rect);
    pen.canvas.restore();
    pen.stroke(body, coat.line, width: _lineWidth, seed: 21);
    // Fluffy chest and belly tufts over the outline.
    _tuft(pen, Offset(rect.right - 2.5, rect.top + h * 0.55), 4, 1.9, 0.35, 61);
    _tuft(pen, Offset(48, rect.bottom - 0.4), 4, 1.5, math.pi / 2, 62);
  }

  /// A small row of fur spikes poking out from an outline at [at], pointing
  /// in [direction] (radians).
  void _tuft(SketchPen pen, Offset at, int spikes, double length, double direction, int seed) {
    final out = Offset(math.cos(direction), math.sin(direction));
    final along = Offset(-out.dy, out.dx);
    const gap = 1.7;
    final start = at - along * (gap * spikes / 2);
    final path = Path()..moveTo(start.dx, start.dy);
    for (var i = 0; i < spikes; i++) {
      final tip = start + along * (gap * (i + 0.5)) + out * length + along * 0.4;
      final next = start + along * (gap * (i + 1));
      path
        ..lineTo(tip.dx, tip.dy)
        ..lineTo(next.dx, next.dy);
    }
    final fill = Path.from(path)..close();
    pen.fill(fill, coat.tuft);
    pen.stroke(path, coat.line, width: 0.75, wobble: 0.05, sketchy: false, seed: seed);
  }

  void _raisedPaw(SketchPen pen, Offset paw) {
    const shoulder = Offset(63, 65);
    final control = Offset((shoulder.dx + paw.dx) / 2 + 3, math.max(shoulder.dy, paw.dy) + 2);
    pen.tube(
      Path()
        ..moveTo(shoulder.dx, shoulder.dy)
        ..quadraticBezierTo(control.dx, control.dy, paw.dx, paw.dy + 1),
      width: _chubby ? 7.6 : 6.6,
      outline: coat.line,
      fill: legFur(3, far: false),
      seed: 17,
    );
    final pad = ovalPath(paw, 8.5, 6.5);
    pen.fill(pad, pawFur(3, far: false));
    pen.stroke(pad, coat.line, width: 0.95, wobble: 0.2, seed: 18);
    pen.fill(ovalPath(paw + const Offset(0.5, 0.8), 3, 2), SketchColors.pink.withValues(alpha: 0.7));
  }

  @override
  bool shouldRepaint(CatAnatomy oldDelegate) =>
      oldDelegate.runtimeType != runtimeType || oldDelegate.frame != frame || oldDelegate.facing != facing;
}

/// Classic tabby stripes (back, haunch, tail rings, legs, forehead "M" and
/// cheek lines) in [stripeColor].
mixin TabbyMarkings on CatAnatomy {
  Color get stripeColor;

  @override
  void paintBodyMarks(SketchPen pen, Rect body) {
    final top = body.top;
    // Back stripes, curving down the flank.
    for (final x in const [32.0, 37.0, 42.0, 47.0, 52.0, 57.0]) {
      pen.stroke(
        Path()
          ..moveTo(x, top + 0.3)
          ..quadraticBezierTo(x + 2.4, top + 5, x + 0.6, top + 9.5),
        stripeColor,
        width: 1.0,
        wobble: 0.15,
        sketchy: false,
        seed: x.toInt(),
      );
    }
    // Haunch swirl.
    pen.stroke(
      Path()
        ..moveTo(31, top + 12)
        ..quadraticBezierTo(36, top + 10, 37, top + 15),
      stripeColor,
      width: 0.9,
      wobble: 0.1,
      sketchy: false,
    );
  }

  @override
  void paintTailMarks(SketchPen pen, Path tail) {
    // Fine rings, closer together toward the tip.
    final metric = tail.computeMetrics().first;
    for (final f in const [0.3, 0.42, 0.53, 0.63, 0.72, 0.8, 0.88, 0.95]) {
      final tangent = metric.getTangentForOffset(metric.length * f)!;
      final n = Offset(-tangent.vector.dy, tangent.vector.dx);
      final t = tangent.vector * 0.6;
      pen.stroke(
        Path()
          ..moveTo((tangent.position - n * 2.7).dx, (tangent.position - n * 2.7).dy)
          ..quadraticBezierTo(
            (tangent.position + t).dx,
            (tangent.position + t).dy,
            (tangent.position + n * 2.7).dx,
            (tangent.position + n * 2.7).dy,
          ),
        stripeColor,
        width: 0.95,
        sketchy: false,
        wobble: 0.1,
      );
    }
  }

  @override
  void paintLegMarks(SketchPen pen, int i, Offset hip, Offset foot, {required bool far}) {
    for (final f in far ? const [0.4] : const [0.3, 0.5, 0.7]) {
      final mid = Offset.lerp(hip, foot, f)!;
      pen.line(
        mid + const Offset(-2.6, 0.3),
        mid + const Offset(2.2, -0.5),
        stripeColor,
        width: 0.85,
        sketchy: false,
        wobble: 0.1,
      );
    }
  }

  @override
  void paintHeadMarks(SketchPen pen, Offset hc) {
    // Tabby "M" on the forehead.
    for (final (a, c, b) in const [
      (Offset(0, -17.5), Offset(0.4, -14), Offset(0, -10)),
      (Offset(-3.6, -16.8), Offset(-3.6, -13.5), Offset(-2.6, -10.8)),
      (Offset(3.6, -16.8), Offset(3.6, -13.5), Offset(2.6, -10.8)),
      (Offset(-7.5, -15.2), Offset(-7.2, -12.6), Offset(-5.6, -10.6)),
      (Offset(7.5, -15.2), Offset(7.2, -12.6), Offset(5.6, -10.6)),
    ]) {
      pen.stroke(
        Path()
          ..moveTo(hc.dx + a.dx, hc.dy + a.dy)
          ..quadraticBezierTo(hc.dx + c.dx, hc.dy + c.dy, hc.dx + b.dx, hc.dy + b.dy),
        stripeColor,
        width: 1.0,
        sketchy: false,
        wobble: 0.08,
      );
    }
    // Cheek stripes running out from the eyes.
    for (final side in const [-1.0, 1.0]) {
      for (final (a, b) in const [(Offset(14.5, -2.5), Offset(20.5, -4)), (Offset(15, 0.5), Offset(21, 0))]) {
        pen.line(
          hc + Offset(a.dx * side, a.dy),
          hc + Offset(b.dx * side, b.dy),
          stripeColor,
          width: 0.9,
          sketchy: false,
          wobble: 0.08,
        );
      }
    }
  }
}
