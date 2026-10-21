import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../game/models/cat_look.dart';
import '../game/sketch/sketch.dart';
import '../game/widgets/cat_character.dart';
import '../game/widgets/food_bowl.dart';
import '../game/widgets/game_action_button.dart';
import '../game/widgets/idle_kitten.dart';
import '../game/widgets/scene_background.dart';
import '../game/widgets/wool_ball.dart';
import '../home_widget/add_widget_sheet.dart';
import '../navigation/app_routes.dart';
import 'fade_route.dart';
import 'how_to_play_screen.dart';
import 'notebook_title.dart';

/// The start page: title, the kitten waiting on her rug, and the Play and
/// How to Play buttons.
class StartScreen extends StatelessWidget {
  const StartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SketchColors.paper,
      body: LayoutBuilder(
        builder: (context, screen) {
          final gridUnit = math.min(screen.maxWidth, screen.maxHeight * 9 / 16);
          return Stack(
            children: [
              Positioned.fill(child: GraphPaper(spacing: gridUnit / 22)),
              SafeArea(
                child: LayoutBuilder(
                  builder: (context, area) {
                    final stage = Size(math.min(area.maxWidth, area.maxHeight * 0.75), area.maxHeight);
                    final unit = math.min(stage.width, stage.height * 9 / 16);
                    Positioned at(double x, double y, Size size, Widget child) => Positioned(
                          left: x * stage.width - size.width / 2,
                          top: y * stage.height - size.height / 2,
                          width: size.width,
                          height: size.height,
                          child: child,
                        );
                    final kittenWidth = unit * 0.5;
                    final kittenHeight = kittenWidth / CatCharacter.aspect;
                    final bowlWidth = unit * 0.2;
                    final ball = WoolBall.boxSize(unit * 0.1);
                    return Center(
                      child: SizedBox.fromSize(
                        size: stage,
                        child: Stack(
                          children: [
                            const Positioned.fill(child: CustomPaint(painter: _StartDecorPainter())),
                            at(0.5, 0.18, Size(stage.width * 0.9, unit * 0.42),
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: NotebookTitle(fontSize: unit * 0.14, subtitle: 'a little notebook kitten'),
                                )),
                            at(0.2, 0.585, Size(bowlWidth, bowlWidth / FoodBowl.aspect),
                                const CustomPaint(painter: _RestingBowl())),
                            at(0.79, 0.59, ball, const CustomPaint(painter: _RestingBall())),
                            // Kitten stands with her paws on the rug line; swipe her
                            // to try another look.
                            Positioned(
                              left: 0,
                              right: 0,
                              top: 0.6 * stage.height - kittenHeight,
                              height: kittenHeight,
                              child: _CatLookCarousel(kittenWidth: kittenWidth),
                            ),
                            at(0.5, 0.655, Size(stage.width * 0.9, unit * 0.065), const _CatLookLabel()),
                            at(0.5, 0.74, Size(unit * 0.64, unit * 0.17),
                                _MenuButton(
                                  label: 'Play',
                                  semanticLabel: 'Play',
                                  primary: true,
                                  icon: const _PawIconPainter(),
                                  onPressed: () => Navigator.of(context).push(AppRoutes.game()),
                                )),
                            at(0.5, 0.875, Size(unit * 0.64, unit * 0.13),
                                _MenuButton(
                                  label: 'How to Play',
                                  semanticLabel: 'How to play',
                                  icon: const _QuestionIconPainter(),
                                  onPressed: () => Navigator.of(context).push(fadeRoute(const HowToPlayScreen())),
                                )),
                            at(0.5, 0.955, Size(stage.width * 0.9, unit * 0.075),
                                SketchPressable(
                                  enabled: true,
                                  semanticLabel: 'Add Kitty to your home screen',
                                  onPressed: () => AddWidgetSheet.show(context),
                                  child: Center(
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        '+ Add Kitty to your home screen',
                                        style: TextStyle(
                                          color: SketchColors.inkSoft,
                                          fontSize: unit * 0.038,
                                          fontWeight: FontWeight.w700,
                                          decoration: TextDecoration.underline,
                                          decorationColor: SketchColors.inkSoft,
                                        ),
                                      ),
                                    ),
                                  ),
                                )),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Swipeable kittens, one per [CatLook]; the one left in view becomes the
/// player's look everywhere in the app.
class _CatLookCarousel extends StatefulWidget {
  const _CatLookCarousel({required this.kittenWidth});

  final double kittenWidth;

  @override
  State<_CatLookCarousel> createState() => _CatLookCarouselState();
}

class _CatLookCarouselState extends State<_CatLookCarousel> {
  late final _pages = PageController(initialPage: catLook.value.index);

  @override
  void initState() {
    super.initState();
    catLook.addListener(_follow);
  }

  @override
  void dispose() {
    catLook.removeListener(_follow);
    _pages.dispose();
    super.dispose();
  }

  /// Slides to a look picked some other way (the arrows under the rug).
  void _follow() {
    if (!_pages.hasClients) return;
    final target = catLook.value.index;
    if ((_pages.page ?? target).round() == target) return;
    _pages.animateToPage(target, duration: const Duration(milliseconds: 350), curve: Curves.easeOutCubic);
  }

  @override
  Widget build(BuildContext context) {
    const looks = CatLook.values;
    return ValueListenableBuilder(
      valueListenable: catLook,
      builder: (context, look, child) => Semantics(
        label: "Kitty's look: ${look.label}, ${look.index + 1} of ${looks.length}",
        hint: 'Swipe left or right to change her look',
        onIncrease: look.index < looks.length - 1 ? () => catLook.select(looks[look.index + 1]) : null,
        onDecrease: look.index > 0 ? () => catLook.select(looks[look.index - 1]) : null,
        child: child,
      ),
      child: PageView.builder(
        controller: _pages,
        itemCount: looks.length,
        onPageChanged: (i) => catLook.select(looks[i]),
        itemBuilder: (context, i) => ExcludeSemantics(
          child: Center(child: IdleKitten(width: widget.kittenWidth, look: looks[i])),
        ),
      ),
    );
  }
}

/// "‹ Fluffy Kitty ●○ ›" under the rug: names the look and steps through them.
class _CatLookLabel extends StatelessWidget {
  const _CatLookLabel();

  @override
  Widget build(BuildContext context) {
    const looks = CatLook.values;
    return LayoutBuilder(
      builder: (context, box) {
        final h = box.maxHeight;
        Widget arrow(String glyph, String label, int step) => SketchPressable(
              enabled: true,
              semanticLabel: label,
              onPressed: () => catLook.select(looks[(catLook.value.index + step) % looks.length]),
              child: SizedBox(
                width: h * 1.6,
                height: h,
                child: Center(
                  child: Text(glyph,
                      style: TextStyle(color: SketchColors.ink, fontSize: h * 0.9, fontWeight: FontWeight.w900, height: 1)),
                ),
              ),
            );
        return ValueListenableBuilder(
          valueListenable: catLook,
          builder: (context, look, _) => Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              arrow('‹', 'Previous look', looks.length - 1),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    look.label,
                    style: TextStyle(color: SketchColors.ink, fontSize: h * 0.5, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
              SizedBox(width: h * 0.25),
              for (final other in looks)
                Container(
                  width: h * 0.2,
                  height: h * 0.2,
                  margin: EdgeInsets.symmetric(horizontal: h * 0.06),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: other == look ? SketchColors.ink : null,
                    border: Border.all(color: SketchColors.ink, width: 1),
                  ),
                ),
              arrow('›', 'Next look', 1),
            ],
          ),
        );
      },
    );
  }
}

class _MenuButton extends StatelessWidget {
  const _MenuButton({
    required this.label,
    required this.semanticLabel,
    required this.icon,
    required this.onPressed,
    this.primary = false,
  });

  final String label;
  final String semanticLabel;
  final CustomPainter icon;
  final VoidCallback onPressed;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    return SketchPressable(
      enabled: true,
      onPressed: onPressed,
      semanticLabel: semanticLabel,
      child: CustomPaint(
        painter: SketchFramePainter(
          radius: 0.4,
          seed: primary ? 21 : 23,
          emphasis: primary,
          fill: primary ? SketchColors.coralLight : SketchColors.white,
        ),
        child: LayoutBuilder(
          builder: (context, box) => Padding(
            padding: EdgeInsets.symmetric(horizontal: box.maxHeight * 0.4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CustomPaint(size: Size.square(box.maxHeight * 0.5), painter: icon),
                SizedBox(width: box.maxHeight * 0.18),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      label,
                      style: TextStyle(
                        color: SketchColors.ink,
                        fontSize: box.maxHeight * (primary ? 0.4 : 0.34),
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
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

class _RestingBowl extends CustomPainter {
  const _RestingBowl();

  @override
  void paint(Canvas canvas, Size size) => FoodBowlPainter().paint(canvas, size);

  @override
  bool shouldRepaint(_RestingBowl oldDelegate) => false;
}

class _RestingBall extends CustomPainter {
  const _RestingBall();

  @override
  void paint(Canvas canvas, Size size) => WoolBallPainter(rotation: 1.2).paint(canvas, size);

  @override
  bool shouldRepaint(_RestingBall oldDelegate) => false;
}

class _PawIconPainter extends CustomPainter {
  const _PawIconPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final k = size.width / 20;
    final pen = SketchPen(canvas, pxPerUnit: k);
    canvas.save();
    canvas.scale(k);
    final pad = ovalPath(const Offset(10, 13.5), 9, 7);
    pen.fill(pad, SketchColors.ink);
    for (final toe in const [Offset(4, 7.5), Offset(8, 4.5), Offset(12, 4.5), Offset(16, 7.5)]) {
      pen.fill(ovalPath(toe, 3.6, 4.2), SketchColors.ink);
    }
    pen.stroke(pad, SketchColors.ink, width: 0.6, sketchy: false);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_PawIconPainter oldDelegate) => false;
}

class _QuestionIconPainter extends CustomPainter {
  const _QuestionIconPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final k = size.width / 20;
    final pen = SketchPen(canvas, pxPerUnit: k);
    canvas.save();
    canvas.scale(k);
    final bubble = ovalPath(const Offset(10, 10), 18, 18);
    pen.fill(bubble, SketchColors.inkWash.withValues(alpha: 0.6));
    pen.stroke(bubble, SketchColors.ink, width: 1.3, wobble: 0.3);
    pen.stroke(
      Path()
        ..moveTo(7, 7.5)
        ..quadraticBezierTo(7.5, 4.5, 10.5, 4.6)
        ..quadraticBezierTo(13.5, 5, 13, 8)
        ..quadraticBezierTo(12.5, 9.8, 10.2, 10.8)
        ..lineTo(10.2, 12.4),
      SketchColors.ink,
      width: 1.8,
      sketchy: false,
      wobble: 0.1,
    );
    pen.fill(ovalPath(const Offset(10.2, 15.2), 2, 2), SketchColors.ink);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_QuestionIconPainter oldDelegate) => false;
}

/// Sun, clouds, a rug and a few doodles around the kitten.
class _StartDecorPainter extends CustomPainter {
  const _StartDecorPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final k = math.min(size.width, size.height * 9 / 16) / 100;
    final w = size.width / k;
    final h = size.height / k;
    final pen = SketchPen(canvas, pxPerUnit: k, weight: 0.6);
    canvas.save();
    canvas.scale(k);
    Offset at(double x, double y) => Offset(x * w, y * h);

    // Sun.
    final sunCenter = at(0.86, 0.045);
    for (var i = 0; i < 10; i++) {
      final a = i / 10 * math.pi * 2;
      final d = Offset(math.cos(a), math.sin(a));
      pen.line(sunCenter + d * 5.6, sunCenter + d * 8, SketchColors.sunEdge, width: 0.8, sketchy: false);
    }
    final sun = ovalPath(sunCenter, 8.4, 8.4);
    pen.fill(sun, SketchColors.sun);
    pen.hatch(sun, SketchColors.sunEdge, spacing: 0.9, cross: true, seed: 1);
    pen.stroke(sun, SketchColors.sunEdge, width: 0.8, seed: 1);

    // Clouds.
    for (final (i, (x, y, s)) in const [(0.06, 0.07, 1.1), (0.62, 0.31, 0.8)].indexed) {
      final o = at(x, y);
      final cloud = Path()
        ..moveTo(o.dx, o.dy)
        ..quadraticBezierTo(o.dx - 2 * s, o.dy - 3.5 * s, o.dx + 1.8 * s, o.dy - 3.9 * s)
        ..quadraticBezierTo(o.dx + 2.8 * s, o.dy - 7.5 * s, o.dx + 6.6 * s, o.dy - 6.1 * s)
        ..quadraticBezierTo(o.dx + 9.8 * s, o.dy - 7.3 * s, o.dx + 10.4 * s, o.dy - 3.5 * s)
        ..quadraticBezierTo(o.dx + 13.6 * s, o.dy - 2.9 * s, o.dx + 11.8 * s, o.dy)
        ..close();
      pen.fill(cloud, SketchColors.white);
      pen.stroke(cloud, SketchColors.ink, width: 0.8, seed: 2 + i);
    }

    // Floor line and rug.
    pen.line(at(0.06, 0.6), at(0.94, 0.6), SketchColors.inkSoft, width: 0.8, seed: 5);
    final rugCenter = at(0.5, 0.605);
    final outer = ovalPath(rugCenter, 62, 12);
    final inner = ovalPath(rugCenter, 44, 8);
    pen.fill(outer, SketchColors.coralLight);
    pen.hatch(Path.combine(PathOperation.difference, outer, inner), SketchColors.coral,
        spacing: 0.9, angle: -0.5, seed: 6);
    pen.fill(inner, SketchColors.inkWash.withValues(alpha: 0.6));
    pen.hatch(inner, SketchColors.inkSoft, spacing: 1.2, seed: 7, cross: true);
    pen.stroke(outer, SketchColors.coral, width: 0.9, seed: 8);

    // Hearts and paw-print trail.
    for (final (i, (x, y, s, color)) in const [
      (0.2, 0.36, 1.0, SketchColors.pinkDeep),
      (0.82, 0.42, 0.8, SketchColors.coral),
      (0.12, 0.47, 0.6, SketchColors.pink),
    ].indexed) {
      final c = at(x, y);
      final heart = Path()
        ..moveTo(c.dx, c.dy + 3 * s)
        ..cubicTo(c.dx - 4.5 * s, c.dy, c.dx - 2.5 * s, c.dy - 3.5 * s, c.dx, c.dy - 1.4 * s)
        ..cubicTo(c.dx + 2.5 * s, c.dy - 3.5 * s, c.dx + 4.5 * s, c.dy, c.dx, c.dy + 3 * s)
        ..close();
      pen.fill(heart, color.withValues(alpha: 0.6));
      pen.stroke(heart, color, width: 0.7, seed: 10 + i);
    }
    for (final (x, y) in const [(0.1, 0.66), (0.17, 0.645), (0.84, 0.655), (0.91, 0.67)]) {
      final c = at(x, y);
      pen.fill(ovalPath(c, 2.6, 2), SketchColors.inkSoft.withValues(alpha: 0.7));
      for (final toe in const [Offset(-1.3, -1.8), Offset(0, -2.3), Offset(1.3, -1.8)]) {
        pen.fill(ovalPath(c + toe, 0.9, 1), SketchColors.inkSoft.withValues(alpha: 0.7));
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_StartDecorPainter oldDelegate) => false;
}
