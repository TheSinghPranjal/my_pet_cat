import 'dart:async';
import 'dart:collection';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

import '../animations/cat_animations.dart';
import '../cats/cat_needs.dart';
import '../cats/cat_persona.dart';
import '../cats/reaction.dart';
import '../environments/activity_scripts.dart';
import '../models/activity_definition.dart';
import '../models/cat_game_state.dart';
import '../models/game_location.dart';
import '../models/game_positions.dart';
import '../models/game_timings.dart';
import '../scripting/activity_runner.dart';
import '../scripting/scene_state.dart';
import '../scripting/script_step.dart';

/// Owns the game clock, the selected location and the scene, and starts
/// activities.
///
/// Every activity is an [ActivityScript] played by one [ActivityRunner]; the
/// idle wander routine runs through the same runner. All animation time
/// comes from one [Ticker] with a clamped frame step, so pausing the ticker
/// freezes everything, including waits.
class CatGameController extends ChangeNotifier {
  CatGameController({
    required TickerProvider vsync,
    GameLocation initialLocation = GameLocation.home,
    CatPersona persona = CatPersonas.mochi,
    bool wanderEnabled = true,
    this.onNeeds,
    this.onCompleted,
  }) : _location = ValueNotifier(initialLocation),
       _persona = persona,
       _wanderEnabled = wanderEnabled {
    _scene = SceneState(locationConfig.startPosition);
    _runner = ActivityRunner(_scene)
      ..onPhase = _setState
      ..onNeeds = ((deltas) => onNeeds?.call(deltas))
      ..reactionFor = ((thingId) => thingId == null ? ReactionOutcome.fine : _persona.reactionTo(thingId));
    _ticker = vsync.createTicker(_onTick)..start();
    unawaited(_wander(_runner.session));
  }

  /// Needs changed by a script (fed, played, bathed...).
  final void Function(Map<Need, double> deltas)? onNeeds;

  /// An activity played through to the end.
  final void Function(CatActivity activity)? onCompleted;

  late final Ticker _ticker;
  late final SceneState _scene;
  late final ActivityRunner _runner;
  final _state = ValueNotifier(CatGameState.idle);
  final ValueNotifier<GameLocation> _location;
  final _sceneOpacity = ValueNotifier<double>(1);
  final CatPersona _persona;

  int _wanderIndex = 0;
  bool _wanderEnabled;
  bool _paused = false;
  bool _disposed = false;
  Duration _lastElapsed = Duration.zero;

  CatActivity? _activity;
  CatActivity? _lastCompleted;

  ValueListenable<CatGameState> get stateListenable => _state;
  CatGameState get state => _state.value;
  GameMode get mode => state.mode;
  bool get isBusy => state != CatGameState.idle;

  ValueListenable<GameLocation> get locationListenable => _location;
  GameLocation get location => _location.value;
  LocationConfig get locationConfig => Locations.of(location);

  /// 0..1 opacity of the scene, dipped during location changes.
  ValueListenable<double> get sceneOpacity => _sceneOpacity;

  Offset get catPosition => _scene.catPosition;

  /// 1 = facing right, -1 = facing left; values between are mid-turn.
  double get facing => _scene.facing;
  CatPose get pose => _scene.pose;

  /// The activity currently running, if any.
  CatActivity? get activeActivity => _activity;

  /// The most recent activity that played through to the end.
  CatActivity? get lastCompletedActivity => _lastCompleted;

  /// How much foam is in the bathtub (bath scene prop).
  double get tubFoam => _scene.value(SceneKeys.tubFoam);

  /// How far the kitchen treat cabinet is open (0 = closed).
  double get cabinetOpen => _scene.value(SceneKeys.cabinetOpen);

  List<SpawnedObject> get objects => UnmodifiableListView(_scene.objects);
  List<SceneEffect> get effects => UnmodifiableListView(_scene.effects);

  SpawnedObject? objectOf(ObjectKind kind) {
    for (final o in _scene.objects) {
      if (o.kind == kind) return o;
    }
    return null;
  }

  SpawnedObject? get bowl => objectOf(ObjectKind.bowl);
  SpawnedObject? get yarn => objectOf(ObjectKind.yarn);

  CatFrame get catFrame => catFrameFor(
    pose: _scene.pose,
    time: _scene.time,
    poseTime: _scene.poseTime,
    walkPhase: _scene.walkPhase,
    gaze: _scene.gaze,
    gazeY: _scene.gazeY,
    swipe: _scene.swipe,
    lift: _scene.lift,
    mark: _scene.mark,
  ).withReaction(_scene.reaction);

