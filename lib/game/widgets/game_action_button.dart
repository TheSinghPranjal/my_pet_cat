import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../sketch/sketch.dart';

/// Shared press behavior: shrinks slightly while held, dims when disabled.
class _SketchPressable extends StatefulWidget {
  const _SketchPressable({
    required this.enabled,
    required this.onPressed,
    required this.semanticLabel,
    required this.child,
  });

  final bool enabled;
  final VoidCallback onPressed;
  final String semanticLabel;
  final Widget child;

  @override
  State<_SketchPressable> createState() => _SketchPressableState();
}

class _SketchPressableState extends State<_SketchPressable> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.enabled;
    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.semanticLabel,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: enabled ? (_) => _setPressed(true) : null,
        onTapUp: enabled ? (_) => _setPressed(false) : null,
        onTapCancel: () => _setPressed(false),
        onTap: enabled ? widget.onPressed : null,
        child: AnimatedScale(
          scale: _pressed ? 0.92 : 1,
          duration: const Duration(milliseconds: 90),
          child: AnimatedOpacity(
            opacity: enabled ? 1 : 0.45,
            duration: const Duration(milliseconds: 200),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

/// Large rounded notebook button (Feed / Play) with emphasis marks.
class GameActionButton extends StatelessWidget {
  const GameActionButton({
    super.key,
    required this.icon,
    required this.onPressed,
    required this.semanticLabel,
    this.enabled = true,
  });

  final Widget icon;
  final VoidCallback onPressed;
  final String semanticLabel;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return _SketchPressable(
      enabled: enabled,
      onPressed: onPressed,
      semanticLabel: semanticLabel,
      child: CustomPaint(
        painter: _ButtonFramePainter(),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 5, 12, 7),
          child: Center(child: icon),
        ),
      ),
    );
  }
}

class _ButtonFramePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final k = size.height / 40;
    final pen = SketchPen(canvas, pxPerUnit: 1);
    final rect = (Offset.zero & size).deflate(k * 1.5);
    final frame = Path()..addRRect(RRect.fromRectAndRadius(rect, Radius.circular(size.height * 0.36)));
    pen.fill(frame, SketchColors.white);
    pen.stroke(frame, SketchColors.ink, width: k * 1.3, wobble: k * 0.5, seed: 1);
    pen.stroke(
      Path()..addRRect(RRect.fromRectAndRadius(rect.deflate(k * 2.2), Radius.circular(size.height * 0.3))),
      SketchColors.ink.withValues(alpha: 0.6),
      width: k * 0.6,
      wobble: k * 0.4,
      seed: 2,
      sketchy: false,
    );
    // Emphasis marks on both sides.
    for (final side in const [-1.0, 1.0]) {
      final x = side < 0 ? -k * 2.5 : size.width + k * 2.5;
      for (final (dy, tilt) in const [(0.3, -0.5), (0.5, 0.0), (0.7, 0.5)]) {
        final start = Offset(x, size.height * dy);
        final dir = Offset(side * math.cos(tilt), math.sin(tilt) * side);
        pen.line(start, start + dir * k * 5, SketchColors.ink, width: k * 0.9, wobble: 0, sketchy: false);
      }
    }
  }

  @override
  bool shouldRepaint(_ButtonFramePainter oldDelegate) => false;
}

enum SketchGlyph { home, settings }

/// Small round icon button used for Home and Settings.
class SketchIconButton extends StatelessWidget {
  const SketchIconButton({
    super.key,
    required this.glyph,
    required this.onPressed,
    required this.semanticLabel,
  });

  final SketchGlyph glyph;
  final VoidCallback onPressed;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    return _SketchPressable(
      enabled: true,
      onPressed: onPressed,
      semanticLabel: semanticLabel,
      child: CustomPaint(painter: _GlyphPainter(glyph), child: const SizedBox.expand()),
    );
  }
}

class _GlyphPainter extends CustomPainter {
  _GlyphPainter(this.glyph);

  final SketchGlyph glyph;

  @override
  void paint(Canvas canvas, Size size) {
    final k = size.width / 40;
    final pen = SketchPen(canvas, pxPerUnit: k);
    canvas.save();
    canvas.scale(k);
    final ring = ovalPath(const Offset(20, 20), 36, 36);
    pen.fill(ring, SketchColors.white);
    pen.stroke(ring, SketchColors.ink, width: 1.6, wobble: 0.5, seed: 3);

    final Path shape;
    if (glyph == SketchGlyph.home) {
      shape = Path()
        ..moveTo(9.5, 20)
        ..lineTo(20, 10.5)
        ..lineTo(30.5, 20)
        ..lineTo(27.5, 20)
        ..lineTo(27.5, 29)
        ..lineTo(12.5, 29)
        ..lineTo(12.5, 20)
        ..close();
    } else {
      shape = Path();
      for (var i = 0; i < 8; i++) {
        final a = i / 8 * math.pi * 2;
        shape.addPath(
          Path()..addRect(Rect.fromCenter(center: const Offset(0, -9.5), width: 4.2, height: 5)),
          const Offset(20, 20),
          matrix4: (Matrix4.identity()..rotateZ(a)).storage,
        );
      }
      shape.addOval(Rect.fromCircle(center: const Offset(20, 20), radius: 8.5));
    }
    pen.fill(shape, SketchColors.ink.withValues(alpha: 0.85));
    pen.hatch(shape, SketchColors.ink, spacing: 1.2, seed: 4);
    pen.stroke(shape, SketchColors.ink, width: 1.1, wobble: 0.3, seed: 5);
    if (glyph == SketchGlyph.home) {
      final door = rectPath(17.6, 22.5, 22.4, 29);
      pen.fill(door, SketchColors.white);
      pen.stroke(door, SketchColors.ink, width: 0.8, sketchy: false, wobble: 0.2);
    } else {
      final hole = ovalPath(const Offset(20, 20), 7, 7);
      pen.fill(hole, SketchColors.white);
      pen.stroke(hole, SketchColors.ink, width: 0.9, sketchy: false, wobble: 0.2);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_GlyphPainter oldDelegate) => oldDelegate.glyph != glyph;
}
