import 'dart:async';
import 'dart:collection';
import 'dart:math' as math;

import 'package:flutter/animation.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

import '../animations/cat_animations.dart';
import '../models/activity_definition.dart';
import '../models/cat_game_state.dart';
import '../models/game_location.dart';
import '../models/game_positions.dart';
import '../models/game_timings.dart';

part 'home_activities.dart';
part 'bath_activities.dart';
part 'outdoor_activities.dart';

double _sec(Duration d) => d.inMicroseconds / Duration.microsecondsPerSecond;

/// One timed step of a sequence, advanced by the controller's game clock.
class _Job {
  _Job(this.duration, this.onTick, this.session);

  final double duration;
  final void Function(double t)? onTick;
  final int session;
  final completer = Completer<bool>();
  double elapsed = 0;
}

/// Owns the game clock, the selected location and every activity.
///
/// Activities are plain async functions (one per activity, in the
/// `*_activities.dart` part files) built from shared steps such as
/// [_walkTo], [_appear], [_moveObject] and [_popAway]. Each step resolves to
/// `true` when it finished, or `false` when it was cancelled because a newer
/// sequence (or disposal) took over; sequences stop as soon as they see
/// `false`, so stale code can never touch newer state.
///
/// All animation time comes from one [Ticker] with a clamped frame step, so
/// pausing the ticker freezes everything, including waits.
class CatGameController extends ChangeNotifier {
  CatGameController({
    required TickerProvider vsync,
    GameLocation initialLocation = GameLocation.home,
  }) : _location = ValueNotifier(initialLocation) {
    _catPosition = locationConfig.startPosition;
    _ticker = vsync.createTicker(_onTick)..start();
    unawaited(_wander(_session));
  }

  late final Ticker _ticker;
  final _state = ValueNotifier(CatGameState.idle);
  final ValueNotifier<GameLocation> _location;
  final _sceneOpacity = ValueNotifier<double>(1);
  final _jobs = <_Job>[];
  final _objects = <SpawnedObject>[];
  final _effects = <SceneEffect>[];

  int _session = 0;
  int _wanderIndex = 0;
  bool _wanderEnabled = true;
  bool _paused = false;
  bool _disposed = false;
  Duration _lastElapsed = Duration.zero;

  double _time = 0;
  double _poseTime = 0;
  double _walkPhase = 0;
  double _gaze = 0;
  double _gazeY = 0;
  double _swipe = 0;
  double _lift = 0;
  double _tubFoam = 0;
  CatPose _pose = CatPose.idle;
  late Offset _catPosition;
  double _facing = 1;

  CatActivity? _activity;

  /// What the cat's eyes follow during an activity.
  SpawnedObject? _focus;

  ValueListenable<CatGameState> get stateListenable => _state;
  CatGameState get state => _state.value;
  bool get isBusy => state != CatGameState.idle;

  ValueListenable<GameLocation> get locationListenable => _location;
  GameLocation get location => _location.value;
  LocationConfig get locationConfig => Locations.of(location);

  /// 0..1 opacity of the scene, dipped during location changes.
  ValueListenable<double> get sceneOpacity => _sceneOpacity;

  Offset get catPosition => _catPosition;

  /// 1 = facing right, -1 = facing left; values between are mid-turn.
  double get facing => _facing;
  CatPose get pose => _pose;

  /// The activity currently running, if any.
  CatActivity? get activeActivity => _activity;

  /// How much foam is in the bathtub (bath scene prop).
  double get tubFoam => _tubFoam;

  List<SpawnedObject> get objects => UnmodifiableListView(_objects);
  List<SceneEffect> get effects => UnmodifiableListView(_effects);

  SpawnedObject? objectOf(ObjectKind kind) {
    for (final o in _objects) {
      if (o.kind == kind) return o;
    }
    return null;
  }

  SpawnedObject? get bowl => objectOf(ObjectKind.bowl);
  SpawnedObject? get yarn => objectOf(ObjectKind.yarn);

