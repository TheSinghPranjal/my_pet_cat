import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'animations/object_animations.dart';
import 'controllers/cat_game_controller.dart';
import 'models/cat_game_state.dart';
import 'models/game_positions.dart';
import 'sketch/sketch.dart';
import 'widgets/cat_character.dart';
import 'widgets/food_bowl.dart';
import 'widgets/game_action_button.dart';
import 'widgets/room_background.dart';
import 'widgets/settings_sheet.dart';
import 'widgets/wool_ball.dart';

/// The whole game: static room, animated playfield, and controls, each on
/// its own layer.
class CatGameScreen extends StatefulWidget {
  const CatGameScreen({super.key});

  @override
  State<CatGameScreen> createState() => CatGameScreenState();
}

class CatGameScreenState extends State<CatGameScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final CatGameController _controller;

  @visibleForTesting
  CatGameController get controller => _controller;

  @override
  void initState() {
    super.initState();
    _controller = CatGameController(vsync: this);
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _controller.setPaused(state != AppLifecycleState.resumed);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  void _openSettings() {
    showDialog<void>(
      context: context,
      builder: (context) => SettingsSheet(controller: _controller),
    );
  }

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
                    // Keep a portrait stage; very wide screens get paper margins.
                    final stage = Size(
                      math.min(area.maxWidth, area.maxHeight * 0.75),
                      area.maxHeight,
                    );
                    final layout = GameLayout(stage);
                    return Center(
                      child: SizedBox.fromSize(
                        size: stage,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Positioned.fill(child: RoomBackground(unit: layout.unit)),
                            Positioned.fill(
                              child: IgnorePointer(
                                child: _Playfield(controller: _controller, layout: layout),
                              ),
                            ),
                            ..._controls(layout),
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

  List<Widget> _controls(GameLayout layout) {
    final buttonSize = Size(
      layout.unit * GameSizes.actionButtonWidth,
      layout.unit * GameSizes.actionButtonHeight,
    );
    Widget actionButton(double centerX, Widget child) {
      final center = layout.toPixels(Offset(centerX, 0.885));
      return Positioned(
        left: center.dx - buttonSize.width / 2,
        top: center.dy - buttonSize.height / 2,
        width: buttonSize.width,
        height: buttonSize.height,
        child: child,
      );
    }

    final corner = layout.unit * GameSizes.cornerButton;
    final inset = layout.unit * 0.035;
    return [
      ValueListenableBuilder<CatGameState>(
        valueListenable: _controller.stateListenable,
        builder: (context, state, _) {
          final enabled = state == CatGameState.idle;
          return Stack(
            clipBehavior: Clip.none,
            children: [
              actionButton(
                0.295,
                GameActionButton(
                  semanticLabel: 'Feed the cat',
                  enabled: enabled,
                  onPressed: _controller.feed,
                  icon: const AspectRatio(
                    aspectRatio: FoodBowl.aspect,
                    child: CustomPaint(painter: _StaticBowlIcon()),
                  ),
                ),
              ),
              actionButton(
                0.705,
                GameActionButton(
                  semanticLabel: 'Play with the cat',
                  enabled: enabled,
                  onPressed: _controller.play,
                  icon: const AspectRatio(
                    aspectRatio: WoolBall.aspect,
                    child: CustomPaint(painter: _StaticYarnIcon()),
                  ),
                ),
              ),
            ],
          );
        },
      ),
      Positioned(
        left: inset,
        top: inset,
        width: corner,
        height: corner,
        child: SketchIconButton(
          glyph: SketchGlyph.home,
          semanticLabel: 'Call kitty home',
          onPressed: _controller.callHome,
        ),
      ),
      Positioned(
        right: inset,
        top: inset,
        width: corner,
        height: corner,
        child: SketchIconButton(
          glyph: SketchGlyph.settings,
          semanticLabel: 'Settings',
          onPressed: _openSettings,
        ),
      ),
    ];
  }
}

// Button icons reuse the in-game prop painters at rest.
class _StaticBowlIcon extends CustomPainter {
  const _StaticBowlIcon();

  @override
  void paint(Canvas canvas, Size size) => FoodBowlPainter().paint(canvas, size);

  @override
  bool shouldRepaint(_StaticBowlIcon oldDelegate) => false;
}

class _StaticYarnIcon extends CustomPainter {
  const _StaticYarnIcon();

  @override
  void paint(Canvas canvas, Size size) => WoolBallPainter(rotation: 0.4).paint(canvas, size);

  @override
  bool shouldRepaint(_StaticYarnIcon oldDelegate) => false;
}

/// The only layer that rebuilds every frame: cat, bowl and yarn, sorted so
/// whatever stands lower on the floor is drawn in front.
class _Playfield extends StatelessWidget {
  const _Playfield({required this.controller, required this.layout});

  final CatGameController controller;
  final GameLayout layout;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final items = <(double, Widget)>[];

        final catWidth = layout.unit * GameSizes.cat;
        final catHeight = catWidth / CatCharacter.aspect;
        final cat = layout.toPixels(controller.catPosition);
        items.add((
          controller.catPosition.dy,
          Positioned(
            left: cat.dx - catWidth / 2,
            top: cat.dy - catHeight,
            child: CatCharacter(
              frame: controller.catFrame,
              facing: controller.facing,
              width: catWidth,
            ),
          ),
        ));

        final bowl = controller.bowl;
        if (bowl != null) {
          final width = layout.unit * GameSizes.bowl;
          final height = width / FoodBowl.aspect;
          final p = layout.toPixels(bowl.position);
          items.add((
            bowl.position.dy,
            Positioned(
              left: p.dx - width / 2,
              top: p.dy - height,
              child: Opacity(
                opacity: ObjectAnimations.popOpacity(bowl.pop),
                child: FoodBowl(width: width, fill: bowl.fill, appear: bowl.appear, pop: bowl.pop),
              ),
            ),
          ));
        }

        final yarn = controller.yarn;
        if (yarn != null) {
          final diameter = layout.unit * GameSizes.yarn;
          final box = WoolBall.boxSize(diameter);
          final p = layout.toPixels(yarn.position);
          items.add((
            yarn.position.dy,
            Positioned(
              left: p.dx - box.width * WoolBall.ballCenterX,
              top: p.dy - box.height,
              child: Opacity(
                opacity: ObjectAnimations.popOpacity(yarn.pop),
                child: WoolBall(
                  ballDiameter: diameter,
                  rotation: yarn.rotation,
                  appear: yarn.appear,
                  pop: yarn.pop,
                ),
              ),
            ),
          ));
        }

        items.sort((a, b) => a.$1.compareTo(b.$1));
        return Stack(clipBehavior: Clip.none, children: [for (final item in items) item.$2]);
      },
    );
  }
}
