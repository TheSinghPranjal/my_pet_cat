import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/animation.dart';
import 'package:flutter/foundation.dart';

import '../animations/cat_animations.dart';
import '../cats/cat_needs.dart';
import '../cats/reaction.dart';
import '../models/cat_game_state.dart';
import '../models/game_timings.dart';
import 'scene_state.dart';
import 'script_step.dart';

/// One timed step, advanced by [ActivityRunner.tick].
class _Job {
  _Job(this.duration, this.onTick, this.until, this.session);

  final double duration;
  final void Function(double t)? onTick;

  /// Ends the job early once true (player input arrived).
  final bool Function()? until;
  final int session;
  final completer = Completer<bool>();
  double elapsed = 0;
}

/// Plays [ScriptStep]s on a [SceneState] against one game clock.
///
/// Every step resolves to `true` when it finished, or `false` when it was
/// cancelled because a newer session ([restart]) or [dispose] took over;
/// scripts stop at the first `false`, so stale steps never touch newer
/// state. Time only moves through [tick], so not ticking (app in the
/// background) freezes every running script, waits included.
class ActivityRunner {
  ActivityRunner(this.scene);

  final SceneState scene;

  /// Reports [Phase] steps.
  void Function(CatGameState state)? onPhase;

  /// Receives [ApplyNeeds] steps.
  void Function(Map<Need, double> deltas)? onNeeds;

  /// Decides a [React] step without a fixed outcome.
  ReactionOutcome Function(String? thingId)? reactionFor;

  /// Multiplies walking speed (the cat's energy).
  double walkSpeedScale = 1;

  final _jobs = <_Job>[];
  final _inputs = {for (final kind in PlayerInputKind.values) kind: 0};
  int _session = 0;
  bool _disposed = false;

  /// Whether the last [PlayerInput] step ran out of time.
  bool lastInputTimedOut = false;

  int get session => _session;

  bool isCurrent(int s) => !_disposed && s == _session;

  /// Cancels everything running (their steps resolve to false) and starts a
  /// new session.
  int restart() {
    _session++;
    final cancelled = List.of(_jobs);
    _jobs.clear();
    for (final job in cancelled) {
      job.completer.complete(false);
    }
    return _session;
  }

  /// The player tapped, dragged or held; wakes a waiting [PlayerInput].
  void sendInput(PlayerInputKind kind) => _inputs[kind] = _inputs[kind]! + 1;

  void dispose() {
    _disposed = true;
    restart();
  }

  // ---------------------------------------------------------------------------
  // Clock
  // ---------------------------------------------------------------------------

  /// Waits [seconds], calling [onTick] with 0..1 progress every frame.
  Future<bool> animate(double seconds, [void Function(double t)? onTick, bool Function()? until]) {
    final job = _Job(seconds, onTick, until, _session);
    _jobs.add(job);
    return job.completer.future;
  }