  CatFrame get catFrame => catFrameFor(
        pose: _pose,
        time: _time,
        poseTime: _poseTime,
        walkPhase: _walkPhase,
        gaze: _gaze,
        gazeY: _gazeY,
        swipe: _swipe,
        lift: _lift,
      );

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
    final (CatGameState first, Future<bool> Function() body) = switch (activity) {
      CatActivity.feed => (CatGameState.walkingToFood, _feedSequence),
      CatActivity.play => (CatGameState.walkingToToy, _playSequence),
      CatActivity.catchMouse => (CatGameState.catchingMouse, _catchMouseSequence),
      CatActivity.bathTime => (CatGameState.walkingToBath, _bathTimeSequence),
      CatActivity.brushFur => (CatGameState.brushing, _brushFurSequence),
      CatActivity.towelDry => (CatGameState.drying, _towelDrySequence),
      CatActivity.catchBird => (CatGameState.catchingBird, _catchBirdSequence),
      CatActivity.climbTree => (CatGameState.climbingTree, _climbTreeSequence),
      CatActivity.chaseButterflies => (CatGameState.chasingButterflies, _chaseButterfliesSequence),
    };
    if (_beginInteraction(first, body)) _activity = activity;
  }

  void feed() => startActivity(CatActivity.feed);

  void play() => startActivity(CatActivity.play);

  /// Fades to [target]. Ignored while any activity is running.
  void goTo(GameLocation target) {
    if (target == location) return;
    _beginInteraction(CatGameState.changingLocation, () async {
      if (!await _animate(_sec(GameTimings.sceneFadeOut), (t) => _sceneOpacity.value = 1 - t)) {
        return false;
      }
      _location.value = target;
      _catPosition = locationConfig.startPosition;
      _facing = 1;
      _setPose(CatPose.idle);
      return _animate(_sec(GameTimings.sceneFadeIn), (t) => _sceneOpacity.value = t);
    });
  }

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
  bool _beginInteraction(CatGameState first, Future<bool> Function() body) {
    if (_disposed || isBusy) return false;
    final s = _newSession();
    _clearTransient();
    _setState(first);
    unawaited(_runInteraction(s, body));
    return true;
  }

  Future<void> _runInteraction(int s, Future<bool> Function() body) async {
    var finished = false;
    try {
      finished = await body();
    } catch (error, stack) {
      _report(error, stack);
    } finally {
      if (_isCurrent(s)) {
        // Always leave a clean scene; if something failed mid-way, put the
        // cat back on safe ground so it can never be stranded (e.g. in a tree).
        _clearTransient();
        if (!finished) _catPosition = locationConfig.startPosition;
        _activity = null;
        _setState(CatGameState.idle);
      }
    }
    if (!_isCurrent(s)) return;
    _wanderIndex = 0;
    await _wander(s);
  }

  /// Plays the idle routine until a newer session replaces [s].
  Future<void> _wander(int s) async {
    while (_isCurrent(s)) {
      final routine = locationConfig.wanderRoutine;
      final step = routine[_wanderIndex % routine.length];
      _wanderIndex = (_wanderIndex + 1) % routine.length;
      final bool ok;
      switch (step.action) {
        case WanderAction.pause:
          ok = await _wait(step.seconds);
        case WanderAction.lick:
          _setPose(CatPose.lick);
          ok = await _wait(_sec(GameTimings.lick));
          if (ok) _setPose(CatPose.idle);
        case WanderAction.walk:
          ok = _wanderEnabled ? await _walkTo(step.target!) : await _wait(1.5);
      }
      if (!ok) return;
    }
  }

  // ---------------------------------------------------------------------------
  // Shared steps
  // ---------------------------------------------------------------------------

  /// Walks from the cat's current rendered position to [target] and lands on
  /// it exactly, so repeated trips never drift.
  Future<bool> _walkTo(
    Offset target, {
    double? endFacing,
    CatPose endPose = CatPose.idle,
  }) async {
    final delta = target - _catPosition;
    // y spans ~1.6x more pixels than the same normalized x on a 9:16 stage.
    final distance = math.sqrt(delta.dx * delta.dx + math.pow(delta.dy * 1.6, 2));
    if (distance > 0.004) {
      if (delta.dx.abs() > 0.01 && !await _turnTo(delta.dx.sign)) return false;
      _setPose(CatPose.walk);
      final seconds = math.max(GameTimings.minWalkSeconds, distance / GameTimings.walkSpeed);
      if (!await _moveCat(target, seconds, curve: Curves.easeInOutSine)) return false;
    }
    _catPosition = target;
    _setPose(endPose);
    if (endFacing != null) return _turnTo(endFacing);
    return true;
  }

  /// Moves the cat in its current pose; [arc] lifts it (cat units) mid-way.
  Future<bool> _moveCat(
    Offset target,
    double seconds, {
    Curve curve = Curves.easeInOut,
    double arc = 0,
  }) async {
    final start = _catPosition;
    final ok = await _animate(seconds, (t) {
      _catPosition = Offset.lerp(start, target, curve.transform(t))!;
      _lift = arc * math.sin(t * math.pi);
    });
    if (ok) {
      _catPosition = target;
      _lift = 0;
    }
    return ok;
  }

  /// A playful leap to [target].
  Future<bool> _pounce(Offset target, {double height = 16, Duration? duration}) {
    _setPose(CatPose.pounce);
    return _moveCat(target, _sec(duration ?? GameTimings.pounce), curve: Curves.linear, arc: height);
  }

  Future<bool> _turnTo(double target) async {
    final from = _facing;
    if (from == target) return true;
    return _animate(_sec(GameTimings.turn), (t) {
      _facing = from + (target - from) * Curves.easeInOut.transform(t);
    });
  }

  Future<bool> _turnToward(Offset point) =>
      _turnTo(point.dx >= _catPosition.dx ? 1 : -1);

  Future<bool> _swipePaw() =>
      _animate(_sec(GameTimings.pawSwipe), (t) => _swipe = math.sin(t * math.pi));

  SpawnedObject _spawn(ObjectKind kind, Offset at, {double facing = 1, double layerBias = 0}) {
    final object = SpawnedObject(kind, at, facing: facing)..layerBias = layerBias;
    _objects.add(object);
    return object;
  }

  Future<bool> _appear(SpawnedObject object) =>
      _animate(_sec(GameTimings.objectAppear), (t) => object.appear = t);

  /// Pop-and-fade, then removal.
  Future<bool> _popAway(SpawnedObject object) async {
    if (!await _animate(_sec(GameTimings.objectPop), (t) => object.pop = t)) return false;
    _remove(object);
    return true;
  }

  void _remove(SpawnedObject object) {
    _objects.remove(object);
    if (_focus == object) _focus = null;
  }

  /// Moves an object along a straight segment, optionally hopping ([arc]) or
  /// bobbing ([wobble]), both in normalized height.
  Future<bool> _moveObject(
    SpawnedObject object,
    Offset to,
    double seconds, {
    Curve curve = Curves.easeInOut,
    double arc = 0,
    double wobble = 0,
    bool faceMovement = true,
  }) async {
    final from = object.position;
    if (faceMovement && (to.dx - from.dx).abs() > 0.005) object.facing = (to.dx - from.dx).sign;
    object.moving = true;
    final ok = await _animate(seconds, (t) {
      object.position = Offset.lerp(from, to, curve.transform(t))! +
          Offset(0, -arc * math.sin(t * math.pi) + wobble * math.sin(t * math.pi * 4));
    });
    object.moving = false;
    if (ok) object.position = to;
    return ok;
  }

  SceneEffect _addEffect(EffectKind kind, Offset anchor, {double? duration}) {
    final effect = SceneEffect(kind, anchor, duration: duration);
    _effects.add(effect);
    return effect;
  }

  void _puff(Offset at) => _addEffect(EffectKind.puff, at, duration: _sec(GameTimings.puff));

  /// Fades out (pops) every running effect, then removes them.
  Future<bool> _fadeEffects() async {
    final fading = List.of(_effects);
    final ok = await _animate(_sec(GameTimings.effectFade), (t) {
      for (final e in fading) {
        e.fade = 1 - t;
      }
    });
    if (ok) _effects.removeWhere(fading.contains);
    return ok;
  }

  Future<bool> _wait(double seconds) => _animate(seconds);

  Future<bool> _after(double delay, Future<bool> Function() step) async =>
      await _wait(delay) && await step();

  Future<bool> _all(List<Future<bool>> steps) async =>
      !(await Future.wait(steps)).contains(false);

  Future<bool> _animate(double seconds, [void Function(double t)? onTick]) {
    final job = _Job(seconds, onTick, _session);
    _jobs.add(job);
    return job.completer.future;
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

    _time += dt;
    _poseTime += dt;
    if (_pose == CatPose.walk || _pose == CatPose.climb) {
      _walkPhase += dt * GameTimings.stepRate;
    }
    _updateGaze(dt);
    for (final o in _objects) {
      o.phase += dt;
    }
    for (final e in _effects) {
      e.time += dt;
    }
    _effects.removeWhere((e) => e.duration != null && e.time >= e.duration!);

    for (final job in List.of(_jobs)) {
      if (!_jobs.contains(job)) continue;
      job.elapsed += dt;
      final t = job.duration <= 0 ? 1.0 : math.min(1.0, job.elapsed / job.duration);
      try {
        job.onTick?.call(t);
      } catch (error, stack) {
        _report(error, stack);
        _jobs.remove(job);
        job.completer.complete(false);
        continue;
      }
      if (t >= 1) {
        _jobs.remove(job);
        job.completer.complete(_isCurrent(job.session));
      }
    }
    notifyListeners();
  }

  void _updateGaze(double dt) {
    final focus = _focus;
    var gx = 0.0, gy = 0.0;
    if (focus != null) {
      gx = ((focus.position.dx - _catPosition.dx) * _facing.sign / 0.18).clamp(-1.0, 1.0);
      gy = ((focus.position.dy - (_catPosition.dy - 0.09)) / 0.12).clamp(-1.0, 1.0);
    }
    final k = math.min(1.0, dt * 10);
    _gaze += (gx - _gaze) * k;
    _gazeY += (gy - _gazeY) * k;
  }

  int _newSession() {
    _session++;
    final cancelled = List.of(_jobs);
    _jobs.clear();
    for (final job in cancelled) {
      job.completer.complete(false);
    }
    return _session;
  }

  bool _isCurrent(int s) => !_disposed && s == _session;

  /// Removes every temporary object and effect and resets the pose.
  void _clearTransient() {
    _objects.clear();
    _effects.clear();
    _focus = null;
    _swipe = 0;
    _lift = 0;
    _tubFoam = 0;
    if (!_disposed) _sceneOpacity.value = 1;
    _setPose(CatPose.idle);
  }

  void _setState(CatGameState value) {
    if (!_disposed) _state.value = value;
  }

  void _setPose(CatPose pose) {
    if (_pose != pose) _poseTime = 0;
    _pose = pose;
    if (pose != CatPose.play && pose != CatPose.swat) _swipe = 0;
  }

  void _report(Object error, StackTrace stack) {
    FlutterError.reportError(FlutterErrorDetails(
      exception: error,
      stack: stack,
      library: 'cat game',
      context: ErrorDescription('while running a cat animation sequence'),
    ));
  }

  @override
  void dispose() {
    _disposed = true;
    _newSession();
    _ticker.dispose();
    _state.dispose();
    _location.dispose();
    _sceneOpacity.dispose();
    super.dispose();
  }
}
