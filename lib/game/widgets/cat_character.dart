import 'package:flutter/widgets.dart';

import '../animations/cat_animations.dart';
import '../models/cat_look.dart';
import 'cat_looks/classic_cat_painter.dart';
import 'cat_looks/fluffy_cat_painter.dart';
import 'cat_looks/ginger_cat_painter.dart';
import 'cat_looks/tortie_cat_painter.dart';
import 'cat_looks/tuxedo_cat_painter.dart';

/// The kitten, drawn procedurally so every pose shares the exact same face,
/// proportions, stripes and anchor (bottom-center of the paws).
class CatCharacter extends StatelessWidget {
  const CatCharacter({super.key, required this.frame, required this.facing, required this.width, this.look});

  /// Width / height of the cat's drawing box.
  static const aspect = 100 / 85;

  final CatFrame frame;
  final double facing;
  final double width;

  /// Drawing style; follows the player's choice ([catLook]) when null.
  final CatLook? look;

  @override
  Widget build(BuildContext context) {
    Widget draw(CatLook look) => CustomPaint(
      size: Size(width, width / aspect),
      painter: CatPainter(frame: frame, facing: facing, look: look),
    );
    final fixed = look;
    if (fixed != null) return draw(fixed);
    return ValueListenableBuilder(valueListenable: catLook, builder: (_, look, _) => draw(look));
  }
}

/// Paints one [CatFrame] in the given [look]. Every look shares the same
/// 100x85 drawing box and anchors, so poses and animations work for all.
class CatPainter extends CustomPainter {
  CatPainter({required this.frame, required this.facing, this.look = CatLook.fluffy});

  final CatFrame frame;
  final double facing;
  final CatLook look;

  @override
  void paint(Canvas canvas, Size size) => switch (look) {
    CatLook.fluffy => FluffyCatPainter(frame: frame, facing: facing),
    CatLook.classic => ClassicCatPainter(frame: frame, facing: facing),
    CatLook.ginger => GingerCatPainter(frame: frame, facing: facing),
    CatLook.tuxedo => TuxedoCatPainter(frame: frame, facing: facing),
    CatLook.tortie => TortieCatPainter(frame: frame, facing: facing),
  }.paint(canvas, size);

  @override
  bool shouldRepaint(CatPainter oldDelegate) =>
      oldDelegate.frame != frame || oldDelegate.facing != facing || oldDelegate.look != look;
}
