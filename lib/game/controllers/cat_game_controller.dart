import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/animation.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

import '../animations/cat_animations.dart';
import '../models/cat_game_state.dart';
import '../models/game_positions.dart';
import '../models/game_timings.dart';

/// One timed step of a sequence, advanced by the controller's game clock.
class _Job {
  _Job(this.duration, this.onTick, this.session);

  final double duration;
  final void Function(double t)? onTick;
  final int session;
  final completer = Completer<bool>();
  double elapsed = 0;
}

/// Owns the game clock and orchestrates every cat / prop animation.
///
/// Sequences are plain async functions that await [_animate] steps. Each step
/// resolves to `true` when it finished, or `false` when it was cancelled
/// because a newer sequence (or disposal) took over; sequences stop as soon
/// as they see `false`, so stale code can never touch newer state.
///
/// All animation time comes from one [Ticker] with a clamped frame step, so
/// pausing the ticker freezes everything, including waits.
class CatGameController extends ChangeNotifier {
  CatGameController({required TickerProvider vsync}) {
    _ticker = vsync.createTicker(_onTick)..start();
    unawaited(_wander(_session));
  }

  late final Ticker _ticker;
  final _state = ValueNotifier(CatGameState.idle);
  final _jobs = <_Job>[];

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
  double _swipe = 0;
  CatPose _pose = CatPose.idle;
  Offset _catPosition = GamePositions.returnPosition;
  double _facing = 1;
  SpawnedObject? _bowl;
  SpawnedObject? _yarn;

  ValueListenable<CatGameState> get stateListenable => _state;
  CatGameState get state => _state.value;
  bool get isBusy => state != CatGameState.idle;

  Offset get catPosition => _catPosition;

  /// 1 = facing right, -1 = facing left; values between are mid-turn.
  double get facing => _facing;
  CatPose get pose => _pose;
  SpawnedObject? get bowl => _bowl;
  SpawnedObject? get yarn => _yarn;

  CatFrame get catFrame => catFrameFor(
        pose: _pose,
        time: _time,
        poseTime: _poseTime,
        walkPhase: _walkPhase,
        gaze: _gaze,
        swipe: _swipe,
      );