  bool get wanderEnabled => _wanderEnabled;
  set wanderEnabled(bool value) {
    _wanderEnabled = value;
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Public requests
  // ---------------------------------------------------------------------------

  /// Starts [activity] if the game is idle and the activity belongs to the
  /// current location; otherwise the request is ignored.
  void startActivity(CatActivity activity) {
    if (!locationConfig.activities.any((d) => d.activity == activity)) return;
    final script = ActivityScripts.of(activity);
    if (_begin(script.firstPhase, () => _runner.run(script.body))) _activity = activity;
  }

  void feed() => startActivity(CatActivity.feed);

  void play() => startActivity(CatActivity.play);

  /// Fades to [target]. Ignored while any activity is running.
  void goTo(GameLocation target) {
    if (target == location) return;
    _begin(CatGameState.changingLocation, () async {
      if (!await _runner.animate(sec(GameTimings.sceneFadeOut), (t) => _sceneOpacity.value = 1 - t)) {
        return false;
      }
      _location.value = target;
      _scene
        ..catPosition = locationConfig.startPosition
        ..facing = 1
        ..setPose(CatPose.idle);
      return _runner.animate(sec(GameTimings.sceneFadeIn), (t) => _sceneOpacity.value = t);
    });
  }

  /// The player tapped, dragged or held during an activity that asks for it.
  void sendInput(PlayerInputKind kind) => _runner.sendInput(kind);

  /// Freezes the game clock (app backgrounded) or resumes it.
  void setPaused(bool paused) {
    if (_disposed || paused == _paused) return;
    _paused = paused;
    if (paused) {
      _ticker.stop();
    } else {
      _lastElapsed = Duration.zero;
      _ticker.start();
    }
  }

  // ---------------------------------------------------------------------------
  // Sequencing
  // ---------------------------------------------------------------------------

  /// Returns false when the request was ignored.
  bool _begin(CatGameState first, Future<bool> Function() body) {
    if (_disposed || isBusy) return false;
    final s = _runner.restart();
    _clearTransient();
    _setState(first);
    unawaited(_play(s, body));
    return true;
  }

  Future<void> _play(int s, Future<bool> Function() body) async {
    var finished = false;
    try {
      finished = await body();
    } catch (error, stack) {
      _runner.report(error, stack);
    } finally {
      if (_runner.isCurrent(s)) {
        // Always leave a clean scene; if something failed mid-way, put the
        // cat back on safe ground so it can never be stranded (e.g. in a tree).
        _clearTransient();
        if (!finished) _scene.catPosition = locationConfig.startPosition;
        final completed = finished ? _activity : null;
        if (completed != null) _lastCompleted = completed;
        _activity = null;
        _setState(CatGameState.idle);
        if (completed != null) onCompleted?.call(completed);
      }
    }
    if (!_runner.isCurrent(s)) return;
    _wanderIndex = 0;
    await _wander(s);
  }

  /// Plays the idle routine until a newer session replaces [s].
  Future<void> _wander(int s) async {
    while (_runner.isCurrent(s)) {
      final routine = locationConfig.wanderRoutine;
      final step = routine[_wanderIndex % routine.length];
      _wanderIndex = (_wanderIndex + 1) % routine.length;
      final ScriptStep script = switch (step.action) {
        WanderAction.pause => Wait(step.seconds),
        WanderAction.lick => Sequence([Pose(CatPose.lick, sec(GameTimings.lick)), const Pose(CatPose.idle)]),
        WanderAction.sniff => Sequence([Pose(CatPose.sniff, step.seconds), const Pose(CatPose.idle)]),
        WanderAction.walk => _wanderEnabled ? WalkTo(step.target!) : const Wait(1.5),
      };
      if (!await _runner.run(script)) return;
    }
  }

  // ---------------------------------------------------------------------------
  // Clock
  // ---------------------------------------------------------------------------

  void _onTick(Duration elapsed) {
    final dt = math.min(
      (elapsed - _lastElapsed).inMicroseconds / Duration.microsecondsPerSecond,
      GameTimings.maxFrameStep,
    );
    _lastElapsed = elapsed;
    if (dt <= 0) return;
    _scene.advance(dt, GameTimings.stepRate);
    _runner.tick(dt);
    notifyListeners();
  }

  void _clearTransient() {
    _scene.clearTransient();
    if (!_disposed) _sceneOpacity.value = 1;
  }

  void _setState(CatGameState value) {
    if (!_disposed) _state.value = value;
  }

  @override
  void dispose() {
    _disposed = true;
    _runner.dispose();
    _ticker.dispose();
    _state.dispose();
    _location.dispose();
    _sceneOpacity.dispose();
    super.dispose();
  }
}
