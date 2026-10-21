// Renders the home-screen widget artwork from the game's own painters, so the
// widget kitten is the exact in-game kitten. Run after changing the art:
//
//   flutter test tool/widget_assets/render_widget_assets_test.dart
//
// Writes Android drawables (res/drawable-nodpi/widget_*.png) and the iOS
// widget extension's asset catalog (ios/PetWidget/Assets.xcassets).
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_pet_cat/game/animations/cat_animations.dart';
import 'package:my_pet_cat/game/models/cat_look.dart';
import 'package:my_pet_cat/game/sketch/sketch.dart';
import 'package:my_pet_cat/game/widgets/cat_character.dart';
import 'package:my_pet_cat/game/widgets/food_bowl.dart';
import 'package:my_pet_cat/game/widgets/wool_ball.dart';

const _androidDir = 'android/app/src/main/res/drawable-nodpi';
const _iosDir = 'ios/PetWidget/Assets.xcassets';

/// Stage frames: the kitten plus her wool ball on one transparent canvas
/// (150x95 units) with identical anchors in every pose.
const _stageUnits = Size(150, 95);
const _px = 5.0;
const _sitFeet = [Offset(-3, -5), Offset(-3, -5), Offset(-1, -5), Offset(-1, -5)];

const poses = <String, CatFrame>{
  'idle': CatFrame(),
  'blink': CatFrame(eyeOpen: 0),
  'tail_up': CatFrame(tailAngle: 0.45),
  'tail_down': CatFrame(tailAngle: -0.35),
  'look_at_toy': CatFrame(
      bodyLift: 5, feet: _sitFeet, headOffset: Offset(1, 0), headTilt: 0.12, gaze: 1, gazeY: 0.8, earTwitch: 0.12),
  'paw_reach': CatFrame(
      bodyLift: 1.5,
      headOffset: Offset(1, 1.5),
      raisedPaw: Offset(88, 66),
      gaze: 1,
      gazeY: 0.8,
      mouth: CatMouth.open,
      tailAngle: 0.2),
  'paw_tap': CatFrame(
      bodyLift: 1.5,
      headOffset: Offset(2, 2),
      raisedPaw: Offset(93, 78),
      gaze: 1,
      gazeY: 1,
      mouth: CatMouth.open,
      tailAngle: 0.3),
  'happy': CatFrame(happyEyes: true, mouth: CatMouth.tongue, tailAngle: 0.35, sparkle: 0.17),
  'rest': CatFrame(bodyLift: 5, feet: _sitFeet, happyEyes: true, headOffset: Offset(-2, -1), tailAngle: -0.2),
};

void _stage(Canvas canvas, double s, CatFrame frame) {
  // Wool ball first, so a tapping paw lands in front of it.
  const ballDiameter = 20.0;
  final ballBox = WoolBall.boxSize(ballDiameter * s);
  canvas.save();
  canvas.translate((116 - ballDiameter * 1.7 * WoolBall.ballCenterX) * s, 91 * s - ballBox.height);
  WoolBallPainter(rotation: 0.4).paint(canvas, ballBox);
  canvas.restore();

  canvas.save();
  canvas.translate(6 * s, 6 * s);
  CatPainter(frame: frame, facing: 1, look: CatLook.fluffy).paint(canvas, Size(100 * s, 85 * s));
  canvas.restore();
}

void _paper(Canvas canvas, Size size, {required bool wide}) {
  canvas.drawRect(Offset.zero & size, Paint()..color = SketchColors.paper);
  final grid = Paint()
    ..color = SketchColors.grid
    ..strokeWidth = 1.4;
  const spacing = 24.0;
  for (var x = spacing / 2; x < size.width; x += spacing) {
    canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
  }
  for (var y = spacing / 2; y < size.height; y += spacing) {
    canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
  }
  final rnd = math.Random(4);
  final grain = Paint()..color = SketchColors.graphite.withValues(alpha: 0.07);
  for (var i = 0; i < 700; i++) {
    canvas.drawCircle(Offset(rnd.nextDouble() * size.width, rnd.nextDouble() * size.height),
        0.6 + rnd.nextDouble(), grain);
  }

  final pen = SketchPen(canvas, pxPerUnit: 4);
  final w = size.width, h = size.height;
  _sun(pen, Offset(w - 52, 56), 15);
  _heart(pen, const Offset(46, 62), 1.6, SketchColors.coral);
  _heart(pen, Offset(w - 46, h - 48), 1.2, SketchColors.pinkDeep);
  for (final p in wide ? [Offset(40, h - 60), Offset(74, h - 36)] : [Offset(44, h - 70), Offset(78, h - 44)]) {
    _paw(pen, p, 1.4);
  }
}

void _sun(SketchPen pen, Offset c, double r) {
  for (var i = 0; i < 10; i++) {
    final a = i / 10 * math.pi * 2;
    final d = Offset(math.cos(a), math.sin(a));
    pen.line(c + d * (r + 5), c + d * (r + 13), SketchColors.sunEdge, width: 3, sketchy: false);
  }
  final disc = ovalPath(c, r * 2, r * 2);
  pen.fill(disc, SketchColors.sun);
  pen.hatch(disc, SketchColors.sunEdge, spacing: 3.5, width: 1.4, cross: true, seed: 1);
  pen.stroke(disc, SketchColors.sunEdge, width: 2.4, wobble: 1, seed: 1);
}

