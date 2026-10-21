import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../sketch/sketch.dart';

/// Shared press behavior: shrinks slightly while held, dims when disabled.
class SketchPressable extends StatefulWidget {
  const SketchPressable({
    super.key,
    required this.enabled,
    required this.onPressed,
    required this.semanticLabel,
    required this.child,
    this.selected = false,
  });

  final bool enabled;
  final bool selected;
  final VoidCallback onPressed;
  final String semanticLabel;
  final Widget child;

  @override
  State<SketchPressable> createState() => _SketchPressableState();
}

class _SketchPressableState extends State<SketchPressable> {
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
      selected: widget.selected,
      label: widget.semanticLabel,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: enabled ? (_) => _setPressed(true) : null,
        onTapUp: enabled ? (_) => _setPressed(false) : null,
        onTapCancel: () => _setPressed(false),
        onTap: enabled
            ? () {
                HapticFeedback.selectionClick();
                widget.onPressed();
              }
            : null,
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

/// Hand-drawn rounded paper card with a doubled blue ink border.
class SketchFramePainter extends CustomPainter {
  const SketchFramePainter({
    this.radius = 0.36,
    this.seed = 1,
    this.emphasis = false,
    this.fill = SketchColors.white,
  });

  /// Paper color inside the frame.
  final Color fill;

  /// Corner radius as a fraction of the height.
  final double radius;
  final int seed;

  /// Adds two small doodled emphasis ticks at the top-right corner.
  final bool emphasis;

  @override
  void paint(Canvas canvas, Size size) {
    final k = math.min(size.height, 60) / 40;
    final pen = SketchPen(canvas);
    final rect = (Offset.zero & size).deflate(k * 1.5);
    final r = Radius.circular(size.height * radius);
    final frame = Path()..addRRect(RRect.fromRectAndRadius(rect, r));
    pen.fill(frame, fill);
    pen.stroke(frame, SketchColors.ink, width: k * 1.3, wobble: k * 0.5, seed: seed);
    pen.stroke(
      Path()..addRRect(RRect.fromRectAndRadius(rect.deflate(k * 2.2), Radius.circular(size.height * radius * 0.85))),
      SketchColors.ink.withValues(alpha: 0.55),
      width: k * 0.6,
      wobble: k * 0.4,
      seed: seed + 1,
      sketchy: false,
    );
    if (emphasis) {
      final corner = Offset(size.width - k * 2, k * 2);
      for (final a in const [-0.5, -1.05]) {
        final dir = Offset(math.cos(a), math.sin(a));
        pen.line(corner + dir * k * 2.5, corner + dir * k * 6, SketchColors.ink,
            width: k * 0.9, wobble: 0, sketchy: false);
      }
    }
  }

  @override
  bool shouldRepaint(SketchFramePainter oldDelegate) =>
      oldDelegate.radius != radius ||
      oldDelegate.seed != seed ||
      oldDelegate.emphasis != emphasis ||
      oldDelegate.fill != fill;
}

/// Large contextual action button: drawn icon with a small label.
class GameActionButton extends StatelessWidget {
  const GameActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    required this.semanticLabel,
    this.enabled = true,
  });

  final Widget icon;
  final String label;
  final VoidCallback onPressed;
  final String semanticLabel;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return SketchPressable(
      enabled: enabled,
      onPressed: onPressed,
      semanticLabel: semanticLabel,
      child: CustomPaint(
        painter: const SketchFramePainter(radius: 0.3, emphasis: true),
        child: LayoutBuilder(
          builder: (context, box) => Padding(
            padding: EdgeInsets.fromLTRB(box.maxWidth * 0.1, box.maxHeight * 0.1,
                box.maxWidth * 0.1, box.maxHeight * 0.08),
            child: Column(
              children: [
                Expanded(child: Center(child: icon)),
                SizedBox(height: box.maxHeight * 0.03),
                // Scales down rather than clipping on narrow screens.
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    maxLines: 1,
                    style: TextStyle(
                      color: SketchColors.ink,
                      fontSize: box.maxHeight * 0.2,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.2,
                      height: 1.1,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

enum SketchGlyph { settings, back }

/// Small rounded-square icon button (settings gear or back arrow).
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
    return SketchPressable(
      enabled: true,
      onPressed: onPressed,
      semanticLabel: semanticLabel,
      child: CustomPaint(painter: SketchGlyphPainter(glyph), child: const SizedBox.expand()),
    );
  }
}

class SketchGlyphPainter extends CustomPainter {
  const SketchGlyphPainter(this.glyph, {this.framed = true});

  final SketchGlyph glyph;

  /// Draws the rounded paper card behind the glyph.
  final bool framed;

  @override
  void paint(Canvas canvas, Size size) {
    final k = math.min(size.width, size.height) / 40;
    final pen = SketchPen(canvas, pxPerUnit: k);
    canvas.save();
    canvas.translate((size.width - 40 * k) / 2, (size.height - 40 * k) / 2);
    canvas.scale(k);
    if (framed) {
      final card = Path()..addRRect(RRect.fromLTRBR(2, 2, 38, 38, const Radius.circular(11)));
      pen.fill(card, SketchColors.white);
      pen.stroke(card, SketchColors.ink, width: 1.6, wobble: 0.5, seed: 3);
    }
    switch (glyph) {
      case SketchGlyph.settings:
        _gear(pen);
      case SketchGlyph.back:
        _arrow(pen);
    }
    canvas.restore();
  }

  void _gear(SketchPen pen) {
    final gear = Path();
    for (var i = 0; i < 8; i++) {
      gear.addPath(
        Path()..addRect(Rect.fromCenter(center: const Offset(0, -9.5), width: 4.2, height: 5)),
        const Offset(20, 20),
        matrix4: (Matrix4.identity()..rotateZ(i / 8 * math.pi * 2)).storage,
      );
    }
    gear.addOval(Rect.fromCircle(center: const Offset(20, 20), radius: 8.5));
    pen.fill(gear, SketchColors.ink.withValues(alpha: 0.85));
    pen.stroke(gear, SketchColors.ink, width: 1.1, wobble: 0.3, seed: 5);
    final hole = ovalPath(const Offset(20, 20), 7, 7);
    pen.fill(hole, SketchColors.white);
    pen.stroke(hole, SketchColors.ink, width: 0.9, sketchy: false, wobble: 0.2);
  }

  void _arrow(SketchPen pen) {
    pen.stroke(
      Path()
        ..moveTo(28, 20)
        ..lineTo(12, 20)
        ..moveTo(19, 12.5)
        ..lineTo(11.5, 20)
        ..lineTo(19, 27.5),
      SketchColors.ink,
      width: 3,
      wobble: 0.3,
      seed: 6,
    );
  }

  @override
  bool shouldRepaint(SketchGlyphPainter oldDelegate) =>
      oldDelegate.glyph != glyph || oldDelegate.framed != framed;
}
