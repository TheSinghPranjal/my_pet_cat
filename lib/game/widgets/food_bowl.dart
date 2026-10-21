import 'package:flutter/widgets.dart';

import '../animations/object_animations.dart';
import '../sketch/sketch.dart';

/// Blue-pen food bowl with a paw print and a heap of kibble.
class FoodBowl extends StatelessWidget {
  const FoodBowl({super.key, required this.width, this.fill = 1, this.appear = 1, this.pop = 0});

  static const aspect = 100 / 62;

  final double width;
  final double fill;
  final double appear;
  final double pop;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(width, width / aspect),
      painter: FoodBowlPainter(fill: fill, appear: appear, pop: pop),
    );
  }
}

class FoodBowlPainter extends CustomPainter {
  FoodBowlPainter({this.fill = 1, this.appear = 1, this.pop = 0});

  final double fill;
  final double appear;
  final double pop;

  // Kibble heap, bottom layer first so the top of the pile empties first.
  static const _kibble = [
    Offset(20, 19), Offset(30, 21), Offset(42, 22), Offset(55, 22), Offset(67, 21),
    Offset(78, 19), Offset(26, 15), Offset(37, 16), Offset(49, 16.5), Offset(61, 16),
    Offset(72, 14.5), Offset(32, 10.5), Offset(44, 11), Offset(56, 10.5), Offset(66, 9.5),
    Offset(40, 6), Offset(51, 5.5), Offset(60, 6.5),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 100;
    final pen = SketchPen(canvas, pxPerUnit: s);
    canvas.save();
    canvas.scale(s);

    final scale = ObjectAnimations.appearScale(appear) * ObjectAnimations.popScale(pop);
    if (scale > 0.01) {
      canvas.save();
      canvas.translate(50, 60 + ObjectAnimations.appearLift(appear) * 60);
      canvas.scale(scale);
      canvas.translate(-50, -60);
      _bowl(pen);
      canvas.restore();
    }
    pen.popMarks(const Offset(50, 32), 42, pop, SketchColors.ink, width: 1.8);
    canvas.restore();
  }

  void _bowl(SketchPen pen) {
    pen.hatch(ovalPath(const Offset(50, 59), 92, 7), SketchColors.inkSoft,
        spacing: 1.6, angle: -0.2, width: 0.6, seed: 2);

    final inner = ovalPath(const Offset(50, 20), 80, 15);
    pen.fill(inner, const Color(0xFFDCE4FA));
    pen.hatch(inner, SketchColors.inkSoft, spacing: 2, angle: -0.5, width: 0.6, seed: 4);

    final count = (_kibble.length * fill).round();
    for (var i = 0; i < count; i++) {
      final k = _kibble[i];
      final bit = ovalPath(k, 9.5, 7.5);
      pen.fill(bit, SketchColors.kibble);
      pen.hatch(bit, SketchColors.kibbleDark, spacing: 1.6, angle: 0.8, width: 0.6, seed: i);
      pen.stroke(bit, SketchColors.kibbleDark, width: 0.8, wobble: 0.2, sketchy: false, seed: i);
    }

    final body = Path()
      ..moveTo(5, 20)
      ..lineTo(15, 54)
      ..quadraticBezierTo(50, 60, 85, 54)
      ..lineTo(95, 20)
      ..quadraticBezierTo(50, 38, 5, 20)
      ..close();
    pen.fill(body, SketchColors.white);
    pen.hatch(body, SketchColors.inkWash, spacing: 2.2, angle: -1.1, width: 0.9, seed: 6);
    final band = Path()
      ..moveTo(13, 47)
      ..quadraticBezierTo(50, 53, 87, 47)
      ..lineTo(85, 54)
      ..quadraticBezierTo(50, 60, 15, 54)
      ..close();
    pen.hatch(band, SketchColors.ink, spacing: 1.5, angle: -0.9, width: 0.7, seed: 7, cross: true);
    pen.stroke(body, SketchColors.ink, width: 1.6, seed: 8);
    pen.stroke(ovalPath(const Offset(50, 20), 90, 19), SketchColors.ink, width: 1.6, seed: 9);

    // Paw print.
    pen.fill(ovalPath(const Offset(50, 37), 11, 8.5), SketchColors.ink);
    for (final toe in const [Offset(42.5, 30.5), Offset(47.5, 27.5), Offset(52.5, 27.5), Offset(57.5, 30.5)]) {
      pen.fill(ovalPath(toe, 4, 4.6), SketchColors.ink);
    }
  }

  @override
  bool shouldRepaint(FoodBowlPainter oldDelegate) =>
      oldDelegate.fill != fill || oldDelegate.appear != appear || oldDelegate.pop != pop;
}
