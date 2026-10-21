import 'dart:ui';

import '../../sketch/sketch.dart';
import 'cat_anatomy.dart';

/// Luna: a black-and-white tuxedo cat with a white bib, muzzle and socks,
/// and yellow-green eyes. Dark fur takes lighter graphite hatching for form
/// and a light outline so she reads on the paper.
class TuxedoCatPainter extends CatAnatomy {
  TuxedoCatPainter({required super.frame, required super.facing});

  static const _white = Color(0xFFFBFBFD);
  static const _whiteShade = Color(0xFFE2E2EA);

  static const _coat = CatCoat(
    fur: Color(0xFF2B2B34),
    farFur: Color(0xFF1F1F27),
    line: Color(0xFF7C7C90),
    faceLine: Color(0xFF9E9EB4),
    mouthLine: Color(0xFF3A3A42),
    whisker: Color(0xFFA8A8BA),
    shade: Color(0xFF9A9AB2),
    bodyShade: 0.55,
    headShade: 0.5,
    blush: 0.25,
    tuft: _white,
  );

  @override
  CatCoat get coat => _coat;

  @override
  CatEyes get eyes => const CatEyes(iris: Color(0xFF9CC21E), glow: Color(0xFFE2F07A));

  @override
  Color pawFur(int i, {required bool far}) => far ? _whiteShade : _white;

  @override
  void paintBodyMarks(SketchPen pen, Rect body) {
    // White bib down the chest, and a white belly.
    final bib = Path()
      ..moveTo(body.right - 14, body.bottom)
      ..quadraticBezierTo(body.right - 13, body.top + 9, body.right - 3, body.top + 4)
      ..lineTo(body.right + 2, body.bottom)
      ..close();
    pen.fill(bib, _white);
    pen.fill(ovalPath(Offset(body.center.dx + 4, body.bottom), body.width * 0.55, 9), _white);
    pen.hatch(bib, _whiteShade, spacing: 1.3, angle: -0.6, width: 0.4, seed: 72);
  }

  @override
  void paintHeadInside(SketchPen pen, Offset hc) {
    // White muzzle and chin with a thin blaze up the nose.
    final muzzle = Path()
      ..addOval(Rect.fromCenter(center: hc + const Offset(0, 11), width: 18, height: 13))
      ..addOval(Rect.fromCenter(center: hc + const Offset(0, 18), width: 22, height: 8));
    pen.fill(muzzle, _white);
    pen.fill(polygon([hc + const Offset(-2.4, 6), hc + const Offset(0, -5), hc + const Offset(2.4, 6)]), _white);
  }

  @override
  void paintTailMarks(SketchPen pen, Path tail) {
    // A little white tip.
    final metric = tail.computeMetrics().first;
    final tip = metric.getTangentForOffset(metric.length * 0.96)!.position;
    pen.fill(ovalPath(tip, 4.6, 4.6), _white);
  }
}
