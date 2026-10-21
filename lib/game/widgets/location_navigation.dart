import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../models/game_location.dart';
import '../sketch/sketch.dart';
import 'activity_icon.dart';
import 'game_action_button.dart';

/// Persistent bottom bar for switching between Home, Bath and Garden.
class LocationNavigation extends StatelessWidget {
  const LocationNavigation({
    super.key,
    required this.selected,
    required this.enabled,
    required this.onSelected,
  });

  final GameLocation selected;
  final bool enabled;
  final ValueChanged<GameLocation> onSelected;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: const SketchFramePainter(radius: 0.45, seed: 7),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 5, 12, 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            for (final location in GameLocation.values)
              Expanded(
                child: SketchPressable(
                  enabled: enabled,
                  selected: location == selected,
                  semanticLabel: 'Go to ${Locations.of(location).title}',
                  onPressed: () => onSelected(location),
                  child: LayoutBuilder(
                    builder: (context, box) => Column(
                      children: [
                        Expanded(
                          child: CustomPaint(
                            painter: _NavIconPainter(location, selected: location == selected),
                            child: const SizedBox.expand(),
                          ),
                        ),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            Locations.of(location).title,
                            style: TextStyle(
                              color: location == selected ? SketchColors.ink : SketchColors.inkSoft,
                              fontSize: box.maxHeight * 0.22,
                              fontWeight: location == selected ? FontWeight.w800 : FontWeight.w600,
                              height: 1.0,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _NavIconPainter extends CustomPainter {
  _NavIconPainter(this.location, {required this.selected});

  final GameLocation location;
  final bool selected;

  @override
  void paint(Canvas canvas, Size size) {
    final side = math.min(size.width, size.height);
    final k = side / 40;
    canvas.save();
    canvas.translate((size.width - side) / 2, (size.height - side) / 2);
    final pen = SketchPen(canvas, pxPerUnit: k);
    canvas.scale(k);
    if (selected) {
      // Pale-blue disc with a quick hand-drawn circle around it.
      final disc = ovalPath(const Offset(20, 20), 37, 37);
      pen.fill(disc, SketchColors.inkWash.withValues(alpha: 0.55));
      pen.hatch(disc, SketchColors.inkSoft.withValues(alpha: 0.5), spacing: 2.2, seed: 8);
      pen.stroke(
        // Skia wraps sweeps over 360 degrees, so the overlap is a second arc.
        Path()
          ..addArc(Rect.fromCircle(center: const Offset(20, 20), radius: 18.5), -1.9, math.pi * 1.97)
          ..addArc(Rect.fromCircle(center: const Offset(20, 20), radius: 19.6), -2.2, 0.75),
        SketchColors.ink,
        width: 1.7,
        wobble: 0.7,
        seed: 9,
      );
    }
    canvas.save();
    canvas.translate(5, 5);
    canvas.scale(30 / 40);
    switch (location) {
      case GameLocation.home:
        _house(pen);
      case GameLocation.bath:
        _tub(pen);
      case GameLocation.outdoors:
        canvas.restore();
        canvas.save();
        canvas.translate(5, 4);
        TreeIconPainter(withSun: true).paint(canvas, const Size(30, 30));
    }
    canvas.restore();
    canvas.restore();
  }

  Color get _ink => selected ? SketchColors.ink : SketchColors.inkSoft;

  void _house(SketchPen pen) {
    final house = Path()
      ..moveTo(4, 20)
      ..lineTo(20, 5)
      ..lineTo(36, 20)
      ..lineTo(32, 20)
      ..lineTo(32, 35)
      ..lineTo(8, 35)
      ..lineTo(8, 20)
      ..close();
    pen.fill(house, _ink.withValues(alpha: 0.85));
    pen.stroke(house, _ink, width: 1.6, wobble: 0.4, seed: 1);
    final door = rectPath(16.5, 24, 23.5, 35);
    pen.fill(door, SketchColors.white);
    pen.stroke(door, _ink, width: 1.0, sketchy: false, wobble: 0.2);
  }

  void _tub(SketchPen pen) {
    for (final (c, r) in const [(Offset(12, 10), 3.5), (Offset(20, 6), 2.6), (Offset(27, 11), 4.0)]) {
      pen.stroke(ovalPath(c, r * 2, r * 2), SketchColors.inkSoft, width: 1.1, sketchy: false, wobble: 0.2);
    }
    final tub = Path()
      ..moveTo(3, 18)
      ..lineTo(37, 18)
      ..cubicTo(36, 30, 30, 32, 20, 32)
      ..cubicTo(10, 32, 4, 30, 3, 18)
      ..close();
    pen.fill(tub, _ink.withValues(alpha: 0.85));
    pen.stroke(tub, _ink, width: 1.6, wobble: 0.4, seed: 2);
    pen.line(const Offset(1, 18), const Offset(39, 18), _ink, width: 2.2, sketchy: false);
    for (final x in const [9.0, 31.0]) {
      pen.line(Offset(x, 32), Offset(x, 36), _ink, width: 1.8, sketchy: false);
    }
  }

  @override
  bool shouldRepaint(_NavIconPainter oldDelegate) =>
      oldDelegate.location != location || oldDelegate.selected != selected;
}
