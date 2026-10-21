import 'package:flutter/widgets.dart';

import '../../sketch/sketch.dart';
import 'cat_anatomy.dart';

/// The fluffy kitten (Mochi): fine graphite lines, cheek tufts and full
/// grey tabby markings.
class FluffyCatPainter extends CatAnatomy with TabbyMarkings {
  FluffyCatPainter({required super.frame, required super.facing});

  static const _coat = CatCoat();

  @override
  CatCoat get coat => _coat;

  @override
  Color get stripeColor => SketchColors.stripe;
}
