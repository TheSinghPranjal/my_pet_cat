import 'dart:math' as math;
import 'dart:ui';

import '../animations/cat_animations.dart';
import '../cats/reaction.dart';
import '../models/cat_game_state.dart';

/// Keys of [SceneState.values] for the scenes' fixed, animated furniture.
abstract final class SceneKeys {
  static const tubFoam = 'bath.tubFoam';
  static const cabinetOpen = 'kitchen.cabinetOpen';
}

/// Everything on stage that scripts move: the cat, temporary props and
/// critters, effects, and animated furniture values.
///
/// It holds no timing of its own; the `ActivityRunner` changes it over time
/// and [advance] only updates the ambient bits (gaze, critter loops).
class SceneState {
  SceneState(this.catPosition);

  Offset catPosition;

  /// 1 = facing right, -1 = facing left; values between are mid-turn.
  double facing = 1;
  CatPose _pose = CatPose.idle;
  double time = 0;
  double poseTime = 0;
  double walkPhase = 0;
  double gaze = 0;
  double gazeY = 0;
  double swipe = 0;
  double lift = 0;
  CatMark mark = CatMark.none;
  ReactionOutcome? reaction;

  final objects = <SpawnedObject>[];
  final effects = <SceneEffect>[];
  final values = <String, double>{};
  final _props = <String, SpawnedObject>{};
  final _effectIds = <String, SceneEffect>{};

  /// What the cat's eyes follow.
  SpawnedObject? focus;

  CatPose get pose => _pose;

  void setPose(CatPose pose) {
    if (_pose != pose) poseTime = 0;
    _pose = pose;
    if (pose != CatPose.play && pose != CatPose.swat) swipe = 0;
  }

  double value(String key) => values[key] ?? 0;

  SpawnedObject? prop(String id) => _props[id];

  SpawnedObject spawn(String id, ObjectKind kind, Offset at, {double facing = 1, double layerBias = 0}) {
    final object = SpawnedObject(kind, at, facing: facing)..layerBias = layerBias;
    final old = _props[id];
    if (old != null) remove(old);
    _props[id] = object;
    objects.add(object);
    return object;
  }

  void remove(SpawnedObject object) {
    objects.remove(object);
    _props.removeWhere((_, o) => o == object);
    if (focus == object) focus = null;
  }

  SceneEffect addEffect(EffectKind kind, Offset anchor, {double? duration, String? id}) {
    final effect = SceneEffect(kind, anchor, duration: duration);
    effects.add(effect);
    if (id != null) _effectIds[id] = effect;
    return effect;
  }

  SceneEffect? effect(String id) => _effectIds[id];

  void removeEffects(bool Function(SceneEffect e) test) {
    effects.removeWhere(test);
    _effectIds.removeWhere((_, e) => !effects.contains(e));
  }

  /// Ambient per-frame updates, before any script step runs this frame.
  void advance(double dt, double walkStepRate) {
    time += dt;
    poseTime += dt;
    if (_pose == CatPose.walk || _pose == CatPose.climb) walkPhase += dt * walkStepRate;
    _updateGaze(dt);
    for (final o in objects) {
      o.phase += dt;
    }
    for (final e in effects) {
      e.time += dt;
    }
    removeEffects((e) => e.duration != null && e.time >= e.duration!);
  }

  void _updateGaze(double dt) {
    final f = focus;
    var gx = 0.0, gy = 0.0;
    if (f != null) {
      gx = ((f.position.dx - catPosition.dx) * facing.sign / 0.18).clamp(-1.0, 1.0);
      gy = ((f.position.dy - (catPosition.dy - 0.09)) / 0.12).clamp(-1.0, 1.0);
    }
    final k = math.min(1.0, dt * 10);
    gaze += (gx - gaze) * k;
    gazeY += (gy - gazeY) * k;
  }

  /// Removes every temporary object and effect and resets the pose.
  void clearTransient() {
    objects.clear();
    effects.clear();
    _props.clear();
    _effectIds.clear();
    values.clear();
    focus = null;
    swipe = 0;
    lift = 0;
    mark = CatMark.none;
    reaction = null;
    setPose(CatPose.idle);
  }
}
