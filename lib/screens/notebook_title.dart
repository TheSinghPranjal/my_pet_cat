import 'package:flutter/material.dart';

import '../game/sketch/sketch.dart';

/// "My Pet Cat" in bold ink with a coral pencil underline.
class NotebookTitle extends StatelessWidget {
  const NotebookTitle({super.key, required this.fontSize, this.subtitle});

  final double fontSize;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Transform.rotate(
          angle: -0.04,
          child: CustomPaint(
            foregroundPainter: _UnderlinePainter(),
            child: Padding(
              padding: EdgeInsets.only(bottom: fontSize * 0.22),
              child: Text(
                'My Pet Cat',
                style: TextStyle(
                  color: SketchColors.ink,
                  fontSize: fontSize,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                  height: 1.0,
                ),
              ),
            ),
          ),
        ),
        if (subtitle != null) ...[
          SizedBox(height: fontSize * 0.25),
          Text(
            subtitle!,
            style: TextStyle(
              color: SketchColors.inkSoft,
              fontSize: fontSize * 0.32,
              fontWeight: FontWeight.w600,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ],
    );
  }
}

class _UnderlinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final pen = SketchPen(canvas);
    final y = size.height - 3;
    final w = size.width;
    pen.stroke(
      Path()
        ..moveTo(w * 0.04, y)
        ..quadraticBezierTo(w * 0.5, y + 5, w * 0.96, y - 2)
        ..moveTo(w * 0.12, y + 5)
        ..quadraticBezierTo(w * 0.5, y + 8, w * 0.86, y + 3),
      SketchColors.coral,
      width: 3,
      wobble: 1.2,
      seed: 4,
    );
  }

  @override
  bool shouldRepaint(_UnderlinePainter oldDelegate) => false;
}
