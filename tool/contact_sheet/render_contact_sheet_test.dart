// Renders a contact sheet of every cat look in six key poses, for visual
// review of the cat painters:
//
//   flutter test tool/contact_sheet/render_contact_sheet_test.dart
//
// Writes build/contact_sheet/cats.png: one row per CatLook (in enum order),
// one column per pose in [poses] order, on notebook paper.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_pet_cat/game/animations/cat_animations.dart';
import 'package:my_pet_cat/game/models/cat_game_state.dart';
import 'package:my_pet_cat/game/models/cat_look.dart';
import 'package:my_pet_cat/game/sketch/sketch.dart';
import 'package:my_pet_cat/game/widgets/cat_character.dart';

const _outDir = 'build/contact_sheet';

/// Pose and the moment of it to capture.
const poses = <(CatPose, double)>[
  (CatPose.idle, 0.4),
  (CatPose.walk, 0.5),
  (CatPose.sit, 1.0),
  (CatPose.eat, 0.6),
  (CatPose.happy, 0.5),
  (CatPose.surprised, 0.3),
];

const _cell = Size(240, 220);
const _catWidth = 200.0;

CatFrame _frame(CatPose pose, double t) =>
    catFrameFor(pose: pose, time: 1.3 + t, poseTime: t, walkPhase: t * 11, gaze: 0.3, swipe: 0);

Future<void> _write(String name, Size size, void Function(Canvas canvas) draw) async {
  final recorder = ui.PictureRecorder();
  draw(Canvas(recorder));
  final image = await recorder.endRecording().toImage(size.width.round(), size.height.round());
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  Directory(_outDir).createSync(recursive: true);
  File('$_outDir/$name').writeAsBytesSync(bytes!.buffer.asUint8List());
}

void main() {
  test('cat contact sheet', () async {
    final size = Size(_cell.width * poses.length, _cell.height * CatLook.values.length);
    await _write('cats.png', size, (canvas) {
      canvas.drawRect(Offset.zero & size, Paint()..color = SketchColors.paper);
      final grid = Paint()
        ..color = SketchColors.grid
        ..strokeWidth = 1;
      for (var x = 0.0; x < size.width; x += 20) {
        canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
      }
      for (var y = 0.0; y < size.height; y += 20) {
        canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
      }
      for (final (row, look) in CatLook.values.indexed) {
        for (final (col, (pose, t)) in poses.indexed) {
          final origin = Offset(col * _cell.width, row * _cell.height);
          final floor = origin.dy + _cell.height - 22;
          canvas.drawLine(
            Offset(origin.dx + 14, floor),
            Offset(origin.dx + _cell.width - 14, floor),
            Paint()
              ..color = SketchColors.inkSoft
              ..strokeWidth = 1.2,
          );
          final catSize = Size(_catWidth, _catWidth / CatCharacter.aspect);
          canvas.save();
          canvas.translate(origin.dx + (_cell.width - catSize.width) / 2, floor - catSize.height);
          CatPainter(frame: _frame(pose, t), facing: 1, look: look).paint(canvas, catSize);
          canvas.restore();
        }
      }
    });
  });
}
