import 'package:flutter/material.dart';

import '../game/animations/cat_animations.dart';
import '../game/models/cat_look.dart';
import '../game/sketch/sketch.dart';
import '../game/widgets/cat_character.dart';
import '../game/widgets/food_bowl.dart';
import '../game/widgets/game_action_button.dart';
import '../game/widgets/grooming_props.dart';
import '../game/widgets/scene_background.dart';
import '../game/widgets/wool_ball.dart';

/// A notebook page of illustrated tips.
class HowToPlayScreen extends StatelessWidget {
  const HowToPlayScreen({super.key});

  static List<(CustomPainter, double, String, String)> get _tips => [
    (CatPainter(frame: const CatFrame(), facing: 1, look: catLook.value), CatCharacter.aspect, 'Meet Kitty',
        'She lives in your notebook. When nothing is happening she blinks, licks her paw and wanders around.'),
    (FoodBowlPainter(), FoodBowl.aspect, 'Pick an activity',
        'Tap one of the three cards at the bottom. At Home you can Feed her, Play with wool or Catch Mice.'),
    (BathTubPainter(foam: 1), BathTubPainter.aspect, 'Visit new places',
        'Use the bar at the very bottom to go to the Bath or Outdoors. Each place has three new things to do.'),
    (WoolBallPainter(rotation: 0.4, motionMarks: true), WoolBall.aspect, 'One thing at a time',
        'While Kitty is busy the cards fade out. When she has finished she comes back and they light up again.'),
    (const SketchGlyphPainter(SketchGlyph.settings, framed: false), 1.0, 'Settings',
        'Tap the gear to choose whether Kitty wanders around or stays put.'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SketchColors.paper,
      body: Stack(
        children: [
          const Positioned.fill(child: GraphPaper(spacing: 18)),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          SizedBox.square(
                            dimension: 48,
                            child: SketchIconButton(
                              glyph: SketchGlyph.back,
                              semanticLabel: 'Back',
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                          ),
                          const Expanded(
                            child: Text(
                              'How to Play',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: SketchColors.ink, fontSize: 28, fontWeight: FontWeight.w900),
                            ),
                          ),
                          const SizedBox(width: 48),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: ListView.separated(
                          itemCount: _tips.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 12),
                          itemBuilder: (context, i) {
                            final (icon, aspect, title, body) = _tips[i];
                            return _TipCard(number: i + 1, icon: icon, aspect: aspect, title: title, body: body);
                          },
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: 220,
                        height: 60,
                        child: SketchPressable(
                          enabled: true,
                          semanticLabel: 'Got it',
                          onPressed: () => Navigator.of(context).pop(),
                          child: const CustomPaint(
                            painter: SketchFramePainter(radius: 0.4, emphasis: true, fill: SketchColors.coralLight),
                            child: Center(
                              child: Text(
                                'Got it!',
                                style: TextStyle(color: SketchColors.ink, fontSize: 24, fontWeight: FontWeight.w900),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TipCard extends StatelessWidget {
  const _TipCard({
    required this.number,
    required this.icon,
    required this.aspect,
    required this.title,
    required this.body,
  });

  final int number;
  final CustomPainter icon;
  final double aspect;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: SketchFramePainter(radius: 0.18, seed: 30 + number),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Row(
          children: [
            SizedBox(
              width: 64,
              height: 52,
              child: Center(child: AspectRatio(aspectRatio: aspect, child: CustomPaint(painter: icon))),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$number. $title',
                    style: const TextStyle(color: SketchColors.ink, fontSize: 17, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    body,
                    style: const TextStyle(color: SketchColors.pencil, fontSize: 14, height: 1.3),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
