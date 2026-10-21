import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../home_widget/pet_home_widget_service.dart';
import '../navigation/app_launch_router.dart';
import 'cats/selected_cat.dart';
import 'controllers/cat_game_controller.dart';
import 'environments/bedroom/bedroom_layer.dart';
import 'environments/environment_id.dart';
import 'models/activity_definition.dart';
import 'models/cat_game_state.dart';
import 'models/game_location.dart';
import 'models/game_positions.dart';
import 'save/game_store.dart';
import 'sketch/sketch.dart';
import 'widgets/activity_icon.dart';
import 'widgets/cat_character.dart';
import 'widgets/critters.dart';
import 'widgets/food_bowl.dart';
import 'widgets/game_action_button.dart';
import 'widgets/grooming_props.dart';
import 'widgets/interactive_object.dart';
import 'widgets/kitchen_props.dart';
import 'widgets/location_navigation.dart';
import 'widgets/scene_background.dart';
import 'widgets/scene_effects.dart';
import 'widgets/settings_sheet.dart';
import 'widgets/wool_ball.dart';

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
    final store = GameStore.instance;
    _controller = CatGameController(
      vsync: this,
      persona: selectedCat.value.persona,
      wanderEnabled: store.save.settings.wander,
      onNeeds: (deltas) => store.applyNeeds(selectedCat.value.id, deltas),
      onCompleted: (activity) => store.update((save) => save.cat(selectedCat.value.id).completed.add(activity.name)),
    );
    WidgetsBinding.instance.addObserver(this);
    _controller.stateListenable.addListener(_onStateChanged);
    _controller.locationListenable.addListener(_recordForWidget);
    widgetHomeRequests.addListener(_onWidgetHomeRequest);
  }

  CatActivity? _reportedActivity;

  void _onStateChanged() {
    if (_controller.state != CatGameState.idle) return;
    final completed = _controller.lastCompletedActivity;
    final isNew = completed != null && completed != _reportedActivity;
    _reportedActivity = completed;
    _recordForWidget(completed: isNew ? completed : null);
  }

  void _recordForWidget({CatActivity? completed}) {
    PetHomeWidgetService.instance.record(location: _controller.location, completed: completed);
    final place = EnvironmentId.fromLocation(_controller.location);
    if (GameStore.instance.save.lastEnvironment != place) {
      GameStore.instance.update((save) => save.lastEnvironment = place);
    }
  }

  /// A widget tap while the game is open: go back to Home (ignored if an
  /// activity is running, so nothing is interrupted).
  void _onWidgetHomeRequest() => _controller.goTo(GameLocation.home);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _controller.setPaused(state != AppLifecycleState.resumed);
    // Refresh the home-screen widget exactly when the home screen shows.
    if (state == AppLifecycleState.paused || state == AppLifecycleState.hidden) {
      PetHomeWidgetService.instance.flush();
    }
  }

  @override
  void dispose() {
    widgetHomeRequests.removeListener(_onWidgetHomeRequest);
    _controller.stateListenable.removeListener(_onStateChanged);
    _controller.locationListenable.removeListener(_recordForWidget);
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    PetHomeWidgetService.instance.flush();
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
            final navSize = Size(layout.unit * GameSizes.navBarWidth, layout.unit * GameSizes.navBarHeight);
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
                  left: inset + corner,
                  right: inset + corner,
                  top: inset,
                  height: corner,
                  child: _Greeting(text: config.greeting),
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
                      accent: definition.accent == null ? null : Color(definition.accent!),
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
      // Back to the start page; only shown when the game was opened from it.
      if (Navigator.of(context).canPop())
        Positioned(
          left: inset,
          top: inset,
          width: corner,
          height: corner,
          child: SketchIconButton(
            glyph: SketchGlyph.back,
            semanticLabel: 'Back to menu',
            onPressed: () => Navigator.of(context).maybePop(),
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

/// Small handwritten greeting at the top, secondary to the scene.
class _Greeting extends StatelessWidget {
  const _Greeting({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) => Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            text,
            style: TextStyle(
              color: SketchColors.ink,
              fontSize: box.maxHeight * 0.34,
              fontWeight: FontWeight.w700,
              fontStyle: FontStyle.italic,
              letterSpacing: 0.4,
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

  static final _restingBowl = FoodBowlPainter();
  static final _restingYarn = WoolBallPainter(rotation: 1.2);
  static final _toyMouse = MousePainter(facing: -1, toy: true);

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
        if (!controller.catHidden) {
          items.add((
            controller.catPosition.dy,
            anchored(
              controller.catPosition,
              Size(catWidth, catWidth / CatCharacter.aspect),
              0.5,
              CatCharacter(frame: controller.catFrame, facing: controller.facing, width: catWidth),
            ),
          ));
        }

        if (controller.location == GameLocation.bedroom) items.addAll(bedroomItems(controller, layout, anchored));

        if (controller.location == GameLocation.home) {
          // Resting props belong to the room; the bowl and ball step aside
          // while their own activity shows the animated version.
          final active = controller.activeActivity;
          void rest(Offset at, Size size, double anchorX, CustomPainter painter, {bool hidden = false}) {
            items.add((
              at.dy,
              anchored(
                at,
                size,
                anchorX,
                AnimatedOpacity(
                  opacity: hidden ? 0 : 1,
                  duration: const Duration(milliseconds: 250),
                  child: RepaintBoundary(child: CustomPaint(size: size, painter: painter)),
                ),
              ),
            ));
          }

          rest(HomePositions.restingBowlPosition, InteractiveObject.sizeOf(ObjectKind.bowl, layout.unit), 0.5,
              _restingBowl,
              hidden: active == CatActivity.feed);
          rest(HomePositions.restingYarnPosition, InteractiveObject.sizeOf(ObjectKind.yarn, layout.unit),
              WoolBall.ballCenterX, _restingYarn,
              hidden: active == CatActivity.play);
          rest(HomePositions.toyMousePosition, InteractiveObject.sizeOf(ObjectKind.mouse, layout.unit) * 0.85,
              0.5, _toyMouse);
        }

        if (controller.location == GameLocation.kitchen && controller.cabinetOpen > 0) {
          // The treat cabinet's door, over the drawn door at the same rect.
          const door = KitchenPositions.treatCabinetDoorRect;
          final topLeft = layout.toPixels(door.topLeft);
          final size = Size(door.width * layout.size.width, door.height * layout.size.height);
          items.add((
            door.bottom - 0.001,
            Positioned(
              left: topLeft.dx,
              top: topLeft.dy,
              child: CustomPaint(size: size, painter: CabinetDoorPainter(open: controller.cabinetOpen)),
            ),
          ));
        }

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
