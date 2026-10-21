part of 'cat_game_controller.dart';

extension _BathActivities on CatGameController {
  Future<bool> _bathTimeSequence() async {
    if (!await _walkTo(BathPositions.catBathEntryPosition, endFacing: -1)) return false;

    _setState(CatGameState.bathing);
    // The tub fills with foam, then the kitten hops in.
    _puff(BathPositions.bathBubbleSpawnPosition);
    if (!await _animate(_sec(GameTimings.foam), (t) => _tubFoam = t)) return false;
    if (!await _pounce(BathPositions.catBathPosition, height: 20, duration: GameTimings.tubHop)) {
      return false;
    }

    _setPose(CatPose.relax);
    _addEffect(EffectKind.bubbles, BathPositions.bathBubbleSpawnPosition);
    _addEffect(EffectKind.splash, BathPositions.catBathPosition + const Offset(0, -0.05));
    if (!await _wait(_sec(GameTimings.bath))) return false;

    // Bubbles pop, the kitten hops back out.
    _puff(BathPositions.bathBubbleSpawnPosition);
    if (!await _fadeEffects()) return false;
    if (!await _turnTo(1)) return false;
    if (!await _pounce(BathPositions.catBathEntryPosition, height: 20, duration: GameTimings.tubHop)) {
      return false;
    }
    _setPose(CatPose.idle);

    _setState(CatGameState.returningToIdle);
    return _all([
      _animate(_sec(GameTimings.foam), (t) => _tubFoam = 1 - t),
      _walkTo(BathPositions.catBathReturnPosition),
    ]);
  }

  Future<bool> _brushFurSequence() async {
    final brush = _spawn(ObjectKind.brush, BathPositions.brushSpawnPosition,
        facing: -1, layerBias: 0.1);
    if (!await _appear(brush)) return false;

    // The kitten settles facing the brush, which hops over to its back.
    if (!await _walkTo(BathPositions.catBrushPosition, endFacing: -1, endPose: CatPose.relax)) {
      return false;
    }
    if (!await _moveObject(brush, BathPositions.brushStrokeStart, 0.6,
        arc: 0.06, faceMovement: false)) {
      return false;
    }

    _addEffect(EffectKind.sparkles, BathPositions.brushSparklePosition);
    for (var i = 0; i < GameTimings.brushStrokes; i++) {
      final to = i.isEven ? BathPositions.brushStrokeEnd : BathPositions.brushStrokeStart;
      if (!await _moveObject(brush, to, _sec(GameTimings.brushStroke), faceMovement: false)) {
        return false;
      }
    }

    if (!await _all([_popAway(brush), _fadeEffects()])) return false;
    _setPose(CatPose.happy);
    if (!await _wait(_sec(GameTimings.happy))) return false;

    _setState(CatGameState.returningToIdle);
    return _walkTo(BathPositions.catBrushReturnPosition);
  }

  Future<bool> _towelDrySequence() async {
    if (!await _walkTo(BathPositions.catDryPosition, endFacing: 1, endPose: CatPose.sit)) {
      return false;
    }
    final towel = _spawn(ObjectKind.towel, BathPositions.towelSpawnPosition, layerBias: 0.1);
    if (!await _appear(towel)) return false;

    // Rub-a-dub: the towel moves up and down over the kitten's head.
    _setPose(CatPose.relax);
    for (var i = 0; i < GameTimings.towelRubs; i++) {
      final to = BathPositions.towelRubPositions[i % 2];
      if (!await _moveObject(towel, to, _sec(GameTimings.towelRub), faceMovement: false)) {
        return false;
      }
    }
    if (!await _moveObject(towel, BathPositions.towelSpawnPosition, 0.3, faceMovement: false)) {
      return false;
    }

    // A big shake sends droplets flying.
    _setPose(CatPose.shake);
    _addEffect(EffectKind.droplets, BathPositions.dropletsPosition, duration: _sec(GameTimings.shake));
    if (!await _wait(_sec(GameTimings.shake))) return false;

    if (!await _popAway(towel)) return false;
    _setPose(CatPose.happy);
    if (!await _wait(_sec(GameTimings.happy))) return false;

    _setState(CatGameState.returningToIdle);
    return _walkTo(BathPositions.catDryReturnPosition);
  }
}