void _heart(SketchPen pen, Offset c, double s, Color color) {
  final k = 6 * s;
  final heart = Path()
    ..moveTo(c.dx, c.dy + 3 * k)
    ..cubicTo(c.dx - 4.5 * k, c.dy, c.dx - 2.5 * k, c.dy - 3.5 * k, c.dx, c.dy - 1.4 * k)
    ..cubicTo(c.dx + 2.5 * k, c.dy - 3.5 * k, c.dx + 4.5 * k, c.dy, c.dx, c.dy + 3 * k)
    ..close();
  pen.fill(heart, color.withValues(alpha: 0.6));
  pen.stroke(heart, color, width: 2.2, wobble: 0.8, seed: 3);
}

void _paw(SketchPen pen, Offset c, double s) {
  final color = SketchColors.inkSoft.withValues(alpha: 0.75);
  pen.fill(ovalPath(c, 11 * s, 8.5 * s), color);
  for (final toe in const [Offset(-5.5, -7), Offset(-2, -9.5), Offset(2, -9.5), Offset(5.5, -7)]) {
    pen.fill(ovalPath(c + toe * s, 4 * s, 4.6 * s), color);
  }
}

void _rug(Canvas canvas, Size size) {
  final pen = SketchPen(canvas, pxPerUnit: size.width / 64);
  canvas.save();
  canvas.scale(size.width / 66);
  final c = Offset(33, size.height / (size.width / 66) / 2);
  final outer = ovalPath(c, 64, 13);
  final middle = ovalPath(c, 54, 10);
  final inner = ovalPath(c, 40, 7);
  pen.fill(outer, SketchColors.coralLight);
  pen.hatch(Path.combine(PathOperation.difference, outer, middle), SketchColors.coral, spacing: 0.9, angle: -0.5, seed: 1);
  pen.fill(middle, SketchColors.paper);
  pen.hatch(Path.combine(PathOperation.difference, middle, inner), SketchColors.sun, spacing: 1.1, angle: 0.6, seed: 2);
  pen.fill(inner, SketchColors.inkWash.withValues(alpha: 0.6));
  pen.hatch(inner, SketchColors.inkSoft, spacing: 1.2, seed: 3, cross: true);
  pen.stroke(outer, SketchColors.coral, width: 0.9, seed: 4);
  canvas.restore();
}

Future<void> _save(String name, Size size, void Function(Canvas canvas) draw) async {
  final recorder = ui.PictureRecorder();
  draw(Canvas(recorder));
  final image = await recorder.endRecording().toImage(size.width.round(), size.height.round());
  final bytes = (await image.toByteData(format: ui.ImageByteFormat.png))!.buffer.asUint8List();
  final file = 'widget_$name';
  File('$_androidDir/$file.png')
    ..createSync(recursive: true)
    ..writeAsBytesSync(bytes);
  final set = Directory('$_iosDir/$file.imageset')..createSync(recursive: true);
  File('${set.path}/$file.png').writeAsBytesSync(bytes);
  File('${set.path}/Contents.json').writeAsStringSync(const JsonEncoder.withIndent('  ').convert({
    'images': [
      {'filename': '$file.png', 'idiom': 'universal'},
    ],
    'info': {'author': 'xcode', 'version': 1},
  }));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('render widget assets', () async {
    File('$_iosDir/Contents.json')
      ..createSync(recursive: true)
      ..writeAsStringSync('{\n  "info" : {\n    "author" : "xcode",\n    "version" : 1\n  }\n}\n');

    final stageSize = _stageUnits * _px;
    for (final entry in poses.entries) {
      await _save('kitten_${entry.key}', stageSize, (c) => _stage(c, _px, entry.value));
    }
    await _save('wool_ball', const Size(340, 220), (c) => WoolBallPainter(rotation: 0.4).paint(c, const Size(340, 220)));
    await _save('food_bowl', const Size(300, 186), (c) => FoodBowlPainter().paint(c, const Size(300, 186)));
    await _save('rug', const Size(660, 150), (c) => _rug(c, const Size(660, 150)));
    await _save('paper', const Size(600, 600), (c) => _paper(c, const Size(600, 600), wide: false));
    await _save('paper_wide', const Size(800, 400), (c) => _paper(c, const Size(800, 400), wide: true));

    // Static previews for widget pickers that can't render live layouts.
    await _save('preview_small', const Size(480, 480), (c) {
      _paper(c, const Size(480, 480), wide: false);
      c.translate(52, 110);
      _stage(c, 2.5, poses['idle']!);
    });
    await _save('preview_medium', const Size(960, 450), (c) {
      _paper(c, const Size(960, 450), wide: true);
      c.save();
      c.translate(40, 70);
      _stage(c, 3.3, poses['idle']!);
      c.restore();
      c.translate(640, 250);
      FoodBowlPainter().paint(c, const Size(200, 124));
    });
    await _save('preview_large', const Size(900, 900), (c) {
      _paper(c, const Size(900, 900), wide: false);
      c.save();
      c.translate(120, 560);
      _rug(c, const Size(660, 150));
      c.restore();
      c.save();
      c.translate(110, 220);
      _stage(c, 4.4, poses['idle']!);
      c.restore();
      c.translate(80, 700);
      FoodBowlPainter().paint(c, const Size(200, 124));
    });
  });
}