  bool get wanderEnabled => _wanderEnabled;
  set wanderEnabled(bool value) {
    _wanderEnabled = value;
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Public requests
  // ---------------------------------------------------------------------------

  void feed() => _beginInteraction(CatGameState.walkingToFood, _feedSequence);

  void play() => _beginInteraction(CatGameState.walkingToToy, _playSequence);

  /// Cancels whatever is happening, pops leftover props and walks the cat
  /// back to its spot. Always leaves the game idle and usable.
  void callHome() {
    if (_disposed) return;
    final s = _newSession();
    final leftovers = [?_bowl, ?_yarn];
    _swipe = 0;
    _setPose(CatPose.idle);
    _setState(CatGameState.idle);
    unawaited(_guard(() async {
      if (leftovers.isNotEmpty) {
        final popped = await _animate(_sec(GameTimings.objectPop), (t) {
          for (final o in leftovers) {
            o.pop = math.max(o.pop, t);
          }
        });
        if (!popped) return;
        _bowl = null;
        _yarn = null;
      }
      _wanderIndex = GamePositions.homeWanderIndex;
      await _wander(s);
    }));
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
  // Sequences
  // ---------------------------------------------------------------------------

  void _beginInteraction(CatGameState first, Future<bool> Function() body) {
    if (_disposed || isBusy) return;
    final s = _newSession();
    _bowl = null;
    _yarn = null;
    _swipe = 0;
    _setPose(CatPose.idle);
    _setState(first);
    unawaited(_runInteraction(s, body));
  }

  Future<void> _runInteraction(int s, Future<bool> Function() body) async {
    var finished = false;
    try {
      finished = await body();
    } catch (error, stack) {
      _report(error, stack);
    }
    if (!_isCurrent(s)) return; // Superseded; the newer sequence owns state.
    if (!finished) {
      // Something failed mid-way: never leave the game locked.
      _bowl = null;
      _yarn = null;
      _swipe = 0;
      _setPose(CatPose.idle);
    }
    _setState(CatGameState.idle);
    _wanderIndex = 0;
    await _wander(s);
  }

  Future<bool> _feedSequence() async {
    final bowl = _bowl = SpawnedObject(GamePositions.bowlPosition);
    if (!await _animate(_sec(GameTimings.objectAppear), (t) => bowl.appear = t)) {
      return false;
    }
    if (!await _walkTo(GamePositions.feedingPosition, endFacing: -1)) return false;

    _setState(CatGameState.eating);
    _setPose(CatPose.eat);
    if (!await _animate(_sec(GameTimings.eating), (t) => bowl.fill = 1 - 0.8 * t)) {
      return false;
    }

    _setPose(CatPose.happy);
    final done = await Future.wait([
      _animate(_sec(GameTimings.happy)),
      _animate(_sec(GameTimings.objectPop), (t) => bowl.pop = t),
    ]);
    if (done.contains(false)) return false;
    _bowl = null;

    _setState(CatGameState.returningFromFood);
    return _walkTo(GamePositions.returnPosition);
  }

  Future<bool> _playSequence() async {
    final yarn = _yarn = SpawnedObject(GamePositions.yarnStartPosition);
    if (!await _animate(_sec(GameTimings.objectAppear), (t) => yarn.appear = t)) {
      return false;
    }
    if (!await _walkTo(GamePositions.playPosition, endFacing: 1, endPose: CatPose.play)) {
      return false;
    }

    _setState(CatGameState.playing);
    // 1. The ball rolls away to the right while the kitten watches it.
    if (!await _rollYarn(yarn, GamePositions.yarnWaypoints[0], GameTimings.yarnRollOut)) {
      return false;
    }
    // 2. The kitten scoots after it.
    if (!await _walkTo(GamePositions.chasePosition, endPose: CatPose.play)) return false;
    // 3. The ball rolls a little way back.
    if (!await _rollYarn(yarn, GamePositions.yarnWaypoints[1], GameTimings.yarnRollBack)) {
      return false;
    }
    // 4. Two paw swipes; the second bats the ball to its resting spot.
    if (!await _swipePaw()) return false;
    final batted = await Future.wait([
      _swipePaw(),
      _rollYarn(yarn, GamePositions.yarnEndPosition, GameTimings.yarnSettle),
    ]);
    if (batted.contains(false)) return false;

    _setPose(CatPose.happy);
    final done = await Future.wait([
      _animate(_sec(GameTimings.happy)),
      _animate(_sec(GameTimings.objectPop), (t) => yarn.pop = t),
    ]);
    if (done.contains(false)) return false;
    _yarn = null;

    _setState(CatGameState.returningFromPlay);
    return _walkTo(GamePositions.returnPosition);
  }

  /// Plays the idle routine until a newer session replaces [s].
  Future<void> _wander(int s) async {
    const routine = GamePositions.wanderRoutine;
    while (_isCurrent(s)) {
      final step = routine[_wanderIndex];
      _wanderIndex = (_wanderIndex + 1) % routine.length;
      final bool ok;
      switch (step.action) {
        case WanderAction.pause:
          ok = await _animate(step.seconds);
        case WanderAction.lick:
          _setPose(CatPose.lick);
          ok = await _animate(_sec(GameTimings.lick));
          if (ok) _setPose(CatPose.idle);
        case WanderAction.walk:
          ok = _wanderEnabled ? await _walkTo(step.target!) : await _animate(1.5);
      }
      if (!ok) return;
    }
  }

  // ---------------------------------------------------------------------------
  // Building blocks
  // ---------------------------------------------------------------------------

  /// Walks from the cat's current rendered position to [target] and lands on
  /// it exactly, so repeated trips never drift.
  Future<bool> _walkTo(
    Offset target, {
    double? endFacing,
    CatPose endPose = CatPose.idle,
  }) async {
    final start = _catPosition;
    final delta = target - start;
    // y spans ~1.6x more pixels than the same normalized x on a 9:16 stage.
    final distance = math.sqrt(delta.dx * delta.dx + math.pow(delta.dy * 1.6, 2));
    if (distance > 0.004) {
      if (delta.dx.abs() > 0.01 && !await _turnTo(delta.dx.sign)) return false;
      _setPose(CatPose.walk);
      final seconds = math.max(GameTimings.minWalkSeconds, distance / GameTimings.walkSpeed);
      final walked = await _animate(seconds, (t) {
        _catPosition = Offset.lerp(start, target, Curves.easeInOutSine.transform(t))!;
      });
      if (!walked) return false;
    }
    _catPosition = target;
    _setPose(endPose);
    if (endFacing != null) return _turnTo(endFacing);
    return true;
  }

  Future<bool> _turnTo(double target) async {
    final from = _facing;
    if (from == target) return true;
    return _animate(_sec(GameTimings.turn), (t) {
      _facing = from + (target - from) * Curves.easeInOut.transform(t);
    });
  }

  Future<bool> _rollYarn(SpawnedObject yarn, Offset to, Duration duration) {
    final from = yarn.position;
    final spin = yarn.rotation;
    return _animate(_sec(duration), (t) {
      yarn.position = Offset.lerp(from, to, Curves.easeOutCubic.transform(t))!;
      yarn.rotation =
          spin + (yarn.position.dx - from.dx) / GameSizes.yarnRadiusNormalized;
    });
  }

  Future<bool> _swipePaw() =>
      _animate(_sec(GameTimings.pawSwipe), (t) => _swipe = math.sin(t * math.pi));

  Future<bool> _animate(double seconds, [void Function(double t)? onTick]) {
    final job = _Job(seconds, onTick, _session);
    _jobs.add(job);
    return job.completer.future;
  }

  void _onTick(Duration elapsed) {
    final dt = math.min(
      (elapsed - _lastElapsed).inMicroseconds / Duration.microsecondsPerSecond,
      GameTimings.maxFrameStep,
    );
    _lastElapsed = elapsed;
    if (dt <= 0) return;

    _time += dt;
    _poseTime += dt;
    if (_pose == CatPose.walk) _walkPhase += dt * GameTimings.stepRate;
    final yarn = _yarn;
    final gazeTarget = yarn == null
        ? 0.0
        : ((yarn.position.dx - _catPosition.dx) * _facing.sign / 0.18).clamp(-1.0, 1.0);
    _gaze += (gazeTarget - _gaze) * math.min(1, dt * 10);

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

  void _setState(CatGameState value) {
    if (!_disposed) _state.value = value;
  }

  void _setPose(CatPose pose) {
    if (_pose != pose) _poseTime = 0;
    _pose = pose;
    if (pose != CatPose.play) _swipe = 0;
  }

  Future<void> _guard(Future<void> Function() body) async {
    try {
      await body();
    } catch (error, stack) {
      _report(error, stack);
    }
  }

  void _report(Object error, StackTrace stack) {
    FlutterError.reportError(FlutterErrorDetails(
      exception: error,
      stack: stack,
      library: 'cat game',
      context: ErrorDescription('while running a cat animation sequence'),
    ));
  }

  static double _sec(Duration d) => d.inMicroseconds / Duration.microsecondsPerSecond;

  @override
  void dispose() {
    _disposed = true;
    _newSession();
    _ticker.dispose();
    _state.dispose();
    super.dispose();
  }
}