  /// Advances every running step by [dt] seconds.
  void tick(double dt) {
    for (final job in List.of(_jobs)) {
      if (!_jobs.contains(job)) continue;
      job.elapsed += dt;
      var t = job.duration <= 0 ? 1.0 : math.min(1.0, job.elapsed / job.duration);
      try {
        if (job.until?.call() ?? false) {
          t = 1;
        } else {
          job.onTick?.call(t);
        }
      } catch (error, stack) {
        report(error, stack);
        _jobs.remove(job);
        job.completer.complete(false);
        continue;
      }
      if (t >= 1) {
        _jobs.remove(job);
        job.completer.complete(isCurrent(job.session));
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Steps
  // ---------------------------------------------------------------------------

  Future<bool> run(ScriptStep step) async {
    switch (step) {
      case Sequence(:final steps):
        final s = _session;
        for (final child in steps) {
          if (!isCurrent(s) || !await run(child)) return false;
        }
        return true;
      case Parallel(:final steps):
        return !(await Future.wait([for (final child in steps) run(child)])).contains(false);
      case Repeat(:final count, :final builder):
        final s = _session;
        for (var i = 0; i < count; i++) {
          if (!isCurrent(s) || !await run(builder(i))) return false;
        }
        return true;
      case Wait(:final seconds):
        return animate(seconds);
      case Phase(:final state):
        onPhase?.call(state);
        return true;

      case Pose(:final pose, :final seconds):
        scene.setPose(pose);
        return seconds > 0 ? animate(seconds) : true;
      case WalkTo(:final target, :final endFacing, :final endPose):
        return _walkTo(target, endFacing: endFacing, endPose: endPose);
      case Turn(:final facing):
        return _turnTo(facing);
      case TurnToward(:final point):
        return _turnTo(point.dx >= scene.catPosition.dx ? 1 : -1);
      case MoveCat(:final target, :final seconds, :final curve, :final arc):
        return _moveCat(target, seconds, curve: curve, arc: arc);
      case Pounce(:final target, :final height, :final seconds):
        scene.setPose(CatPose.pounce);
        return _moveCat(target, seconds ?? sec(GameTimings.pounce), curve: Curves.linear, arc: height);
      case SwipePaw():
        return animate(sec(GameTimings.pawSwipe), (t) => scene.swipe = math.sin(t * math.pi));
      case Mark(:final mark, :final seconds):
        scene.mark = mark;
        final ok = await animate(seconds);
        if (ok) scene.mark = CatMark.none;
        return ok;
      case React(:final seconds, :final outcome, :final thingId):
        scene.reaction = outcome ?? reactionFor?.call(thingId) ?? ReactionOutcome.fine;
        final ok = await animate(seconds);
        if (ok) scene.reaction = null;
        return ok;

      case Spawn(:final id, :final kind, :final at, :final facing, :final layerBias, :final focus):
        final object = scene.spawn(id, kind, at, facing: facing, layerBias: layerBias)
          ..fill = step.fill
          ..airborne = step.airborne;
        if (focus) scene.focus = object;
        return true;
      case Appear(:final id):
        final object = _prop(id);
        return animate(sec(GameTimings.objectAppear), (t) => object.appear = t);
      case PopAway(:final id):
        final object = _prop(id);
        if (!await animate(sec(GameTimings.objectPop), (t) => object.pop = t)) return false;
        scene.remove(object);
        return true;
      case Remove(:final id):
        scene.remove(_prop(id));
        return true;
      case Focus(:final id):
        scene.focus = id == null ? null : _prop(id);
        return true;
      case SetProp(:final id, :final fill, :final airborne, :final progress):
        final object = _prop(id);
        if (fill != null) object.fill = fill;
        if (airborne != null) object.airborne = airborne;
        if (progress != null) object.progress = progress;
        return true;
      case MoveProp():
        return _moveProp(step);
      case PropAnim(:final id, :final seconds, :final tween):
        final object = _prop(id);
        final PropStart start = (position: object.position, rotation: object.rotation);
        return animate(seconds, (t) => tween(object, start, t));
      case SceneValue(:final key, :final seconds, :final value):
        return animate(seconds, (t) => scene.values[key] = value(t));
      case SetValue(:final key, :final value):
        scene.values[key] = value;
        return true;
      case TweenValue(:final key, :final to, :final seconds, :final curve):
        final from = scene.value(key);
        return animate(seconds, (t) => scene.values[key] = from + (to - from) * curve.transform(t));

      case Effect(:final kind, :final anchor, :final id, :final duration, :final nearCat):
        scene.addEffect(kind, nearCat ? scene.catPosition + anchor : anchor, duration: duration, id: id);
        return true;
      case Puff(:final at):
        scene.addEffect(EffectKind.puff, at, duration: sec(GameTimings.puff));
        return true;
      case RemoveEffects(:final ids, :final kinds, :final all):
        final named = {for (final id in ids) ?scene.effect(id)};
        scene.removeEffects((e) => all || kinds.contains(e.kind) || named.contains(e));
        return true;
      case FadeEffects():
        final fading = List.of(scene.effects);
        final ok = await animate(sec(GameTimings.effectFade), (t) {
          for (final e in fading) {
            e.fade = 1 - t;
          }
        });
        if (ok) scene.removeEffects(fading.contains);
        return ok;

      case PlayerInput(:final kind, :final timeout):
        final before = _inputs[kind];
        var answered = false;
        final ok = await animate(timeout, null, () => answered = _inputs[kind] != before);
        if (ok) lastInputTimedOut = !answered;
        return ok;
      case ApplyNeeds(:final deltas):
        onNeeds?.call(deltas);
        return true;
    }
  }

  SpawnedObject _prop(String id) => scene.prop(id) ?? (throw StateError('No prop "$id" on stage'));

  /// Walks from the cat's current rendered position to [target] and lands on
  /// it exactly, so repeated trips never drift.
  Future<bool> _walkTo(Offset target, {double? endFacing, CatPose endPose = CatPose.idle}) async {
    final delta = target - scene.catPosition;
    // y spans ~1.6x more pixels than the same normalized x on a 9:16 stage.
    final distance = math.sqrt(delta.dx * delta.dx + math.pow(delta.dy * 1.6, 2));
    if (distance > 0.004) {
      if (delta.dx.abs() > 0.01 && !await _turnTo(delta.dx.sign)) return false;
      scene.setPose(CatPose.walk);
      final speed = GameTimings.walkSpeed * walkSpeedScale;
      final seconds = math.max(GameTimings.minWalkSeconds, distance / speed);
      if (!await _moveCat(target, seconds, curve: Curves.easeInOutSine)) return false;
    }
    scene.catPosition = target;
    scene.setPose(endPose);
    if (endFacing != null) return _turnTo(endFacing);
    return true;
  }

  Future<bool> _moveCat(Offset target, double seconds, {Curve curve = Curves.easeInOut, double arc = 0}) async {
    final start = scene.catPosition;
    final ok = await animate(seconds, (t) {
      scene.catPosition = Offset.lerp(start, target, curve.transform(t))!;
      scene.lift = arc * math.sin(t * math.pi);
    });
    if (ok) {
      scene.catPosition = target;
      scene.lift = 0;
    }
    return ok;
  }

  Future<bool> _turnTo(double target) async {
    final from = scene.facing;
    if (from == target) return true;
    return animate(sec(GameTimings.turn), (t) {
      scene.facing = from + (target - from) * Curves.easeInOut.transform(t);
    });
  }

  Future<bool> _moveProp(MoveProp step) async {
    final object = _prop(step.id);
    final from = object.position;
    final spin = object.rotation;
    final to = step.to;
    final roll = step.rollRadius;
    if (step.faceMovement && (to.dx - from.dx).abs() > 0.005) object.facing = (to.dx - from.dx).sign;
    object.moving = true;
    final ok = await animate(step.seconds, (t) {
      object.position =
          Offset.lerp(from, to, step.curve.transform(t))! +
          Offset(0, -step.arc * math.sin(t * math.pi) + step.wobble * math.sin(t * math.pi * 4));
      if (roll != null) object.rotation = spin + (object.position.dx - from.dx) / roll;
    });
    object.moving = false;
    if (ok) object.position = to;
    return ok;
  }

  void report(Object error, StackTrace stack) {
    FlutterError.reportError(
      FlutterErrorDetails(
        exception: error,
        stack: stack,
        library: 'cat game',
        context: ErrorDescription('while running a cat animation sequence'),
      ),
    );
  }
}
