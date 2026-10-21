import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../game/models/cat_game_state.dart';
import '../game/sketch/sketch.dart';
import '../game/widgets/idle_kitten.dart';
import '../game/widgets/scene_background.dart';
import 'fade_route.dart';
import 'notebook_title.dart';
import 'start_screen.dart';

/// Opening page: the kitten hops happily while the title draws in, then the
/// start screen fades in. Tap anywhere to skip.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  static const duration = Duration(milliseconds: 2400);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: SplashScreen.duration)
        ..addStatusListener((status) {
          if (status == AnimationStatus.completed) _continue();
        })
        ..forward();
  bool _left = false;

  void _continue() {
    if (_left || !mounted) return;
    _left = true;
    Navigator.of(context).pushReplacement(fadeRoute(const StartScreen()));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SketchColors.paper,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _continue,
        child: LayoutBuilder(
          builder: (context, box) {
            final unit = math.min(box.maxWidth, box.maxHeight * 9 / 16);
            return Stack(
              children: [
                Positioned.fill(child: GraphPaper(spacing: unit / 22)),
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IdleKitten(width: unit * 0.5, pose: CatPose.happy, loopSeconds: 1.6),
                      SizedBox(height: unit * 0.08),
                      FadeTransition(
                        opacity: CurvedAnimation(parent: _controller, curve: const Interval(0.1, 0.45)),
                        child: SizedBox(
                          width: unit * 0.9,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: NotebookTitle(fontSize: unit * 0.13, subtitle: 'a little notebook kitten'),
                          ),
                        ),
                      ),
                      SizedBox(height: unit * 0.1),
                      _LoadingDots(animation: _controller, size: unit * 0.03),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Three pencil dots that fill in one after another.
class _LoadingDots extends AnimatedWidget {
  const _LoadingDots({required Animation<double> animation, required this.size})
      : super(listenable: animation);

  final double size;

  @override
  Widget build(BuildContext context) {
    final t = (listenable as Animation<double>).value;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < 3; i++)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: size * 0.5),
            child: CustomPaint(
              size: Size.square(size),
              painter: _DotPainter(filled: ((t * 6) % 3) >= i),
            ),
          ),
      ],
    );
  }
}

class _DotPainter extends CustomPainter {
  _DotPainter({required this.filled});

  final bool filled;

  @override
  void paint(Canvas canvas, Size size) {
    final pen = SketchPen(canvas);
    final dot = ovalPath(size.center(Offset.zero), size.width, size.height);
    if (filled) pen.fill(dot, SketchColors.coral);
    pen.stroke(dot, SketchColors.ink, width: 1.4, wobble: 0.4, sketchy: false);
  }

  @override
  bool shouldRepaint(_DotPainter oldDelegate) => oldDelegate.filled != filled;
}
