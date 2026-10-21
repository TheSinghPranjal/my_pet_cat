import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'controllers/cat_game_controller.dart';
import 'models/cat_game_state.dart';
import 'models/game_location.dart';
import 'models/game_positions.dart';
import 'sketch/sketch.dart';
import 'widgets/activity_icon.dart';
import 'widgets/cat_character.dart';
import 'widgets/game_action_button.dart';
import 'widgets/grooming_props.dart';
import 'widgets/interactive_object.dart';
import 'widgets/location_navigation.dart';
import 'widgets/scene_background.dart';
import 'widgets/scene_effects.dart';
import 'widgets/settings_sheet.dart';

/// The whole game: paper, static scene, animated playfield, and controls,
/// each on its own layer.
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
                            Positioned.fill(child: _Scene(controller: _controller, layout: layout)),
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
    final corner = layout.unit * GameSizes.cornerButton;
    final inset = layout.unit * 0.03;
    return [
      ValueListenableBuilder<GameLocation>(
        valueListenable: _controller.locationListenable,
        builder: (context, location, _) => ValueListenableBuilder<CatGameState>(
          valueListenable: _controller.stateListenable,
          builder: (context, state, _) {
            final config = Locations.of(location);
            final enabled = state == CatGameState.idle;
            final buttonSize = Size(
              layout.unit * GameSizes.actionButtonWidth,
              layout.unit * GameSizes.actionButtonHeight,
            );
            final navSize = Size(layout.unit * 0.8, layout.unit * GameSizes.navBarHeight);
            Positioned at(Offset center, Size size, Widget child) {
              final c = layout.toPixels(center);
              return Positioned(
                left: c.dx - size.width / 2,
                top: c.dy - size.height / 2,
                width: size.width,
                height: size.height,
                child: child,
              );
            }

            return Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  left: inset,
                  top: inset,
                  height: corner * 0.72,
                  child: _LocationTag(title: config.title),
                ),
                for (final (i, definition) in config.activities.indexed)
                  at(
                    Offset(const [0.18, 0.5, 0.82][i], SceneMetrics.actionRowY),
                    buttonSize,
                    GameActionButton(
                      key: ValueKey(definition.activity),
                      icon: ActivityIcon(definition.activity),
                      label: definition.label,
                      semanticLabel: definition.semanticLabel,
                      enabled: enabled,
                      onPressed: () => _controller.startActivity(definition.activity),
                    ),
                  ),
                at(
                  const Offset(0.5, SceneMetrics.navBarY),
                  navSize,
                  LocationNavigation(
                    selected: location,
                    enabled: enabled,
                    onSelected: _controller.goTo,
                  ),
                ),
              ],
            );
          },
        ),
      ),
      Positioned(
        right: inset,
        top: inset,
        width: corner,
        height: corner,
        child: SketchSettingsButton(onPressed: _openSettings),
      ),
    ];
  }
}

/// Small sketch tag naming the current location.
class _LocationTag extends StatelessWidget {
  const _LocationTag({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) => CustomPaint(
        painter: const SketchFramePainter(radius: 0.5, seed: 11),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: box.maxHeight * 0.55),
          child: Center(
            widthFactor: 1,
            child: Text(
              title,
              style: TextStyle(
                color: SketchColors.ink,
                fontSize: box.maxHeight * 0.42,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Background and playfield, faded together during location changes.
class _Scene extends StatelessWidget {
  const _Scene({required this.controller, required this.layout});

  final CatGameController controller;
  final GameLayout layout;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<double>(
      valueListenable: controller.sceneOpacity,
      child: Stack(
        children: [
          Positioned.fill(
            child: ValueListenableBuilder<GameLocation>(
              valueListenable: controller.locationListenable,
              builder: (context, location, _) =>
                  GameBackground(location: location, unit: layout.unit),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(child: _Playfield(controller: controller, layout: layout)),
          ),
        ],
      ),
      builder: (context, opacity, child) => Opacity(opacity: opacity, child: child),
    );
  }
}

/// The only layer that rebuilds every frame: cat, props, critters and
/// effects, sorted so whatever stands lower on the floor is drawn in front.
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
        Widget anchored(Offset position, Size size, double anchorX, Widget child) {
          final p = layout.toPixels(position);
          return Positioned(
            left: p.dx - size.width * anchorX,
            top: p.dy - size.height,
            child: child,
          );
        }

        final catWidth = layout.unit * GameSizes.cat;
        items.add((
          controller.catPosition.dy,
          anchored(
            controller.catPosition,
            Size(catWidth, catWidth / CatCharacter.aspect),
            0.5,
            CatCharacter(frame: controller.catFrame, facing: controller.facing, width: catWidth),
          ),
        ));

        if (controller.location == GameLocation.bath) {
          final width = layout.unit * GameSizes.tub;
          final size = Size(width, width / BathTubPainter.aspect);
          items.add((
            BathPositions.bathTubPosition.dy,
            anchored(
              BathPositions.bathTubPosition,
              size,
              0.5,
              RepaintBoundary(
                child: CustomPaint(size: size, painter: BathTubPainter(foam: controller.tubFoam)),
              ),
            ),
          ));
        }

        for (final object in controller.objects) {
          items.add((
            object.sortY,
            anchored(
              object.position,
              InteractiveObject.sizeOf(object.kind, layout.unit),
              InteractiveObject.anchorX(object.kind),
              InteractiveObject(object: object, unit: layout.unit),
            ),
          ));
        }

        items.sort((a, b) => a.$1.compareTo(b.$1));
        return Stack(
          clipBehavior: Clip.none,
          children: [
            for (final item in items) item.$2,
            if (controller.effects.isNotEmpty)
              Positioned.fill(
                child: CustomPaint(
                  painter: SceneEffectsPainter(effects: controller.effects, layout: layout),
                ),
              ),
          ],
        );
      },
    );
  }
}
