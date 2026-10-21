import 'dart:ui';

import '../../sketch/sketch.dart';
import 'cat_anatomy.dart';

/// Biscuit: a chubby orange ginger tabby with a cream belly, cream toes and
/// a cream muzzle.
class GingerCatPainter extends CatAnatomy with TabbyMarkings {
  GingerCatPainter({required super.frame, required super.facing});

  static const _cream = Color(0xFFFFF0D6);
  static const _creamShade = Color(0xFFF6DDB4);

  static const _coat = CatCoat(
    fur: Color(0xFFF7B568),
    farFur: Color(0xFFE9A052),
    line: Color(0xFF4A3B33),
    shade: Color(0xFFB8641E),
    bodyShade: 0.4,
    headShade: 0.32,
    tuft: _cream,
  );

  @override
  CatCoat get coat => _coat;

  @override
  CatEyes get eyes => const CatEyes(iris: Color(0xFF8DB43A), glow: Color(0xFFD7E87A));

  @override
  CatBuild get build => CatBuild.chubby;

  @override
  Color get stripeColor => const Color(0xFFD27A2A);

  @override
  Color pawFur(int i, {required bool far}) => far ? _creamShade : _cream;

  @override
  void paintBodyMarks(SketchPen pen, Rect body) {
    super.paintBodyMarks(pen, body);
    // A round cream belly.
    final belly = ovalPath(Offset(body.center.dx + 3, body.bottom - 1), body.width * 0.66, body.height * 0.62);
    pen.fill(belly, _cream);
    pen.hatch(belly, _creamShade, spacing: 1.2, angle: -0.6, width: 0.4, seed: 71);
  }

  @override
  void paintHeadInside(SketchPen pen, Offset hc) {
    final muzzle = ovalPath(hc + const Offset(0, 10.5), 17, 10);
    pen.fill(muzzle, _cream);
    pen.fill(ovalPath(hc + const Offset(0, 17), 24, 8), _cream);
  }
}
